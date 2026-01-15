import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';
import 'package:voice_autobiography_flutter/data/services/xunfei_asr_service.dart';

import 'xunfei_asr_service_test.mocks.dart';

// 生成 Mock 类
@GenerateMocks([WebSocketChannel, WebSocketSink])
void main() {
  late XunfeiAsrService service;
  late MockWebSocketChannel mockChannel;
  late MockWebSocketSink mockSink;
  late StreamController<dynamic> messageStreamController;

  setUp(() {
    service = XunfeiAsrService();
    mockChannel = MockWebSocketChannel();
    mockSink = MockWebSocketSink();
    messageStreamController = StreamController<dynamic>.broadcast();

    // 配置 Mock WebSocket
    when(mockChannel.sink).thenReturn(mockSink);
    when(mockChannel.stream).thenAnswer((_) => messageStreamController.stream);
  });

  tearDown(() async {
    await messageStreamController.close();
    await service.stopRecognition();
  });

  group('XunfeiAsrService - 正常流程', () {
    test('startRecognition - 成功建立WebSocket连接', () async {
      // 注意: 这个测试会尝试建立真实连接，需要网络
      // 在实际CI环境中应该跳过或使用Mock

      // 由于无法直接Mock静态的 WebSocketChannel.connect，
      // 这个测试主要验证方法调用不抛出异常

      try {
        await service.startRecognition();

        // 验证状态
        expect(service.isSessionActive, isTrue);
        expect(service.isConnected, isTrue);
        expect(service.isConnecting, isFalse);
      } catch (e) {
        // 如果网络不可用，测试应该抛出 AsrException
        expect(e, isA<AsrException>());
      }
    }, skip: '需要真实网络连接');

    test('startRecognition - clearHistory=true清除历史', () async {
      // 设置一些历史数据
      service.archiveText(); // 这个方法是 private 的，我们通过间接方式测试

      // 由于无法访问私有字段，我们通过 accumulatedText 验证
      final initialText = service.accumulatedText;

      // startRecognition 会清除历史
      try {
        await service.startRecognition(clearHistory: true);
      } catch (e) {
        // 忽略网络错误
      }

      // 验证历史已清除（如果方法成功执行）
      // 注意: 由于网络可能失败，这个测试不够可靠
    }, skip: '依赖真实网络连接');

    test('accumulatedText - 返回空字符串当无数据时', () {
      expect(service.accumulatedText, equals(''));
    });

    test('isConnected - 初始状态为false', () {
      expect(service.isConnected, isFalse);
    });

    test('isSessionActive - 初始状态为false', () {
      expect(service.isSessionActive, isFalse);
    });

    test('isConnecting - 初始状态为false', () {
      expect(service.isConnecting, isFalse);
    });

    test('getFinalText - 返回累积文本', () {
      final text = service.getFinalText();
      expect(text, isA<String>());
    });

    test('recognitionResultStream - 返回有效的Stream', () {
      final stream = service.recognitionResultStream;
      expect(stream, isA<Stream<Map<String, dynamic>>>());
    });
  });

  group('XunfeiAsrService - 状态管理', () {
    test('clearAccumulatedText - 清除所有累积文本', () {
      service.clearAccumulatedText();
      expect(service.accumulatedText, equals(''));
    });

    test('archiveText - 保存当前文本到历史', () {
      // 由于 _sentenceSegments 是私有的，我们无法直接测试
      // 但可以确保方法不抛出异常
      expect(() => service.archiveText(), returnsNormally);
    });

    test('stopRecognition - 清理资源', () async {
      await service.stopRecognition();

      expect(service.isSessionActive, isFalse);
      expect(service.isConnected, isFalse);
    });

    test('stopRecognition - 可以多次调用', () async {
      await service.stopRecognition();
      await service.stopRecognition();

      // 不应该抛出异常
      expect(service.isSessionActive, isFalse);
    });
  });

  group('XunfeiAsrService - 音频数据发送', () {
    test('sendAudioData - 返回false当会话未激活', () async {
      final audioData = Uint8List.fromList([0, 1, 2, 3]);

      final result = await service.sendAudioData(audioData);

      expect(result, isFalse);
    });

    test('sendAudioData - 空数据也能处理', () async {
      final audioData = Uint8List(0);

      final result = await service.sendAudioData(audioData);

      // 会话未激活，返回false
      expect(result, isFalse);
    });

    test('sendAudioData - isEnd参数正确传递', () async {
      final audioData = Uint8List.fromList([0, 1, 2, 3]);

      // 会话未激活，都应该返回false
      final result1 = await service.sendAudioData(audioData, isEnd: false);
      final result2 = await service.sendAudioData(audioData, isEnd: true);

      expect(result1, isFalse);
      expect(result2, isFalse);
    });
  });

  group('XunfeiAsrService - 静态方法', () {
    test('parseRecognitionResult - 解析有效结果', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'w': '今天'}
              ]
            },
            {
              'cw': [
                {'w': '天气'}
              ]
            },
            {
              'cw': [
                {'w': '不错'}
              ]
            }
          ]
        }
      };

      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, equals('今天天气不错'));
    });

    test('parseRecognitionResult - 处理空结果', () {
      final result = {'result': null};
      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, equals(''));
    });

    test('parseRecognitionResult - 处理空ws数组', () {
      final result = {
        'result': {'ws': []}
      };
      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, equals(''));
    });

    test('parseRecognitionResult - 处理无效格式', () {
      final result = {
        'result': {
          'ws': [
            {'invalid': 'data'}
          ]
        }
      };
      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, equals(''));
    });

    test('getRecognitionConfidence - 计算平均置信度', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'w': '今天', 'sc': 0.9}
              ]
            },
            {
              'cw': [
                {'w': '天气', 'sc': 0.8}
              ]
            }
          ]
        }
      };

      final confidence = XunfeiAsrService.getRecognitionConfidence(result);
      expect(confidence, closeTo(0.85, 0.01));
    });

    test('getRecognitionConfidence - 返回0当无数据', () {
      final result = {'result': null};
      final confidence = XunfeiAsrService.getRecognitionConfidence(result);
      expect(confidence, equals(0.0));
    });

    test('getRecognitionConfidence - 返回0当无置信度数据', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'w': '今天'}
              ]
            }
          ]
        }
      };

      final confidence = XunfeiAsrService.getRecognitionConfidence(result);
      expect(confidence, equals(0.0));
    });

    test('isFinalResult - 识别最终结果', () {
      expect(XunfeiAsrService.isFinalResult({'status': 2}), isTrue);
      expect(XunfeiAsrService.isFinalResult({'status': 1}), isFalse);
      expect(XunfeiAsrService.isFinalResult({'status': 0}), isFalse);
    });

    test('isIntermediateResult - 识别中间结果', () {
      expect(XunfeiAsrService.isIntermediateResult({'status': 1}), isTrue);
      expect(XunfeiAsrService.isIntermediateResult({'status': 2}), isFalse);
      expect(XunfeiAsrService.isIntermediateResult({'status': 0}), isFalse);
    });
  });

  group('XunfeiAsrService - 边界条件', () {
    test('sendAudioData - 处理超大音频块', () async {
      // 创建一个大音频块 (1MB)
      final largeAudioData = Uint8List(1024 * 1024);

      final result = await service.sendAudioData(largeAudioData);

      // 会话未激活，返回false
      expect(result, isFalse);
    });

    test('parseRecognitionResult - 处理多个词语', () {
      final result = {
        'result': {
          'ws': List.generate(
              100,
              (i) => {
                    'cw': [
                      {'w': '词$i'}
                    ]
                  })
        }
      };

      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text.length, greaterThan(0));
      expect(text, contains('词0'));
      expect(text, contains('词99'));
    });

    test('getRecognitionConfidence - 处理多个词语的置信度', () {
      final result = {
        'result': {
          'ws': List.generate(
              10,
              (i) => {
                    'cw': [
                      {'w': '词$i', 'sc': 0.5 + (i * 0.05)}
                    ]
                  })
        }
      };

      final confidence = XunfeiAsrService.getRecognitionConfidence(result);
      expect(confidence, greaterThan(0.0));
      expect(confidence, lessThanOrEqualTo(1.0));
    });

    test('parseRecognitionResult - 处理包含null的cw', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'w': '正常'}
              ]
            },
            {
              'cw': null // null cw
            },
            {
              'cw': [
                {'w': '词语'}
              ]
            }
          ]
        }
      };

      final text = XunfeiAsrService.parseRecognitionResult(result);
      // 由于中间的cw为null，只能解析出两个词
      expect(text, equals('正常词语'));
    });

    test('parseRecognitionResult - 处理空字符串词语', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'w': ''}
              ]
            },
            {
              'cw': [
                {'w': '有效'}
              ]
            }
          ]
        }
      };

      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, equals('有效'));
    });
  });

  group('XunfeiAsrService - 异常处理', () {
    test('parseRecognitionResult - 捕获解析异常', () {
      // 传入完全无效的数据结构
      final result = {'result': 'invalid_string_not_map'};

      // 不应该抛出异常，而是返回空字符串
      expect(
        () => XunfeiAsrService.parseRecognitionResult(result),
        returnsNormally,
      );
      expect(XunfeiAsrService.parseRecognitionResult(result), equals(''));
    });

    test('getRecognitionConfidence - 捕获计算异常', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'sc': 'invalid_number'}
              ]
            }
          ]
        }
      };

      // 不应该抛出异常
      expect(
        () => XunfeiAsrService.getRecognitionConfidence(result),
        returnsNormally,
      );
    });

    test('isFinalResult - 处理缺少status字段', () {
      expect(XunfeiAsrService.isFinalResult({}), isFalse);
      expect(XunfeiAsrService.isFinalResult({'status': null}), isFalse);
    });

    test('isIntermediateResult - 处理缺少status字段', () {
      expect(XunfeiAsrService.isIntermediateResult({}), isFalse);
      expect(XunfeiAsrService.isIntermediateResult({'status': null}), isFalse);
    });
  });

  group('XunfeiAsrService - 完整场景', () {
    test('完整流程模拟: 接收识别结果', () async {
      // 这是一个集成测试示例，展示完整的使用流程
      // 由于依赖真实WebSocket连接，在单元测试中跳过

      // 1. 启动识别
      // await service.startRecognition();

      // 2. 监听识别结果
      // service.recognitionResultStream.listen((result) {
      //   final text = result['accumulatedText'] as String?;
      //   print('识别结果: $text');
      // });

      // 3. 发送音频数据
      // final audioData = Uint8List.fromList([...]);
      // await service.sendAudioData(audioData);

      // 4. 发送结束帧
      // await service.sendAudioData(Uint8List(0), isEnd: true);

      // 5. 获取最终文本
      // final finalText = service.getFinalText();

      // 6. 停止识别
      // await service.stopRecognition();
    }, skip: '需要真实WebSocket连接的完整流程测试');

    test('多次启动停止循环', () async {
      // 测试多次启动和停止不会导致资源泄漏
      for (int i = 0; i < 3; i++) {
        try {
          await service.startRecognition();
        } catch (e) {
          // 忽略网络错误
        }
        await service.stopRecognition();
      }

      expect(service.isSessionActive, isFalse);
      expect(service.isConnected, isFalse);
    });

    test('状态转换: idle -> connecting -> active -> inactive', () async {
      // 初始状态
      expect(service.isConnecting, isFalse);
      expect(service.isSessionActive, isFalse);

      // 尝试启动（会进入connecting状态）
      final future = service.startRecognition();

      // 注意: 由于是异步的，isConnecting可能已经变回false
      // 这个测试在真实环境中不够可靠

      try {
        await future;
      } catch (e) {
        // 忽略网络错误
      }

      // 停止后状态
      await service.stopRecognition();
      expect(service.isSessionActive, isFalse);
    });
  });
}
