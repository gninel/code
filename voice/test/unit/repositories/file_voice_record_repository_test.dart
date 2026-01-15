// FileVoiceRecordRepository 测试
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/repositories/file_voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FileVoiceRecordRepository repository;
  late Directory tempDir;

  setUp(() async {
    // 创建临时目录
    tempDir = await Directory.systemTemp.createTemp('voice_record_test');

    // Mock path_provider
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    repository = FileVoiceRecordRepository();
  });

  tearDown(() async {
    // 清理临时目录
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    // 清除 Mock
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('FileVoiceRecordRepository', () {
    final tRecord = VoiceRecord(
      id: '1',
      title: 'Test Record',
      timestamp: DateTime.now(),
      transcription: 'Test Content',
      tags: const ['test'],
    );

    test('初始状态应该为空', () async {
      final result = await repository.getAllVoiceRecords();
      result.fold(
        (l) => fail('Should not fail'),
        (records) => expect(records, isEmpty),
      );
    });

    test('应该能够插入和获取记录', () async {
      // Insert
      final insertResult = await repository.insertVoiceRecord(tRecord);
      expect(insertResult.isRight(), isTrue);

      // Get All
      final getResult = await repository.getAllVoiceRecords();
      getResult.fold(
        (l) => fail('Should not fail'),
        (records) {
          expect(records.length, 1);
          expect(records.first.id, tRecord.id);
          expect(records.first.title, tRecord.title);
        },
      );

      // Get By Id
      final getByIdResult = await repository.getVoiceRecordById(tRecord.id);
      getByIdResult.fold(
        (l) => fail('Should not fail'),
        (record) {
          expect(record.id, tRecord.id);
        },
      );
    });

    test('应该能够更新记录', () async {
      await repository.insertVoiceRecord(tRecord);

      final updatedRecord = tRecord.copyWith(title: 'Updated Title');
      final updateResult = await repository.updateVoiceRecord(updatedRecord);
      expect(updateResult.isRight(), isTrue);

      final result = await repository.getVoiceRecordById(tRecord.id);
      result.fold(
        (l) => fail('Should not fail'),
        (record) => expect(record.title, 'Updated Title'),
      );
    });

    test('应该能够删除记录', () async {
      await repository.insertVoiceRecord(tRecord);

      final deleteResult = await repository.deleteVoiceRecord(tRecord.id);
      expect(deleteResult.isRight(), isTrue);

      final result = await repository.getAllVoiceRecords();
      result.fold(
        (l) => fail('Should not fail'),
        (records) => expect(records, isEmpty),
      );
    });

    test('searchVoiceRecords 应该能根据标题搜索', () async {
      await repository.insertVoiceRecord(tRecord);
      final tRecord2 =
          VoiceRecord(id: '2', title: 'Other', timestamp: DateTime.now());
      await repository.insertVoiceRecord(tRecord2);

      final result = await repository.searchVoiceRecords('Test');
      result.fold((l) => fail('Should not fail'), (records) {
        expect(records.length, 1);
        expect(records.first.title, 'Test Record');
      });
    });
  });
}
