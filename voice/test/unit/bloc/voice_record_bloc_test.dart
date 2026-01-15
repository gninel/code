// VoiceRecordBloc 测试
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_state.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart';
import 'package:voice_autobiography_flutter/data/services/auto_tagger_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

import 'voice_record_bloc_test.mocks.dart';

@GenerateMocks([
  VoiceRecordRepository,
  RecordingUseCases,
  AutoTaggerService,
])
void main() {
  late VoiceRecordBloc bloc;
  late MockVoiceRecordRepository mockRepository;
  late MockRecordingUseCases mockRecordingUseCases;
  late MockAutoTaggerService mockAutoTaggerService;

  setUp(() {
    mockRepository = MockVoiceRecordRepository();
    mockRecordingUseCases = MockRecordingUseCases();
    mockAutoTaggerService = MockAutoTaggerService();

    bloc = VoiceRecordBloc(
      mockRepository,
      mockRecordingUseCases,
      mockAutoTaggerService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('VoiceRecordBloc', () {
    test('初始状态应该正确', () {
      expect(bloc.state.records, isEmpty);
      expect(bloc.state.isLoading, false);
    });

    final tRecord = VoiceRecord(
      id: '1',
      title: 'Test',
      timestamp: DateTime.now(),
      transcription: 'Content',
    );
    final tRecords = [tRecord];

    blocTest<VoiceRecordBloc, VoiceRecordState>(
      'LoadVoiceRecords: 成功时应该更新 records',
      build: () {
        when(mockRepository.getAllVoiceRecords())
            .thenAnswer((_) async => Right(tRecords));
        // Auto tagging might be triggered, stub it or ignore
        // when(mockAutoTaggerService.autoTagRecords(any)).thenAnswer((_) async => {});
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadVoiceRecords()),
      expect: () => [
        const VoiceRecordState(isLoading: true),
        isA<VoiceRecordState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.records, 'records', tRecords)
            .having((s) => s.filteredRecords, 'filteredRecords', tRecords),
      ],
    );

    blocTest<VoiceRecordBloc, VoiceRecordState>(
      'LoadVoiceRecords: 失败时应该更新 error',
      build: () {
        when(mockRepository.getAllVoiceRecords())
            .thenAnswer((_) async => Left(DatabaseFailure.queryFailed()));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadVoiceRecords()),
      expect: () => [
        const VoiceRecordState(isLoading: true),
        isA<VoiceRecordState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', isNotEmpty),
      ],
    );

    blocTest<VoiceRecordBloc, VoiceRecordState>(
      'AddVoiceRecord: 成功时应该重新加载记录',
      build: () {
        when(mockRepository.insertVoiceRecord(any))
            .thenAnswer((_) async => const Right(null));
        when(mockRepository.getAllVoiceRecords())
            .thenAnswer((_) async => Right(tRecords));
        return bloc;
      },
      act: (bloc) => bloc.add(AddVoiceRecord(tRecord)),
      expect: () => [
        const VoiceRecordState(isLoading: true),
        isA<VoiceRecordState>().having((s) => s.records, 'records', tRecords),
      ],
    );
  });
}
