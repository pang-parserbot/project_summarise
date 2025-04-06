import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_options.dart';
import '../services/preferences_service.dart';

final filterOptionsProvider = StateNotifierProvider<FilterOptionsNotifier, FilterOptions>((ref) {
  return FilterOptionsNotifier(PreferencesService());
});

class FilterOptionsNotifier extends StateNotifier<FilterOptions> {
  final PreferencesService _preferencesService;

  FilterOptionsNotifier(this._preferencesService) : super(const FilterOptions()) {
    _loadSavedFilters();
  }

  Future<void> _loadSavedFilters() async {
    final savedFilters = await _preferencesService.getFilterOptions();
    if (savedFilters != null) {
      state = savedFilters;
    }
  }

  Future<void> _saveFilters() async {
    await _preferencesService.saveFilterOptions(state);
  }

  void updateIncludedExtensions(List<String> extensions) {
    state = state.copyWith(includedExtensions: extensions);
    _saveFilters();
  }

  void updateExcludedExtensions(List<String> extensions) {
    state = state.copyWith(excludedExtensions: extensions);
    _saveFilters();
  }

  void updateExcludedFolders(List<String> folders) {
    state = state.copyWith(excludedFolders: folders);
    _saveFilters();
  }

  void updateSearchText(String? text) {
    state = state.copyWith(
      searchText: text,
      clearSearchText: text == null || text.isEmpty,
    );
    _saveFilters();
  }

  void toggleShowHiddenFiles() {
    state = state.copyWith(showHiddenFiles: !state.showHiddenFiles);
    _saveFilters();
  }

  void toggleCaseSensitive() {
    state = state.copyWith(caseSensitive: !state.caseSensitive);
    _saveFilters();
  }

  void updateModifiedDateRange(DateTime? after, DateTime? before) {
    state = state.copyWith(
      modifiedAfter: after,
      modifiedBefore: before,
      clearModifiedAfter: after == null,
      clearModifiedBefore: before == null,
    );
    _saveFilters();
  }

  void updateSizeRange(int? min, int? max) {
    state = state.copyWith(
      minSize: min,
      maxSize: max,
      clearMinSize: min == null,
      clearMaxSize: max == null,
    );
    _saveFilters();
  }

  void resetFilters() {
    state = const FilterOptions();
    _saveFilters();
  }
}