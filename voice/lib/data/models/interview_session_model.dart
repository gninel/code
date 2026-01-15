import '../../domain/entities/interview_session.dart';
// ignore: unused_import
import '../../domain/entities/interview_question.dart';
import 'interview_question_model.dart';

class InterviewSessionModel extends InterviewSession {
  const InterviewSessionModel({
    required super.id,
    super.questions = const [],
    super.currentQuestionIndex = 0,
    super.isActive = true,
    required super.createdAt,
    super.updatedAt,
  });

  factory InterviewSessionModel.fromEntity(InterviewSession entity) {
    return InterviewSessionModel(
      id: entity.id,
      questions: entity.questions,
      currentQuestionIndex: entity.currentQuestionIndex,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory InterviewSessionModel.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List<dynamic>?;
    final questions = questionsList
        ?.map((q) => InterviewQuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();

    return InterviewSessionModel(
      id: json['id'] as String,
      questions: questions ?? const [],
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      isActive: _parseBool(json['isActive']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 解析布尔值，支持int和bool类型
  static bool _parseBool(dynamic value) {
    if (value == null) return true; // isActive默认为true
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questions': questions
          .map((q) => InterviewQuestionModel.fromEntity(q).toJson())
          .toList(),
      'currentQuestionIndex': currentQuestionIndex,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
