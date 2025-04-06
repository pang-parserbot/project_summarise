import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_options.dart';
import '../models/recent_path.dart';

class PreferencesService {
  static const String _filterOptionsKey = 'filter_options';
  static const String _recentPathsKey = 'recent_paths';
  static const String _favoritesKey = 'favorites';

  // 过滤器选项相关操作
  Future<FilterOptions?> getFilterOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final filterOptionsJson = prefs.getString(_filterOptionsKey);
    
    if (filterOptionsJson == null) return null;
    
    try {
      final Map<String, dynamic> json = jsonDecode(filterOptionsJson);
      return FilterOptions.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveFilterOptions(FilterOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(options.toJson());
    await prefs.setString(_filterOptionsKey, json);
  }

  // 最近路径相关操作
  Future<List<RecentPath>?> getRecentPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final recentPathsJson = prefs.getString(_recentPathsKey);
    
    if (recentPathsJson == null) return null;
    
    try {
      final List<dynamic> jsonList = jsonDecode(recentPathsJson);
      return jsonList.map((json) => RecentPath.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> saveRecentPaths(List<RecentPath> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = paths.map((path) => path.toJson()).toList();
    final json = jsonEncode(jsonList);
    await prefs.setString(_recentPathsKey, json);
  }

  // 收藏夹相关操作
  Future<List<RecentPath>?> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson == null) return null;
    
    try {
      final List<dynamic> jsonList = jsonDecode(favoritesJson);
      return jsonList.map((json) => RecentPath.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> saveFavorites(List<RecentPath> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map((path) => path.toJson()).toList();
    final json = jsonEncode(jsonList);
    await prefs.setString(_favoritesKey, json);
  }
}