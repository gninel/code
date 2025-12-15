import '../../domain/entities/autobiography.dart';
import '../../domain/entities/chapter.dart';

class AutobiographyModel extends Autobiography {
  const AutobiographyModel({
    required super.id,
    required super.title,
    required super.content,
    super.chapters,
    required super.generatedAt,
    required super.lastModifiedAt,
    super.version,
    super.wordCount,
    super.voiceRecordIds,
    super.summary,
    super.tags,
    super.status,
    super.style,
  });

  factory AutobiographyModel.fromEntity(Autobiography autobiography) {
    return AutobiographyModel(
      id: autobiography.id,
      title: autobiography.title,
      content: autobiography.content,
      chapters: autobiography.chapters,
      generatedAt: autobiography.generatedAt,
      lastModifiedAt: autobiography.lastModifiedAt,
      version: autobiography.version,
      wordCount: autobiography.wordCount,
      voiceRecordIds: autobiography.voiceRecordIds,
      summary: autobiography.summary,
      tags: autobiography.tags,
      status: autobiography.status,
      style: autobiography.style,
    );
  }

  factory AutobiographyModel.fromJson(Map<String, dynamic> json) {
    return AutobiographyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      chapters: _parseChapters(json['chapters']),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      version: json['version'] as int? ?? 1,
      wordCount: json['wordCount'] as int? ?? 0,
      voiceRecordIds: (json['voiceRecordIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      summary: json['summary'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      status: _parseStatus(json['status'] as String?),
      style: _parseStyle(json['style'] as String?),
    );
  }

  static List<Chapter> _parseChapters(dynamic chaptersJson) {
    if (chaptersJson == null) return const [];
    if (chaptersJson is! List) return const [];
    return (chaptersJson as List<dynamic>).map<Chapter>((chapterJson) {
      return Chapter(
        id: chapterJson['id'] as String? ?? '',
        title: chapterJson['title'] as String? ?? '',
        content: chapterJson['content'] as String? ?? '',
        order: chapterJson['order'] as int? ?? 0,
        sourceRecordIds: (chapterJson['sourceRecordIds'] as List<dynamic>?)
            ?.map((e) => e as String).toList() ?? const [],
        summary: chapterJson['summary'] as String?,
        lastModifiedAt: chapterJson['lastModifiedAt'] != null
            ? DateTime.parse(chapterJson['lastModifiedAt'] as String)
            : DateTime.now(),
      );
    }).toList();
  }

  static AutobiographyStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft':
        return AutobiographyStatus.draft;
      case 'published':
        return AutobiographyStatus.published;
      case 'archived':
        return AutobiographyStatus.archived;
      case 'editing':
        return AutobiographyStatus.editing;
      case 'generating':
        return AutobiographyStatus.generating;
      case 'generationFailed':
        return AutobiographyStatus.generationFailed;
      default:
        return AutobiographyStatus.draft;
    }
  }

  static AutobiographyStyle? _parseStyle(String? style) {
    switch (style) {
      case 'narrative':
        return AutobiographyStyle.narrative;
      case 'emotional':
        return AutobiographyStyle.emotional;
      case 'achievement':
        return AutobiographyStyle.achievement;
      case 'chronological':
        return AutobiographyStyle.chronological;
      case 'reflection':
        return AutobiographyStyle.reflection;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'chapters': chapters.map((c) => {
        'id': c.id,
        'title': c.title,
        'content': c.content,
        'order': c.order,
        'sourceRecordIds': c.sourceRecordIds,
        'summary': c.summary,
        'lastModifiedAt': c.lastModifiedAt.toIso8601String(),
      }).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'version': version,
      'wordCount': wordCount,
      'voiceRecordIds': voiceRecordIds,
      'summary': summary,
      'tags': tags,
      'status': status.name,
      'style': style?.name,
    };
  }
}
