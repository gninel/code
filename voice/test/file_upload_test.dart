// 文件上传识别测试脚本
// 用于在 macOS 上测试 XunfeiAsrService 的文件识别功能
// 运行方式: dart run test/file_upload_test.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:voice_autobiography_flutter/data/services/xunfei_asr_service.dart';

void main() async {
  print('========================================');
  print('文件上传识别测试');
  print('========================================\n');

  final asrService = XunfeiAsrService();
  
  // 测试文件列表
  final testFiles = [
    'test_audio/test_1.wav',
    'test_audio/test_2.wav', 
    'test_audio/test_3.wav',
  ];

  for (final filePath in testFiles) {
    print('测试文件: $filePath');
    print('-' * 40);
    
    try {
      await testRecognizeFile(asrService, filePath);
      print('✅ 测试通过\n');
    } catch (e) {
      print('❌ 测试失败: $e\n');
    }
    
    // 等待一下再测试下一个文件，避免请求过快
    await Future.delayed(const Duration(seconds: 2));
  }
  
  print('========================================');
  print('测试完成');
  print('========================================');
}

Future<void> testRecognizeFile(XunfeiAsrService asrService, String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw Exception('文件不存在: $filePath');
  }

  final completer = Completer<String>();
  String accumulatedText = '';
  bool sessionEnded = false;

  // 启动识别
  print('启动 ASR...');
  await asrService.startRecognition();
  
  // 等待握手
  await Future.delayed(const Duration(milliseconds: 300));
  print('握手完成');

  // 监听结果
  final subscription = asrService.recognitionResultStream.listen((result) {
    final text = result['accumulatedText'] as String? ?? '';
    final status = result['status'] as int?;
    
    if (text.isNotEmpty) {
      accumulatedText = text;
      print('识别结果: $text');
    }
    
    if (status == 2) {
      print('收到最终结果 (status=2)');
      sessionEnded = true;
      if (!completer.isCompleted) {
        completer.complete(accumulatedText);
      }
    }
  }, onError: (error) {
    print('错误: $error');
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  });

  // 读取并发送文件
  print('开始发送音频数据...');
  const chunkSize = 1280;
  int totalBytes = 0;
  int chunksSent = 0;
  
  // 跳过 WAV 头 (44 bytes)
  final fileData = await file.readAsBytes();
  final audioData = fileData.sublist(44);
  
  for (var i = 0; i < audioData.length && !sessionEnded; i += chunkSize) {
    final end = (i + chunkSize < audioData.length) ? i + chunkSize : audioData.length;
    final chunk = audioData.sublist(i, end);
    totalBytes += chunk.length;
    chunksSent++;
    
    try {
      await asrService.sendAudioData(Uint8List.fromList(chunk));
      await Future.delayed(const Duration(milliseconds: 20));
    } catch (e) {
      if (sessionEnded) {
        print('会话已结束，停止发送 (这是预期行为)');
        break;
      }
      rethrow;
    }
  }
  
  print('发送完成: $totalBytes 字节, $chunksSent 个数据块, 会话结束: $sessionEnded');
  
  // 如果会话还没结束，发送结束帧
  if (!sessionEnded) {
    print('发送结束帧...');
    await asrService.sendAudioData(Uint8List(0), isEnd: true);
    
    // 等待最终结果 (最多 5 秒)
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      print('等待超时，获取当前结果');
    }
  }
  
  // 清理
  await subscription.cancel();
  await asrService.stopRecognition();
  
  final finalText = asrService.getFinalText();
  print('最终识别文本: $finalText');
  
  if (finalText.isEmpty) {
    throw Exception('识别结果为空');
  }
}
