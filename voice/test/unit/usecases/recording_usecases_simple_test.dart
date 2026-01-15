import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';

void main() {
  group('RecordingUseCases', () {
    late RecordingUseCases useCases;

    setUp(() {
      // Use null for repositories since we're testing TODO implementations
      useCases = RecordingUseCases(
        null as dynamic,
        null as dynamic,
        null as dynamic,
        MockGenerateAutobiographyUseCase(),
      );
    });

    group('startRecording', () {
      test('should return file path on success', () async {
        // Act
        final result = await useCases.startRecording();

        // Assert
        expect(result.isRight(), true);
        expect(result.fold((l) => '', (r) => r), isA<String>());
      });
    });

    group('stopRecording', () {
      test('should return VoiceRecord with required fields', () async {
        // Act
        final result = await useCases.stopRecording();

        // Assert
        expect(result.isRight(), true);
        final record = result.fold((l) => null, (r) => r);
        expect(record, isA<VoiceRecord>());
        expect(record?.id, isNotEmpty);
        expect(record?.title, isNotEmpty);
        expect(record?.duration, greaterThan(0));
      });

      test('should generate unique IDs', () async {
        // Act
        final result1 = await useCases.stopRecording();
        final result2 = await useCases.stopRecording();

        // Assert
        final id1 = result1.fold((l) => '', (r) => r.id);
        final id2 = result2.fold((l) => '', (r) => r.id);
        expect(id1, isNot(equals(id2)));
      });
    });

    group('pauseRecording', () {
      test('should return Right', () async {
        // Act
        final result = await useCases.pauseRecording();

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('resumeRecording', () {
      test('should return Right', () async {
        // Act
        final result = await useCases.resumeRecording();

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('cancelRecording', () {
      test('should return Right', () async {
        // Act
        final result = await useCases.cancelRecording();

        // Assert
        expect(result.isRight(), true);
      });
    });
  });

  group('GenerateAutobiographyUseCase', () {
    late GenerateAutobiographyUseCase useCase;

    setUp(() {
      useCase = GenerateAutobiographyUseCase();
    });

    final testVoiceRecords = [
      VoiceRecord(
        id: 'vr-1',
        title: 'Record 1',
        content: 'Content 1',
        timestamp: DateTime(2024, 12, 26),
      ),
      VoiceRecord(
        id: 'vr-2',
        title: 'Record 2',
        content: 'Content 2',
        timestamp: DateTime(2024, 12, 25),
      ),
    ];

    group('call', () {
      test('should generate autobiography', () async {
        // Arrange
        final params = GenerateAutobiographyParams(
          voiceRecords: testVoiceRecords,
          style: 'narrative',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Autobiography>());
        expect(result.id, isNotEmpty);
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });

      test('should include voice record IDs', () async {
        // Arrange
        final params = GenerateAutobiographyParams(
          voiceRecords: testVoiceRecords,
          style: 'narrative',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.voiceRecordIds, containsAll(['vr-1', 'vr-2']));
      });

      test('should generate unique IDs', () async {
        // Arrange
        final params = GenerateAutobiographyParams(
          voiceRecords: testVoiceRecords,
          style: 'emotional',
        );

        // Act
        final result1 = await useCase(params);
        final result2 = await useCase(params);

        // Assert
        expect(result1.id, isNot(equals(result2.id)));
      });

      test('should set draft status', () async {
        // Arrange
        final params = GenerateAutobiographyParams(
          voiceRecords: testVoiceRecords,
          style: 'reflection',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.status, AutobiographyStatus.draft);
      });

      test('should handle empty records', () async {
        // Arrange
        final params = GenerateAutobiographyParams(
          voiceRecords: [],
          style: 'achievement',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Autobiography>());
        expect(result.voiceRecordIds, isEmpty);
      });
    });
  });
}

// Mock class for testing
class MockGenerateAutobiographyUseCase extends GenerateAutobiographyUseCase {
  @override
  Future<Autobiography> call(GenerateAutobiographyParams params) async {
    return Autobiography(
      id: 'mock-id',
      title: 'Mock Autobiography',
      content: 'Mock content',
      generatedAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );
  }
}
