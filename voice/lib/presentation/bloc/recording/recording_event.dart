import 'package:equatable/equatable.dart';

abstract class RecordingEvent extends Equatable {
  const RecordingEvent();

  @override
  List<Object?> get props => [];
}

/// 开始录音事件
class StartRecording extends RecordingEvent {
  const StartRecording();
}

/// 停止录音事件
class StopRecording extends RecordingEvent {
  const StopRecording();
}

/// 暂停录音事件
class PauseRecording extends RecordingEvent {
  const PauseRecording();
}

/// 恢复录音事件
class ResumeRecording extends RecordingEvent {
  const ResumeRecording();
}

/// 取消录音事件
class CancelRecording extends RecordingEvent {
  const CancelRecording();
}

/// 更新录音时长事件
class UpdateRecordingDuration extends RecordingEvent {
  final int duration;

  const UpdateRecordingDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

/// 更新音频电平事件
class UpdateAudioLevel extends RecordingEvent {
  final double audioLevel;

  const UpdateAudioLevel(this.audioLevel);

  @override
  List<Object?> get props => [audioLevel];
}