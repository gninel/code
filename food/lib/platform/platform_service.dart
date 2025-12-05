import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/camera_service.dart';
import 'web_camera_service.dart';

/// 平台服务工厂
abstract class PlatformService {
  /// 获取相机服务
  static dynamic getCameraService() {
    if (kIsWeb) {
      return WebCameraService();
    } else {
      return CameraService();
    }
  }

  /// 检查是否支持相机
  static Future<bool> isCameraSupported() async {
    if (kIsWeb) {
      // Web平台支持文件上传
      return true;
    } else {
      final cameraService = CameraService();
      return await cameraService.checkCameraPermission();
    }
  }

  /// 获取平台特定功能描述
  static String getPlatformDescription() {
    if (kIsWeb) {
      return 'Web版本 - 支持图片上传识别';
    } else {
      return '移动版本 - 支持相机拍照识别';
    }
  }

  /// 请求必要权限
  static Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return true; // Web平台无需特殊权限
    } else {
      final cameraService = CameraService();
      return await cameraService.requestCameraPermission();
    }
  }
}