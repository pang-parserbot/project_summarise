import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/file_item.dart';
import '../models/filter_options.dart';
import '../services/file_service.dart';
import 'filter_provider.dart';

// Navigation history provider
final navigationHistoryProvider = StateNotifierProvider<NavigationHistoryNotifier, List<String>>((ref) {
  return NavigationHistoryNotifier();
});

class NavigationHistoryNotifier extends StateNotifier<List<String>> {
  NavigationHistoryNotifier() : super([]);
  
  void addPath(String path) {
    // Only add path if it's different from the current one
    if (state.isEmpty || state.last != path) {
      state = [...state, path];
    }
  }
  
  String? goBack() {
    if (state.length > 1) {
      final newState = [...state];
      newState.removeLast(); // Remove current path
      final previousPath = newState.last; // Get previous path
      state = newState;
      return previousPath;
    }
    return null;
  }
  
  void clear() {
    state = [];
  }
  
  bool get canGoBack => state.length > 1;
}

// Current path provider
final currentPathProvider = StateProvider<String?>((ref) => null);

// File system provider
final fileSystemProvider = StateNotifierProvider<FileSystemNotifier, AsyncValue<List<FileItem>>>((ref) {
  final fileService = FileService();
  final currentPath = ref.watch(currentPathProvider);
  final filterOptions = ref.watch(filterOptionsProvider);
  
  return FileSystemNotifier(ref, fileService, currentPath, filterOptions);
});

class FileSystemNotifier extends StateNotifier<AsyncValue<List<FileItem>>> {
  final FileService _fileService;
  final String? _currentPath;
  final FilterOptions _filterOptions;
  final Ref _ref;
  bool _disposed = false;

  FileSystemNotifier(this._ref, this._fileService, this._currentPath, this._filterOptions)
      : super(const AsyncValue.loading()) {
    if (_currentPath != null) {
      _loadFiles();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadFiles() async {
    try {
      if (_disposed) return;
      
      state = const AsyncValue.loading();
      if (_currentPath == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final items = await _fileService.listDirectory(_currentPath!);
      if (_disposed) return;
      
      final filteredItems = _applyFilters(items);
      state = AsyncValue.data(filteredItems);
    } catch (e) {
      if (_disposed) return;
      state = AsyncValue.error("Failed to load directory contents: ${e.toString()}", StackTrace.current);
    }
  }

  List<FileItem> _applyFilters(List<FileItem> items) {
    return items.where((item) {
      // Handle hidden files
      if (!_filterOptions.showHiddenFiles && item.name.startsWith('.')) {
        return false;
      }

      // Handle excluded folders
      if (item.isFolder) {
        return !_filterOptions.excludedFolders.contains(item.name);
      }

      // File type filtering
      if (item.isFile) {
        // If included extensions are specified, check if file extension is in the list
        if (_filterOptions.includedExtensions.isNotEmpty) {
          if (item.extension == null) return false;
          if (!_filterOptions.includedExtensions.contains(item.extension)) return false;
        }

        // Check excluded extensions
        if (item.extension != null && _filterOptions.excludedExtensions.contains(item.extension)) {
          return false;
        }

        // File size filtering
        if (_filterOptions.minSize != null && item.size < _filterOptions.minSize!) {
          return false;
        }
        if (_filterOptions.maxSize != null && item.size > _filterOptions.maxSize!) {
          return false;
        }
      }

      // Modified date filtering
      if (_filterOptions.modifiedAfter != null && item.modifiedTime.isBefore(_filterOptions.modifiedAfter!)) {
        return false;
      }
      if (_filterOptions.modifiedBefore != null && item.modifiedTime.isAfter(_filterOptions.modifiedBefore!)) {
        return false;
      }

      // Text search filtering (only execute when search text exists)
      if (_filterOptions.searchText != null && _filterOptions.searchText!.isNotEmpty) {
        final searchText = _filterOptions.caseSensitive
            ? _filterOptions.searchText!
            : _filterOptions.searchText!.toLowerCase();
        final itemName = _filterOptions.caseSensitive
            ? item.name
            : item.name.toLowerCase();

        if (!itemName.contains(searchText)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    await _loadFiles();
  }

  // Navigate to a new path and add it to history
  Future<void> navigateToPath(String path) async {
    try {
      if (_disposed) return;
      
      if (await Directory(path).exists()) {
        if (_disposed) return;
        state = const AsyncValue.loading();
        
        // Add path to navigation history
        _ref.read(navigationHistoryProvider.notifier).addPath(path);
        
        // Update current path
        _ref.read(currentPathProvider.notifier).state = path;
        
        final items = await _fileService.listDirectory(path);
        if (_disposed) return;
        
        final filteredItems = _applyFilters(items);
        state = AsyncValue.data(filteredItems);
      } else {
        if (_disposed) return;
        state = AsyncValue.error("Path does not exist", StackTrace.current);
      }
    } catch (e) {
      if (_disposed) return;
      state = AsyncValue.error("Failed to navigate to path: ${e.toString()}", StackTrace.current);
    }
  }
  
  // Navigate back to previous path in history
  Future<bool> navigateBack() async {
    if (_disposed) return false;
    
    final historyNotifier = _ref.read(navigationHistoryProvider.notifier);
    
    if (!historyNotifier.canGoBack) {
      return false;
    }
    
    final previousPath = historyNotifier.goBack();
    
    if (previousPath != null) {
      try {
        if (_disposed) return false;
        state = const AsyncValue.loading();
        
        // Update current path reference
        _ref.read(currentPathProvider.notifier).state = previousPath;
        
        final items = await _fileService.listDirectory(previousPath);
        if (_disposed) return false;
        
        final filteredItems = _applyFilters(items);
        state = AsyncValue.data(filteredItems);
        return true;
      } catch (e) {
        if (_disposed) return false;
        state = AsyncValue.error("Failed to navigate back: ${e.toString()}", StackTrace.current);
      }
    }
    return false;
  }
  
  // Get parent directory and navigate to it
  Future<bool> navigateUp() async {
    if (_disposed) return false;
    if (_currentPath == null) return false;
    
    final parent = path.dirname(_currentPath!);
    
    // Check if we're already at root
    if (parent == _currentPath) return false;
    
    await navigateToPath(parent);
    return true;
  }
  
  // Check if navigation back is possible
  bool get canGoBack => !_disposed && _ref.read(navigationHistoryProvider.notifier).canGoBack;
}