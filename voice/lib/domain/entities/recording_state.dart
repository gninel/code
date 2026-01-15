import 'package:equatable/equatable.dart';

/// 录音状态枚举
enum RecordingStatus {
  idle,
  processing,
  recording,
  paused,
  completed,
  error,
}

/// 领域层的录音状态实体（与 presentation 层的状态同构，供 tests 和其他层引用）
class RecordingState extends Equatable {
  final RecordingStatus status;
  final int duration; // 录音时长（毫秒）
  final String? filePath; // 录音文件路径
  final String? errorMessage; // 错误信息
  final double? audioLevel; // 音频电平 (0.0 - 1.0)
  final DateTime? startTime; // 开始录音时间

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.duration = 0,
    this.filePath,
    this.errorMessage,
    this.audioLevel,
    this.startTime,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    int? duration,
    String? filePath,
    String? errorMessage,
    double? audioLevel,
    DateTime? startTime,
  }) {
    return RecordingState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      audioLevel: audioLevel ?? this.audioLevel,
      startTime: startTime ?? this.startTime,
    );
  }

  bool get isRecording => status == RecordingStatus.recording;
  bool get isPaused => status == RecordingStatus.paused;
  bool get isProcessing => status == RecordingStatus.processing;
  bool get isCompleted => status == RecordingStatus.completed;
  bool get hasError => status == RecordingStatus.error;
  bool get canStart => status == RecordingStatus.idle || status == RecordingStatus.error;
  bool get canStop => isRecording || isPaused;
  bool get canPause => isRecording && duration >= 1000;
  bool get canResume => isPaused;
  bool get canCancel => isRecording || isPaused || isProcessing;

  String get formattedDuration {
    final seconds = (duration / 1000) % 60;
    final minutes = (duration / 60000) % 60;
    final hours = duration / 3600000;

    if (hours > 0) {
      return '${hours.toInt()}:${minutes.toInt().toString().padLeft(2, '0')}:${seconds.toInt().toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes.toInt()}:${seconds.toInt().toString().padLeft(2, '0')}';
    } else {
      return '${seconds.toInt()}';
    }
  }

  @override
  List<Object?> get props => [
        status,
        duration,
        filePath,
        errorMessage,
        audioLevel,
        startTime,
      ];
}

/// RecordingStatus 扩展，提供展示用的文本/颜色/图标名
extension RecordingStatusExtension on RecordingStatus {
  String get displayName {
    switch (this) {
      case RecordingStatus.idle:
        return '空闲';
      case RecordingStatus.processing:
        return '处理中';
      case RecordingStatus.recording:
        return '录音中';
      case RecordingStatus.paused:
        return '已暂停';
      case RecordingStatus.completed:
        return '已完成';
      case RecordingStatus.error:
        return '错误';
    }
  }

  String get description {
    switch (this) {
      case RecordingStatus.idle:
        return '准备录音';
      case RecordingStatus.processing:
        return '处理中...';
      case RecordingStatus.recording:
        return '正在录音';
      case RecordingStatus.paused:
        return '录音已暂停';
      case RecordingStatus.completed:
        return '录音完成';
      case RecordingStatus.error:
        return '录音错误';
    }
  }

  int get colorValue {
    switch (this) {
      case RecordingStatus.idle:
        return 0xFF9E9E9E;
      case RecordingStatus.processing:
        return 0xFF1976D2;
      case RecordingStatus.recording:
        return 0xFF4CAF50;
      case RecordingStatus.paused:
        return 0xFFFFC107;
      case RecordingStatus.completed:
        return 0xFF4CAF50;
      case RecordingStatus.error:
        return 0xFFF44336;
    }
  }

  String get iconName {
    switch (this) {
      case RecordingStatus.idle:
        return 'mic_none';
      case RecordingStatus.processing:
        return 'autorenew';
      case RecordingStatus.recording:
        return 'mic';
      case RecordingStatus.paused:
        return 'pause';
      case RecordingStatus.completed:
        return 'check_circle';
      case RecordingStatus.error:
        return 'error';
    }
  }
}
