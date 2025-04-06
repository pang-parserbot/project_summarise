import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../models/file_item.dart';

class FileService {
  Future<List<FileItem>> listDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    
    if (!await directory.exists()) {
      throw Exception('目录不存在: $directoryPath');
    }
    
    final List<FileItem> items = [];
    
    try {
      await for (final entity in directory.list()) {
        final stat = await entity.stat();
        final name = path.basename(entity.path);
        
        if (entity is File) {
          final extension = path.extension(name).isNotEmpty 
              ? path.extension(name).substring(1) // 去掉开头的点
              : null;
          
          items.add(FileItem(
            path: entity.path,
            name: name,
            type: FileItemType.file,
            modifiedTime: stat.modified,
            size: stat.size,
            extension: extension,
          ));
        } else if (entity is Directory) {
          items.add(FileItem(
            path: entity.path,
            name: name,
            type: FileItemType.folder,
            modifiedTime: stat.modified,
          ));
        }
      }
      
      // 排序：先文件夹，再文件，各自按名称排序
      items.sort((a, b) {
        if (a.type != b.type) {
          return a.type == FileItemType.folder ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      return items;
    } catch (e) {
      throw Exception('无法列出目录内容: ${e.toString()}');
    }
  }

  Future<String> readFileAsString(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      throw Exception('无法读取文件: ${e.toString()}');
    }
  }

  Future<List<int>> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('无法读取文件: ${e.toString()}');
    }
  }

  String? getFileType(String filePath) {
    return lookupMimeType(filePath);
  }

  Future<void> exportSummary(
    String directoryPath,
    String outputPath,
    List<String> excludedFolders,
    List<String> excludedFiles,
  ) async {
    try {
      final outputFile = File(outputPath);
      final outputSink = outputFile.openWrite();
      
      outputSink.writeln('CODE SUMMARY - Generated ${DateTime.now().toString()}');
      outputSink.writeln('===================================================');
      
      await _processDirectoryForSummary(
        directoryPath,
        outputSink,
        excludedFolders,
        excludedFiles,
      );
      
      await outputSink.close();
    } catch (e) {
      throw Exception('导出代码摘要失败: ${e.toString()}');
    }
  }

  Future<void> _processDirectoryForSummary(
    String directoryPath,
    IOSink outputSink,
    List<String> excludedFolders,
    List<String> excludedFiles,
  ) async {
    final directory = Directory(directoryPath);
    
    if (!await directory.exists()) {
      throw Exception('目录不存在: $directoryPath');
    }
    
    try {
      final entities = await directory.list(recursive: false).toList();
      
      // 处理文件
      for (final entity in entities) {
        final basename = path.basename(entity.path);
        
        if (entity is File) {
          if (excludedFiles.contains(basename)) continue;
          
          outputSink.writeln('\n----- ${entity.path} -----');
          final content = await File(entity.path).readAsString();
          
          // 处理内容：移除import语句等
          final lines = content.split('\n');
          for (final line in lines) {
            if (line.trim().startsWith('import ')) continue;
            outputSink.writeln(line);
          }
        } else if (entity is Directory) {
          final dirName = path.basename(entity.path);
          if (excludedFolders.contains(dirName)) continue;
          
          await _processDirectoryForSummary(
            entity.path,
            outputSink,
            excludedFolders,
            excludedFiles,
          );
        }
      }
    } catch (e) {
      throw Exception('处理目录内容失败: ${e.toString()}');
    }
  }
}