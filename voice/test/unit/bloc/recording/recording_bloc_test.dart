import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/usecases/recording_usecases.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_state.dart';

import 'recording_bloc_test.mocks.dart';

@GenerateMocks([RecordingUseCases])
void main() {
  late RecordingBloc bloc;
  late MockRecordingUseCases mockUseCases;

  setUp(() {
    mockUseCases = MockRecordingUseCases();
    bloc = RecordingBloc(mockUseCases);
  });

  tearDown(() {
    bloc.close();
  });

  group('RecordingBloc', () {
    const testFilePath = '/path/to/recording.wav';
    final testVoiceRecord = VoiceRecord(
      id: 'test-id',
      title: '测试录音',
      timestamp: DateTime.now(),
      audioFilePath: testFilePath,
      duration: 5000,
    );

    group('初始状态', () {
      test('应该返回idle状态', () {
        expect(bloc.state.status, RecordingStatus.idle);
        expect(bloc.state.duration, 0);
        expect(bloc.state.filePath, isNull);
      });
    });

    group('StartRecording', () {
      blocTest<RecordingBloc, RecordingState>(
        '成功开始录音应该发射processing然后recording状态',
        build: () {
          when(mockUseCases.startRecording())
              .thenAnswer((_) async => const Right(testFilePath));
          return bloc;
        },
        act: (bloc) => bloc.add(const StartRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.processing,
            errorMessage: null,
          ),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having((s) => s.duration, 'duration', 0)
              .having((s) => s.startTime, 'startTime', isNotNull),
        ],
        verify: (_) {
          verify(mockUseCases.startRecording()).called(1);
        },
      );

      blocTest<RecordingBloc, RecordingState>(
        '开始录音失败应该发射error状态',
        build: () {
          when(mockUseCases.startRecording()).thenAnswer(
            (_) async => Left(
              RecordingFailure.recordingFailed(),
            ),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const StartRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.processing,
            errorMessage: null,
          ),
          const RecordingState(
            status: RecordingStatus.error,
            errorMessage: '录音失败',
          ),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        '开始录音抛出异常应该发射error状态',
        build: () {
          when(mockUseCases.startRecording()).thenThrow(Exception('测试异常'));
          return bloc;
        },
        act: (bloc) => bloc.add(const StartRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.processing,
            errorMessage: null,
          ),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.error)
              .having(
                  (s) => s.errorMessage, 'errorMessage', contains('录音启动失败')),
        ],
      );
    });

    group('StopRecording', () {
      blocTest<RecordingBloc, RecordingState>(
        '成功停止录音应该发射processing然后completed状态',
        setUp: () {
          when(mockUseCases.stopRecording())
              .thenAnswer((_) async => Right(testVoiceRecord));
        },
        build: () => bloc,
        seed: () => RecordingState(
          status: RecordingStatus.recording,
          filePath: testFilePath,
          startTime: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const StopRecording()),
        expect: () => [
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.processing)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having((s) => s.startTime, 'startTime', isNotNull),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.completed)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having((s) => s.startTime, 'startTime', isNotNull)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
        verify: (_) {
          verify(mockUseCases.stopRecording()).called(1);
        },
      );

      blocTest<RecordingBloc, RecordingState>(
        '停止录音失败应该发射error状态',
        setUp: () {
          when(mockUseCases.stopRecording()).thenAnswer(
            (_) async => Left(
              RecordingFailure.audioFileNotFound(),
            ),
          );
        },
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          filePath: testFilePath,
        ),
        act: (bloc) => bloc.add(const StopRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.processing,
            filePath: testFilePath,
          ),
          const RecordingState(
            status: RecordingStatus.error,
            filePath: testFilePath,
            errorMessage: '音频文件未找到',
          ),
        ],
      );

      test('不能停止非录音状态', () {
        // idle状态不能停止
        const initialState = RecordingState(status: RecordingStatus.idle);

        expect(initialState.canStop, false);
      });

      blocTest<RecordingBloc, RecordingState>(
        '在idle状态停止录音不应该触发任何操作',
        build: () => bloc,
        seed: () => const RecordingState(status: RecordingStatus.idle),
        act: (bloc) => bloc.add(const StopRecording()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockUseCases.stopRecording());
        },
      );
    });

    group('PauseRecording', () {
      blocTest<RecordingBloc, RecordingState>(
        '成功暂停录音应该发射paused状态',
        setUp: () {
          when(mockUseCases.pauseRecording())
              .thenAnswer((_) async => const Right(null));
        },
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          filePath: testFilePath,
          duration: 2000, // 至少1秒才能暂停
        ),
        act: (bloc) => bloc.add(const PauseRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.paused,
            filePath: testFilePath,
            duration: 2000,
          ),
        ],
        verify: (_) {
          verify(mockUseCases.pauseRecording()).called(1);
        },
      );

      blocTest<RecordingBloc, RecordingState>(
        '暂停录音失败应该保持当前状态并设置错误信息',
        setUp: () {
          when(mockUseCases.pauseRecording()).thenAnswer(
            (_) async => Left(
              RecordingFailure.recordingFailed(),
            ),
          );
        },
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          duration: 2000,
        ),
        act: (bloc) => bloc.add(const PauseRecording()),
        wait: const Duration(milliseconds: 300),
        skip: 0,
        expect: () => [
          const RecordingState(
            status: RecordingStatus.recording,
            duration: 2000,
            errorMessage: '录音失败',
          ),
        ],
        verify: (_) {
          verify(mockUseCases.pauseRecording()).called(1);
        },
      );

      test('录音时长小于1秒不能暂停', () {
        const state = RecordingState(
          status: RecordingStatus.recording,
          duration: 999, // 小于1秒
        );

        expect(state.canPause, false);
      });

      blocTest<RecordingBloc, RecordingState>(
        '时长不足时暂停不应该触发操作',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          duration: 500,
        ),
        act: (bloc) => bloc.add(const PauseRecording()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockUseCases.pauseRecording());
        },
      );
    });

    group('ResumeRecording', () {
      blocTest<RecordingBloc, RecordingState>(
        '成功恢复录音应该发射recording状态',
        setUp: () {
          when(mockUseCases.resumeRecording())
              .thenAnswer((_) async => const Right(null));
        },
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.paused,
          filePath: testFilePath,
          duration: 5000,
        ),
        act: (bloc) => bloc.add(const ResumeRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.recording,
            filePath: testFilePath,
            duration: 5000,
          ),
        ],
        verify: (_) {
          verify(mockUseCases.resumeRecording()).called(1);
        },
      );

      blocTest<RecordingBloc, RecordingState>(
        '恢复录音失败应该保持paused状态并设置错误信息',
        setUp: () {
          when(mockUseCases.resumeRecording()).thenAnswer(
            (_) async => Left(
              RecordingFailure.recordingFailed(),
            ),
          );
        },
        build: () => bloc,
        seed: () => const RecordingState(status: RecordingStatus.paused),
        act: (bloc) => bloc.add(const ResumeRecording()),
        wait: const Duration(milliseconds: 300),
        skip: 0, // Catch all states
        expect: () => [
          const RecordingState(
            status: RecordingStatus.paused,
            errorMessage: '录音失败',
          ),
        ],
        verify: (_) {
          verify(mockUseCases.resumeRecording()).called(1);
        },
      );

      blocTest<RecordingBloc, RecordingState>(
        '在recording状态恢复不应该触发操作',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          filePath: testFilePath,
        ),
        act: (bloc) => bloc.add(const ResumeRecording()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockUseCases.resumeRecording());
        },
      );
    });

    group('CancelRecording', () {
      blocTest<RecordingBloc, RecordingState>(
        '成功取消录音应该重置为idle状态',
        setUp: () {
          when(mockUseCases.cancelRecording())
              .thenAnswer((_) async => const Right(null));
        },
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          filePath: testFilePath,
          duration: 3000,
        ),
        act: (bloc) => bloc.add(const CancelRecording()),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.idle,
            duration: 0,
            filePath: null,
            errorMessage: null,
            audioLevel: null,
            startTime: null,
          ),
        ],
        verify: (_) {
          verify(mockUseCases.cancelRecording()).called(1);
        },
      );

      blocTest<RecordingBloc, RecordingState>(
        '取消录音失败应该发射error状态',
        setUp: () {
          when(mockUseCases.cancelRecording()).thenThrow(
            Exception('取消失败'),
          );
        },
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          filePath: testFilePath,
        ),
        act: (bloc) => bloc.add(const CancelRecording()),
        expect: () => [
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.error)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having(
                  (s) => s.errorMessage, 'errorMessage', contains('录音取消失败')),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        '在idle状态取消不应该触发操作',
        build: () => bloc,
        seed: () => const RecordingState(status: RecordingStatus.idle),
        act: (bloc) => bloc.add(const CancelRecording()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockUseCases.cancelRecording());
        },
      );
    });

    group('UpdateRecordingDuration', () {
      blocTest<RecordingBloc, RecordingState>(
        '在recording状态应该更新时长',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          duration: 5000,
        ),
        act: (bloc) => bloc.add(const UpdateRecordingDuration(10000)),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.recording,
            duration: 10000,
          ),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        '在paused状态不应该更新时长',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.paused,
          duration: 5000,
        ),
        act: (bloc) => bloc.add(const UpdateRecordingDuration(10000)),
        expect: () => [],
      );

      blocTest<RecordingBloc, RecordingState>(
        '在idle状态不应该更新时长',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.idle,
          duration: 0,
        ),
        act: (bloc) => bloc.add(const UpdateRecordingDuration(5000)),
        expect: () => [],
      );
    });

    group('UpdateAudioLevel', () {
      blocTest<RecordingBloc, RecordingState>(
        '在recording状态应该更新音频电平',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.recording,
          audioLevel: 0.5,
        ),
        act: (bloc) => bloc.add(const UpdateAudioLevel(0.8)),
        expect: () => [
          const RecordingState(
            status: RecordingStatus.recording,
            audioLevel: 0.8,
          ),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        '在paused状态不应该更新音频电平',
        build: () => bloc,
        seed: () => const RecordingState(
          status: RecordingStatus.paused,
          audioLevel: 0.5,
        ),
        act: (bloc) => bloc.add(const UpdateAudioLevel(0.8)),
        expect: () => [],
      );

      blocTest<RecordingBloc, RecordingState>(
        '应该支持边界值0.0和1.0',
        build: () => bloc,
        seed: () => const RecordingState(status: RecordingStatus.recording),
        act: (bloc) async {
          bloc.add(const UpdateAudioLevel(0.0));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(const UpdateAudioLevel(1.0));
        },
        expect: () => [
          const RecordingState(status: RecordingStatus.recording, audioLevel: 0.0),
          const RecordingState(status: RecordingStatus.recording, audioLevel: 1.0),
        ],
      );
    });

    group('状态转换流程', () {
      blocTest<RecordingBloc, RecordingState>(
        '完整的录音流程: 开始 -> 暂停 -> 恢复 -> 停止',
        setUp: () {
          when(mockUseCases.startRecording())
              .thenAnswer((_) async => const Right(testFilePath));
          when(mockUseCases.pauseRecording())
              .thenAnswer((_) async => const Right(null));
          when(mockUseCases.resumeRecording())
              .thenAnswer((_) async => const Right(null));
          when(mockUseCases.stopRecording())
              .thenAnswer((_) async => Right(testVoiceRecord));
        },
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const StartRecording());
          await Future.delayed(const Duration(milliseconds: 50));

          // Must update duration to > 1000ms to allow pausing
          bloc.add(const UpdateRecordingDuration(2000));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const PauseRecording());
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const ResumeRecording());
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const StopRecording());
        },
        expect: () => [
          // Start
          const RecordingState(
              status: RecordingStatus.processing, errorMessage: null),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having((s) => s.duration, 'duration', 0)
              .having((s) => s.startTime, 'startTime', isNotNull),
          // Update Duration
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording)
              .having((s) => s.duration, 'duration', 2000),
          // Pause
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.paused)
              .having((s) => s.filePath, 'filePath', testFilePath),
          // Resume
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording)
              .having((s) => s.filePath, 'filePath', testFilePath),
          // Stop
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.processing)
              .having((s) => s.filePath, 'filePath', testFilePath),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.completed)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        '取消录音流程: 开始 -> 取消',
        setUp: () {
          when(mockUseCases.startRecording())
              .thenAnswer((_) async => const Right(testFilePath));
          when(mockUseCases.cancelRecording())
              .thenAnswer((_) async => const Right(null));
        },
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const StartRecording());
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const CancelRecording());
        },
        expect: () => [
          // Start
          const RecordingState(
              status: RecordingStatus.processing, errorMessage: null),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording)
              .having((s) => s.filePath, 'filePath', testFilePath)
              .having((s) => s.duration, 'duration', 0)
              .having((s) => s.startTime, 'startTime', isNotNull),
          // Cancel
          const RecordingState(
            status: RecordingStatus.idle,
            duration: 0,
            filePath: null,
            errorMessage: null,
            audioLevel: null,
            startTime: null,
          ),
        ],
      );
    });
  });
}
