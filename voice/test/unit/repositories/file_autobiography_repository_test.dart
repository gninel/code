// FileAutobiographyRepository 测试
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/repositories/file_autobiography_repository.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FileAutobiographyRepository repository;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('autobiography_test');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    repository = FileAutobiographyRepository();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('FileAutobiographyRepository', () {
    final tAutobiography = Autobiography(
        id: '1',
        title: 'Test Autobiography',
        content: 'Content',
        generatedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        chapters: [
          Chapter(
              id: 'c1',
              title: 'Chapter 1',
              content: 'Content',
              order: 0,
              lastModifiedAt: DateTime.now())
        ]);

    test('初始状态应该为空', () async {
      final result = await repository.getAllAutobiographies();
      result.fold(
        (l) => fail('Should not fail'),
        (list) => expect(list, isEmpty),
      );
    });

    test('insertAutobiography 应该保存自传', () async {
      final result = await repository.insertAutobiography(tAutobiography);
      expect(result.isRight(), isTrue);

      final loadResult =
          await repository.getAutobiographyById(tAutobiography.id);
      loadResult.fold(
        (l) => fail('Should not fail'),
        (auto) {
          expect(auto.id, tAutobiography.id);
          expect(auto.title, tAutobiography.title);
          expect(auto.chapters.length, 1);
        },
      );
    });

    test('updateAutobiography 应该更新自传', () async {
      await repository.insertAutobiography(tAutobiography);

      final updated = tAutobiography.copyWith(title: 'Updated Title');
      final updateResult = await repository.updateAutobiography(updated);
      expect(updateResult.isRight(), isTrue);

      final result = await repository.getAutobiographyById(tAutobiography.id);
      result.fold(
        (l) => fail('Should not fail'),
        (auto) => expect(auto.title, 'Updated Title'),
      );
    });

    test('deleteAutobiography 应该删除自传', () async {
      await repository.insertAutobiography(tAutobiography);

      final deleteResult =
          await repository.deleteAutobiography(tAutobiography.id);
      expect(deleteResult.isRight(), isTrue);

      final result = await repository.getAllAutobiographies();
      result.fold(
          (l) => fail('Should not fail'), (list) => expect(list, isEmpty));
    });
  });
}
