import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:voice_autobiography_flutter/domain/entities/recording_state.dart';
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_bloc.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

import 'recording_bloc_test.mocks.dart';

@GenerateMocks([RecordingUseCases])
void main() {
  group('RecordingBloc', () {
    late RecordingBloc recordingBloc;
    late MockRecordingUseCases mockRecordingUseCases;

    setUp(() {
      mockRecordingUseCases = MockRecordingUseCases();
      recordingBloc = RecordingBloc(mockRecordingUseCases);
    });

    tearDown(() {
      recordingBloc.close();
    });

    test('初始状态应该是 idle', () {
      expect(recordingBloc.state.status, RecordingStatus.idle);
      expect(recordingBloc.state.duration, 0);
      expect(recordingBloc.state.filePath, null);
    });

    blocTest<RecordingBloc, RecordingState>(
      '开始录音成功',
      setUp: () {
        when(mockRecordingUseCases.startRecording())
            .thenAnswer((_) async => Right('test_path.mp3'));
      },
      build: () => recordingBloc,
      act: (bloc) => bloc.add(const StartRecording()),
      expect: () => [
        const RecordingState(status: RecordingStatus.processing),
        RecordingState(
          status: RecordingStatus.recording,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
      ],
      verify: (bloc) {
        verify(mockRecordingUseCases.startRecording()).called(1);
      },
    );

    blocTest<RecordingBloc, RecordingState>(
      '开始录音失败',
      setUp: () {
        when(mockRecordingUseCases.startRecording())
            .thenAnswer((_) async => Left(const RecordingFailure.recordingFailed()));
      },
      build: () => recordingBloc,
      act: (bloc) => bloc.add(const StartRecording()),
      expect: () => [
        const RecordingState(status: RecordingStatus.processing),
        const RecordingState(
          status: RecordingStatus.error,
          errorMessage: '录音失败',
        ),
      ],
      verify: (bloc) {
        verify(mockRecordingUseCases.startRecording()).called(1);
      },
    );

    blocTest<RecordingBloc, RecordingState>(
      '停止录音成功',
      setUp: () {
        when(mockRecordingUseCases.stopRecording())
            .thenAnswer((_) async => Right(null));
      },
      build: () {
        when(mockRecordingUseCases.startRecording())
            .thenAnswer((_) async => Right('test_path.mp3'));
        return recordingBloc;
      },
      act: (bloc) async {
        bloc.add(const StartRecording());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const StopRecording());
      },
      expect: () => [
        const RecordingState(status: RecordingStatus.processing),
        RecordingState(
          status: RecordingStatus.recording,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
        RecordingState(
          status: RecordingStatus.recording,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
        RecordingState(
          status: RecordingStatus.processing,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
        RecordingState(
          status: RecordingStatus.completed,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
      ],
    );

    blocTest<RecordingBloc, RecordingState>(
      '更新录音时长',
      build: () => recordingBloc,
      act: (bloc) {
        bloc.add(const UpdateRecordingDuration(5000));
      },
      expect: () => [
        const RecordingState(duration: 5000),
      ],
    );

    blocTest<RecordingBloc, RecordingState>(
      '更新音频电平',
      build: () => recordingBloc,
      act: (bloc) {
        bloc.add(const UpdateAudioLevel(0.8));
      },
      expect: () => [
        const RecordingState(audioLevel: 0.8),
      ],
    );

    blocTest<RecordingBloc, RecordingState>(
      '取消录音',
      setUp: () {
        when(mockRecordingUseCases.cancelRecording())
            .thenAnswer((_) async {});
        when(mockRecordingUseCases.startRecording())
            .thenAnswer((_) async => Right('test_path.mp3'));
      },
      build: () => recordingBloc,
      act: (bloc) async {
        bloc.add(const StartRecording());
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const CancelRecording());
      },
      expect: () => [
        const RecordingState(status: RecordingStatus.processing),
        RecordingState(
          status: RecordingStatus.recording,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
        RecordingState(
          status: RecordingStatus.recording,
          filePath: 'test_path.mp3',
          startTime: anyNamed('startTime'),
        ),
        const RecordingState(),
      ],
      verify: (bloc) {
        verify(mockRecordingUseCases.cancelRecording()).called(1);
      },
    );
  });
}