import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';

void main() {
  group('VoiceRecord Entity', () {
    late VoiceRecord voiceRecord;

    setUp(() {
      voiceRecord = VoiceRecord(
        id: 'test-id-1',
        title: '测试录音',
        content: '这是一段测试内容',
        audioFilePath: '/path/to/audio.wav',
        duration: 65000, // 1分5秒
        timestamp: DateTime(2024, 12, 26, 14, 30),
        isProcessed: true,
        tags: const ['童年', '回忆'],
        transcription: '这是一段转写内容',
        confidence: 0.95,
        note: '这是一条备注',
        isIncludedInBio: false,
      );
    });

    test('should create VoiceRecord with all required fields', () {
      expect(voiceRecord.id, 'test-id-1');
      expect(voiceRecord.title, '测试录音');
      expect(voiceRecord.content, '这是一段测试内容');
      expect(voiceRecord.duration, 65000);
      expect(voiceRecord.timestamp, DateTime(2024, 12, 26, 14, 30));
    });

    test('should format duration correctly - minutes and seconds', () {
      expect(voiceRecord.formattedDuration, '1:05');
    });

    test('should format duration correctly - only seconds', () {
      final shortRecord = voiceRecord.copyWith(duration: 5000);
      expect(shortRecord.formattedDuration, '5秒');
    });

    test('should format duration correctly - hours, minutes and seconds', () {
      final longRecord = voiceRecord.copyWith(duration: 3665000); // 1:01:05
      expect(longRecord.formattedDuration, '1:01:05');
    });

    test('should determine if recording is valid', () {
      expect(voiceRecord.isValidRecording, true);

      final invalidRecord = voiceRecord.copyWith(duration: 500); // 小于1秒
      expect(invalidRecord.isValidRecording, false);
    });

    test('should create copy with updated values', () {
      final updated = voiceRecord.copyWith(
        title: '更新后的标题',
        isProcessed: false,
      );

      expect(updated.id, voiceRecord.id); // 不变的字段
      expect(updated.title, '更新后的标题'); // 更新的字段
      expect(updated.isProcessed, false); // 更新的字段
      expect(updated.content, voiceRecord.content); // 不变的字段
    });

    test('should implement equality correctly', () {
      final sameTime = DateTime(2024, 12, 26, 14, 30);

      final record1 = VoiceRecord(
        id: 'test-id',
        title: '测试',
        timestamp: sameTime,
      );

      final record2 = VoiceRecord(
        id: 'test-id',
        title: '测试',
        timestamp: sameTime,
      );

      final record3 = VoiceRecord(
        id: 'different-id',
        title: '测试',
        timestamp: sameTime,
      );

      expect(record1, equals(record2));
      expect(record1, isNot(equals(record3)));
    });

    test('should include all fields in props', () {
      expect(
        voiceRecord.props,
        [
          voiceRecord.id,
          voiceRecord.title,
          voiceRecord.content,
          voiceRecord.audioFilePath,
          voiceRecord.duration,
          voiceRecord.timestamp,
          voiceRecord.isProcessed,
          voiceRecord.tags,
          voiceRecord.transcription,
          voiceRecord.confidence,
          voiceRecord.note,
          voiceRecord.isIncludedInBio,
        ],
      );
    });

    test('should handle default values correctly', () {
      final defaultRecord = VoiceRecord(
        id: 'test-id',
        title: '测试',
        timestamp: DateTime.now(),
      );

      expect(defaultRecord.content, '');
      expect(defaultRecord.duration, 0);
      expect(defaultRecord.isProcessed, false);
      expect(defaultRecord.tags, []);
      expect(defaultRecord.isIncludedInBio, false);
    });

    test('should convert to string correctly', () {
      final str = voiceRecord.toString();
      expect(str, contains('test-id-1'));
      expect(str, contains('测试录音'));
      expect(str, contains('65000'));
    });

    group('Edge Cases', () {
      test('should handle zero duration', () {
        final record = voiceRecord.copyWith(duration: 0);
        expect(record.formattedDuration, '0秒');
        expect(record.isValidRecording, false);
      });

      test('should handle very long duration', () {
        final record = voiceRecord.copyWith(duration: 86400000); // 24小时
        expect(record.formattedDuration, '24:00:00');
      });

      test('should handle empty title', () {
        final record = VoiceRecord(
          id: 'test',
          title: '',
          timestamp: DateTime.now(),
        );
        expect(record.title, '');
      });

      test('should handle null optional fields', () {
        final record = VoiceRecord(
          id: 'test',
          title: 'Test',
          timestamp: DateTime.now(),
        );
        expect(record.audioFilePath, null);
        expect(record.transcription, null);
        expect(record.confidence, null);
        expect(record.note, null);
      });
    });
  });
}
