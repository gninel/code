import 'dart:convert';

import 'package:equatable/equatable.dart';

/// 自传版本实体
/// 用于保存自传的历史版本
class AutobiographyVersion extends Equatable {
  final String id;
  final String autobiographyId;
  final String versionName;
  final String content;
  final List<Map<String, dynamic>> chapters;
  final DateTime createdAt;
  final int wordCount;
  final String? summary;

  const AutobiographyVersion({
    required this.id,
    required this.autobiographyId,
    required this.versionName,
    required this.content,
    required this.chapters,
    required this.createdAt,
    required this.wordCount,
    this.summary,
  });

  @override
  List<Object?> get props => [
        id,
        autobiographyId,
        versionName,
        content,
        chapters,
        createdAt,
        wordCount,
        summary,
      ];

  AutobiographyVersion copyWith({
    String? id,
    String? autobiographyId,
    String? versionName,
    String? content,
    List<Map<String, dynamic>>? chapters,
    DateTime? createdAt,
    int? wordCount,
    String? summary,
  }) {
    return AutobiographyVersion(
      id: id ?? this.id,
      autobiographyId: autobiographyId ?? this.autobiographyId,
      versionName: versionName ?? this.versionName,
      content: content ?? this.content,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt ?? this.createdAt,
      wordCount: wordCount ?? this.wordCount,
      summary: summary ?? this.summary,
    );
  }

  /// 转换为JSON (用于数据库存储，使用下划线命名)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'autobiography_id': autobiographyId,
      'version_name': versionName,
      'content': content,
      'chapters': chapters,
      'created_at': createdAt.millisecondsSinceEpoch,
      'word_count': wordCount,
      'summary': summary,
    };
  }

  /// 从JSON创建 (从数据库读取，使用下划线命名)
  factory AutobiographyVersion.fromJson(Map<String, dynamic> json) {
    dynamic chaptersData = json['chapters'];
    List<Map<String, dynamic>> chapters;

    if (chaptersData is String) {
      // 如果是JSON字符串，需要解析
      final decoded = jsonDecode(chaptersData);
      chapters = (decoded as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } else if (chaptersData is List) {
      // 如果已经是List，直接使用
      chapters = (chaptersData)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } else {
      chapters = [];
    }

    return AutobiographyVersion(
      id: json['id'] as String,
      autobiographyId: json['autobiography_id'] as String,
      versionName: json['version_name'] as String,
      content: json['content'] as String,
      chapters: chapters,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      wordCount: json['word_count'] as int,
      summary: json['summary'] as String?,
    );
  }
}
