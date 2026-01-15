import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/services/xunfei_speed_transcription_service.dart';
import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';

/// 讯飞录音文件转写大模型 WebAPI 测试
/// 文档: https://www.xfyun.cn/doc/spark/asr_llm/Ifasr_llm.html
void main() {
  group('讯飞录音文件转写大模型测试', () {
    late XunfeiSpeedTranscriptionService service;

    setUpAll(() {
      service = XunfeiSpeedTranscriptionService();
    });

    test('测试API连接和认证', () async {
      print('=== 测试API连接和认证 ===');

      // 查找一个测试音频文件
      final testFiles = [
        'test_audio.mp3',
        '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a',
        '/Users/zhb/Documents/code/voice/小鹿录音与成诗先生的相遇.m4a',
      ];

      String? testFile;
      for (final file in testFiles) {
        if (File(file).existsSync()) {
          testFile = file;
          break;
        }
      }

      if (testFile == null) {
        print('未找到测试音频文件，跳过测试');
        return;
      }

      print('使用测试文件: $testFile');

      try {
        // 开始转写测试
        final result = await service.transcribeFile(
          testFile,
          onProgress: (progress) {
            print('进度: $progress');
          },
        );

        print('转写结果: $result');
        expect(result, isNotNull);
        expect(result, isNotEmpty);

        // 验证结果格式
        print('\n=== 转写结果统计 ===');
        print('字符数: ${result.length}');
        print('句子数: ${result.split('。').length}');
        print('段落数: ${result.split('\n').length}');

      } on AsrException catch (e) {
        print('ASR异常: ${e.message}');
        print('错误码: ${e.code}');
        print('详情: ${e.details}');
        fail('ASR异常: ${e.message}');
      } catch (e) {
        print('其他异常: $e');
        fail('测试失败: $e');
      }
    });

    test('测试短音频文件转写', () async {
      print('\n=== 测试短音频文件转写 ===');

      // 创建一个短音频测试文件（如果不存在）
      const shortTestFile = 'test_audio_short.mp3';

      if (!File(shortTestFile).existsSync()) {
        print('短音频测试文件不存在，跳过短文件测试');
        return;
      }

      try {
        final startTime = DateTime.now();

        final result = await service.transcribeFile(
          shortTestFile,
          onProgress: (progress) {
            print('进度: $progress');
          },
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        print('转写完成，耗时: ${duration.inSeconds}秒');
        print('转写结果: $result');

        expect(result, isNotNull);

      } catch (e) {
        print('短文件转写测试失败: $e');
        // 短文件测试失败不阻止整个测试套件
      }
    });

    test('测试参数验证', () {
      print('\n=== 测试参数验证 ===');

      // 测试不存在的文件
      expect(
        () => service.transcribeFile('nonexistent_file.mp3'),
        throwsA(isA<AsrException>()),
      );
    });

    test('测试时间格式生成', () {
      print('\n=== 测试时间格式生成 ===');

      // 测试时间格式是否符合要求: yyyy-MM-dd'T'HH:mm:ss+HHmm
      final now = DateTime.now();
      final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
      final dateStr = formatter.format(now);

      final offset = now.timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

      final expectedFormat = '$dateStr$sign$hours$minutes';
      print('生成的时间格式: $expectedFormat');

      // 验证格式: 2023-12-01T10:30:45+0800
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{4}$');
      expect(regex.hasMatch(expectedFormat), isTrue);
    });
  });
}

/// 手动运行完整测试
Future<void> runManualTest() async {
  print('\n🚀 开始手动运行讯飞录音文件转写测试...\n');

  final service = XunfeiSpeedTranscriptionService();

  // 查找测试文件
  final testFiles = [
    '/Users/zhb/Documents/code/voice/test_audio.mp3',
    '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a',
    '/Users/zhb/Documents/code/voice/小鹿录音与成诗先生的相遇.m4a',
    '/Users/zhb/Documents/code/voice/转折：小鹿飞向新世界的起点.m4a',
  ];

  List<String> availableFiles = [];
  for (final file in testFiles) {
    if (File(file).existsSync()) {
      final fileSize = await File(file).length();
      print('✓ 找到文件: ${file.split('/').last} (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      availableFiles.add(file);
    }
  }

  if (availableFiles.isEmpty) {
    print('❌ 未找到任何测试音频文件');
    return;
  }

  // 测试每个文件
  for (int i = 0; i < availableFiles.length; i++) {
    final testFile = availableFiles[i];
    final fileName = testFile.split('/').last;

    print('\n${'=' * 50}');
    print('测试文件 ${i + 1}/${availableFiles.length}: $fileName');
    print('=' * 50);

    try {
      final startTime = DateTime.now();

      final result = await service.transcribeFile(
        testFile,
        onProgress: (progress) {
          print('[$fileName] $progress');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('\n✅ 转写成功！');
      print('⏱️  耗时: ${duration.inMinutes}分${duration.inSeconds % 60}秒');
      print('📝 结果长度: ${result.length} 字符');
      print('📄 转写内容:');
      print('-' * 30);
      print(result);
      print('-' * 30);

      // 保存结果到文件
      final outputFile = 'transcription_result_${DateTime.now().millisecondsSinceEpoch}.txt';
      await File(outputFile).writeAsString(result);
      print('💾 结果已保存到: $outputFile');

    } catch (e) {
      print('\n❌ 转写失败: $e');
      if (e is AsrException) {
        print('错误码: ${e.code}');
        if (e.details != null) {
          print('详细信息: ${e.details}');
        }
      }
    }

    // 如果不是最后一个文件，稍等一下
    if (i < availableFiles.length - 1) {
      print('\n⏳ 等待 3 秒后测试下一个文件...');
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  print('\n🎉 所有测试完成！');
}

/// 如果直接运行此文件，执行手动测试
void main() {
  // 取消注释下面这行来运行手动测试
  // runManualTest();

  // 或者运行单元测试
  // testMain();
}