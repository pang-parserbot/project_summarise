enum FileItemType { file, folder }

class FileItem {
  final String path;
  final String name;
  final FileItemType type;
  final DateTime modifiedTime;
  final int size; // 仅对文件有效
  final String? extension; // 仅对文件有效

  const FileItem({
    required this.path,
    required this.name,
    required this.type,
    required this.modifiedTime,
    this.size = 0,
    this.extension,
  });

  bool get isFolder => type == FileItemType.folder;
  bool get isFile => type == FileItemType.file;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type == FileItemType.file ? 'file' : 'folder',
      'modifiedTime': modifiedTime.toIso8601String(),
      'size': size,
      'extension': extension,
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      path: json['path'],
      name: json['name'],
      type: json['type'] == 'file' ? FileItemType.file : FileItemType.folder,
      modifiedTime: DateTime.parse(json['modifiedTime']),
      size: json['size'] ?? 0,
      extension: json['extension'],
    );
  }
}