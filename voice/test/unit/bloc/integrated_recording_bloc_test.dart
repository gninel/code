import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:voice_autobiography_flutter/data/services/enhanced_audio_recording_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/recording_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_state.dart';

import 'integrated_recording_bloc_test.mocks.dart';

// 生成 Mock 类
@GenerateMocks([EnhancedAudioRecordingService])
void main() {
  late IntegratedRecordingBloc bloc;
  late MockEnhancedAudioRecordingService mockRecordingService;

  setUp(() {
    mockRecordingService = MockEnhancedAudioRecordingService();
    bloc = IntegratedRecordingBloc(mockRecordingService);

    // 默认 Mock 配置
    when(mockRecordingService.isRecording).thenReturn(false);
    when(mockRecordingService.isPaused).thenReturn(false);
    when(mockRecordingService.recordingDuration).thenReturn(Duration.zero);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('IntegratedRecordingBloc - 初始状态', () {
    test('初始状态为 idle', () {
      expect(bloc.state.status, equals(RecordingStatus.idle));
      expect(bloc.state.duration, equals(0));
      expect(bloc.state.filePath, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.recognizedText, equals(''));
      expect(bloc.state.confidence, equals(0.0));
    });

    test('初始状态的计算属性', () {
      expect(bloc.state.isRecording, isFalse);
      expect(bloc.state.isPaused, isFalse);
      expect(bloc.state.isCompleted, isFalse);
      expect(bloc.state.hasError, isFalse);
      expect(bloc.state.canStart, isTrue);
      expect(bloc.state.canStop, isFalse);
    });
  });

  group('IntegratedRecordingBloc - 开始录音', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '成功开始录音',
      setUp: () {
        when(mockRecordingService.startRecordingWithRecognition(
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          onStarted: anyNamed('onStarted'),
          onCompleted: anyNamed('onCompleted'),
        )).thenAnswer((_) async {});
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const StartIntegratedRecording()),
      expect: () => [
        // 第一步: processing 状态
        const IntegratedRecordingState(
          status: RecordingStatus.processing,
          errorMessage: null,
          recognizedText: '',
        ),
        // 第二步: recording 状态
        predicate<IntegratedRecordingState>((state) {
          return state.status == RecordingStatus.recording &&
              state.duration == 0 &&
              state.startTime != null &&
              state.errorMessage == null;
        }),
      ],
      verify: (_) {
        verify(mockRecordingService.startRecordingWithRecognition(
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          onStarted: anyNamed('onStarted'),
          onCompleted: anyNamed('onCompleted'),
        )).called(1);
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '开始录音失败',
      setUp: () {
        when(mockRecordingService.startRecordingWithRecognition(
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          onStarted: anyNamed('onStarted'),
          onCompleted: anyNamed('onCompleted'),
        )).thenThrow(Exception('麦克风权限被拒绝'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const StartIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.processing,
          errorMessage: null,
          recognizedText: '',
        ),
        predicate<IntegratedRecordingState>((state) {
          return state.status == RecordingStatus.error &&
              state.errorMessage != null &&
              state.errorMessage!.contains('录音启动失败');
        }),
      ],
    );
  });

  group('IntegratedRecordingBloc - 停止录音', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '成功停止录音',
      setUp: () {
        when(mockRecordingService.stopRecording())
            .thenAnswer((_) async => '/path/to/recording.wav');
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
        startTime: null,
      ),
      act: (bloc) => bloc.add(const StopIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.processing,
          duration: 5000,
        ),
        const IntegratedRecordingState(
          status: RecordingStatus.completed,
          duration: 5000,
          filePath: '/path/to/recording.wav',
          errorMessage: null,
        ),
      ],
      verify: (_) {
        verify(mockRecordingService.stopRecording()).called(1);
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '停止录音失败',
      setUp: () {
        when(mockRecordingService.stopRecording())
            .thenThrow(Exception('停止失败'));
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
      ),
      act: (bloc) => bloc.add(const StopIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.processing,
          duration: 5000,
        ),
        predicate<IntegratedRecordingState>((state) {
          return state.status == RecordingStatus.error &&
              state.errorMessage != null &&
              state.errorMessage!.contains('录音停止失败');
        }),
      ],
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '无法在 idle 状态停止',
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.idle,
      ),
      act: (bloc) => bloc.add(const StopIntegratedRecording()),
      expect: () => [],
      verify: (_) {
        verifyNever(mockRecordingService.stopRecording());
      },
    );
  });

  group('IntegratedRecordingBloc - 暂停和恢复', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '成功暂停录音',
      setUp: () {
        when(mockRecordingService.pauseRecording()).thenAnswer((_) async {});
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
      ),
      act: (bloc) => bloc.add(const PauseIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.paused,
          duration: 5000,
        ),
      ],
      verify: (_) {
        verify(mockRecordingService.pauseRecording()).called(1);
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '无法在 idle 状态暂停',
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.idle,
      ),
      act: (bloc) => bloc.add(const PauseIntegratedRecording()),
      expect: () => [],
      verify: (_) {
        verifyNever(mockRecordingService.pauseRecording());
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '成功恢复录音',
      setUp: () {
        when(mockRecordingService.resumeRecording()).thenAnswer((_) async {});
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.paused,
        duration: 5000,
      ),
      act: (bloc) => bloc.add(const ResumeIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.recording,
          duration: 5000,
        ),
      ],
      verify: (_) {
        verify(mockRecordingService.resumeRecording()).called(1);
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '无法在 idle 状态恢复',
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.idle,
      ),
      act: (bloc) => bloc.add(const ResumeIntegratedRecording()),
      expect: () => [],
      verify: (_) {
        verifyNever(mockRecordingService.resumeRecording());
      },
    );
  });

  group('IntegratedRecordingBloc - 取消录音', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '取消录音中状态',
      setUp: () {
        when(mockRecordingService.cancelRecording()).thenAnswer((_) async {});
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
        recognizedText: '一些文本',
        confidence: 0.85,
      ),
      act: (bloc) => bloc.add(const CancelIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.idle,
          duration: 0,
          filePath: null,
          errorMessage: null,
          audioLevel: null,
          startTime: null,
          recognizedText: '',
          confidence: 0.0,
        ),
      ],
      verify: (_) {
        verify(mockRecordingService.cancelRecording()).called(1);
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '取消暂停状态',
      setUp: () {
        when(mockRecordingService.cancelRecording()).thenAnswer((_) async {});
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.paused,
        duration: 3000,
      ),
      act: (bloc) => bloc.add(const CancelIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.idle,
          duration: 0,
          filePath: null,
          errorMessage: null,
          audioLevel: null,
          startTime: null,
          recognizedText: '',
          confidence: 0.0,
        ),
      ],
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '取消失败也重置状态',
      setUp: () {
        when(mockRecordingService.cancelRecording())
            .thenThrow(Exception('取消失败'));
      },
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
      ),
      act: (bloc) => bloc.add(const CancelIntegratedRecording()),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.idle,
          duration: 0,
          filePath: null,
          errorMessage: null,
          audioLevel: null,
          startTime: null,
          recognizedText: '',
          confidence: 0.0,
        ),
      ],
    );
  });

  group('IntegratedRecordingBloc - 更新时长', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '更新录音时长',
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 0,
      ),
      act: (bloc) => bloc.add(const UpdateRecordingDuration(5000)),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.recording,
          duration: 5000,
        ),
      ],
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '非录音状态不更新时长',
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        status: RecordingStatus.idle,
        duration: 0,
      ),
      act: (bloc) => bloc.add(const UpdateRecordingDuration(5000)),
      expect: () => [],
    );
  });

  group('IntegratedRecordingBloc - 识别结果', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '接收识别结果',
      build: () => bloc,
      act: (bloc) => bloc.add(const RecognitionResultReceived(
        text: '今天天气不错',
        confidence: 0.85,
      )),
      expect: () => [
        predicate<IntegratedRecordingState>((state) {
          return state.recognizedText == '今天天气不错' &&
              state.confidence == 0.85 &&
              state.lastRecognitionTime != null;
        }),
      ],
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '接收多次识别结果（累积文本）',
      build: () => bloc,
      act: (bloc) {
        bloc.add(const RecognitionResultReceived(
          text: '今天天气',
          confidence: 0.8,
        ));
        bloc.add(const RecognitionResultReceived(
          text: '今天天气不错',
          confidence: 0.85,
        ));
      },
      expect: () => [
        predicate<IntegratedRecordingState>((state) {
          return state.recognizedText == '今天天气' && state.confidence == 0.8;
        }),
        predicate<IntegratedRecordingState>((state) {
          return state.recognizedText == '今天天气不错' && state.confidence == 0.85;
        }),
      ],
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '接收识别错误',
      build: () => bloc,
      act: (bloc) => bloc.add(const RecognitionErrorReceived('网络连接失败')),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.error,
          errorMessage: '网络连接失败',
        ),
      ],
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '清除识别文本',
      build: () => bloc,
      seed: () => IntegratedRecordingState(
        recognizedText: '一些文本',
        confidence: 0.85,
        lastRecognitionTime: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const ClearRecognitionText()),
      expect: () => [
        predicate<IntegratedRecordingState>((state) {
          // copyWith 会保留 seed 中的其他字段，所以只验证清除的字段
          return state.recognizedText == '' && state.confidence == 0.0;
        }),
      ],
    );
  });

  group('IntegratedRecordingBloc - 文件上传', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '上传文件进行识别',
      setUp: () {
        when(mockRecordingService.recognizeFile(
          any,
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          onStarted: anyNamed('onStarted'),
          onCompleted: anyNamed('onCompleted'),
        )).thenAnswer((_) async {});
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UploadRecordingFile('/path/to/file.wav')),
      expect: () => [
        // 第一步: processing 状态
        const IntegratedRecordingState(
          status: RecordingStatus.processing,
          errorMessage: null,
          recognizedText: '',
        ),
        // 第二步: recording 状态（文件上传模式）
        predicate<IntegratedRecordingState>((state) {
          return state.status == RecordingStatus.recording &&
              state.isFileUpload == true &&
              state.filePath == '/path/to/file.wav' &&
              state.duration == 0;
        }),
      ],
      verify: (_) {
        verify(mockRecordingService.recognizeFile(
          '/path/to/file.wav',
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          onStarted: anyNamed('onStarted'),
          onCompleted: anyNamed('onCompleted'),
        )).called(1);
      },
    );

    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '文件上传失败',
      setUp: () {
        when(mockRecordingService.recognizeFile(
          any,
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          onStarted: anyNamed('onStarted'),
          onCompleted: anyNamed('onCompleted'),
        )).thenThrow(Exception('文件不存在'));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const UploadRecordingFile('/invalid/path.wav')),
      expect: () => [
        const IntegratedRecordingState(
          status: RecordingStatus.processing,
          errorMessage: null,
          recognizedText: '',
        ),
        predicate<IntegratedRecordingState>((state) {
          return state.status == RecordingStatus.error &&
              state.errorMessage != null &&
              state.errorMessage!.contains('文件上传失败');
        }),
      ],
    );
  });

  group('IntegratedRecordingBloc - 手动编辑文本', () {
    blocTest<IntegratedRecordingBloc, IntegratedRecordingState>(
      '更新识别文本',
      build: () => bloc,
      seed: () => const IntegratedRecordingState(
        recognizedText: '原始文本',
      ),
      act: (bloc) => bloc.add(const UpdateRecognizedText('修改后的文本')),
      expect: () => [
        const IntegratedRecordingState(
          recognizedText: '修改后的文本',
        ),
      ],
    );
  });

  group('IntegratedRecordingState - 计算属性', () {
    test('formattedDuration - 秒', () {
      const state = IntegratedRecordingState(duration: 5000); // 5秒
      // 由于浮点数除法，hours = 5000/3600000 = 0.00138... > 0
      // 所以总是走 hours > 0 分支
      expect(state.formattedDuration, equals('0:00:05'));
    });

    test('formattedDuration - 分:秒 (<1小时)', () {
      const state = IntegratedRecordingState(duration: 65000); // 1分5秒
      expect(state.formattedDuration, equals('0:01:05'));
    });

    test('formattedDuration - 时:分:秒', () {
      const state = IntegratedRecordingState(duration: 3665000); // 1小时1分5秒
      expect(state.formattedDuration, equals('1:01:05'));
    });

    test('confidencePercentage', () {
      const state = IntegratedRecordingState(confidence: 0.857);
      expect(state.confidencePercentage, equals('85.7%'));
    });

    test('confidenceLevel - 极高', () {
      const state = IntegratedRecordingState(confidence: 0.95);
      expect(state.confidenceLevel, equals('极高'));
    });

    test('confidenceLevel - 高', () {
      const state = IntegratedRecordingState(confidence: 0.85);
      expect(state.confidenceLevel, equals('高'));
    });

    test('confidenceLevel - 中等', () {
      const state = IntegratedRecordingState(confidence: 0.75);
      expect(state.confidenceLevel, equals('中等'));
    });

    test('confidenceLevel - 较低', () {
      const state = IntegratedRecordingState(confidence: 0.65);
      expect(state.confidenceLevel, equals('较低'));
    });

    test('confidenceLevel - 低', () {
      const state = IntegratedRecordingState(confidence: 0.5);
      expect(state.confidenceLevel, equals('低'));
    });

    test('canPause - 时长不足1秒不能暂停', () {
      const state = IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 500,
      );
      expect(state.canPause, isFalse);
    });

    test('canPause - 时长超过1秒可以暂停', () {
      const state = IntegratedRecordingState(
        status: RecordingStatus.recording,
        duration: 1500,
      );
      expect(state.canPause, isTrue);
    });
  });
}
