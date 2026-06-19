import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  /// 支持的平台 URL 特征
  static const _patterns = [
    'v.douyin.com',
    'www.douyin.com/video',
    'www.douyin.com/note',
    'vm.tiktok.com',
    'vt.tiktok.com',
    'www.tiktok.com',
    'tiktok.com/t/',
    'b23.tv',
    'bilibili.com/video',
    'xhslink.com',
    'xiaohongshu.com/explore',
    'xiaohongshu.com/discovery',
  ];

  String? _lastClipboard;
  Timer? _pollTimer;
  final _controller = StreamController<String>.broadcast();

  Stream<String> get onLinkDetected => _controller.stream;

  /// 开始监听剪贴板变化（App 回到前台时调用）
  void startWatching() {
    _pollTimer?.cancel();
    // 轮询方式（Flutter 暂无原生剪贴板变化监听）
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _check());
  }

  void stopWatching() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _check() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty || text == _lastClipboard) return;
      _lastClipboard = text;

      if (_containsSupportedUrl(text)) {
        _controller.add(text);
      }
    } catch (_) {
      // 剪贴板访问权限问题，静默忽略
    }
  }

  bool _containsSupportedUrl(String text) {
    final lower = text.toLowerCase();
    return _patterns.any((p) => lower.contains(p));
  }

  /// 手动读取剪贴板
  Future<String?> readClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim();
  }

  /// 检查文本是否包含支持的链接
  static bool isSupported(String text) {
    final lower = text.toLowerCase();
    return _patterns.any((p) => lower.contains(p));
  }

  void dispose() {
    stopWatching();
    _controller.close();
  }
}
