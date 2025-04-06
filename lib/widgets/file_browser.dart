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

class FileBrowser extends ConsumerWidget {
  const FileBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final pathParts = path.split(currentPath);
    final isFavorite = ref.watch(favoritesProvider)
      .any((item) => item.path == currentPath && item.isFavorite);
    
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
          // Path breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (Platform.isWindows && pathParts.length > 1)
                    _buildPathButton(context, ref, pathParts[0] + '\\', pathParts[0])
                  else if (Platform.isWindows)
                    _buildPathButton(context, ref, pathParts[0], pathParts[0])
                  else
                    _buildPathButton(context, ref, '/', '/'),
                  
                  for (int i = Platform.isWindows ? 1 : 1; i < pathParts.length; i++) 
                    Row(
                      children: [
                        const Icon(Icons.chevron_right, size: 16),
                        _buildPathButton(
                          context, 
                          ref, 
                          path.joinAll(pathParts.sublist(0, i + 1)), 
                          pathParts[i],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
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

  Widget _buildPathButton(BuildContext context, WidgetRef ref, String pathToNavigate, String label) {
    return TextButton(
      onPressed: () {
        ref.read(currentPathProvider.notifier).state = pathToNavigate;
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
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(fileSystemProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return FileListItem(
            item: item,
            onTap: () {
              if (item.isFolder) {
                ref.read(currentPathProvider.notifier).state = item.path;
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