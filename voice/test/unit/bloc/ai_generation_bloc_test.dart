// AiGenerationBloc 测试
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
import 'package:voice_autobiography_flutter/data/services/ai_generation_persistence_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

import 'ai_generation_bloc_test.mocks.dart';

@GenerateMocks([
  AiGenerationUseCases,
  AutobiographyRepository,
  BackgroundAiService,
  AiGenerationPersistenceService
])
void main() {
  late AiGenerationBloc bloc;
  late MockAiGenerationUseCases mockUseCases;
  late MockAutobiographyRepository mockRepository;
  late MockBackgroundAiService mockBackgroundService;
  late MockAiGenerationPersistenceService mockPersistenceService;

  setUp(() {
    mockUseCases = MockAiGenerationUseCases();
    mockRepository = MockAutobiographyRepository();
    mockBackgroundService = MockBackgroundAiService();
    mockPersistenceService = MockAiGenerationPersistenceService();

    // Default behavior for persistence service
    when(mockPersistenceService.getUnfinishedTaskInfo()).thenReturn(null);
    // Suppress background service calls
    when(mockBackgroundService.startBackgroundTask(
            taskDescription: anyNamed('taskDescription')))
        .thenAnswer((_) async => true);
    when(mockBackgroundService.stopBackgroundTask()).thenAnswer((_) async {});
    when(mockPersistenceService.saveGenerationState(
      generationType: anyNamed('generationType'),
      voiceRecordIds: anyNamed('voiceRecordIds'),
      currentAutobiographyId: anyNamed('currentAutobiographyId'),
      status: anyNamed('status'),
    )).thenAnswer((_) async {});
    when(mockPersistenceService.clearGenerationState())
        .thenAnswer((_) async {});
    when(mockPersistenceService.updateGenerationProgress(
      generatedContent: anyNamed('generatedContent'),
      generatedTitle: anyNamed('generatedTitle'),
      generatedSummary: anyNamed('generatedSummary'),
      status: anyNamed('status'),
    )).thenAnswer((_) async {});
    when(mockPersistenceService.isTaskTimeout()).thenReturn(false);

    bloc = AiGenerationBloc(
      mockUseCases,
      mockRepository,
      mockBackgroundService,
      mockPersistenceService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AiGenerationBloc', () {
    test('初始状态应该为 idle', () {
      expect(bloc.state.status, AiGenerationStatus.idle);
    });

    final tVoiceRecords = [
      VoiceRecord(id: '1', title: 'Test', timestamp: DateTime.now())
    ];
    const tContent = 'Generated Content';

    blocTest<AiGenerationBloc, AiGenerationState>(
      'GenerateAutobiography: 应该发出 generating 和 completed 状态',
      build: () {
        when(mockUseCases.generateAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        )).thenAnswer((_) async => const Right(tContent));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(GenerateAutobiography(voiceRecords: tVoiceRecords)),
      expect: () => [
        const AiGenerationState(status: AiGenerationStatus.generating),
        const AiGenerationState(
          status: AiGenerationStatus.completed,
          generatedContent: tContent,
        ),
      ],
    );

    blocTest<AiGenerationBloc, AiGenerationState>(
      'GenerateAutobiography: 失败时应该发出 error 状态',
      build: () {
        when(mockUseCases.generateAutobiography(
          voiceRecords: anyNamed('voiceRecords'),
          style: anyNamed('style'),
          wordCount: anyNamed('wordCount'),
        )).thenAnswer((_) async => Left(
            AiGenerationFailure.contentGenerationFailed(message: 'Error')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(GenerateAutobiography(voiceRecords: tVoiceRecords)),
      expect: () => [
        const AiGenerationState(status: AiGenerationStatus.generating),
        const AiGenerationState(
          status: AiGenerationStatus.error,
          error: 'Error',
        ),
      ],
    );

    group('State Restoration', () {
      blocTest<AiGenerationBloc, AiGenerationState>(
        'CheckRestorableState: 应该恢复 completed 状态',
        build: () {
          when(mockPersistenceService.getUnfinishedTaskInfo()).thenReturn({
            'status': 'completed',
            'generatedContent': 'Restored Content',
            'generatedTitle': 'Restored Title',
            'generatedSummary': 'Restored Summary',
            'style': 'narrative',
          });
          return bloc;
        },
        act: (bloc) => bloc.add(const CheckRestorableState()),
        expect: () => [
          isA<AiGenerationState>()
              .having((s) => s.status, 'status', AiGenerationStatus.completed)
              .having((s) => s.generatedContent, 'content', 'Restored Content')
              .having((s) => s.generatedTitle, 'title', 'Restored Title'),
        ],
      );

      blocTest<AiGenerationBloc, AiGenerationState>(
          'CheckRestorableState: 如果是 generating 但未超时，应显示错误（中断）',
          build: () {
            when(mockPersistenceService.getUnfinishedTaskInfo()).thenReturn({
              'status': 'generating',
              'startTime': DateTime.now().millisecondsSinceEpoch,
            });
            when(mockPersistenceService.isTaskTimeout()).thenReturn(false);
            return bloc;
          },
          act: (bloc) => bloc.add(const CheckRestorableState()),
          expect: () => [
                isA<AiGenerationState>()
                    .having((s) => s.status, 'status', AiGenerationStatus.error)
                    .having((s) => s.error, 'error', contains('意外中断')),
              ],
          verify: (_) {
            verify(mockPersistenceService.clearGenerationState()).called(1);
          });
    });
  });
}
