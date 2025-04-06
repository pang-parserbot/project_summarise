import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recent_path.dart';
import '../services/preferences_service.dart';
import 'favorites_provider.dart';

final recentPathsProvider = StateNotifierProvider<RecentPathsNotifier, List<RecentPath>>((ref) {
  final favoritesNotifier = ref.watch(favoritesProvider.notifier);
  return RecentPathsNotifier(PreferencesService(), favoritesNotifier);
});

class RecentPathsNotifier extends StateNotifier<List<RecentPath>> {
  final PreferencesService _preferencesService;
  final FavoritesNotifier _favoritesNotifier;
  static const int _maxRecentCount = 20;

  RecentPathsNotifier(this._preferencesService, this._favoritesNotifier) : super([]) {
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await _preferencesService.getRecentPaths();
    state = recents ?? [];
  }

  Future<void> _saveRecents() async {
    await _preferencesService.saveRecentPaths(state);
  }

  Future<void> addRecentPath(String path) async {
    // 检查是否已存在
    final existingIndex = state.indexWhere((item) => item.path == path);
    
    if (existingIndex >= 0) {
      // 已存在，更新访问时间
      final updated = state[existingIndex].copyWith(
        accessTime: DateTime.now(),
      );
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // 新增记录
      state = [
        ...state,
        RecentPath(
          path: path,
          accessTime: DateTime.now(),
          isFavorite: _favoritesNotifier.isFavorite(path),
        ),
      ];
    }
    
    // 限制最大数量
    if (state.length > _maxRecentCount) {
      // 按日期排序，保留最近访问的
      final sorted = List<RecentPath>.from(state)
        ..sort((a, b) => b.accessTime.compareTo(a.accessTime));
      state = sorted.take(_maxRecentCount).toList();
    }
    
    await _saveRecents();
  }

  Future<void> removeRecentPath(String path) async {
    state = state.where((item) => item.path != path).toList();
    await _saveRecents();
  }

  Future<void> clearRecentPaths() async {
    // 保留收藏项
    state = state.where((item) => item.isFavorite).toList();
    await _saveRecents();
  }
}