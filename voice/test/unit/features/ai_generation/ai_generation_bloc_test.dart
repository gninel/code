import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_state.dart';
import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';
import 'package:voice_autobiography_flutter/data/services/background_ai_service.dart';

import 'ai_generation_bloc_test.mocks.dart';

@GenerateMocks([
  AiGenerationUseCases,
  AutobiographyRepository,
])
class MockBackgroundAiService extends Mock implements BackgroundAiService {}

void main() {
  group('AiGenerationBloc - 完整重新生成功能', () {
    late AiGenerationBloc aiGenerationBloc;
    late MockAiGenerationUseCases mockAiGenerationUseCases;
    late MockAutobiographyRepository mockAutobiographyRepository;
    late MockBackgroundAiService mockBackgroundService;

    setUp(() {
      mockAiGenerationUseCases = MockAiGenerationUseCases();
      mockAutobiographyRepository = MockAutobiographyRepository();
      mockBackgroundService = MockBackgroundAiService();

      when(mockBackgroundService.startBackgroundTask(
        taskDescription: anyNamed('taskDescription'),
      )).thenAnswer((_) async => true);
      when(mockBackgroundService.stopBackgroundTask())
          .thenAnswer((_) async => true);

      aiGenerationBloc = AiGenerationBloc(
        mockAiGenerationUseCases,
        mockAutobiographyRepository,
        mockBackgroundService,
      );
    });

    tearDown(() {
      aiGenerationBloc.close();
    });

    // 测试数据
    final testVoiceRecords = [
      VoiceRecord(
        id: '1',
        title: '测试记录1',
        content: '这是测试内容1',
        transcription: '这是转写内容1',
        duration: 60,
        timestamp: DateTime.now(),
        isProcessed: true,
        tags: const ['测试'],
        isIncludedInBio: true,
      ),
      VoiceRecord(
        id: '2',
        title: '测试记录2',
        content: '这是测试内容2',
        transcription: '这是转写内容2',
        duration: 90,
        timestamp: DateTime.now(),
        isProcessed: true,
        tags: const ['测试'],
        isIncludedInBio: true,
      ),
    ];

    final existingAutobiographies = [
      Autobiography(
        id: 'existing-1',
        title: '旧自传',
        content: '旧的自传内容',
        chapters: const [],
        generatedAt: DateTime.now().subtract(const Duration(days: 1)),
        lastModifiedAt: DateTime.now().subtract(const Duration(days: 1)),
        version: 1,
        wordCount: 100,
        voiceRecordIds: const ['1'],
        status: AutobiographyStatus.published,
        style: AutobiographyStyle.narrative,
      ),
    ];

    final newAutobiographyResult = AutobiographyGenerationResult(
      content: '新的自传内容',
      title: '新的自传',
      summary: '新的摘要',
      wordCount: 200,
      style: AutobiographyStyle.narrative,
    );

    test('初始状态应该是空闲状态', () {
      expect(aiGenerationBloc.state.status, AiGenerationStatus.idle);
      expect(aiGenerationBloc.state.isGenerating, false);
      expect(aiGenerationBloc.state.hasGeneratedContent, false);
    });

    blocTest<AiGenerationBloc, AiGenerationState>(
      '完整重新生成成功 - 删除现有自传后生成新自传',
      setUp: () {
        // 模拟获取现有自传
        when(mockAutobiographyRepository.getAllAutobiographies())
            .thenAnswer((_) async => Right(existingAutobiographies));

        // 模拟删除所有自传
        when(mockAutobiographyRepository.deleteAutobiographies(['existing-1']))
            .thenAnswer((_) async => const Right(null));

        // 模拟生成新自传
        when(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).thenAnswer((_) async => Right(newAutobiographyResult));
      },
      build: () => aiGenerationBloc,
      act: (bloc) => bloc.add(RegenerateCompleteAutobiography(
        allVoiceRecords: testVoiceRecords,
        style: AutobiographyStyle.narrative,
      )),
      expect: () => [
        const AiGenerationState(
          status: AiGenerationStatus.generating,
          error: null,
        ),
        AiGenerationState(
          status: AiGenerationStatus.completed,
          generationResult: newAutobiographyResult,
          generatedContent: '新的自传内容',
          generatedTitle: '新的自传',
          generatedSummary: '新的摘要',
          activeVoiceRecords: testVoiceRecords,
          baseAutobiography: null,
          error: null,
        ),
      ],
      verify: (bloc) {
        verify(mockAutobiographyRepository.getAllAutobiographies()).called(1);
        verify(mockAutobiographyRepository.deleteAutobiographies(['existing-1']))
            .called(1);
        verify(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '完整重新生成成功 - 无现有自传直接生成',
      setUp: () {
        // 模拟没有现有自传
        when(mockAutobiographyRepository.getAllAutobiographies())
            .thenAnswer((_) async => const Right([]));

        // 模拟生成新自传
        when(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).thenAnswer((_) async => Right(newAutobiographyResult));
      },
      build: () => aiGenerationBloc,
      act: (bloc) => bloc.add(RegenerateCompleteAutobiography(
        allVoiceRecords: testVoiceRecords,
      )),
      expect: () => [
        const AiGenerationState(
          status: AiGenerationStatus.generating,
          error: null,
        ),
        AiGenerationState(
          status: AiGenerationStatus.completed,
          generationResult: newAutobiographyResult,
          generatedContent: '新的自传内容',
          generatedTitle: '新的自传',
          generatedSummary: '新的摘要',
          activeVoiceRecords: testVoiceRecords,
          baseAutobiography: null,
          error: null,
        ),
      ],
      verify: (bloc) {
        verify(mockAutobiographyRepository.getAllAutobiographies()).called(1);
        // 确保没有调用删除方法
        verifyNever(mockAutobiographyRepository.deleteAutobiographies(any));
        verify(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '完整重新生成失败 - AI生成失败',
      setUp: () {
        // 模拟获取现有自传
        when(mockAutobiographyRepository.getAllAutobiographies())
            .thenAnswer((_) async => Right(existingAutobiographies));

        // 模拟删除成功
        when(mockAutobiographyRepository.deleteAutobiographies(['existing-1']))
            .thenAnswer((_) async => const Right(null));

        // 模拟生成失败
        when(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).thenAnswer(
          (_) async => Left(AiGenerationFailure.contentGenerationFailed(message: 'AI服务错误')),
        );
      },
      build: () => aiGenerationBloc,
      act: (bloc) => bloc.add(RegenerateCompleteAutobiography(
        allVoiceRecords: testVoiceRecords,
      )),
      expect: () => [
        const AiGenerationState(
          status: AiGenerationStatus.generating,
          error: null,
        ),
        const AiGenerationState(
          status: AiGenerationStatus.error,
          error: 'AI服务错误',
        ),
      ],
      verify: (bloc) {
        verify(mockAutobiographyRepository.getAllAutobiographies()).called(1);
        verify(mockAutobiographyRepository.deleteAutobiographies(['existing-1']))
            .called(1);
        verify(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '完整重新生成 - 指定字数和风格',
      setUp: () {
        when(mockAutobiographyRepository.getAllAutobiographies())
            .thenAnswer((_) async => const Right([]));

        when(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.emotional,
          wordCount: 1000,
        )).thenAnswer((_) async => Right(newAutobiographyResult));
      },
      build: () => aiGenerationBloc,
      act: (bloc) => bloc.add(RegenerateCompleteAutobiography(
        allVoiceRecords: testVoiceRecords,
        style: AutobiographyStyle.emotional,
        wordCount: 1000,
      )),
      expect: () => [
        const AiGenerationState(
          status: AiGenerationStatus.generating,
          error: null,
        ),
        AiGenerationState(
          status: AiGenerationStatus.completed,
          generationResult: newAutobiographyResult,
          generatedContent: '新的自传内容',
          generatedTitle: '新的自传',
          generatedSummary: '新的摘要',
          activeVoiceRecords: testVoiceRecords,
          baseAutobiography: null,
          error: null,
        ),
      ],
      verify: (bloc) {
        verify(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.emotional,
          wordCount: 1000,
        )).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '完整重新生成 - 获取现有自传失败但仍继续生成',
      setUp: () {
        // 模拟获取现有自传失败
        when(mockAutobiographyRepository.getAllAutobiographies())
            .thenAnswer((_) async => const Left(CacheFailure('读取失败')));

        // 模拟生成新自传
        when(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).thenAnswer((_) async => Right(newAutobiographyResult));
      },
      build: () => aiGenerationBloc,
      act: (bloc) => bloc.add(RegenerateCompleteAutobiography(
        allVoiceRecords: testVoiceRecords,
      )),
      expect: () => [
        const AiGenerationState(
          status: AiGenerationStatus.generating,
          error: null,
        ),
        AiGenerationState(
          status: AiGenerationStatus.completed,
          generationResult: newAutobiographyResult,
          generatedContent: '新的自传内容',
          generatedTitle: '新的自传',
          generatedSummary: '新的摘要',
          activeVoiceRecords: testVoiceRecords,
          baseAutobiography: null,
          error: null,
        ),
      ],
      verify: (bloc) {
        verify(mockAutobiographyRepository.getAllAutobiographies()).called(1);
        verifyNever(mockAutobiographyRepository.deleteAutobiographies(any));
        verify(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: null,
        )).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '完整重新生成 - 正在生成时忽略新请求',
      setUp: () {
        // 模拟延迟响应，测试状态检查
        when(mockAutobiographyRepository.getAllAutobiographies())
            .thenAnswer((_) async => const Right([]));

        when(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        )).thenAnswer((_) async => Right(newAutobiographyResult));
      },
      build: () => aiGenerationBloc,
      seed: () => const AiGenerationState(
        status: AiGenerationStatus.generating,
      ),
      act: (bloc) => bloc.add(RegenerateCompleteAutobiography(
        allVoiceRecords: testVoiceRecords,
      )),
      expect: () => [],
      verify: (bloc) {
        // 验证不会重新调用生成方法
        verifyNever(mockAiGenerationUseCases.generateCompleteAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        ));
      },
    );
  });
}
