import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_service.dart';

/// 相机拍照界面
class CameraScreen extends StatefulWidget {
  final Function(String) onPictureTaken;

  const CameraScreen({
    Key? key,
    required this.onPictureTaken,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _hasPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraService.controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// 初始化相机
  Future<void> _initializeCamera() async {
    try {
      // 检查权限
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        setState(() {
          _error = '需要相机权限才能拍照';
          _hasPermission = false;
        });
        return;
      }

      setState(() {
        _hasPermission = true;
      });

      // 初始化相机
      final success = await _cameraService.initializeCamera();
      if (success) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      } else {
        setState(() {
          _error = '相机初始化失败';
          _isInitialized = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '相机初始化错误: $e';
        _isInitialized = false;
      });
    }
  }

  /// 检查权限
  Future<bool> _checkPermissions() async {
    final status = await _cameraService.checkCameraPermission();
    if (!status) {
      return await _requestPermissions();
    }
    return true;
  }

  /// 请求权限
  Future<bool> _requestPermissions() async {
    final status = await _cameraService.requestCameraPermission();
    if (!status) {
      _showPermissionDialog();
      return false;
    }
    return true;
  }

  /// 显示权限对话框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要相机权限'),
          content: const Text('为了识别食物热量，需要访问相机拍照。请在设置中允许相机权限。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回上一页
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  /// 拍照
  Future<void> _takePicture() async {
    if (!_isInitialized || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      // 拍照
      final imagePath = await _cameraService.takePicture();
      if (imagePath == null) {
        throw Exception('拍照失败');
      }

      // 保存图片到应用目录
      final savedPath = await _cameraService.saveImageToAppDirectory(imagePath);
      if (savedPath == null) {
        throw Exception('保存图片失败');
      }

      // 优化图片用于API上传 - 已移除，由ApiService统一处理
      // await _cameraService.optimizeImageForAPI(savedPath);

      // 删除临时图片
      await _cameraService.deleteTempImage(imagePath);

      // 返回拍照结果
      if (mounted) {
        widget.onPictureTaken(savedPath);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('拍照失败', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  /// 切换摄像头
  Future<void> _switchCamera() async {
    if (!_isInitialized || _isTakingPicture) return;

    setState(() {
      _isInitialized = false;
    });

    final success = await _cameraService.switchCamera();

    if (mounted) {
      setState(() {
        _isInitialized = success;
      });
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('拍照识别食物'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isInitialized && _cameraService.cameras != null && _cameraService.cameras!.length > 1)
            IconButton(
              icon: Icon(
                _cameraService.isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                color: Colors.white,
              ),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorView();
    }

    if (!_hasPermission) {
      return _buildPermissionView();
    }

    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return _buildCameraView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '相机错误',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _initializeCamera();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '需要相机权限',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请允许访问相机以拍照识别食物',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _requestPermissions().then((granted) {
                if (granted) {
                  _initializeCamera();
                }
              }),
              child: const Text('授予权限'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            '正在初始化相机...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _cameraService.controller!;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 相机预览
        Center(
          child: CameraPreview(
            controller,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 拍照指导框
        Center(
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    color: Colors.white70,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '将食物放入框内',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 控制按钮
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 拍照按钮
              GestureDetector(
                onTap: _isTakingPicture ? null : _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isTakingPicture ? Colors.grey : Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: _isTakingPicture
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 40,
                        ),
                ),
              ),
            ],
          ),
        ),

        // 顶部提示
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '确保光线充足，食物清晰可见',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}