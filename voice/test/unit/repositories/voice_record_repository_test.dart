import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

@GenerateMocks([VoiceRecordRepository])
import 'voice_record_repository_test.mocks.dart';

void main() {
  late MockVoiceRecordRepository mockRepository;

  setUp(() {
    mockRepository = MockVoiceRecordRepository();
  });

  group('VoiceRecordRepository Tests', () {
    final testVoiceRecord = VoiceRecord(
      id: 'test-id-1',
      title: '测试录音',
      content: '测试内容',
      timestamp: DateTime.now(),
    );

    test('should get voice records successfully', () async {
      // Arrange
      when(mockRepository.getVoiceRecords())
          .thenAnswer((_) async => Right([testVoiceRecord]));

      // Act
      final result = await mockRepository.getVoiceRecords();

      // Assert
      expect(result, Right<[Failure, List<VoiceRecord>], List<VoiceRecord>>([testVoiceRecord]));
      verify(mockRepository.getVoiceRecords());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when getting voice records fails', () async {
      // Arrange
      final failure = ServerFailure('Server error');
      when(mockRepository.getVoiceRecords())
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.getVoiceRecords();

      // Assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });

    test('should get voice record by id successfully', () async {
      // Arrange
      when(mockRepository.getVoiceRecordById('test-id-1'))
          .thenAnswer((_) async => Right(testVoiceRecord));

      // Act
      final result = await mockRepository.getVoiceRecordById('test-id-1');

      // Assert
      expect(result, Right<Failure, VoiceRecord>(testVoiceRecord));
      verify(mockRepository.getVoiceRecordById('test-id-1'));
    });

    test('should return NotFoundFailure when id does not exist', () async {
      // Arrange
      final failure = NotFoundFailure('Record not found');
      when(mockRepository.getVoiceRecordById('non-existent'))
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.getVoiceRecordById('non-existent');

      // Assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<NotFoundFailure>());
    });

    test('should save voice record successfully', () async {
      // Arrange
      when(mockRepository.saveVoiceRecord(testVoiceRecord))
          .thenAnswer((_) async => Right(testVoiceRecord));

      // Act
      final result = await mockRepository.saveVoiceRecord(testVoiceRecord);

      // Assert
      expect(result, Right(testVoiceRecord));
      verify(mockRepository.saveVoiceRecord(testVoiceRecord));
    });

    test('should delete voice record successfully', () async {
      // Arrange
      when(mockRepository.deleteVoiceRecord('test-id-1'))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.deleteVoiceRecord('test-id-1');

      // Assert
      expect(result, const Right(null));
      verify(mockRepository.deleteVoiceRecord('test-id-1'));
    });

    test('should update voice record successfully', () async {
      // Arrange
      final updatedRecord = testVoiceRecord.copyWith(title: '更新标题');
      when(mockRepository.updateVoiceRecord(updatedRecord))
          .thenAnswer((_) async => Right(updatedRecord));

      // Act
      final result = await mockRepository.updateVoiceRecord(updatedRecord);

      // Assert
      expect(result, Right(updatedRecord));
      expect(result.fold((l) => null, (r) => r.title), '更新标题');
    });

    test('should get voice records by tags successfully', () async {
      // Arrange
      final taggedRecords = [
        testVoiceRecord.copyWith(tags: ['童年']),
        testVoiceRecord.copyWith(id: '2', tags: ['童年', '回忆']),
      ];
      when(mockRepository.getVoiceRecordsByTags(['童年']))
          .thenAnswer((_) async => Right(taggedRecords));

      // Act
      final result = await mockRepository.getVoiceRecordsByTags(['童年']);

      // Assert
      expect(result.isRight(), true);
      expect(result.fold((l) => [], (r) => r).length, 2);
    });

    test('should get voice records by date range successfully', () async {
      // Arrange
      final startDate = DateTime(2024, 12, 1);
      final endDate = DateTime(2024, 12, 31);
      when(mockRepository.getVoiceRecordsByDateRange(startDate, endDate))
          .thenAnswer((_) async => Right([testVoiceRecord]));

      // Act
      final result = await mockRepository.getVoiceRecordsByDateRange(startDate, endDate);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.getVoiceRecordsByDateRange(startDate, endDate));
    });

    group('Error Handling', () {
      test('should handle network failure', () async {
        // Arrange
        const failure = NetworkFailure('No internet connection');
        when(mockRepository.getVoiceRecords())
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getVoiceRecords();

        // Assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
      });

      test('should handle cache failure', () async {
        // Arrange
        const failure = CacheFailure('Cache error');
        when(mockRepository.saveVoiceRecord(testVoiceRecord))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.saveVoiceRecord(testVoiceRecord);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should handle permission denied failure', () async {
        // Arrange
        const failure = PermissionFailure('Permission denied');
        when(mockRepository.deleteVoiceRecord('test-id'))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.deleteVoiceRecord('test-id');

        // Assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => null), isA<PermissionFailure>());
      });
    });
  });
}
