import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../domain/usecases/recognition_usecases.dart';

abstract class VoiceRecognitionEvent extends Equatable {
  const VoiceRecognitionEvent();

  @override
  List<Object?> get props => [];
}

/// 开始语音识别事件
class StartVoiceRecognition extends VoiceRecognitionEvent {
  const StartVoiceRecognition();
}

/// 发送音频数据事件
class SendAudioData extends VoiceRecognitionEvent {
  final Uint8List audioData;
  final bool isEnd;

  const SendAudioData(
    this.audioData, {
    this.isEnd = false,
  });

  @override
  List<Object?> get props => [audioData, isEnd];
}

/// 停止语音识别事件
class StopVoiceRecognition extends VoiceRecognitionEvent {
  const StopVoiceRecognition();
}

/// 取消语音识别事件
class CancelVoiceRecognition extends VoiceRecognitionEvent {
  const CancelVoiceRecognition();
}

/// 清除识别结果事件
class ClearRecognitionResult extends VoiceRecognitionEvent {
  const ClearRecognitionResult();
}

/// 识别结果接收事件（内部使用）
class RecognitionResultReceived extends VoiceRecognitionEvent {
  final RecognitionResult result;

  const RecognitionResultReceived(this.result);

  @override
  List<Object?> get props => [result];
}

/// 识别完成事件（内部使用）
class RecognitionCompleted extends VoiceRecognitionEvent {
  const RecognitionCompleted();
}

/// 识别错误事件（内部使用）
class RecognitionError extends VoiceRecognitionEvent {
  final String error;

  const RecognitionError(this.error);

  @override
  List<Object?> get props => [error];
}