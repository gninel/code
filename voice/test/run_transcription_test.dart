import 'dart:io';
import 'package:voice_autobiography_flutter/data/services/xunfei_speed_transcription_service.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';

/// 运行讯飞录音文件转写测试
/// 使用方法: dart test/run_transcription_test.dart [音频文件路径]
void main(List<String> args) async {
  print('🎤 讯飞录音文件转写大模型测试');
  print('=' * 50);

  // 初始化服务
  final service = XunfeiSpeedTranscriptionService();

  // 确定要测试的文件
  String testFile;

  if (args.isNotEmpty) {
    testFile = args[0];
    if (!File(testFile).existsSync()) {
      print('❌ 指定的文件不存在: $testFile');
      return;
    }
  } else {
    // 自动查找测试文件
    final candidates = [
      'test_audio.mp3',
      '/Users/zhb/Documents/code/voice/test_audio.mp3',
      '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a',
      '/Users/zhb/Documents/code/voice/小鹿录音与成诗先生的相遇.m4a',
      '/Users/zhb/Documents/code/voice/转折：小鹿飞向新世界的起点.m4a',
    ];

    testFile = '';
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        testFile = candidate;
        break;
      }
    }

    if (testFile.isEmpty) {
      print('❌ 未找到测试音频文件');
      print('请将音频文件放在以下位置之一:');
      candidates.forEach(print);
      print('或直接指定文件路径: dart test/run_transcription_test.dart <文件路径>');
      return;
    }
  }

  final fileName = testFile.split('/').last;
  final fileSize = await File(testFile).length();

  print('📁 测试文件: $fileName');
  print('📏 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
  print('🔑 API Key: ${AppConstants.xunfeiLlmApiKey.substring(0, 8)}...');
  print('');

  try {
    // 开始转写
    print('🚀 开始转写...');
    final startTime = DateTime.now();

    String result = await service.transcribeFile(
      testFile,
      onProgress: (progress) {
        print('⏳ $progress');
      },
    );

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // 显示结果
    print('');
    print('✅ 转写成功！');
    print('⏱️  总耗时: ${duration.inMinutes}分${duration.inSeconds % 60}秒');
    print('📝 转写文本长度: ${result.length} 字符');
    print('📊 平均速度: ${(result.length / duration.inSeconds).toStringAsFixed(1)} 字符/秒');

    // 预览结果
    print('');
    print('📄 转写结果预览:');
    print('-' * 40);
    final preview = result.length > 200 ? '${result.substring(0, 200)}...' : result;
    print(preview);
    print('-' * 40);

    // 保存完整结果
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = 'transcription_${timestamp}_$fileName.txt';
    await File(outputFile).writeAsString(result);
    print('💾 完整结果已保存到: $outputFile');

    // 分析结果
    print('');
    print('📈 结果分析:');
    print('   段落数: ${result.split('\n').length}');
    print('   句子数: ${result.split('。').length}');
    print('   逗号数: ${result.split('，').length - 1}');
    print('   问号数: ${result.split('？').length - 1}');
    print('   感叹号数: ${result.split('！').length - 1}');

  } catch (e) {
    print('');
    print('❌ 转写失败: $e');

    if (e.toString().contains('AsrException')) {
      print('💡 这可能是由于:');
      print('   1. API密钥配置错误');
      print('   2. 网络连接问题');
      print('   3. 音频文件格式不支持');
      print('   4. 服务器繁忙');
      print('   5. 签名算法错误');
    }
  }

  print('');
  print('🏁 测试结束');
}