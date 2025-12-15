import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/recording_state.dart';
import '../../../domain/usecases/recording_usecases.dart';

import 'recording_event.dart';

@injectable
class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  final RecordingUseCases _recordingUseCases;

  RecordingBloc(this._recordingUseCases) : super(const RecordingState()) {
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<PauseRecording>(_onPauseRecording);
    on<ResumeRecording>(_onResumeRecording);
    on<CancelRecording>(_onCancelRecording);
    on<UpdateRecordingDuration>(_onUpdateRecordingDuration);
    on<UpdateAudioLevel>(_onUpdateAudioLevel);
  }

  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<RecordingState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: RecordingStatus.processing,
        errorMessage: null,
      ));

      final result = await _recordingUseCases.startRecording();

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: RecordingStatus.error,
            errorMessage: failure.message,
          ));
        },
        (filePath) {
          emit(state.copyWith(
            status: RecordingStatus.recording,
            filePath: filePath,
            duration: 0,
            startTime: DateTime.now(),
            errorMessage: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: RecordingStatus.error,
        errorMessage: '录音启动失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.canStop) return;

    try {
      emit(state.copyWith(
        status: RecordingStatus.processing,
      ));

      final result = await _recordingUseCases.stopRecording();

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: RecordingStatus.error,
            errorMessage: failure.message,
          ));
        },
        (voiceRecord) {
          emit(state.copyWith(
            status: RecordingStatus.completed,
            errorMessage: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: RecordingStatus.error,
        errorMessage: '录音停止失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPauseRecording(
    PauseRecording event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.canPause) return;

    try {
      final result = await _recordingUseCases.pauseRecording();

      result.fold(
        (failure) {
          emit(state.copyWith(
            errorMessage: failure.message,
          ));
        },
        (_) {
          emit(state.copyWith(
            status: RecordingStatus.paused,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '录音暂停失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onResumeRecording(
    ResumeRecording event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.canResume) return;

    try {
      final result = await _recordingUseCases.resumeRecording();

      result.fold(
        (failure) {
          emit(state.copyWith(
            errorMessage: failure.message,
          ));
        },
        (_) {
          emit(state.copyWith(
            status: RecordingStatus.recording,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '录音恢复失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCancelRecording(
    CancelRecording event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.canCancel) return;

    try {
      await _recordingUseCases.cancelRecording();

      emit(const RecordingState(
        status: RecordingStatus.idle,
        duration: 0,
        filePath: null,
        errorMessage: null,
        audioLevel: null,
        startTime: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RecordingStatus.error,
        errorMessage: '录音取消失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateRecordingDuration(
    UpdateRecordingDuration event,
    Emitter<RecordingState> emit,
  ) async {
    if (state.isRecording) {
      emit(state.copyWith(
        duration: event.duration,
      ));
    }
  }

  Future<void> _onUpdateAudioLevel(
    UpdateAudioLevel event,
    Emitter<RecordingState> emit,
  ) async {
    if (state.isRecording) {
      emit(state.copyWith(
        audioLevel: event.audioLevel,
      ));
    }
  }
}