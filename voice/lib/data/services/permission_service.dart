import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/exceptions.dart';

/// 权限服务
@singleton
class PermissionService {
  /// 检查麦克风权限
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// 请求麦克风权限
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        throw PermissionException.microphonePermanentlyDenied();
      } else {
        throw PermissionException.microphoneDenied();
      }
    } catch (e) {
      if (e is PermissionException) {
        rethrow;
      }
      throw PermissionException.microphoneDenied();
    }
  }

  /// 检查存储权限
  Future<bool> checkStoragePermission() async {
    // Android 10+ 不需要存储权限来访问应用专属目录
    if (Platform.isAndroid) {
      return true;
    }

    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// 请求存储权限
  Future<bool> requestStoragePermission() async {
    try {
      // Android 10+ 不需要存储权限来访问应用专属目录
      if (Platform.isAndroid) {
        return true;
      }

      final status = await Permission.storage.request();

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        throw PermissionException.storageDenied();
      } else {
        throw PermissionException.storageDenied();
      }
    } catch (e) {
      if (e is PermissionException) {
        rethrow;
      }
      throw PermissionException.storageDenied();
    }
  }

  /// 检查所有必需的权限
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'microphone': await checkMicrophonePermission(),
      'storage': await checkStoragePermission(),
    };
  }

  /// 请求所有必需的权限
  Future<bool> requestAllPermissions() async {
    try {
      final microphonePermission = await requestMicrophonePermission();
      final storagePermission = await requestStoragePermission();

      return microphonePermission && storagePermission;
    } catch (e) {
      return false;
    }
  }

  /// 打开应用设置页面
  Future<void> openAppSettings() async {
    await Permission.microphone.request();
  }

  /// 检查权限是否被永久拒绝
  Future<bool> isPermissionPermanentlyDenied(String permissionType) async {
    Permission permission;

    switch (permissionType.toLowerCase()) {
      case 'microphone':
        permission = Permission.microphone;
        break;
      case 'storage':
        permission = Permission.storage;
        break;
      default:
        throw ArgumentError('Unknown permission type: $permissionType');
    }

    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}