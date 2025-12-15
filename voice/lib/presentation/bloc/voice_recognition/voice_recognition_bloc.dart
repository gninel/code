import 'dart:async';

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/usecases/recognition_usecases.dart';

import 'voice_recognition_event.dart';
import 'voice_recognition_state.dart';

@injectable
class VoiceRecognitionBloc extends Bloc<VoiceRecognitionEvent, VoiceRecognitionState> {
  final RecognitionUseCases _recognitionUseCases;
  StreamSubscription<Either<Failure, RecognitionResult>>? _recognitionSubscription;

  VoiceRecognitionBloc(this._recognitionUseCases) : super(const VoiceRecognitionState()) {
    on<StartVoiceRecognition>(_onStartVoiceRecognition);
    on<SendAudioData>(_onSendAudioData);
    on<StopVoiceRecognition>(_onStopVoiceRecognition);
    on<CancelVoiceRecognition>(_onCancelVoiceRecognition);
    on<ClearRecognitionResult>(_onClearRecognitionResult);
  }

  Future<void> _onStartVoiceRecognition(
    StartVoiceRecognition event,
    Emitter<VoiceRecognitionState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: VoiceRecognitionStatus.connecting,
        error: null,
      ));

      // 开始语音识别
      final recognitionStream = _recognitionUseCases.startRecognition();

      // 监听识别结果
      _recognitionSubscription = recognitionStream.listen(
        (result) {
          result.fold(
            (failure) {
              add(RecognitionError(failure.message));
            },
            (recognitionResult) {
              add(RecognitionResultReceived(recognitionResult));
            },
          );
        },
        onError: (error) {
          add(RecognitionError('语音识别过程中出现错误: ${error.toString()}'));
        },
        onDone: () {
          add(const RecognitionCompleted());
        },
      );

      emit(state.copyWith(
        status: VoiceRecognitionStatus.listening,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VoiceRecognitionStatus.error,
        error: '启动语音识别失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSendAudioData(
    SendAudioData event,
    Emitter<VoiceRecognitionState> emit,
  ) async {
    if (state.status != VoiceRecognitionStatus.listening) {
      return;
    }

    try {
      final result = await _recognitionUseCases.sendAudioData(
        event.audioData,
        isEnd: event.isEnd,
      );

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: VoiceRecognitionStatus.error,
            error: failure.message,
          ));
        },
        (_) {
          // 音频数据发送成功，不需要更新状态
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: VoiceRecognitionStatus.error,
        error: '发送音频数据失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopVoiceRecognition(
    StopVoiceRecognition event,
    Emitter<VoiceRecognitionState> emit,
  ) async {
    try {
      await _recognitionSubscription?.cancel();

      final result = await _recognitionUseCases.stopRecognition();

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: VoiceRecognitionStatus.error,
            error: failure.message,
          ));
        },
        (_) {
          emit(state.copyWith(
            status: VoiceRecognitionStatus.completed,
            error: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: VoiceRecognitionStatus.error,
        error: '停止语音识别失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCancelVoiceRecognition(
    CancelVoiceRecognition event,
    Emitter<VoiceRecognitionState> emit,
  ) async {
    try {
      await _recognitionSubscription?.cancel();

      final result = await _recognitionUseCases.cancelRecognition();

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: VoiceRecognitionStatus.error,
            error: failure.message,
          ));
        },
        (_) {
          emit(const VoiceRecognitionState());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: VoiceRecognitionStatus.error,
        error: '取消语音识别失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearRecognitionResult(
    ClearRecognitionResult event,
    Emitter<VoiceRecognitionState> emit,
  ) async {
    emit(const VoiceRecognitionState());
  }

  @override
  Future<void> close() {
    _recognitionSubscription?.cancel();
    return super.close();
  }
}