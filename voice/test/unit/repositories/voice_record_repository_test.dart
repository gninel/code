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
      when(mockRepository.getAllVoiceRecords())
          .thenAnswer((_) async => Right([testVoiceRecord]));

      // Act
      final result = await mockRepository.getAllVoiceRecords();

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), equals([testVoiceRecord]));
      verify(mockRepository.getAllVoiceRecords());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when getting voice records fails', () async {
      // Arrange
      final failure = NetworkFailure.serverError();
      when(mockRepository.getAllVoiceRecords())
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.getAllVoiceRecords();

      // Assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
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

    test('should return DatabaseFailure when id does not exist', () async {
      // Arrange
      final failure = DatabaseFailure.tableNotFound('id not found');
      when(mockRepository.getVoiceRecordById('non-existent'))
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.getVoiceRecordById('non-existent');

      // Assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<DatabaseFailure>());
    });

    test('should save voice record successfully', () async {
      // Arrange
      when(mockRepository.insertVoiceRecord(testVoiceRecord))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.insertVoiceRecord(testVoiceRecord);

      // Assert
      expect(result, const Right(null));
      verify(mockRepository.insertVoiceRecord(testVoiceRecord));
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
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.updateVoiceRecord(updatedRecord);

      // Assert
      expect(result, const Right(null));
      // Verify update called
      verify(mockRepository.updateVoiceRecord(updatedRecord));
    });

    test('should get voice records by date range successfully', () async {
      // Arrange
      final startDate = DateTime(2024, 12, 1);
      final endDate = DateTime(2024, 12, 31);
      when(mockRepository.getVoiceRecordsByDateRange(startDate, endDate))
          .thenAnswer((_) async => Right([testVoiceRecord]));

      // Act
      final result =
          await mockRepository.getVoiceRecordsByDateRange(startDate, endDate);

      // Assert
      expect(result.isRight(), true);
      verify(mockRepository.getVoiceRecordsByDateRange(startDate, endDate));
    });

    group('Error Handling', () {
      test('should handle network failure', () async {
        // Arrange
        const failure = NetworkFailure('No internet connection');
        when(mockRepository.getAllVoiceRecords())
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.getAllVoiceRecords();

        // Assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => null), isA<NetworkFailure>());
      });

      test('should handle cache failure', () async {
        // Arrange
        const failure = CacheFailure('Cache error');
        when(mockRepository.insertVoiceRecord(testVoiceRecord))
            .thenAnswer((_) async => const Left(failure));

        // Act
        final result = await mockRepository.insertVoiceRecord(testVoiceRecord);

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
