// AI 生成 UseCase 完整功能测试
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/domain/repositories/ai_generation_repository.dart';
import 'package:voice_autobiography_flutter/domain/services/autobiography_structure_service.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

import 'ai_generation_usecases_complete_test.mocks.dart';

@GenerateMocks([AiGenerationRepository])
void main() {
  late AiGenerationUseCases useCases;
  late MockAiGenerationRepository mockRepository;

  setUp(() {
    mockRepository = MockAiGenerationRepository();
    useCases = AiGenerationUseCases(mockRepository);
  });

  group('AiGenerationUseCases - generateCompleteAutobiography', () {
    final testVoiceRecords = [
      VoiceRecord(
        id: '1',
        title: '童年记忆',
        transcription: '我的童年在一个小镇度过',
        timestamp: DateTime(2024, 1, 1),
        duration: 60,
      ),
      VoiceRecord(
        id: '2',
        title: '求学经历',
        transcription: '我在大学学习了计算机科学',
        timestamp: DateTime(2024, 1, 2),
        duration: 120,
      ),
    ];

    test('应该成功生成完整自传（包含内容、标题和摘要）', () async {
      // 模拟生成自传内容
      when(mockRepository.generateAutobiography(
        voiceRecords: anyNamed('voiceRecords'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenAnswer((_) async => const Right('这是生成的自传内容。'));

      // 模拟生成标题
      when(mockRepository.generateTitle(
        content: anyNamed('content'),
      )).thenAnswer((_) async => const Right('我的人生故事'));

      // 模拟生成摘要
      when(mockRepository.generateSummary(
        content: anyNamed('content'),
      )).thenAnswer((_) async => const Right('这是一段精彩的人生旅程。'));

      final result = await useCases.generateCompleteAutobiography(
        voiceRecords: testVoiceRecords,
        style: AutobiographyStyle.narrative,
        wordCount: 2000,
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (generationResult) {
          expect(generationResult.content, equals('这是生成的自传内容。'));
          expect(generationResult.title, equals('我的人生故事'));
          expect(generationResult.summary, equals('这是一段精彩的人生旅程。'));
          expect(generationResult.style, equals(AutobiographyStyle.narrative));
          expect(generationResult.wordCount, greaterThan(0));
        },
      );

      // 验证调用顺序
      verifyInOrder([
        mockRepository.generateAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: 2000,
        ),
        mockRepository.generateTitle(content: '这是生成的自传内容。'),
        mockRepository.generateSummary(content: '这是生成的自传内容。'),
      ]);
    });

    test('内容生成失败时应该返回 Failure', () async {
      when(mockRepository.generateAutobiography(
        voiceRecords: anyNamed('voiceRecords'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenAnswer(
        (_) async => Left(AiGenerationFailure.contentGenerationFailed()),
      );

      final result = await useCases.generateCompleteAutobiography(
        voiceRecords: testVoiceRecords,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AiGenerationFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('标题生成失败时应该使用默认标题', () async {
      when(mockRepository.generateAutobiography(
        voiceRecords: anyNamed('voiceRecords'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenAnswer((_) async => const Right('自传内容'));

      when(mockRepository.generateTitle(
        content: anyNamed('content'),
      )).thenAnswer(
        (_) async => Left(AiGenerationFailure.contentGenerationFailed()),
      );

      when(mockRepository.generateSummary(
        content: anyNamed('content'),
      )).thenAnswer((_) async => const Right('摘要'));

      final result = await useCases.generateCompleteAutobiography(
        voiceRecords: testVoiceRecords,
      );

      result.fold(
        (_) => fail('Should succeed'),
        (generationResult) {
          expect(generationResult.title, equals('我的自传'));
          expect(generationResult.content, equals('自传内容'));
        },
      );
    });

    test('摘要生成失败时应该继续完成生成', () async {
      when(mockRepository.generateAutobiography(
        voiceRecords: anyNamed('voiceRecords'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenAnswer((_) async => const Right('自传内容'));

      when(mockRepository.generateTitle(
        content: anyNamed('content'),
      )).thenAnswer((_) async => const Right('标题'));

      when(mockRepository.generateSummary(
        content: anyNamed('content'),
      )).thenAnswer(
        (_) async => Left(AiGenerationFailure.contentGenerationFailed()),
      );

      final result = await useCases.generateCompleteAutobiography(
        voiceRecords: testVoiceRecords,
      );

      result.fold(
        (_) => fail('Should succeed'),
        (generationResult) {
          expect(generationResult.title, equals('标题'));
          expect(generationResult.summary, equals(''));
          expect(generationResult.content, equals('自传内容'));
        },
      );
    });

    test('应该支持不同的写作风格', () async {
      for (final style in AutobiographyStyle.values) {
        when(mockRepository.generateAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: style,
          wordCount: anyNamed('wordCount'),
        )).thenAnswer((_) async => const Right('内容'));

        when(mockRepository.generateTitle(content: anyNamed('content')))
            .thenAnswer((_) async => const Right('标题'));

        when(mockRepository.generateSummary(content: anyNamed('content')))
            .thenAnswer((_) async => const Right('摘要'));

        final result = await useCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: style,
        );

        result.fold(
          (_) => fail('Should succeed for style $style'),
          (generationResult) {
            expect(generationResult.style, equals(style));
          },
        );
      }
    });
  });

  group('AiGenerationUseCases - incrementalUpdateAutobiography', () {
    final existingChapters = [
      Chapter(
        id: '1',
        title: '童年',
        content: '我的童年很快乐。',
        order: 0,
        lastModifiedAt: DateTime(2024, 1, 1),
      ),
    ];

    final existingAutobiography = Autobiography(
      id: 'auto-1',
      title: '我的自传',
      content: '我的童年很快乐。',
      generatedAt: DateTime(2024, 1, 1),
      lastModifiedAt: DateTime(2024, 1, 1),
      wordCount: 10,
      voiceRecordIds: const ['1'],
      chapters: existingChapters,
    );

    test('应该成功创建新章节（全量替换模式）', () async {
      final structurePlan = StructureUpdatePlan(
        action: StructureAction.createNew,
        newChapterTitle: '求学经历',
        reasoning: '内容涉及新主题',
      );

      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => Right(structurePlan));

      when(mockRepository.generateChapterContent(
        originalContent: anyNamed('originalContent'),
        newVoiceContent: anyNamed('newVoiceContent'),
      )).thenAnswer((_) async => const Right('新的章节内容'));

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '我在大学学习计算机',
        currentAutobiography: existingAutobiography,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (updateResult) {
          // 当有现有章节时，会执行全量替换
          expect(updateResult.updateType, equals(UpdateType.fullReplacement));
          expect(updateResult.updatedChapter, isNotNull);
          expect(updateResult.updateIndex, equals(0));
        },
      );
    });

    test('应该成功更新现有章节', () async {
      final structurePlan = StructureUpdatePlan(
        action: StructureAction.updateExisting,
        targetChapterIndex: 0,
        reasoning: '补充童年内容',
      );

      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => Right(structurePlan));

      when(mockRepository.generateChapterContent(
        originalContent: anyNamed('originalContent'),
        newVoiceContent: anyNamed('newVoiceContent'),
      )).thenAnswer((_) async => const Right('更新后的童年内容'));

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '童年时我还养了一只小狗',
        currentAutobiography: existingAutobiography,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (updateResult) {
          expect(updateResult.updateType, equals(UpdateType.chapterUpdated));
          expect(updateResult.updatedChapter, isNotNull);
          expect(updateResult.updateIndex, equals(0));
        },
      );
    });

    test('应该处理忽略的内容', () async {
      final structurePlan = StructureUpdatePlan(
        action: StructureAction.ignore,
        reasoning: '内容过于简短或无意义',
      );

      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => Right(structurePlan));

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '嗯嗯啊啊',
        currentAutobiography: existingAutobiography,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should succeed'),
        (updateResult) {
          expect(updateResult.updateType, equals(UpdateType.ignored));
          expect(updateResult.updatedChapter, isNull);
          expect(updateResult.updateIndex, equals(-1));
        },
      );
    });

    test('全新自传应该执行全量替换', () async {
      final structurePlan = StructureUpdatePlan(
        action: StructureAction.createNew,
        newChapterTitle: '第一章',
        reasoning: '全新内容',
      );

      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => Right(structurePlan));

      when(mockRepository.generateChapterContent(
        originalContent: anyNamed('originalContent'),
        newVoiceContent: anyNamed('newVoiceContent'),
      )).thenAnswer((_) async => const Right('完整的融合内容'));

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '这是新的录音内容',
        currentAutobiography: existingAutobiography,
      );

      result.fold(
        (_) => fail('Should succeed'),
        (updateResult) {
          // 验证章节内容已生成
          expect(updateResult.updatedChapter, isNotNull);
        },
      );

      // 验证调用了 generateChapterContent 并传递了完整内容
      verify(mockRepository.generateChapterContent(
        originalContent: anyNamed('originalContent'),
        newVoiceContent: '这是新的录音内容',
      )).called(1);
    });

    test('结构分析失败时应该返回 Failure', () async {
      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer(
        (_) async => Left(AiGenerationFailure.serviceUnavailable()),
      );

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '新内容',
        currentAutobiography: existingAutobiography,
      );

      expect(result.isLeft(), true);
    });

    test('章节生成失败时应该返回 Failure', () async {
      final structurePlan = StructureUpdatePlan(
        action: StructureAction.createNew,
        newChapterTitle: '新章节',
        reasoning: '新主题',
      );

      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => Right(structurePlan));

      when(mockRepository.generateChapterContent(
        originalContent: anyNamed('originalContent'),
        newVoiceContent: anyNamed('newVoiceContent'),
      )).thenAnswer(
        (_) async => Left(AiGenerationFailure.contentGenerationFailed()),
      );

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '新内容',
        currentAutobiography: existingAutobiography,
      );

      expect(result.isLeft(), true);
    });

    test('无效的章节索引应该返回 Failure', () async {
      final structurePlan = StructureUpdatePlan(
        action: StructureAction.updateExisting,
        targetChapterIndex: 999, // 无效索引
        reasoning: '更新',
      );

      when(mockRepository.analyzeStructure(
        newContent: anyNamed('newContent'),
        currentChapters: anyNamed('currentChapters'),
      )).thenAnswer((_) async => Right(structurePlan));

      final result = await useCases.incrementalUpdateAutobiography(
        newVoiceContent: '新内容',
        currentAutobiography: existingAutobiography,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AiGenerationFailure>()),
        (_) => fail('Should fail with invalid index'),
      );
    });
  });

  group('AiGenerationUseCases - generateAutobiography', () {
    test('应该调用 repository 生成自传', () async {
      final voiceRecords = [
        VoiceRecord(
          id: '1',
          title: '测试',
          transcription: '测试内容',
          timestamp: DateTime.now(),
          duration: 60,
        ),
      ];

      when(mockRepository.generateAutobiography(
        voiceRecords: anyNamed('voiceRecords'),
        style: anyNamed('style'),
        wordCount: anyNamed('wordCount'),
      )).thenAnswer((_) async => const Right('生成的内容'));

      final result = await useCases.generateAutobiography(
        voiceRecords: voiceRecords,
        style: AutobiographyStyle.emotional,
        wordCount: 3000,
      );

      expect(result.isRight(), true);
      verify(mockRepository.generateAutobiography(
        voiceRecords: voiceRecords,
        style: AutobiographyStyle.emotional,
        wordCount: 3000,
      )).called(1);
    });
  });

  group('AiGenerationUseCases - optimizeAutobiography', () {
    test('应该调用 repository 优化内容', () async {
      when(mockRepository.optimizeAutobiography(
        content: anyNamed('content'),
        optimizationType: anyNamed('optimizationType'),
      )).thenAnswer((_) async => const Right('优化后的内容'));

      final result = await useCases.optimizeAutobiography(
        content: '原始内容',
        optimizationType: OptimizationType.clarity,
      );

      expect(result.isRight(), true);
      verify(mockRepository.optimizeAutobiography(
        content: '原始内容',
        optimizationType: OptimizationType.clarity,
      )).called(1);
    });
  });

  group('AiGenerationUseCases - generateTitle', () {
    test('应该调用 repository 生成标题', () async {
      when(mockRepository.generateTitle(content: anyNamed('content')))
          .thenAnswer((_) async => const Right('标题'));

      final result = await useCases.generateTitle(content: '内容');

      expect(result.isRight(), true);
      verify(mockRepository.generateTitle(content: '内容')).called(1);
    });
  });

  group('AiGenerationUseCases - generateSummary', () {
    test('应该调用 repository 生成摘要', () async {
      when(mockRepository.generateSummary(content: anyNamed('content')))
          .thenAnswer((_) async => const Right('摘要'));

      final result = await useCases.generateSummary(content: '内容');

      expect(result.isRight(), true);
      verify(mockRepository.generateSummary(content: '内容')).called(1);
    });
  });

  group('AutobiographyGenerationResult', () {
    test('toAutobiography 应该正确转换', () async {
      final result = AutobiographyGenerationResult(
        content: '测试内容',
        title: '测试标题',
        summary: '测试摘要',
        wordCount: 100,
        style: AutobiographyStyle.narrative,
      );

      final autobiography = result.toAutobiography(
        id: 'test-id',
        voiceRecordIds: ['1', '2'],
        tags: ['测试', '自传'],
      );

      expect(autobiography.id, equals('test-id'));
      expect(autobiography.title, equals('测试标题'));
      expect(autobiography.content, equals('测试内容'));
      expect(autobiography.summary, equals('测试摘要'));
      expect(autobiography.wordCount, equals(100));
      expect(autobiography.voiceRecordIds, equals(['1', '2']));
      expect(autobiography.tags, equals(['测试', '自传']));
      expect(autobiography.status, equals(AutobiographyStatus.draft));
    });

    test('estimatedReadingMinutes 应该正确计算', () {
      final result = AutobiographyGenerationResult(
        content: 'x' * 500,
        title: '标题',
        summary: '摘要',
        wordCount: 500,
        style: AutobiographyStyle.narrative,
      );

      expect(result.estimatedReadingMinutes, equals(3)); // 500 / 200 = 2.5, ceil = 3
    });

    test('contentPreview 应该正确截取', () {
      final longContent = 'x' * 200;
      final result = AutobiographyGenerationResult(
        content: longContent,
        title: '标题',
        summary: '摘要',
        wordCount: 200,
        style: AutobiographyStyle.narrative,
      );

      expect(result.contentPreview.length, lessThanOrEqualTo(103)); // 100 + '...'
      expect(result.contentPreview, endsWith('...'));
    });

    test('copyWith 应该正确复制和修改', () {
      final original = AutobiographyGenerationResult(
        content: '原内容',
        title: '原标题',
        summary: '原摘要',
        wordCount: 100,
        style: AutobiographyStyle.narrative,
      );

      final copy = original.copyWith(
        title: '新标题',
        wordCount: 200,
      );

      expect(copy.title, equals('新标题'));
      expect(copy.wordCount, equals(200));
      expect(copy.content, equals('原内容'));
      expect(copy.summary, equals('原摘要'));
    });
  });
}
