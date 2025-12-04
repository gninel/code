import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// 内部任务类，用于传递参数给 compute
class _ResizeTaskParams {
  final String imagePath;
  final int maxWidth;
  final int maxHeight;

  _ResizeTaskParams(this.imagePath, this.maxWidth, this.maxHeight);
}

/// 顶层函数，用于 compute 执行
Future<String?> _resizeImageTask(_ResizeTaskParams params) async {
  try {
    final file = File(params.imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return null;

    // 计算新尺寸，保持宽高比
    int newWidth = image.width;
    int newHeight = image.height;

    if (newWidth > params.maxWidth || newHeight > params.maxHeight) {
      final widthRatio = params.maxWidth / newWidth;
      final heightRatio = params.maxHeight / newHeight;
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      newWidth = (newWidth * ratio).round();
      newHeight = (newHeight * ratio).round();
    }

    final resizedImage = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
    );

    final resizedBytes = img.encodeJpg(resizedImage, quality: 60);
    
    // 使用系统临时目录而不是原图所在目录
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final resizedPath = '${tempDir.path}/resized_$timestamp.jpg';
        
    await File(resizedPath).writeAsBytes(resizedBytes);

    return resizedPath;
  } catch (e) {
    debugPrint('调整图片尺寸任务失败: $e');
    return null;
  }
}

/// 图片处理工具类
class ImageUtils {
  /// 裁剪图片为正方形
  static Future<String?> cropSquare(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final size = image.width < image.height ? image.width : image.height;
      final x = (image.width - size) ~/ 2;
      final y = (image.height - size) ~/ 2;

      final croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      final croppedBytes = img.encodeJpg(croppedImage, quality: 85);
      final croppedPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
      await File(croppedPath).writeAsBytes(croppedBytes);

      return croppedPath;
    } catch (e) {
      print('裁剪图片失败: $e');
      return null;
    }
  }

  /// 调整图片尺寸
  static Future<String?> resizeImage(String imagePath, int maxWidth, int maxHeight) async {
    return compute(_resizeImageTask, _ResizeTaskParams(imagePath, maxWidth, maxHeight));
  }

  /// 旋转图片
  static Future<String?> rotateImage(String imagePath, double angle) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final rotatedImage = img.copyRotate(image, angle: angle);
      final rotatedBytes = img.encodeJpg(rotatedImage, quality: 85);
      final rotatedPath = imagePath.replaceAll('.jpg', '_rotated.jpg');
      await File(rotatedPath).writeAsBytes(rotatedBytes);

      return rotatedPath;
    } catch (e) {
      print('旋转图片失败: $e');
      return null;
    }
  }

  /// 调整图片亮度
  /*
  static Future<String?> adjustBrightness(String imagePath, double brightness) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final adjustedImage = img.brightness(image, brightness);
      final adjustedBytes = img.encodeJpg(adjustedImage, quality: 85);
      final adjustedPath = imagePath.replaceAll('.jpg', '_brightness.jpg');
      await File(adjustedPath).writeAsBytes(adjustedBytes);

      return adjustedPath;
    } catch (e) {
      print('调整亮度失败: $e');
      return null;
    }
  }
  */

  /// 调整图片对比度
  /*
  static Future<String?> adjustContrast(String imagePath, double contrast) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final adjustedImage = img.contrast(image, contrast);
      final adjustedBytes = img.encodeJpg(adjustedImage, quality: 85);
      final adjustedPath = imagePath.replaceAll('.jpg', '_contrast.jpg');
      await File(adjustedPath).writeAsBytes(adjustedBytes);

      return adjustedPath;
    } catch (e) {
      print('调整对比度失败: $e');
      return null;
    }
  }
  */

  /// 添加水印
  /*
  static Future<String?> addWatermark(
    String imagePath,
    String watermark, {
    int fontSize = 24,
    int x = 10,
    int y = 10,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // 创建水印文字
      final font = img.arial24;
      final watermarkedImage = img.drawString(image, font, x, y, watermark);

      final watermarkedBytes = img.encodeJpg(watermarkedImage, quality: 85);
      final watermarkedPath = imagePath.replaceAll('.jpg', '_watermarked.jpg');
      await File(watermarkedPath).writeAsBytes(watermarkedBytes);

      return watermarkedPath;
    } catch (e) {
      print('添加水印失败: $e');
      return null;
    }
  }
  */

  /// 创建缩略图
  static Future<String?> createThumbnail(
    String imagePath,
    int thumbnailSize, {
    int quality = 70,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // 创建缩略图
      final thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
      );

      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);
      final thumbnailPath = imagePath.replaceAll('.jpg', '_thumb.jpg');
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);

      return thumbnailPath;
    } catch (e) {
      print('创建缩略图失败: $e');
      return null;
    }
  }

  /// 检查图片格式
  static String? getImageFormat(String imagePath) {
    try {
      final extension = path.extension(imagePath).toLowerCase();
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          return 'JPEG';
        case '.png':
          return 'PNG';
        case '.gif':
          return 'GIF';
        case '.webp':
          return 'WebP';
        case '.bmp':
          return 'BMP';
        default:
          return 'Unknown';
      }
    } catch (e) {
      print('获取图片格式失败: $e');
      return null;
    }
  }

  /// 检查图片是否有效
  static Future<bool> isValidImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      print('检查图片有效性失败: $e');
      return false;
    }
  }

  /// 获取图片文件大小（KB）
  static Future<double?> getImageSizeKB(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.length();
      return bytes / 1024; // 转换为KB
    } catch (e) {
      print('获取图片大小失败: $e');
      return null;
    }
  }

  /// 比较两个图片是否相同
  static Future<bool> compareImages(String imagePath1, String imagePath2) async {
    try {
      final file1 = File(imagePath1);
      final file2 = File(imagePath2);

      if (!await file1.exists() || !await file2.exists()) {
        return false;
      }

      final bytes1 = await file1.readAsBytes();
      final bytes2 = await file2.readAsBytes();

      if (bytes1.length != bytes2.length) {
        return false;
      }

      for (int i = 0; i < bytes1.length; i++) {
        if (bytes1[i] != bytes2[i]) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('比较图片失败: $e');
      return false;
    }
  }

  /// 批量处理图片
  static Future<List<String>> batchProcessImages(
    List<String> imagePaths,
    Future<String?> Function(String) processor,
  ) async {
    final List<String> processedPaths = [];

    for (final imagePath in imagePaths) {
      try {
        final processedPath = await processor(imagePath);
        if (processedPath != null) {
          processedPaths.add(processedPath);
        }
      } catch (e) {
        print('处理图片失败 $imagePath: $e');
      }
    }

    return processedPaths;
  }

  /// 清理临时图片文件
  static Future<void> cleanupTempImages(List<String> imagePaths) async {
    for (final imagePath in imagePaths) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('删除临时图片失败 $imagePath: $e');
      }
    }
  }
}