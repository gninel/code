import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// 相机服务类
class CameraService {
  static CameraService? _instance;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  CameraService._internal();

  factory CameraService() {
    _instance ??= CameraService._internal();
    return _instance!;
  }

  /// 获取可用相机列表
  List<CameraDescription>? get cameras => _cameras;

  /// 获取当前相机控制器
  CameraController? get controller => _cameraController;

  /// 检查相机权限
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// 请求相机权限
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 初始化相机
  Future<bool> initializeCamera({CameraDescription? camera}) async {
    try {
      // 获取可用相机
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // 选择后置相机，如果没有则使用第一个相机
      final selectedCamera = camera ??
          _cameras!.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras!.first,
          );

      // 创建相机控制器
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      return true;
    } catch (e) {
      debugPrint('相机初始化失败: $e');
      return false;
    }
  }

  /// 切换前后摄像头
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _cameraController == null) {
      return false;
    }

    try {
      final currentCameraIndex = _cameras!.indexOf(_cameraController!.description);
      final nextCameraIndex = (currentCameraIndex + 1) % _cameras!.length;
      final nextCamera = _cameras![nextCameraIndex];

      await _cameraController!.dispose();
      _cameraController = CameraController(
        nextCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      return true;
    } catch (e) {
      debugPrint('切换摄像头失败: $e');
      return false;
    }
  }

  /// 拍照
  Future<String?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }

    try {
      final XFile picture = await _cameraController!.takePicture();
      return picture.path;
    } catch (e) {
      debugPrint('拍照失败: $e');
      return null;
    }
  }

  /// 保存图片到应用目录
  Future<String?> saveImageToAppDirectory(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final foodImagesDir = Directory('${directory.path}/food_images');

      if (!await foodImagesDir.exists()) {
        await foodImagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'food_$timestamp.jpg';
      final savedImagePath = '${foodImagesDir.path}/$fileName';

      final originalFile = File(imagePath);
      await originalFile.copy(savedImagePath);

      return savedImagePath;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return null;
    }
  }

  /// 压缩图片
  Future<String?> compressImage(String imagePath, {int quality = 85, int maxWidth = 1024}) async {
    try {
      final originalFile = File(imagePath);
      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        return null;
      }

      // 计算新尺寸
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxWidth) {
        final ratio = maxWidth / newWidth;
        newWidth = maxWidth;
        newHeight = (newHeight * ratio).round();
      }

      // 调整图片大小
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
      );

      // 压缩图片
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      // 保存压缩后的图片
      final compressedImagePath = imagePath.replaceAll('.jpg', '_compressed.jpg');
      final compressedFile = File(compressedImagePath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedImagePath;
    } catch (e) {
      debugPrint('图片压缩失败: $e');
      return imagePath; // 返回原始路径
    }
  }

  /// 将图片转换为Base64
  Future<String?> imageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('图片转Base64失败: $e');
      return null;
    }
  }

  /// 优化图片用于API上传
  Future<String?> optimizeImageForAPI(String imagePath) async {
    try {
      // 先压缩图片
      final compressedPath = await compressImage(imagePath, quality: 70, maxWidth: 800);
      if (compressedPath == null) return null;

      // 再转换为Base64
      return await imageToBase64(compressedPath);
    } catch (e) {
      debugPrint('优化图片失败: $e');
      return null;
    }
  }

  /// 删除临时图片
  Future<void> deleteTempImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('删除临时图片失败: $e');
    }
  }

  /// 获取图片信息
  Future<Map<String, dynamic>?> getImageInfo(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      return {
        'path': imagePath,
        'size': stat.size,
        'width': image.width,
        'height': image.height,
        'modified': stat.modified,
      };
    } catch (e) {
      debugPrint('获取图片信息失败: $e');
      return null;
    }
  }

  /// 清理应用目录中的旧图片
  Future<void> cleanupOldImages({int daysToKeep = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final foodImagesDir = Directory('${directory.path}/food_images');

      if (!await foodImagesDir.exists()) {
        return;
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final files = await foodImagesDir.list().toList();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            debugPrint('删除旧图片: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('清理旧图片失败: $e');
    }
  }

  /// 释放相机资源
  Future<void> dispose() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
    } catch (e) {
      debugPrint('释放相机资源失败: $e');
    }
  }

  /// 检查相机是否可用
  bool get isCameraAvailable =>
      _cameraController != null && _cameraController!.value.isInitialized;

  /// 获取相机方向
  CameraLensDirection? get cameraDirection =>
      _cameraController?.description.lensDirection;

  /// 检查是否为前置摄像头
  bool get isFrontCamera =>
      cameraDirection == CameraLensDirection.front;

  /// 检查是否为后置摄像头
  bool get isBackCamera =>
      cameraDirection == CameraLensDirection.back;
}