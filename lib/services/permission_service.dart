import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// 请求存储权限
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 需要请求存储权限
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS 不需要特别的存储权限
      return true;
    } else {
      // 桌面平台不需要请求权限
      return true;
    }
  }

  /// 检查是否有存储权限
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      return await Permission.storage.isGranted;
    } else {
      return true;
    }
  }

  /// 请求读取外部存储权限 (Android 10+)
  Future<bool> requestExternalStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      return true;
    }
  }

  /// 检查是否可以访问指定路径
  Future<bool> canAccessPath(String path) async {
    try {
      final directory = Directory(path);
      final exists = await directory.exists();
      if (!exists) return false;
      
      // 尝试列出目录内容作为访问测试
      await directory.list().first;
      return true;
    } catch (e) {
      return false;
    }
  }
}