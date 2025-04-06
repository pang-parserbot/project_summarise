import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/file_item.dart';
import '../models/filter_options.dart';
import '../services/file_service.dart';
import 'filter_provider.dart';

final currentPathProvider = StateProvider<String?>((ref) => null);

final fileSystemProvider = StateNotifierProvider<FileSystemNotifier, AsyncValue<List<FileItem>>>((ref) {
  final fileService = FileService();
  final currentPath = ref.watch(currentPathProvider);
  final filterOptions = ref.watch(filterOptionsProvider);
  
  return FileSystemNotifier(fileService, currentPath, filterOptions);
});

class FileSystemNotifier extends StateNotifier<AsyncValue<List<FileItem>>> {
  final FileService _fileService;
  final String? _currentPath;
  final FilterOptions _filterOptions;

  FileSystemNotifier(this._fileService, this._currentPath, this._filterOptions)
      : super(const AsyncValue.loading()) {
    if (_currentPath != null) {
      _loadFiles();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _loadFiles() async {
    try {
      state = const AsyncValue.loading();
      if (_currentPath == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final items = await _fileService.listDirectory(_currentPath!);
      final filteredItems = _applyFilters(items);

      state = AsyncValue.data(filteredItems);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  List<FileItem> _applyFilters(List<FileItem> items) {
    return items.where((item) {
      // 处理隐藏文件
      if (!_filterOptions.showHiddenFiles && item.name.startsWith('.')) {
        return false;
      }

      // 处理排除的文件夹
      if (item.isFolder) {
        return !_filterOptions.excludedFolders.contains(item.name);
      }

      // 文件类型过滤
      if (item.isFile) {
        // 如果有指定包含的扩展名，且不为空，则检查文件扩展名是否在列表中
        if (_filterOptions.includedExtensions.isNotEmpty) {
          if (item.extension == null) return false;
          if (!_filterOptions.includedExtensions.contains(item.extension)) return false;
        }

        // 检查排除的扩展名
        if (item.extension != null && _filterOptions.excludedExtensions.contains(item.extension)) {
          return false;
        }

        // 文件大小过滤
        if (_filterOptions.minSize != null && item.size < _filterOptions.minSize!) {
          return false;
        }
        if (_filterOptions.maxSize != null && item.size > _filterOptions.maxSize!) {
          return false;
        }
      }

      // 修改时间过滤
      if (_filterOptions.modifiedAfter != null && item.modifiedTime.isBefore(_filterOptions.modifiedAfter!)) {
        return false;
      }
      if (_filterOptions.modifiedBefore != null && item.modifiedTime.isAfter(_filterOptions.modifiedBefore!)) {
        return false;
      }

      // 搜索文本过滤 (只有当有搜索文本时才执行)
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
    await _loadFiles();
  }

  Future<void> navigateToPath(String path) async {
    try {
      if (await Directory(path).exists()) {
        state = const AsyncValue.loading();
        final items = await _fileService.listDirectory(path);
        final filteredItems = _applyFilters(items);
        state = AsyncValue.data(filteredItems);
      } else {
        state = AsyncValue.error("路径不存在", StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}