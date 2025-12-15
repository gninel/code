import '../../domain/entities/voice_record.dart';

class VoiceRecordModel extends VoiceRecord {
  const VoiceRecordModel({
    required super.id,
    required super.title,
    super.content,
    super.audioFilePath,
    super.duration,
    required super.timestamp,
    super.isProcessed,
    super.tags,
    super.transcription,
    super.confidence,
    super.note,
    super.isIncludedInBio,
  });

  factory VoiceRecordModel.fromEntity(VoiceRecord record) {
    return VoiceRecordModel(
      id: record.id,
      title: record.title,
      content: record.content,
      audioFilePath: record.audioFilePath,
      duration: record.duration,
      timestamp: record.timestamp,
      isProcessed: record.isProcessed,
      tags: record.tags,
      transcription: record.transcription,
      confidence: record.confidence,
      note: record.note,
      isIncludedInBio: record.isIncludedInBio,
    );
  }

  factory VoiceRecordModel.fromJson(Map<String, dynamic> json) {
    return VoiceRecordModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      audioFilePath: json['audioFilePath'] as String?,
      duration: json['duration'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isProcessed: json['isProcessed'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      transcription: json['transcription'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      note: json['note'] as String?,
      isIncludedInBio: json['isIncludedInBio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'audioFilePath': audioFilePath,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
      'isProcessed': isProcessed,
      'tags': tags,
      'transcription': transcription,
      'confidence': confidence,
      'note': note,
      'isIncludedInBio': isIncludedInBio,
    };
  }
}
