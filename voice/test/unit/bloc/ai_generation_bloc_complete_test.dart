// AI 生成 BLoC 完整场景测试
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_state.dart';
import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart';
import 'package:voice_autobiography_flutter/data/services/background_ai_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

import 'ai_generation_bloc_complete_test.mocks.dart';

@GenerateMocks([
  AiGenerationUseCases,
  AutobiographyRepository,
  BackgroundAiService,
])
void main() {
  late AiGenerationBloc bloc;
  late MockAiGenerationUseCases mockUseCases;
  late MockAutobiographyRepository mockRepository;
  late MockBackgroundAiService mockBackgroundService;

  setUp(() {
    mockUseCases = MockAiGenerationUseCases();
    mockRepository = MockAutobiographyRepository();
    mockBackgroundService = MockBackgroundAiService();

    // 默认 mock 后台服务返回Future
    when(mockBackgroundService.startBackgroundTask(
      taskDescription: anyNamed('taskDescription'),
    )).thenAnswer((_) async => true);
    when(mockBackgroundService.stopBackgroundTask())
        .thenAnswer((_) async => true);

    bloc = AiGenerationBloc(
      mockUseCases,
      mockRepository,
      mockBackgroundService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AiGenerationBloc - GenerateCompleteAutobiography', () {
    final testVoiceRecords = [
      VoiceRecord(
        id: '1',
        title: '童年',
        transcription: '我的童年很快乐',
        timestamp: DateTime(2024, 1, 1),
        duration: 60,
      ),
    ];

    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该成功生成完整自传',
      build: () {
        when(mockUseCases.generateCompleteAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        )).thenAnswer(
          (_) async => Right(
            AutobiographyGenerationResult(
              content: '生成的自传内容',
              title: '我的人生',
              summary: '精彩的一生',
              wordCount: 100,
              style: AutobiographyStyle.narrative,
            ),
          ),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        GenerateCompleteAutobiography(
          voiceRecords: testVoiceRecords,
          style: AutobiographyStyle.narrative,
          wordCount: 2000,
        ),
      ),
      expect: () => [
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.generating &&
              state.activeVoiceRecords == testVoiceRecords &&
              state.baseAutobiography == null;
        }),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.completed &&
              state.generatedContent == '生成的自传内容' &&
              state.generatedTitle == '我的人生' &&
              state.generatedSummary == '精彩的一生' &&
              state.generationResult != null;
        }),
      ],
      verify: (_) {
        verify(mockBackgroundService.startBackgroundTask(
          taskDescription: '正在生成完整自传...',
        )).called(1);
        verify(mockBackgroundService.stopBackgroundTask()).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '生成失败时应该发出 error 状态',
      build: () {
        when(mockUseCases.generateCompleteAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        )).thenAnswer(
          (_) async => Left(AiGenerationFailure.contentGenerationFailed()),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        GenerateCompleteAutobiography(voiceRecords: testVoiceRecords),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.generating,
        ),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.error &&
              state.error != null;
        }),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '正在生成时应该忽略新的生成请求',
      build: () => bloc,
      seed: () => const AiGenerationState(
        status: AiGenerationStatus.generating,
      ),
      act: (bloc) => bloc.add(
        GenerateCompleteAutobiography(voiceRecords: testVoiceRecords),
      ),
      expect: () => [],
    );
  });

  group('AiGenerationBloc - IncrementalUpdateAutobiography', () {
    final existingAutobiography = Autobiography(
      id: '1',
      title: '我的自传',
      content: '现有内容',
      generatedAt: DateTime(2024, 1, 1),
      lastModifiedAt: DateTime(2024, 1, 1),
      wordCount: 10,
      voiceRecordIds: const [],
      chapters: [
        Chapter(
          id: '1',
          title: '童年',
          content: '童年内容',
          order: 0,
          lastModifiedAt: DateTime(2024, 1, 1),
        ),
      ],
    );

    final newVoiceRecords = [
      VoiceRecord(
        id: '2',
        title: '新录音',
        transcription: '新的内容',
        timestamp: DateTime(2024, 1, 2),
        duration: 60,
      ),
    ];

    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该成功执行增量更新',
      build: () {
        when(mockUseCases.incrementalUpdateAutobiography(
          newVoiceContent: anyNamed('newVoiceContent'),
          currentAutobiography: anyNamed('currentAutobiography'),
        )).thenAnswer(
          (_) async => Right(
            IncrementalUpdateResult(
              updatedChapter: Chapter(
                id: '2',
                title: '新章节',
                content: '更新后的内容',
                order: 1,
                lastModifiedAt: DateTime(2024, 1, 2),
              ),
              updateType: UpdateType.newChapter,
              updateIndex: 1,
            ),
          ),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        IncrementalUpdateAutobiography(
          newVoiceRecords: newVoiceRecords,
          currentAutobiography: existingAutobiography,
        ),
      ),
      expect: () => [
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.generating &&
              state.activeVoiceRecords == newVoiceRecords &&
              state.baseAutobiography == existingAutobiography;
        }),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.completed &&
              state.generatedContent != null;
        }),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该处理全量替换更新',
      build: () {
        when(mockUseCases.incrementalUpdateAutobiography(
          newVoiceContent: anyNamed('newVoiceContent'),
          currentAutobiography: anyNamed('currentAutobiography'),
        )).thenAnswer(
          (_) async => Right(
            IncrementalUpdateResult(
              updatedChapter: Chapter(
                id: 'new',
                title: '完整内容',
                content: '全新的完整内容',
                order: 0,
                lastModifiedAt: DateTime(2024, 1, 2),
              ),
              updateType: UpdateType.fullReplacement,
              updateIndex: 0,
            ),
          ),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        IncrementalUpdateAutobiography(
          newVoiceRecords: newVoiceRecords,
          currentAutobiography: existingAutobiography,
        ),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.generating,
        ),
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.completed,
        ),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '新录音没有有效内容时应该返回错误',
      build: () => bloc,
      act: (bloc) => bloc.add(
        IncrementalUpdateAutobiography(
          newVoiceRecords: [
            VoiceRecord(
              id: '3',
              title: '空录音',
              timestamp: DateTime(2024, 1, 2),
              duration: 0,
            ),
          ],
          currentAutobiography: existingAutobiography,
        ),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.generating,
        ),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.error &&
              state.error == '新录音没有有效的转录内容';
        }),
      ],
    );
  });

  group('AiGenerationBloc - RegenerateCompleteAutobiography', () {
    final allVoiceRecords = [
      VoiceRecord(
        id: '1',
        title: '录音1',
        transcription: '内容1',
        timestamp: DateTime(2024, 1, 1),
        duration: 60,
      ),
      VoiceRecord(
        id: '2',
        title: '录音2',
        transcription: '内容2',
        timestamp: DateTime(2024, 1, 2),
        duration: 60,
      ),
    ];

    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该成功重新生成完整自传',
      build: () {
        // Mock 获取现有自传
        when(mockRepository.getAllAutobiographies()).thenAnswer(
          (_) async => Right([
            Autobiography(
              id: 'old-1',
              title: '旧自传',
              content: '旧内容',
              generatedAt: DateTime(2024, 1, 1),
              lastModifiedAt: DateTime(2024, 1, 1),
              wordCount: 10,
              voiceRecordIds: const [],
            ),
          ]),
        );

        // Mock 删除自传
        when(mockRepository.deleteAutobiographies(any))
            .thenAnswer((_) async => const Right(null));

        // Mock 生成新自传
        when(mockUseCases.generateCompleteAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        )).thenAnswer(
          (_) async => Right(
            AutobiographyGenerationResult(
              content: '新生成的内容',
              title: '全新的自传',
              summary: '全新的摘要',
              wordCount: 200,
              style: AutobiographyStyle.narrative,
            ),
          ),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        RegenerateCompleteAutobiography(
          allVoiceRecords: allVoiceRecords,
        ),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.generating,
        ),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.completed &&
              state.generatedContent == '新生成的内容' &&
              state.generatedTitle == '全新的自传';
        }),
      ],
      verify: (_) {
        verify(mockRepository.getAllAutobiographies()).called(1);
        verify(mockRepository.deleteAutobiographies(any)).called(1);
      },
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '正在生成时应该阻止重新生成',
      build: () => bloc,
      seed: () => const AiGenerationState(
        status: AiGenerationStatus.generating,
      ),
      act: (bloc) => bloc.add(
        RegenerateCompleteAutobiography(allVoiceRecords: allVoiceRecords),
      ),
      expect: () => [],
    );
  });

  group('AiGenerationBloc - OptimizeAutobiography', () {
    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该成功优化自传内容',
      build: () {
        when(mockUseCases.optimizeAutobiography(
          content: anyNamed('content'),
          optimizationType: anyNamed('optimizationType'),
        )).thenAnswer(
          (_) async => const Right('优化后的内容'),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        const OptimizeAutobiography(
          content: '原始内容',
          optimizationType: OptimizationType.clarity,
        ),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.optimizing,
        ),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.optimized &&
              state.generatedContent == '优化后的内容';
        }),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '优化失败时应该发出 error 状态',
      build: () {
        when(mockUseCases.optimizeAutobiography(
          content: anyNamed('content'),
          optimizationType: anyNamed('optimizationType'),
        )).thenAnswer(
          (_) async => Left(AiGenerationFailure.serviceUnavailable()),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        const OptimizeAutobiography(content: '原始内容'),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.status == AiGenerationStatus.optimizing,
        ),
        predicate<AiGenerationState>((state) {
          return state.status == AiGenerationStatus.error &&
              state.error != null;
        }),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '正在优化时应该忽略新的优化请求',
      build: () => bloc,
      seed: () => const AiGenerationState(
        status: AiGenerationStatus.optimizing,
      ),
      act: (bloc) => bloc.add(
        const OptimizeAutobiography(content: '内容'),
      ),
      expect: () => [],
    );
  });

  group('AiGenerationBloc - GenerateTitle', () {
    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该成功生成标题',
      build: () {
        when(mockUseCases.generateTitle(content: anyNamed('content')))
            .thenAnswer((_) async => const Right('生成的标题'));

        return bloc;
      },
      act: (bloc) => bloc.add(
        const GenerateTitle(content: '内容'),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.generatedTitle == '生成的标题',
        ),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '标题生成失败时应该静默处理',
      build: () {
        when(mockUseCases.generateTitle(content: anyNamed('content')))
            .thenAnswer(
          (_) async => Left(AiGenerationFailure.serviceUnavailable()),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        const GenerateTitle(content: '内容'),
      ),
      expect: () => [],
    );
  });

  group('AiGenerationBloc - GenerateSummary', () {
    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该成功生成摘要',
      build: () {
        when(mockUseCases.generateSummary(content: anyNamed('content')))
            .thenAnswer((_) async => const Right('生成的摘要'));

        return bloc;
      },
      act: (bloc) => bloc.add(
        const GenerateSummary(content: '内容'),
      ),
      expect: () => [
        predicate<AiGenerationState>(
          (state) => state.generatedSummary == '生成的摘要',
        ),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      '摘要生成失败时应该静默处理',
      build: () {
        when(mockUseCases.generateSummary(content: anyNamed('content')))
            .thenAnswer(
          (_) async => Left(AiGenerationFailure.serviceUnavailable()),
        );

        return bloc;
      },
      act: (bloc) => bloc.add(
        const GenerateSummary(content: '内容'),
      ),
      expect: () => [],
    );
  });

  group('AiGenerationBloc - ClearGenerationResult', () {
    blocTest<AiGenerationBloc, AiGenerationState>(
      '应该清除生成结果',
      build: () => bloc,
      seed: () => AiGenerationState(
        status: AiGenerationStatus.completed,
        generatedContent: '内容',
        generatedTitle: '标题',
        generationResult: AutobiographyGenerationResult(
          content: '内容',
          title: '标题',
          summary: '摘要',
          wordCount: 100,
          style: AutobiographyStyle.narrative,
        ),
      ),
      act: (bloc) => bloc.add(const ClearGenerationResult()),
      expect: () => [
        const AiGenerationState(),
      ],
    );
  });
}
