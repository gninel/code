import 'package:equatable/equatable.dart';
import 'chapter.dart';

/// 自传实体
class Autobiography extends Equatable {
  final String id;
  final String title;
  final String content; // 兼容旧版，可以是所有章节内容的拼接
  final List<Chapter> chapters; // 新增：章节列表
  final DateTime generatedAt;
  final DateTime lastModifiedAt;
  final int version;
  final int wordCount;
  final List<String> voiceRecordIds; // 关联的语音记录ID列表
  final String? summary; // 摘要
  final List<String> tags; // 标签
  final AutobiographyStatus status; // 状态
  final AutobiographyStyle? style; // 自传风格
  final String promptVersion; // 生成时使用的Prompt版本号

  const Autobiography({
    required this.id,
    required this.title,
    required this.content,
    this.chapters = const [], // 默认为空列表
    required this.generatedAt,
    required this.lastModifiedAt,
    this.version = 1,
    this.wordCount = 0,
    this.voiceRecordIds = const [],
    this.summary,
    this.tags = const [],
    this.status = AutobiographyStatus.draft,
    this.style,
    this.promptVersion = '1.0.0', // 默认版本
  });

  /// 创建一个新的自传实例
  Autobiography copyWith({
    String? id,
    String? title,
    String? content,
    List<Chapter>? chapters,
    DateTime? generatedAt,
    DateTime? lastModifiedAt,
    int? version,
    int? wordCount,
    List<String>? voiceRecordIds,
    String? summary,
    List<String>? tags,
    AutobiographyStatus? status,
    AutobiographyStyle? style,
    String? promptVersion,
  }) {
    return Autobiography(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      chapters: chapters ?? this.chapters,
      generatedAt: generatedAt ?? this.generatedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
      wordCount: wordCount ?? this.wordCount,
      voiceRecordIds: voiceRecordIds ?? this.voiceRecordIds,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      style: style ?? this.style,
      promptVersion: promptVersion ?? this.promptVersion,
    );
  }

  /// 获取阅读时长（估算，按每分钟200字计算）
  int get estimatedReadingMinutes {
    return (wordCount / 200).ceil();
  }

  /// 获取内容预览（前100个字符）
  String get contentPreview {
    if (content.length <= 100) {
      return content;
    }
    return '${content.substring(0, 100)}...';
  }

  /// 是否为空内容
  bool get isEmpty => content.trim().isEmpty;

  /// 是否有内容
  bool get hasContent => content.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        chapters,
        generatedAt,
        lastModifiedAt,
        version,
        wordCount,
        voiceRecordIds,
        summary,
        tags,
        status,
        style,
        promptVersion,
      ];

  @override
  String toString() {
    return 'Autobiography{id: $id, title: $title, wordCount: $wordCount, status: $status}';
  }
}

/// 自传状态枚举
enum AutobiographyStatus {
  /// 草稿
  draft,

  /// 已发布
  published,

  /// 已归档
  archived,

  /// 正在编辑
  editing,

  /// 正在生成
  generating,

  /// 生成失败
  generationFailed,
}

/// 自传状态扩展方法
extension AutobiographyStatusExtension on AutobiographyStatus {
  /// 获取状态显示名称
  String get displayName {
    switch (this) {
      case AutobiographyStatus.draft:
        return '草稿';
      case AutobiographyStatus.published:
        return '已发布';
      case AutobiographyStatus.archived:
        return '已归档';
      case AutobiographyStatus.editing:
        return '编辑中';
      case AutobiographyStatus.generating:
        return '生成中';
      case AutobiographyStatus.generationFailed:
        return '生成失败';
    }
  }

  /// 是否可以编辑
  bool get isEditable {
    switch (this) {
      case AutobiographyStatus.draft:
      case AutobiographyStatus.editing:
      case AutobiographyStatus.generationFailed:
        return true;
      case AutobiographyStatus.published:
      case AutobiographyStatus.archived:
      case AutobiographyStatus.generating:
        return false;
    }
  }

  /// 是否可以删除
  bool get isDeletable {
    switch (this) {
      case AutobiographyStatus.draft:
      case AutobiographyStatus.editing:
      case AutobiographyStatus.generationFailed:
      case AutobiographyStatus.archived:
        return true;
      case AutobiographyStatus.published:
      case AutobiographyStatus.generating:
        return false;
    }
  }
}

/// 自传风格枚举
enum AutobiographyStyle {
  /// 叙事风格
  narrative,

  /// 情感风格
  emotional,

  /// 成就风格
  achievement,

  /// 编年体风格
  chronological,

  /// 反思风格
  reflection,
}

/// 优化类型枚举
enum OptimizationType {
  /// 清晰度优化
  clarity,

  /// 流畅性优化
  fluency,

  /// 风格优化
  style,

  /// 结构优化
  structure,

  /// 简洁性优化
  conciseness,
}