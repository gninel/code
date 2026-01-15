import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';
import 'package:voice_autobiography_flutter/data/repositories/autobiography_version_repository_impl.dart';
import 'package:voice_autobiography_flutter/data/services/database_service.dart';

import 'autobiography_version_repository_test.mocks.dart';

@GenerateMocks([DatabaseService])
void main() {
  late AutobiographyVersionRepositoryImpl repository;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    repository = AutobiographyVersionRepositoryImpl(mockDatabaseService);
  });

  const tAutobiographyId = 'auto_123';
  const tVersionName = 'Test Version';
  const tContent = 'Test Content';
  const tChapters = [
    {'title': 'Chapter 1', 'content': 'Content 1'}
  ];
  const tWordCount = 100;
  const tSummary = 'Summary';

  group('saveVersion', () {
    test('should save version successfully', () async {
      // Arrange
      when(mockDatabaseService.getCount(any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 0);
      when(mockDatabaseService.insert(any, any)).thenAnswer((_) async => 1);
      // Stub for the validation query in logging
      when(mockDatabaseService.query(any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => [
                {'id': '1'}
              ]);

      // Act
      final result = await repository.saveVersion(
        autobiographyId: tAutobiographyId,
        versionName: tVersionName,
        content: tContent,
        chapters: tChapters,
        wordCount: tWordCount,
        summary: tSummary,
      );

      // Assert
      expect(result.isRight(), true);
      verify(mockDatabaseService.insert(
        DatabaseTables.autobiographyVersions,
        argThat(predicate<Map<String, dynamic>>((map) {
          return map['autobiography_id'] == tAutobiographyId &&
              map['version_name'] == tVersionName &&
              map['content'] == tContent &&
              map['word_count'] == tWordCount;
        })),
      )).called(1);
    });

    test('should delete oldest version when limit reached', () async {
      // Arrange
      when(mockDatabaseService.getCount(any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 20); // Max limit

      when(mockDatabaseService.query(any,
              where: anyNamed('where'),
              whereArgs: anyNamed('whereArgs'),
              orderBy: anyNamed('orderBy'),
              limit: anyNamed('limit')))
          .thenAnswer((_) async => [
                {'id': 'oldest_id'}
              ]);

      when(mockDatabaseService.delete(any,
              where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);

      when(mockDatabaseService.insert(any, any)).thenAnswer((_) async => 1);

      // Act
      await repository.saveVersion(
        autobiographyId: tAutobiographyId,
        versionName: tVersionName,
        content: tContent,
        chapters: tChapters,
        wordCount: tWordCount,
      );

      // Assert
      verify(mockDatabaseService.delete(
        DatabaseTables.autobiographyVersions,
        where: 'id = ?',
        whereArgs: ['oldest_id'],
      )).called(1);
    });
  });

  group('getVersions', () {
    test('should return list of versions', () async {
      // Arrange
      final tVersionsData = [
        {
          'id': '1',
          'autobiography_id': tAutobiographyId,
          'version_name': 'V1',
          'content': 'C1',
          'chapters': '[{"title":"C1","content":"C1"}]',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'word_count': 100,
          'summary': 'S1',
        }
      ];

      when(mockDatabaseService.query(
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
      )).thenAnswer((_) async => tVersionsData);

      // Act
      final result =
          await repository.getVersions(autobiographyId: tAutobiographyId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (versions) {
          expect(versions.length, 1);
          expect(versions.first.versionName, 'V1');
        },
      );
    });
  });
}
