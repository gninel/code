import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_state.dart'
    as ai_state;
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_state.dart';

import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart';
import 'package:voice_autobiography_flutter/data/services/background_ai_service.dart';
import 'package:voice_autobiography_flutter/data/services/ai_generation_persistence_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart';

import 'main_flow_test.mocks.dart';

@GenerateMocks([
  AiGenerationUseCases,
  AutobiographyRepository,
  BackgroundAiService,
  AiGenerationPersistenceService,
  VoiceRecordRepository,
  RecordingUseCases,
])
void main() {
  group('Main Integration Flow', () {
    late AiGenerationBloc aiBloc;
    late AutobiographyBloc autoBloc;
    late MockAiGenerationUseCases mockAiUseCases;
    late MockAutobiographyRepository mockAutoRepo;
    late MockBackgroundAiService mockBgService;
    late MockAiGenerationPersistenceService mockPersistence;
    late MockVoiceRecordRepository mockVoiceRepo;
    late MockRecordingUseCases mockRecordingUseCases;

    setUp(() {
      mockAiUseCases = MockAiGenerationUseCases();
      mockAutoRepo = MockAutobiographyRepository();
      mockBgService = MockBackgroundAiService();
      mockPersistence = MockAiGenerationPersistenceService();
      mockVoiceRepo = MockVoiceRecordRepository();
      mockRecordingUseCases = MockRecordingUseCases();

      // Default Setup
      when(mockBgService.startBackgroundTask(
              taskDescription: anyNamed('taskDescription')))
          .thenAnswer((_) async => true);
      when(mockBgService.stopBackgroundTask()).thenAnswer((_) async {});
      when(mockPersistence.saveGenerationState(
              generationType: anyNamed('generationType'),
              voiceRecordIds: anyNamed('voiceRecordIds'),
              status: anyNamed('status'),
              currentAutobiographyId: anyNamed('currentAutobiographyId')))
          .thenAnswer((_) async {});
      when(mockPersistence.clearGenerationState()).thenAnswer((_) async {});
      when(mockPersistence.updateGenerationProgress(
              generatedContent: anyNamed('generatedContent'),
              generatedTitle: anyNamed('generatedTitle'),
              generatedSummary: anyNamed('generatedSummary'),
              status: anyNamed('status')))
          .thenAnswer((_) async {});
      // Default: No restorable state
      when(mockPersistence.getUnfinishedTaskInfo()).thenReturn(null);

      // Auto Bloc Setup
      when(mockAutoRepo.getAllAutobiographies())
          .thenAnswer((_) async => const Right([]));

      aiBloc = AiGenerationBloc(
        mockAiUseCases,
        mockAutoRepo,
        mockBgService,
        mockPersistence,
      );

      autoBloc =
          AutobiographyBloc(mockAutoRepo, mockVoiceRepo, mockRecordingUseCases);
    });

    tearDown(() {
      aiBloc.close();
      autoBloc.close();
    });

    test('Flow 1: Full Generation -> User Save -> List Update', () async {
      // 1. Arrange Data
      final records = [
        VoiceRecord(id: 'r1', title: 'Rec 1', timestamp: DateTime.now())
      ];
      const generatedContent = 'Generated Autobiography Content';

      // 2. Act - Trigger Generation
      when(mockAiUseCases.generateCompleteAutobiography(
              voiceRecords: anyNamed('voiceRecords'),
              style: anyNamed('style'),
              wordCount: anyNamed('wordCount')))
          .thenAnswer((_) async => Right(AutobiographyGenerationResult(
              content: generatedContent,
              title: 'Title',
              summary: 'Summary',
              wordCount: 100,
              style: AutobiographyStyle.narrative)));

      aiBloc.add(GenerateCompleteAutobiography(voiceRecords: records));

      // 3. Verify Generating State
      await expectLater(
        aiBloc.stream,
        emitsInOrder([
          isA<ai_state.AiGenerationState>().having((p0) => p0.status, 'status',
              ai_state.AiGenerationStatus.generating),
          isA<ai_state.AiGenerationState>().having((p0) => p0.status, 'status',
              ai_state.AiGenerationStatus.completed),
        ]),
      );

      // Verify Persistence calls
      verify(mockBgService.startBackgroundTask(
              taskDescription: anyNamed('taskDescription')))
          .called(1);
      verify(mockPersistence.saveGenerationState(
              generationType: 'complete',
              voiceRecordIds: ['r1'],
              status: 'generating'))
          .called(1);
      verify(mockPersistence.updateGenerationProgress(
              generatedContent: generatedContent,
              generatedTitle: 'Title',
              generatedSummary: 'Summary',
              status: 'completed'))
          .called(1);

      // 4. Act - User Saves (Simulated by verifying Repo call and updating AutoBloc)
      // When user clicks save, the UI constructs an Autobiography object and adds AddAutobiography event to Bloc (or calls Repo direct then refresh).
      // Checking AutobiographyBloc logic, it has AddAutobiography event which calls repository.insertAutobiography.

      final newAutobiography = Autobiography(
          id: 'new_id',
          title: 'Title',
          content: generatedContent,
          generatedAt: DateTime.now(),
          lastModifiedAt: DateTime.now());

      when(mockAutoRepo.insertAutobiography(any)).thenAnswer((_) async =>
          const Right(
              null)); // insert assumes void/success return usually check Repo definition
      when(mockAutoRepo.getAllAutobiographies())
          .thenAnswer((_) async => Right([newAutobiography]));

      autoBloc.add(AddAutobiography(newAutobiography));

      await expectLater(
          autoBloc.stream,
          emitsInOrder([
            isA<AutobiographyState>()
                .having((s) => s.isLoading, 'loading', true), // add -> loading
            isA<AutobiographyState>()
                .having((s) => s.autobiographies.length, 'length', 1),
          ]));

      expect(autoBloc.state.autobiographies.first.content,
          equals(generatedContent));
    });

    test('Flow 2: App Restart with Persisted State (Restoration)', () async {
      // 1. Simulate finding persisted unfinished task
      when(mockPersistence.getUnfinishedTaskInfo()).thenReturn({
        'status': 'completed',
        'generatedContent': 'Restored Content',
        'generatedTitle': 'Restored Title',
        'generatedSummary': 'Summary',
        'style': 'narrative'
      });

      // 2. Create NEW Bloc instance (simulating app restart)
      await aiBloc.close(); // Close the setup one

      // Re-mock for the new instance
      when(mockPersistence.getUnfinishedTaskInfo()).thenReturn({
        'status': 'completed',
        'generatedContent': 'Restored Content',
        'generatedTitle': 'Restored Title',
        'generatedSummary': 'Summary',
        'style': 'narrative'
      });

      final newAiBloc = AiGenerationBloc(
        mockAiUseCases,
        mockAutoRepo,
        mockBgService,
        mockPersistence,
      );
      newAiBloc.add(const CheckRestorableState());

      // 3. Verify it restores state immediately
      await expectLater(
          newAiBloc.stream,
          emits(isA<ai_state.AiGenerationState>()
              .having((s) => s.status, 'status',
                  ai_state.AiGenerationStatus.completed)
              .having(
                  (s) => s.generatedContent, 'content', 'Restored Content')));

      newAiBloc.close();
    });
  });
}
