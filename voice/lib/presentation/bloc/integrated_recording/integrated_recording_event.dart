import 'package:equatable/equatable.dart';

abstract class IntegratedRecordingEvent extends Equatable {
  const IntegratedRecordingEvent();

  @override
  List<Object?> get props => [];
}

/// 开始集成录音（录音+语音识别）
class StartIntegratedRecording extends IntegratedRecordingEvent {
  const StartIntegratedRecording();
}

/// 停止集成录音
class StopIntegratedRecording extends IntegratedRecordingEvent {
  const StopIntegratedRecording();
}

/// 暂停集成录音
class PauseIntegratedRecording extends IntegratedRecordingEvent {
  const PauseIntegratedRecording();
}

/// 恢复集成录音
class ResumeIntegratedRecording extends IntegratedRecordingEvent {
  const ResumeIntegratedRecording();
}

/// 取消集成录音
class CancelIntegratedRecording extends IntegratedRecordingEvent {
  const CancelIntegratedRecording();
}

/// 更新录音时长
class UpdateRecordingDuration extends IntegratedRecordingEvent {
  final int duration;

  const UpdateRecordingDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

/// 接收到语音识别结果
class RecognitionResultReceived extends IntegratedRecordingEvent {
  final String text;
  final double confidence;

  const RecognitionResultReceived({
    required this.text,
    required this.confidence,
  });

  @override
  List<Object?> get props => [text, confidence];
}

/// 接收到语音识别错误
class RecognitionErrorReceived extends IntegratedRecordingEvent {
  final String error;

  const RecognitionErrorReceived(this.error);

  @override
  List<Object?> get props => [error];
}


/// 清除识别文本
class ClearRecognitionText extends IntegratedRecordingEvent {
  const ClearRecognitionText();
}

/// 上传并识别录音文件
class UploadRecordingFile extends IntegratedRecordingEvent {
  final String filePath;

  const UploadRecordingFile(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// 手动更新识别文本（编辑）
class UpdateRecognizedText extends IntegratedRecordingEvent {
  final String text;

  const UpdateRecognizedText(this.text);

  @override
  List<Object?> get props => [text];
}