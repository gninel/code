import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:voice_autobiography_flutter/data/services/xunfei_asr_service.dart';

import 'xunfei_asr_service_test.mocks.dart';

@GenerateMocks([WebSocketChannel])
void main() {
  group('XunfeiAsrService Tests', () {
    late XunfeiAsrService asrService;
    late MockWebSocketChannel mockWebSocketChannel;

    setUp(() {
      mockWebSocketChannel = MockWebSocketChannel();
      asrService = XunfeiAsrService();
    });

    tearDown(() async {
      await asrService.stopRecognition();
    });

    test('parseRecognitionResult should correctly extract text', () {
      // 测试数据
      final result = {
        'ws': [
          {
            'cw': [
              {
                'w': '你好',
                'sc': 0.95,
              }
            ]
          },
          {
            'cw': [
              {
                'w': '世界',
                'sc': 0.92,
              }
            ]
          }
        ],
        'status': 1,
      };

      // 解析结果
      final text = XunfeiAsrService.parseRecognitionResult(result);

      // 验证结果
      expect(text, equals('你好世界'));
    });

    test('parseRecognitionResult should handle empty result', () {
      // 空结果
      final result = {'ws': [], 'status': 1};

      // 解析结果
      final text = XunfeiAsrService.parseRecognitionResult(result);

      // 验证结果
      expect(text, equals(''));
    });

    test('parseRecognitionResult should handle malformed result', () {
      // 格式错误的结果
      final result = {'invalid': 'data'};

      // 解析结果
      final text = XunfeiAsrService.parseRecognitionResult(result);

      // 验证结果
      expect(text, equals(''));
    });

    test('getRecognitionConfidence should calculate average confidence', () {
      // 测试数据
      final result = {
        'ws': [
          {
            'cw': [
              {
                'w': '你好',
                'sc': 0.95,
              }
            ]
          },
          {
            'cw': [
              {
                'w': '世界',
                'sc': 0.92,
              }
            ]
          }
        ],
        'status': 1,
      };

      // 计算置信度
      final confidence = XunfeiAsrService.getRecognitionConfidence(result);

      // 验证结果
      expect(confidence, closeTo(0.935, 0.001));
    });

    test('getRecognitionConfidence should handle empty result', () {
      // 空结果
      final result = {'ws': [], 'status': 1};

      // 计算置信度
      final confidence = XunfeiAsrService.getRecognitionConfidence(result);

      // 验证结果
      expect(confidence, equals(0.0));
    });

    test('isFinalResult should correctly identify final results', () {
      // 最终结果
      final finalResult = {'status': 2};
      final intermediateResult = {'status': 1};

      // 验证结果
      expect(XunfeiAsrService.isFinalResult(finalResult), isTrue);
      expect(XunfeiAsrService.isFinalResult(intermediateResult), isFalse);
    });

    test('isIntermediateResult should correctly identify intermediate results', () {
      // 中间结果
      final intermediateResult = {'status': 1};
      final finalResult = {'status': 2};

      // 验证结果
      expect(XunfeiAsrService.isIntermediateResult(intermediateResult), isTrue);
      expect(XunfeiAsrService.isIntermediateResult(finalResult), isFalse);
    });

    test('generateAuthUrl should contain required parameters', () {
      // 注意：这个测试可能需要mock DateTime.now() 来确保可预测性
      // 由于涉及到时间戳和加密，这里只验证URL格式

      final authUrl = asrService._generateAuthUrl();

      // 验证URL不为空
      expect(authUrl, isNotEmpty);
      expect(authUrl, contains('authorization'));
      expect(authUrl, contains('date'));
      expect(authUrl, contains('host'));
    });

    test('parseRecognitionResult should handle words without confidence', () {
      // 测试没有置信度的情况
      final result = {
        'ws': [
          {
            'cw': [
              {
                'w': '测试',
                // 没有 sc 字段
              }
            ]
          }
        ],
        'status': 1,
      };

      // 解析结果
      final text = XunfeiAsrService.parseRecognitionResult(result);

      // 验证结果
      expect(text, equals('测试'));
    });

    test('getRecognitionConfidence should handle missing confidence scores', () {
      // 测试没有置信度的情况
      final result = {
        'ws': [
          {
            'cw': [
              {
                'w': '测试',
                // 没有 sc 字段
              }
            ]
          }
        ],
        'status': 1,
      };

      // 计算置信度
      final confidence = XunfeiAsrService.getRecognitionConfidence(result);

      // 验证结果
      expect(confidence, equals(0.0));
    });

    test('parseRecognitionResult should handle multiple words in same ws', () {
      // 测试同一个ws中有多个词
      final result = {
        'ws': [
          {
            'cw': [
              {
                'w': '中国',
                'sc': 0.98,
              },
              {
                'w': '人民',
                'sc': 0.96,
              }
            ]
          }
        ],
        'status': 1,
      };

      // 解析结果
      final text = XunfeiAsrService.parseRecognitionResult(result);

      // 验证结果（应该只取第一个词）
      expect(text, equals('中国'));
    });

    group('Error Handling', () {
      test('should handle WebSocket connection errors', () async {
        // 模拟WebSocket连接错误
        when(mockWebSocketChannel.stream).thenThrow(Exception('Connection failed'));

        // 尝试开始识别
        expect(() async => await asrService.startRecognition(), throwsA(isA<Exception>()));
      });

      test('should handle message parsing errors', () async {
        // 创建模拟的WebSocket
        final mockStreamController = StreamController<String>();

        // 模拟无效的JSON消息
        mockStreamController.add('invalid json');

        // 监听识别结果流
        asrService.recognitionResultStream.listen(
          (result) {
            // 应该不抛出异常
          },
          onError: (error) {
            // 应该处理解析错误
            expect(error, isA<AsrException>());
          },
        );

        mockStreamController.close();
      });
    });
  });
}