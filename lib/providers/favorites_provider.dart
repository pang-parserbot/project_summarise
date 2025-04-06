import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recent_path.dart';
import '../services/preferences_service.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<RecentPath>>((ref) {
  return FavoritesNotifier(PreferencesService());
});

class FavoritesNotifier extends StateNotifier<List<RecentPath>> {
  final PreferencesService _preferencesService;

  FavoritesNotifier(this._preferencesService) : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _preferencesService.getFavorites();
    state = favorites ?? [];
  }

  Future<void> _saveFavorites() async {
    await _preferencesService.saveFavorites(state);
  }

  Future<void> addFavorite(String path) async {
    // 检查是否已存在
    final existingIndex = state.indexWhere((item) => item.path == path);
    
    if (existingIndex >= 0) {
      // 已存在，更新访问时间
      final updated = state[existingIndex].copyWith(
        accessTime: DateTime.now(),
        isFavorite: true,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // 新增收藏
      state = [
        ...state,
        RecentPath(
          path: path,
          accessTime: DateTime.now(),
          isFavorite: true,
        ),
      ];
    }
    
    await _saveFavorites();
  }

  Future<void> removeFavorite(String path) async {
    state = state.where((item) => item.path != path).toList();
    await _saveFavorites();
  }

  bool isFavorite(String path) {
    return state.any((item) => item.path == path && item.isFavorite);
  }
}