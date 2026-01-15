import 'package:equatable/equatable.dart';

/// 语音识别状态
class VoiceRecognitionState extends Equatable {
  final VoiceRecognitionStatus status;
  final String recognizedText;
  final double confidence;
  final String? error;
  final DateTime? lastUpdateTime;

  const VoiceRecognitionState({
    this.status = VoiceRecognitionStatus.idle,
    this.recognizedText = '',
    this.confidence = 0.0,
    this.error,
    this.lastUpdateTime,
  });

  /// 创建新状态
  VoiceRecognitionState copyWith({
    VoiceRecognitionStatus? status,
    String? recognizedText,
    double? confidence,
    String? error,
    DateTime? lastUpdateTime,
  }) {
    return VoiceRecognitionState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      confidence: confidence ?? this.confidence,
      error: error ?? this.error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  /// 是否正在监听
  bool get isListening => status == VoiceRecognitionStatus.listening;

  /// 是否正在连接
  bool get isConnecting => status == VoiceRecognitionStatus.connecting;

  /// 是否已完成
  bool get isCompleted => status == VoiceRecognitionStatus.completed;

  /// 是否有错误
  bool get hasError => status == VoiceRecognitionStatus.error;

  /// 是否空闲
  bool get isIdle => status == VoiceRecognitionStatus.idle;

  /// 是否有识别文本
  bool get hasRecognizedText => recognizedText.isNotEmpty;

  /// 获取置信度百分比
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  @override
  List<Object?> get props => [
        status,
        recognizedText,
        confidence,
        error,
        lastUpdateTime,
      ];

  @override
  String toString() {
    return 'VoiceRecognitionState{status: $status, recognizedText: $recognizedText, confidence: $confidence}';
  }
}

/// 语音识别状态枚举
enum VoiceRecognitionStatus {
  /// 空闲状态
  idle,

  /// 连接中
  connecting,

  /// 正在监听
  listening,

  /// 识别完成
  completed,

  /// 识别错误
  error,
}

/// 语音识别状态扩展方法
extension VoiceRecognitionStatusExtension on VoiceRecognitionStatus {
  /// 获取状态显示名称
  String get displayName {
    switch (this) {
      case VoiceRecognitionStatus.idle:
        return '准备识别';
      case VoiceRecognitionStatus.connecting:
        return '连接中...';
      case VoiceRecognitionStatus.listening:
        return '正在识别';
      case VoiceRecognitionStatus.completed:
        return '识别完成';
      case VoiceRecognitionStatus.error:
        return '识别错误';
    }
  }

  /// 获取状态描述
  String get description {
    switch (this) {
      case VoiceRecognitionStatus.idle:
        return '点击开始按钮进行语音识别';
      case VoiceRecognitionStatus.connecting:
        return '正在连接语音识别服务...';
      case VoiceRecognitionStatus.listening:
        return '请清晰地说话，系统正在实时识别';
      case VoiceRecognitionStatus.completed:
        return '语音识别完成';
      case VoiceRecognitionStatus.error:
        return '语音识别过程中出现错误';
    }
  }

  /// 获取对应的状态颜色
  int get colorValue {
    switch (this) {
      case VoiceRecognitionStatus.idle:
        return 0xFF9E9E9E; // Grey
      case VoiceRecognitionStatus.connecting:
        return 0xFF2196F3; // Blue
      case VoiceRecognitionStatus.listening:
        return 0xFF4CAF50; // Green
      case VoiceRecognitionStatus.completed:
        return 0xFF1976D2; // Material Blue
      case VoiceRecognitionStatus.error:
        return 0xFFF44336; // Red
    }
  }

  /// 获取对应的图标
  String get iconName {
    switch (this) {
      case VoiceRecognitionStatus.idle:
        return 'mic';
      case VoiceRecognitionStatus.connecting:
        return 'hourglass_empty';
      case VoiceRecognitionStatus.listening:
        return 'hearing';
      case VoiceRecognitionStatus.completed:
        return 'check_circle';
      case VoiceRecognitionStatus.error:
        return 'error';
    }
  }
}