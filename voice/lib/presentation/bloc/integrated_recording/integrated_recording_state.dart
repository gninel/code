import 'package:equatable/equatable.dart';
import '../../../domain/entities/recording_state.dart';

/// 集成录音状态（录音+语音识别）
class IntegratedRecordingState extends Equatable {
  final RecordingStatus status;
  final int duration; // 录音时长（毫秒）
  final String? filePath; // 录音文件路径
  final String? errorMessage; // 错误信息
  final double? audioLevel; // 音频电平 (0.0 - 1.0)
  final DateTime? startTime; // 开始录音时间
  final String recognizedText; // 识别文本
  final double confidence; // 识别置信度
  final DateTime? lastRecognitionTime; // 最后识别时间
  final bool isFileUpload; // 是否为文件上传模式

  const IntegratedRecordingState({
    this.status = RecordingStatus.idle,
    this.duration = 0,
    this.filePath,
    this.errorMessage,
    this.audioLevel,
    this.startTime,
    this.recognizedText = '',
    this.confidence = 0.0,
    this.lastRecognitionTime,
    this.isFileUpload = false,
  });

  /// 创建新状态
  IntegratedRecordingState copyWith({
    RecordingStatus? status,
    int? duration,
    String? filePath,
    String? errorMessage,
    double? audioLevel,
    DateTime? startTime,
    String? recognizedText,
    double? confidence,
    DateTime? lastRecognitionTime,
    bool? isFileUpload,
  }) {
    return IntegratedRecordingState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      audioLevel: audioLevel ?? this.audioLevel,
      startTime: startTime ?? this.startTime,
      recognizedText: recognizedText ?? this.recognizedText,
      confidence: confidence ?? this.confidence,
      lastRecognitionTime: lastRecognitionTime ?? this.lastRecognitionTime,
      isFileUpload: isFileUpload ?? this.isFileUpload,
    );
  }

  /// 是否正在录音
  bool get isRecording => status == RecordingStatus.recording;

  /// 是否已暂停
  bool get isPaused => status == RecordingStatus.paused;

  /// 是否正在处理
  bool get isProcessing => status == RecordingStatus.processing;

  /// 是否已完成
  bool get isCompleted => status == RecordingStatus.completed;

  /// 是否有错误
  bool get hasError => status == RecordingStatus.error;

  /// 是否正在识别（基于识别时间判断）
  bool get isRecognizing => lastRecognitionTime != null &&
      DateTime.now().difference(lastRecognitionTime!).inSeconds < 5;

  /// 是否可以开始录音
  bool get canStart => status == RecordingStatus.idle || status == RecordingStatus.error;

  /// 是否可以停止录音
  bool get canStop => isRecording || isPaused;

  /// 是否可以暂停录音
  bool get canPause => isRecording && duration >= 1000; // 至少录音1秒才能暂停

  /// 是否可以继续录音
  bool get canResume => isPaused;

  /// 是否可以取消录音
  bool get canCancel => isRecording || isPaused || isProcessing || isCompleted;

  /// 是否有识别文本
  bool get hasRecognizedText => recognizedText.isNotEmpty;

  /// 获取格式化的时长字符串
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

  /// 获取置信度百分比
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  /// 获取置信度等级
  String get confidenceLevel {
    if (confidence >= 0.9) return '极高';
    if (confidence >= 0.8) return '高';
    if (confidence >= 0.7) return '中等';
    if (confidence >= 0.6) return '较低';
    return '低';
  }

  /// 获取置信度颜色
  int get confidenceColor {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.6) return 0xFFFF9800; // Amber
    return 0xFFF44336; // Red
  }

  /// 获取综合状态描述
  String get statusDescription {
    if (isRecording && isRecognizing) {
      return '正在录音和识别...';
    } else if (isRecording) {
      return '正在录音...';
    } else if (isRecognizing) {
      return '正在识别...';
    }
    return status.displayName;
  }

  @override
  List<Object?> get props => [
        status,
        duration,
        filePath,
        errorMessage,
        audioLevel,
        startTime,
        recognizedText,
        confidence,
        lastRecognitionTime,
        isFileUpload,
      ];

  @override
  String toString() {
    return 'IntegratedRecordingState{status: $status, duration: ${duration}ms, recognizedText: $recognizedText, confidence: $confidence}';
  }
}