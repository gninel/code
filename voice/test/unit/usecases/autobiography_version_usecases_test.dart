import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography_version.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_version_repository.dart';
import 'package:voice_autobiography_flutter/domain/usecases/autobiography_version_usecases.dart';

@GenerateMocks([AutobiographyVersionRepository])
import 'autobiography_version_usecases_test.mocks.dart';

void main() {
  late AutobiographyVersionUseCases useCases;
  late MockAutobiographyVersionRepository mockRepository;

  setUp(() {
    mockRepository = MockAutobiographyVersionRepository();
    useCases = AutobiographyVersionUseCases(mockRepository);
  });

  group('saveCurrentAsVersion', () {
    late Autobiography testAutobiography;
    late AutobiographyVersion testVersion;

    setUp(() {
      testAutobiography = Autobiography(
        id: 'auto-123',
        title: '我的自传',
        content: '这是我的人生故事...',
        chapters: [
          Chapter(
            id: 'ch1',
            title: '童年',
            content: '童年回忆...',
            order: 0,
            sourceRecordIds: const ['rec1'],
            lastModifiedAt: DateTime.now(),
          ),
        ],
        generatedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        wordCount: 100,
        summary: '一个普通人的故事',
      );

      testVersion = AutobiographyVersion(
        id: 'version-123',
        autobiographyId: 'auto-123',
        versionName: '2025-01-01 12:00:00',
        content: testAutobiography.content,
        chapters: const [],
        createdAt: DateTime.now(),
        wordCount: 100,
      );
    });

    test('应该使用默认名称（当前日期时间）保存版本', () async {
      // Arrange
      when(mockRepository.saveVersion(
        autobiographyId: anyNamed('autobiographyId'),
        versionName: anyNamed('versionName'),
        content: anyNamed('content'),
        chapters: anyNamed('chapters'),
        wordCount: anyNamed('wordCount'),
        summary: anyNamed('summary'),
      )).thenAnswer((_) async => Right(testVersion));

      // Act
      final result = await useCases.saveCurrentAsVersion(
        autobiography: testAutobiography,
      );

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.saveVersion(
        autobiographyId: testAutobiography.id,
        versionName: anyNamed('versionName'), // 会是当前日期时间
        content: testAutobiography.content,
        chapters: anyNamed('chapters'),
        wordCount: testAutobiography.wordCount,
        summary: testAutobiography.summary,
      )).called(1);
    });

    test('应该使用自定义名称保存版本', () async {
      // Arrange
      const customName = '第一版';

      when(mockRepository.saveVersion(
        autobiographyId: anyNamed('autobiographyId'),
        versionName: customName,
        content: anyNamed('content'),
        chapters: anyNamed('chapters'),
        wordCount: anyNamed('wordCount'),
        summary: anyNamed('summary'),
      )).thenAnswer((_) async => Right(testVersion));

      // Act
      final result = await useCases.saveCurrentAsVersion(
        autobiography: testAutobiography,
        customName: customName,
      );

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.saveVersion(
        autobiographyId: testAutobiography.id,
        versionName: customName,
        content: anyNamed('content'),
        chapters: anyNamed('chapters'),
        wordCount: anyNamed('wordCount'),
        summary: anyNamed('summary'),
      )).called(1);
    });

    test('应该正确转换章节数据', () async {
      // Arrange
      List<Map<String, dynamic>>? capturedChapters;

      when(mockRepository.saveVersion(
        autobiographyId: anyNamed('autobiographyId'),
        versionName: anyNamed('versionName'),
        content: anyNamed('content'),
        chapters: anyNamed('chapters'),
        wordCount: anyNamed('wordCount'),
        summary: anyNamed('summary'),
      )).thenAnswer((invocation) async {
        capturedChapters = invocation.namedArguments[const Symbol('chapters')]
            as List<Map<String, dynamic>>;
        return Right(testVersion);
      });

      // Act
      await useCases.saveCurrentAsVersion(
        autobiography: testAutobiography,
      );

      // Assert
      expect(capturedChapters, isNotNull);
      expect(capturedChapters!.length, 1);
      expect(capturedChapters![0]['id'], 'ch1');
      expect(capturedChapters![0]['title'], '童年');
      expect(capturedChapters![0]['content'], '童年回忆...');
      expect(capturedChapters![0]['order'], 0);
      expect(capturedChapters![0]['sourceRecordIds'], isA<List>());
    });

    test('应该正确处理保存失败', () async {
      // Arrange
      when(mockRepository.saveVersion(
        autobiographyId: anyNamed('autobiographyId'),
        versionName: anyNamed('versionName'),
        content: anyNamed('content'),
        chapters: anyNamed('chapters'),
        wordCount: anyNamed('wordCount'),
        summary: anyNamed('summary'),
      )).thenAnswer((_) async => Left(DatabaseFailure.insertFailed()));

      // Act
      final result = await useCases.saveCurrentAsVersion(
        autobiography: testAutobiography,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('应该返回失败'),
      );
    });
  });

  group('getVersionsForAutobiography', () {
    const testAutobiographyId = 'auto-123';

    test('应该成功获取版本列表', () async {
      // Arrange
      final testVersions = [
        AutobiographyVersion(
          id: 'v1',
          autobiographyId: testAutobiographyId,
          versionName: '版本 1',
          content: '内容 1',
          chapters: const [],
          createdAt: DateTime.now(),
          wordCount: 100,
        ),
        AutobiographyVersion(
          id: 'v2',
          autobiographyId: testAutobiographyId,
          versionName: '版本 2',
          content: '内容 2',
          chapters: const [],
          createdAt: DateTime.now(),
          wordCount: 150,
        ),
      ];

      when(mockRepository.getVersions(
        autobiographyId: testAutobiographyId,
      )).thenAnswer((_) async => Right(testVersions));

      // Act
      final result = await useCases.getVersionsForAutobiography(
        autobiographyId: testAutobiographyId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('应该成功'),
        (versions) {
          expect(versions.length, 2);
          expect(versions[0].versionName, '版本 1');
          expect(versions[1].versionName, '版本 2');
        },
      );

      verify(mockRepository.getVersions(
        autobiographyId: testAutobiographyId,
      )).called(1);
    });

    test('应该返回空列表当没有版本时', () async {
      // Arrange
      when(mockRepository.getVersions(
        autobiographyId: anyNamed('autobiographyId'),
      )).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCases.getVersionsForAutobiography(
        autobiographyId: testAutobiographyId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('应该成功'),
        (versions) => expect(versions, isEmpty),
      );
    });

    test('应该正确处理查询失败', () async {
      // Arrange
      when(mockRepository.getVersions(
        autobiographyId: anyNamed('autobiographyId'),
      )).thenAnswer((_) async => Left(DatabaseFailure.queryFailed()));

      // Act
      final result = await useCases.getVersionsForAutobiography(
        autobiographyId: testAutobiographyId,
      );

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('deleteVersion', () {
    const testVersionId = 'version-123';

    test('应该成功删除版本', () async {
      // Arrange
      when(mockRepository.deleteVersion(
        versionId: testVersionId,
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCases.deleteVersion(versionId: testVersionId);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.deleteVersion(
        versionId: testVersionId,
      )).called(1);
    });

    test('应该正确处理删除失败', () async {
      // Arrange
      when(mockRepository.deleteVersion(
        versionId: anyNamed('versionId'),
      )).thenAnswer((_) async => Left(DatabaseFailure.deleteFailed()));

      // Act
      final result = await useCases.deleteVersion(versionId: testVersionId);

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('getVersionDetail', () {
    const testVersionId = 'version-123';

    test('应该成功获取版本', () async {
      // Arrange
      final testVersion = AutobiographyVersion(
        id: testVersionId,
        autobiographyId: 'auto-123',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [],
        createdAt: DateTime.now(),
        wordCount: 50,
      );

      when(mockRepository.getVersion(
        versionId: testVersionId,
      )).thenAnswer((_) async => Right(testVersion));

      // Act
      final result = await useCases.getVersionDetail(versionId: testVersionId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('应该成功'),
        (version) {
          expect(version.id, testVersionId);
          expect(version.versionName, '测试版本');
        },
      );
    });

    test('应该正确处理版本不存在', () async {
      // Arrange
      when(mockRepository.getVersion(
        versionId: anyNamed('versionId'),
      )).thenAnswer((_) async => Left(DatabaseFailure.queryFailed()));

      // Act
      final result = await useCases.getVersionDetail(versionId: 'non-existent');

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
