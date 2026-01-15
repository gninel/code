// AI 生成仓库测试
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:voice_autobiography_flutter/data/repositories/ai_generation_repository_impl.dart';
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/domain/services/autobiography_structure_service.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';
import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';

import 'ai_generation_repository_test.mocks.dart';

@GenerateMocks([DoubaoAiService])
void main() {
  late AiGenerationRepositoryImpl repository;
  late MockDoubaoAiService mockAiService;

  setUp(() {
    mockAiService = MockDoubaoAiService();
    repository = AiGenerationRepositoryImpl(mockAiService);
  });

  group('generateAutobiography', () {
    final tVoiceRecords = [
      VoiceRecord(
        id: '1',
        title: 'Title',
        transcription: 'Content 1',
        timestamp: DateTime.now(),
      ),
      VoiceRecord(
        id: '2',
        title: 'Title 2',
        transcription: 'Content 2',
        timestamp: DateTime.now(),
      ),
    ];
    const tContent = 'Generated Content';

    test('应该返回生成的自传内容', () async {
      // Arrange
      when(mockAiService.generateAutobiography(
        voiceContents: anyNamed('voiceContents'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenAnswer((_) async => tContent);

      // Act
      final result = await repository.generateAutobiography(
        voiceRecords: tVoiceRecords,
      );

      // Assert
      expect(result, const Right(tContent));
      verify(mockAiService.generateAutobiography(
        voiceContents: ['Content 1', 'Content 2'],
        style: AutobiographyStyle.narrative,
        wordCount: null,
      ));
    });

    test('当没有有效转录内容时应该返回 contentGenerationFailed', () async {
      // Arrange
      final emptyRecords = [
        VoiceRecord(
          id: '1',
          title: 'Empty',
          transcription: '',
          timestamp: DateTime.now(),
        ),
      ];

      // Act
      final result = await repository.generateAutobiography(
        voiceRecords: emptyRecords,
      );

      // Assert
      result.fold(
        (failure) => expect(failure, isA<AiGenerationFailure>()),
        (r) => fail('Should return failure'),
      );
    });

    test('当 Service 抛出 AiGenerationException 时应该映射为 Failure', () async {
      // Arrange
      when(mockAiService.generateAutobiography(
        voiceContents: anyNamed('voiceContents'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenThrow(AiGenerationException.quotaExceeded());

      // Act
      final result = await repository.generateAutobiography(
        voiceRecords: tVoiceRecords,
      );

      // Assert
      result.fold(
        (failure) {
          expect(failure, isA<AiGenerationFailure>());
          expect((failure as AiGenerationFailure).code, 'QUOTA_EXCEEDED');
        },
        (r) => fail('Should return failure'),
      );
    });
  });

  group('analyzeStructure', () {
    const tNewContent = 'New Voice Content';
    final tChapters = [
      Chapter(
        id: '1',
        title: 'Chapter 1',
        content: 'Content',
        order: 0,
        lastModifiedAt: DateTime.now(),
      )
    ];

    test('应该正确解析 createNew 结果', () async {
      // Arrange
      final tAnalysisResult = {
        'action': 'createNew',
        'newChapterTitle': 'New Chapter',
        'reasoning': 'Reason',
      };

      when(mockAiService.analyzeAutobiographyStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => tAnalysisResult);

      // Act
      final result = await repository.analyzeStructure(
        newContent: tNewContent,
        currentChapters: tChapters,
      );

      // Assert
      result.fold(
        (l) => fail('Should not fail'),
        (plan) {
          expect(plan.action, StructureAction.createNew);
          expect(plan.newChapterTitle, 'New Chapter');
        },
      );
    });

    test('Service 抛出异常时应返回 Failure', () async {
      when(mockAiService.analyzeAutobiographyStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenThrow(Exception('Error'));

      final result = await repository.analyzeStructure(
        newContent: tNewContent,
        currentChapters: tChapters,
      );

      expect(result.isLeft(), true);
    });
  });

  group('generateTitle', () {
    test('空内容应返回默认标题', () async {
      final result = await repository.generateTitle(content: '   ');
      expect(result, const Right('我的自传'));
    });

    test('应返回生成的标题', () async {
      when(mockAiService.generateTitle(any))
          .thenAnswer((_) async => 'Generated Title');
      final result = await repository.generateTitle(content: 'Content');
      expect(result, const Right('Generated Title'));
    });
  });
}
