import 'package:equatable/equatable.dart';

/// 自传章节实体
class Chapter extends Equatable {
  final String id;
  final String title;
  final String content;
  final int order; // 章节顺序
  final List<String> sourceRecordIds; // 关联的语音记录ID
  final String? summary; // 章节摘要
  final DateTime lastModifiedAt;

  const Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    this.sourceRecordIds = const [],
    this.summary,
    required this.lastModifiedAt,
  });

  /// 创建一个新的章节实例
  Chapter copyWith({
    String? id,
    String? title,
    String? content,
    int? order,
    List<String>? sourceRecordIds,
    String? summary,
    DateTime? lastModifiedAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      sourceRecordIds: sourceRecordIds ?? this.sourceRecordIds,
      summary: summary ?? this.summary,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  /// 章节字数
  int get wordCount => content.length;

  /// 章节预览
  String get contentPreview {
    if (content.length <= 50) return content;
    return '${content.substring(0, 50)}...';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        order,
        sourceRecordIds,
        summary,
        lastModifiedAt,
      ];
}
