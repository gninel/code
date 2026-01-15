// 综合功能测试 - 覆盖最近修复的bug和核心实体
// 运行方式: flutter test test/comprehensive_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/services/xunfei_asr_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/data/models/autobiography_model.dart';

void main() {
  group('T01-T03: XunfeiAsrService 会话状态管理测试', () {
    late XunfeiAsrService asrService;

    setUp(() {
      asrService = XunfeiAsrService();
    });

    tearDown(() async {
      await asrService.stopRecognition();
    });

    test('T01: 初始状态 - isSessionActive 应为 false', () {
      expect(asrService.isSessionActive, isFalse);
      expect(asrService.isConnected, isFalse);
      expect(asrService.isConnecting, isFalse);
    });

    test('T02: isConnecting getter 应正确返回连接状态', () {
      expect(asrService.isConnecting, isFalse);
      expect(asrService.isConnecting, isA<bool>());
    });

    test('T03: accumulatedText 应正确累积文本', () {
      expect(asrService.accumulatedText, isEmpty);
      expect(() => asrService.archiveText(), returnsNormally);
      asrService.clearAccumulatedText();
      expect(asrService.accumulatedText, isEmpty);
    });

    test('T03b: getFinalText 应返回累积文本', () {
      final text = asrService.getFinalText();
      expect(text, isA<String>());
    });
  });

  group('T07-T08: AutobiographyModel 序列化测试', () {
    test('T07: AutobiographyModel 应正确序列化为JSON', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: 'test-id-123',
        title: '我的自传',
        content: '这是内容',
        summary: '这是摘要',
        wordCount: 100,
        generatedAt: now,
        lastModifiedAt: now,
        voiceRecordIds: const ['record-1', 'record-2'],
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );

      final model = AutobiographyModel.fromEntity(autobiography);
      final json = model.toJson();

      expect(json['id'], equals('test-id-123'));
      expect(json['title'], equals('我的自传'));
      expect(json['voiceRecordIds'], equals(['record-1', 'record-2']));
    });

    test('T08: AutobiographyModel 应正确从JSON反序列化', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-id-456',
        'title': '测试自传',
        'content': '测试内容',
        'summary': '测试摘要',
        'wordCount': 200,
        'generatedAt': now.toIso8601String(),
        'lastModifiedAt': now.toIso8601String(),
        'voiceRecordIds': ['r1', 'r2', 'r3'],
        'status': 'draft',
        'style': 'narrative',
      };

      final model = AutobiographyModel.fromJson(json);

      expect(model.id, equals('test-id-456'));
      expect(model.wordCount, equals(200));
      expect(model.voiceRecordIds.length, equals(3));
    });

    test('T08b: 序列化往返应保持数据一致', () {
      final now = DateTime.now();
      final original = Autobiography(
        id: 'roundtrip-id',
        title: '往返测试',
        content: '往返内容',
        summary: '往返摘要',
        wordCount: 50,
        generatedAt: now,
        lastModifiedAt: now,
        voiceRecordIds: const ['a', 'b'],
        status: AutobiographyStatus.published,
        style: AutobiographyStyle.emotional,
      );

      final model = AutobiographyModel.fromEntity(original);
      final json = model.toJson();
      final restored = AutobiographyModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.content, equals(original.content));
    });
  });

  group('T10-T11: Autobiography Entity 测试', () {
    test('T10: Autobiography copyWith 应正确复制并修改', () {
      final now = DateTime.now();
      final original = Autobiography(
        id: 'copy-test',
        title: '原标题',
        content: '原内容',
        summary: '原摘要',
        wordCount: 10,
        generatedAt: now,
        lastModifiedAt: now,
        voiceRecordIds: const [],
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );

      final modified = original.copyWith(
        title: '新标题',
        wordCount: 20,
      );

      expect(modified.id, equals(original.id));
      expect(modified.title, equals('新标题'));
      expect(modified.content, equals(original.content));
      expect(modified.wordCount, equals(20));
    });

    test('T11: AutobiographyStatus 枚举应包含所有状态', () {
      expect(AutobiographyStatus.values.contains(AutobiographyStatus.draft), isTrue);
      expect(AutobiographyStatus.values.contains(AutobiographyStatus.published), isTrue);
    });

    test('T11b: AutobiographyStyle 枚举应包含所有风格', () {
      expect(AutobiographyStyle.values.contains(AutobiographyStyle.narrative), isTrue);
      expect(AutobiographyStyle.values.contains(AutobiographyStyle.emotional), isTrue);
    });
  });

  group('T14-T16: ASR 解析功能测试 (修复结构)', () {
    test('T14: parseRecognitionResult 应处理嵌套的result结构', () {
      final result = {
        'result': {
          'ws': [
            {
              'cw': [
                {'w': '测试', 'sc': 0.95}
              ]
            }
          ]
        },
        'status': 1,
      };

      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, equals('测试'));
    });

    test('T15: parseRecognitionResult 应处理空ws数组', () {
      final result = {
        'result': {'ws': []},
        'status': 1
      };
      final text = XunfeiAsrService.parseRecognitionResult(result);
      expect(text, isEmpty);
    });

    test('T16: isFinalResult 应正确识别状态2', () {
      expect(XunfeiAsrService.isFinalResult({'status': 2}), isTrue);
      expect(XunfeiAsrService.isFinalResult({'status': 1}), isFalse);
    });
  });

  group('T17-T20: 边界条件测试', () {
    test('T17: 空内容自传应能正确创建', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: 'empty-content',
        title: '',
        content: '',
        summary: '',
        wordCount: 0,
        generatedAt: now,
        lastModifiedAt: now,
        voiceRecordIds: const [],
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );

      expect(autobiography.wordCount, equals(0));
    });

    test('T18: 超长内容自传应能正确处理', () {
      final now = DateTime.now();
      final longContent = 'ab' * 5000;
      
      final autobiography = Autobiography(
        id: 'long-content',
        title: '长篇',
        content: longContent,
        summary: '摘要',
        wordCount: longContent.length,
        generatedAt: now,
        lastModifiedAt: now,
        voiceRecordIds: const [],
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );

      expect(autobiography.content.length, equals(10000));
    });

    test('T19: 大量voiceRecordIds应能正确处理', () {
      final now = DateTime.now();
      final manyIds = List.generate(100, (i) => 'record-$i');
      
      final autobiography = Autobiography(
        id: 'many-records',
        title: '多记录',
        content: '内容',
        summary: '摘要',
        wordCount: 2,
        generatedAt: now,
        lastModifiedAt: now,
        voiceRecordIds: manyIds,
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );

      expect(autobiography.voiceRecordIds.length, equals(100));
    });

    test('T20: getRecognitionConfidence 应处理嵌套结构和极端值', () {
      // 置信度为0 (nested)
      final lowConfidenceResult = {
        'result': {
          'ws': [
            {'cw': [{'w': '测试', 'sc': 0.0}]}
          ]
        },
        'status': 1,
      };
      expect(XunfeiAsrService.getRecognitionConfidence(lowConfidenceResult), equals(0.0));

      // 置信度为1 (nested)
      final highConfidenceResult = {
        'result': {
          'ws': [
            {'cw': [{'w': '测试', 'sc': 1.0}]}
          ]
        },
        'status': 1,
      };
      expect(XunfeiAsrService.getRecognitionConfidence(highConfidenceResult), equals(1.0));
    });
  });

  group('T21-T23: VoiceRecord Entity 测试 (新增)', () {
    test('T21: VoiceRecord 格式化时长应正确', () {
      final now = DateTime.now();
      final record = VoiceRecord(
        id: '1',
        title: 'Test',
        timestamp: now,
        duration: 65000, // 1分05秒
      );
      
      // 检查 formattedDuration getter
      // 根据实现: seconds = 5, minutes = 1
      // 应为 "1:05" (如果 hours=0)
      expect(record.formattedDuration, equals('1:05'));
    });

    test('T22: VoiceRecord copyWith 应正常工作', () {
      final now = DateTime.now();
      final record = VoiceRecord(
        id: '1',
        title: 'Original',
        timestamp: now,
      );
      
      final modified = record.copyWith(title: 'Modified');
      expect(modified.id, equals('1'));
      expect(modified.title, equals('Modified'));
    });

    test('T23: VoiceRecord isValidRecording 校验', () {
      final now = DateTime.now();
      final validRecord = VoiceRecord(
        id: '1', 
        title: 'Valid', 
        timestamp: now, 
        duration: 2000
      );
      final invalidRecord = VoiceRecord(
        id: '2', 
        title: 'Invalid', 
        timestamp: now, 
        duration: 500
      );
      
      expect(validRecord.isValidRecording, isTrue);
      expect(invalidRecord.isValidRecording, isFalse);
    });
  });
}
