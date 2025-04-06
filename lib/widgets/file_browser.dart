import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../models/file_item.dart';
import '../../providers/file_system_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/recent_provider.dart';
import '../screens/code_viewer_screen.dart';
import 'file_list_item.dart';

class FileBrowser extends ConsumerStatefulWidget {
  const FileBrowser({super.key});

  @override
  ConsumerState<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends ConsumerState<FileBrowser> {
  // 主列表控制器
  final ScrollController _listScrollController = ScrollController();

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = ref.watch(currentPathProvider);
    final fileSystemState = ref.watch(fileSystemProvider);
    
    return Column(
      children: [
        if (currentPath != null) _buildPathNavigator(context, ref, currentPath),
        Expanded(
          child: fileSystemState.when(
            data: (items) => _buildFileList(context, ref, items),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading files',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(fileSystemProvider.notifier).refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathNavigator(BuildContext context, WidgetRef ref, String currentPath) {
    final pathSegments = _getPathSegments(currentPath);
    final isFavorite = ref.watch(favoritesProvider)
      .any((item) => item.path == currentPath && item.isFavorite);
    final canNavigateBack = ref.watch(fileSystemProvider.notifier).canGoBack;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      width: double.infinity,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Go back (Ctrl+Z)',
            onPressed: canNavigateBack 
                ? () => ref.read(fileSystemProvider.notifier).navigateBack()
                : null,
          ),
          
          // Up navigation button
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: 'Go to parent folder (Alt+Up)',
            onPressed: () => ref.read(fileSystemProvider.notifier).navigateUp(),
          ),
          
          // Project name / root folder indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pathSegments.isNotEmpty ? pathSegments[0] : path.basename(currentPath),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Path breadcrumbs - 移除滚动条，简化结构
          if (pathSegments.length > 1)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 1; i < pathSegments.length; i++) 
                      Row(
                        children: [
                          const Icon(Icons.chevron_right, size: 16),
                          _buildPathButton(
                            context, 
                            ref, 
                            _buildPathFromSegments(pathSegments.sublist(0, i + 1), currentPath), 
                            pathSegments[i],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          
          // Favorite button
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
              size: 20,
            ),
            onPressed: () {
              if (isFavorite) {
                ref.read(favoritesProvider.notifier).removeFavorite(currentPath);
              } else {
                ref.read(favoritesProvider.notifier).addFavorite(currentPath);
              }
            },
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
    );
  }

  // Get simplified path segments for display
  List<String> _getPathSegments(String fullPath) {
    final segments = <String>[];
    
    // Get the project name (last folder in the path)
    final projectName = path.basename(fullPath);
    segments.add(projectName);
    
    // Get subdirectories if any
    final pathParts = path.split(fullPath);
    final rootIndex = pathParts.indexOf(projectName);
    
    if (rootIndex >= 0 && rootIndex < pathParts.length - 1) {
      segments.addAll(pathParts.sublist(rootIndex + 1));
    }
    
    return segments;
  }
  
  // Build full path from segments
  String _buildPathFromSegments(List<String> segments, String currentFullPath) {
    final fullParts = path.split(currentFullPath);
    final projectName = segments[0];
    final rootIndex = fullParts.indexOf(projectName);
    
    if (rootIndex >= 0) {
      final basePath = path.joinAll(fullParts.sublist(0, rootIndex + 1));
      if (segments.length > 1) {
        return path.join(basePath, path.joinAll(segments.sublist(1)));
      }
      return basePath;
    }
    
    return currentFullPath;
  }

  Widget _buildPathButton(BuildContext context, WidgetRef ref, String pathToNavigate, String label) {
    return TextButton(
      onPressed: () {
        // Use navigateToPath for proper history tracking
        ref.read(fileSystemProvider.notifier).navigateToPath(pathToNavigate);
        ref.read(recentPathsProvider.notifier).addRecentPath(pathToNavigate);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(
        label.isEmpty ? '/' : label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFileList(BuildContext context, WidgetRef ref, List<FileItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Empty folder',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'This folder contains no files or folders',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // 使用primary: true代替Scrollbar
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(fileSystemProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _listScrollController,
        primary: false, // 避免使用PrimaryScrollController
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return FileListItem(
            item: item,
            onTap: () {
              if (item.isFolder) {
                // Use navigateToPath for proper history tracking
                ref.read(fileSystemProvider.notifier).navigateToPath(item.path);
                ref.read(recentPathsProvider.notifier).addRecentPath(item.path);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CodeViewerScreen(filePath: item.path),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}