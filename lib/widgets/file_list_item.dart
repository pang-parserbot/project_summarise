import 'package:flutter/material.dart';
import '../../models/file_item.dart';
import '../../utils/file_utils.dart';

class FileListItem extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;

  const FileListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(),
      trailing: item.isFile ? _buildFileDetails() : null,
      onTap: onTap,
    );
  }

  Widget _buildIcon() {
    if (item.isFolder) {
      return const Icon(Icons.folder, color: Colors.amber);
    }
    
    // 根据文件类型返回不同图标
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
    final lastModified = '修改: ${_formatDate(item.modifiedTime)}';
    
    if (item.isFile) {
      return Text('$lastModified · ${FileUtils.formatFileSize(item.size)}');
    }
    
    return Text(lastModified);
  }

  Widget _buildFileDetails() {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (item.extension != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.extension!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚才';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}