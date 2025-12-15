import 'package:equatable/equatable.dart';

/// 语音记录实体
class VoiceRecord extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? audioFilePath;
  final int duration; // 录音时长（毫秒）
  final DateTime timestamp;
  final bool isProcessed; // 是否已通过AI处理
  final List<String> tags; // 标签分类
  final String? transcription; // 转写内容
  final double? confidence; // 识别准确度
  final String? note; // 备注
  final bool isIncludedInBio; // 是否已纳入自传

  const VoiceRecord({
    required this.id,
    required this.title,
    this.content = '',
    this.audioFilePath,
    this.duration = 0,
    required this.timestamp,
    this.isProcessed = false,
    this.tags = const [],
    this.transcription,
    this.confidence,
    this.note,
    this.isIncludedInBio = false,
  });

  /// 创建一个新的语音记录
  VoiceRecord copyWith({
    String? id,
    String? title,
    String? content,
    String? audioFilePath,
    int? duration,
    DateTime? timestamp,
    bool? isProcessed,
    List<String>? tags,
    String? transcription,
    double? confidence,
    String? note,
    bool? isIncludedInBio,
  }) {
    return VoiceRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      isProcessed: isProcessed ?? this.isProcessed,
      tags: tags ?? this.tags,
      transcription: transcription ?? this.transcription,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      isIncludedInBio: isIncludedInBio ?? this.isIncludedInBio,
    );
  }

  /// 获取格式化的时长字符串
  String get formattedDuration {
    final duration = this.duration;
    final seconds = (duration / 1000) % 60;
    final minutes = (duration / 60000) % 60;
    final hours = duration / 3600000;

    if (hours > 0) {
      return '${hours.toInt()}:${minutes.toInt().toString().padLeft(2, '0')}:${seconds.toInt().toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes.toInt()}:${seconds.toInt().toString().padLeft(2, '0')}';
    } else {
      return '${seconds.toInt()}秒';
    }
  }

  /// 获取文件大小字符串（如果有音频文件）
  String? get audioFileSize {
    // TODO: 实现获取音频文件大小的逻辑
    return null;
  }

  /// 是否为有效的录音（时长至少1秒）
  bool get isValidRecording => duration >= 1000;

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        audioFilePath,
        duration,
        timestamp,
        isProcessed,
        tags,
        transcription,
        confidence,
        note,
        isIncludedInBio,
      ];

  @override
  String toString() {
    return 'VoiceRecord{id: $id, title: $title, duration: $duration, timestamp: $timestamp}';
  }
}