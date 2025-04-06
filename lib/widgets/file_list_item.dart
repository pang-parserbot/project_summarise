import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_summarise/models/file_item.dart';
import 'package:project_summarise/providers/code_summary_provider.dart' show summaryOptionsProvider;
import 'package:project_summarise/utils/file_utils.dart';

class FileListItem extends ConsumerWidget {
  final FileItem item;
  final VoidCallback onTap;

  const FileListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryOptions = ref.watch(summaryOptionsProvider);
    final isExcluded = item.isFolder 
        ? summaryOptions.excludedFolders.contains(item.name)
        : summaryOptions.excludedFiles.contains(item.name);

    return ListTile(
      leading: _buildIcon(),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Include in summary switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Include:', 
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: !isExcluded,
                onChanged: (value) {
                  if (item.isFolder) {
                    if (value) {
                      // Include folder (remove from excluded)
                      ref.read(summaryOptionsProvider.notifier).removeExcludedFolder(item.name);
                    } else {
                      // Exclude folder (add to excluded)
                      ref.read(summaryOptionsProvider.notifier).addExcludedFolder(item.name);
                    }
                  } else {
                    if (value) {
                      // Include file (remove from excluded)
                      ref.read(summaryOptionsProvider.notifier).removeExcludedFile(item.name);
                    } else {
                      // Exclude file (add to excluded)
                      ref.read(summaryOptionsProvider.notifier).addExcludedFile(item.name);
                    }
                  }
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (item.isFile) _buildFileDetails(),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildIcon() {
    if (item.isFolder) {
      return const Icon(Icons.folder, color: Colors.amber);
    }
    
    // Return different icons based on file type
    if (item.extension != null) {
      switch (item.extension!.toLowerCase()) {
        case 'dart':
          return const Icon(Icons.code, color: Colors.blue);
        case 'json':
          return const Icon(Icons.data_object, color: Colors.orange);
        case 'md':
          return const Icon(Icons.description, color: Colors.green);
        case 'yaml':
        case 'yml':
          return const Icon(Icons.settings, color: Colors.purple);
        case 'png':
        case 'jpg':
        case 'jpeg':
        case 'gif':
          return const Icon(Icons.image, color: Colors.pink);
        default:
          return const Icon(Icons.insert_drive_file);
      }
    }
    
    return const Icon(Icons.insert_drive_file);
  }

  Widget _buildSubtitle() {
    final lastModified = 'Modified: ${_formatDate(item.modifiedTime)}';
    
    if (item.isFile) {
      return Text('$lastModified · ${FileUtils.formatFileSize(item.size)}');
    }
    
    return Text(lastModified);
  }

  Widget _buildFileDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        item.extension?.toUpperCase() ?? '',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}