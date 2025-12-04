import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Web平台相机服务（使用FileUpload替代相机）
class WebCameraService {
  static WebCameraService? _instance;
  html.FileUploadInputElement? _fileInput;

  WebCameraService._internal();

  factory WebCameraService() {
    _instance ??= WebCameraService._internal();
    return _instance!;
  }

  /// 检查浏览器支持
  bool get isSupported => true; // Web平台始终支持文件上传

  /// 初始化文件选择器
  void initialize() {
    _fileInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false
      ..style.display = 'none';

    _fileInput?.onChange.listen((event) {
      _handleFileSelection();
    });

    html.document.body?.append(_fileInput!);
  }

  /// 选择图片文件
  Future<String?> selectImage() async {
    if (_fileInput == null) {
      initialize();
    }

    try {
      _fileInput?.click();

      // 等待用户选择文件
      final completer = Completer<String?>();

      // 创建临时事件监听器
      void onFileSelected(html.Event event) {
        _fileInput?.removeEventListener('change', onFileSelected);
        _handleFileSelection();
        if (!completer.isCompleted) {
          completer.complete(_getSelectedImagePath());
        }
      }

      _fileInput?.addEventListener('change', onFileSelected);

      // 超时处理
      Timer(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          _fileInput?.removeEventListener('change', onFileSelected);
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint('Web相机服务错误: $e');
      return null;
    }
  }

  /// 处理文件选择
  void _handleFileSelection() {
    final files = _fileInput?.files;
    if (files != null && files.isNotEmpty) {
      debugPrint('选择了图片文件: ${files.first.name}');
    }
  }

  /// 获取选中图片的路径
  String? _getSelectedImagePath() {
    final files = _fileInput?.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      // 创建对象URL
      return html.Url.createObjectUrl(file);
    }
    return null;
  }

  /// 转换图片为Base64
  Future<String?> imageToBase64(String imageUrl) async {
    try {
      final response = await html.HttpRequest.request(
        imageUrl,
        responseType: 'blob',
      );

      if (response.status == 200 && response.response is html.Blob) {
        final reader = html.FileReader();
        final completer = Completer<String?>();

        reader.onLoad.listen((event) {
          if (reader.readyState == html.FileReader.DONE) {
            final result = reader.result as String?;
            completer.complete(result);
          }
        });

        reader.readAsDataUrl(response.response as html.Blob);
        return await completer.future;
      }
    } catch (e) {
      debugPrint('Web图片转Base64失败: $e');
    }
    return null;
  }

  /// 创建文件输入对话框
  Future<String?> showImagePicker() async {
    try {
      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..style.position = 'absolute'
        ..style.left = '-9999px';

      html.document.body?.append(input);

      final completer = Completer<String?>();

      input.onChange.listen((event) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files.first;
          final url = html.Url.createObjectUrl(file);
          completer.complete(url);
        } else {
          completer.complete(null);
        }
        input.remove();
      });

      input.click();

      return await completer.future;
    } catch (e) {
      debugPrint('显示图片选择器失败: $e');
      return null;
    }
  }

  /// 验证图片文件
  Future<bool> validateImageFile(String imageUrl) async {
    try {
      final response = await html.HttpRequest.request(
        imageUrl,
        method: 'HEAD',
      );

      if (response.status == 200) {
        final contentType = response.getResponseHeader('content-type');
        return contentType?.startsWith('image/') ?? false;
      }
    } catch (e) {
      debugPrint('验证图片文件失败: $e');
    }
    return false;
  }

  /// 获取图片信息
  Future<Map<String, dynamic>?> getImageInfo(String imageUrl) async {
    try {
      final image = html.ImageElement();
      final completer = Completer<Map<String, dynamic>?>();

      image.onLoad.listen((event) {
        final info = {
          'width': image.width,
          'height': image.height,
          'naturalWidth': image.naturalWidth,
          'naturalHeight': image.naturalHeight,
        };
        completer.complete(info);
      });

      image.onError.listen((event) {
        completer.complete(null);
      });

      image.src = imageUrl;
      return await completer.future;
    } catch (e) {
      debugPrint('获取图片信息失败: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    _fileInput?.remove();
    _fileInput = null;
  }
}