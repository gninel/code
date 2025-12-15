import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/recording_state.dart';
import '../../../data/services/enhanced_audio_recording_service.dart';

import 'integrated_recording_event.dart';
import 'integrated_recording_state.dart';

@injectable
class IntegratedRecordingBloc extends Bloc<IntegratedRecordingEvent, IntegratedRecordingState> {
  final EnhancedAudioRecordingService _recordingService;

  IntegratedRecordingBloc(this._recordingService) : super(const IntegratedRecordingState()) {
    on<StartIntegratedRecording>(_onStartIntegratedRecording);
    on<StopIntegratedRecording>(_onStopIntegratedRecording);
    on<PauseIntegratedRecording>(_onPauseIntegratedRecording);
    on<ResumeIntegratedRecording>(_onResumeIntegratedRecording);
    on<CancelIntegratedRecording>(_onCancelIntegratedRecording);
    on<UpdateRecordingDuration>(_onUpdateRecordingDuration);
    on<RecognitionResultReceived>(_onRecognitionResultReceived);
    on<RecognitionErrorReceived>(_onRecognitionErrorReceived);
    on<ClearRecognitionText>(_onClearRecognitionText);
    on<UploadRecordingFile>(_onUploadRecordingFile);
    on<UpdateRecognizedText>(_onUpdateRecognizedText);
  }

  Future<void> _onUpdateRecognizedText(
    UpdateRecognizedText event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    emit(state.copyWith(
      recognizedText: event.text,
    ));
  }

  Future<void> _onUploadRecordingFile(
    UploadRecordingFile event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    print('Bloc: Received UploadRecordingFile for ${event.filePath}');
    try {
      emit(state.copyWith(
        status: RecordingStatus.processing,
        errorMessage: null,
        recognizedText: '',
      ));

      _recordingService.recognizeFile(
        event.filePath,
        onResult: (text, confidence) {
          print('Bloc: Received result: $text');
          add(RecognitionResultReceived(text: text, confidence: confidence));
        },
        onError: (error) {
          print('Bloc: Received error: $error');
          add(RecognitionErrorReceived(error));
        },
        onStarted: () {
          print('Bloc: Recognition started');
        },
        onCompleted: () {
          print('Bloc: Recognition completed');
          add(const StopIntegratedRecording());
        },
      );
      
      emit(state.copyWith(
        status: RecordingStatus.recording,
        duration: 0,
        startTime: DateTime.now(),
        errorMessage: null,
        isFileUpload: true, // 标记为文件上传模式
        filePath: event.filePath, // 设置文件路径
      ));

    } catch (e) {
      print('Bloc: Error in handler: $e');
      emit(state.copyWith(
        status: RecordingStatus.error,
        errorMessage: '文件上传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStartIntegratedRecording(
    StartIntegratedRecording event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: RecordingStatus.processing,
        errorMessage: null,
        recognizedText: '',
      ));

      await _recordingService.startRecordingWithRecognition(
        onResult: (text, confidence) {
          add(RecognitionResultReceived(text: text, confidence: confidence));
        },
        onError: (error) {
          add(RecognitionErrorReceived(error));
        },
        onStarted: () {
          // 录音和识别开始
        },
        onCompleted: () {
          // 识别完成
        },
      );

      emit(state.copyWith(
        status: RecordingStatus.recording,
        duration: 0,
        startTime: DateTime.now(),
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RecordingStatus.error,
        errorMessage: '录音启动失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopIntegratedRecording(
    StopIntegratedRecording event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    if (!state.canStop) return;

    try {
      emit(state.copyWith(
        status: RecordingStatus.processing,
      ));

      final filePath = await _recordingService.stopRecording();

      emit(state.copyWith(
        status: RecordingStatus.completed,
        filePath: filePath,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RecordingStatus.error,
        errorMessage: '录音停止失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPauseIntegratedRecording(
    PauseIntegratedRecording event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    if (!state.canPause) return;

    try {
      await _recordingService.pauseRecording();

      emit(state.copyWith(
        status: RecordingStatus.paused,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '录音暂停失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onResumeIntegratedRecording(
    ResumeIntegratedRecording event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    if (!state.canResume) return;

    try {
      await _recordingService.resumeRecording();

      emit(state.copyWith(
        status: RecordingStatus.recording,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '录音恢复失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCancelIntegratedRecording(
    CancelIntegratedRecording event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    try {
      // 尝试取消录音服务（如果正在录音中）
      if (state.isRecording || state.isPaused) {
        await _recordingService.cancelRecording();
      }

      // 无论当前状态如何，都重置为idle
      emit(const IntegratedRecordingState(
        status: RecordingStatus.idle,
        duration: 0,
        filePath: null,
        errorMessage: null,
        audioLevel: null,
        startTime: null,
        recognizedText: '',
        confidence: 0.0,
      ));
    } catch (e) {
      // 即使取消失败，也要重置状态
      emit(const IntegratedRecordingState(
        status: RecordingStatus.idle,
        duration: 0,
        filePath: null,
        errorMessage: null,
        audioLevel: null,
        startTime: null,
        recognizedText: '',
        confidence: 0.0,
      ));
    }
  }

  Future<void> _onUpdateRecordingDuration(
    UpdateRecordingDuration event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    if (state.isRecording) {
      emit(state.copyWith(
        duration: event.duration,
      ));
    }
  }

  Future<void> _onRecognitionResultReceived(
    RecognitionResultReceived event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    emit(state.copyWith(
      recognizedText: event.text,
      confidence: event.confidence,
      lastRecognitionTime: DateTime.now(),
    ));
  }

  Future<void> _onRecognitionErrorReceived(
    RecognitionErrorReceived event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    emit(state.copyWith(
      errorMessage: event.error,
    ));
  }

  Future<void> _onClearRecognitionText(
    ClearRecognitionText event,
    Emitter<IntegratedRecordingState> emit,
  ) async {
    emit(state.copyWith(
      recognizedText: '',
      confidence: 0.0,
      lastRecognitionTime: null,
    ));
  }

  /// 启动录音时长更新定时器
  void startDurationTimer() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.isRecording) {
        add(UpdateRecordingDuration(state.duration + 100));
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _recordingService.dispose();
    return super.close();
  }
}