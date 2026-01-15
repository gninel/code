import '../../domain/entities/interview_question.dart';

class InterviewQuestionModel extends InterviewQuestion {
  const InterviewQuestionModel({
    required super.id,
    required super.question,
    super.answer,
    required super.order,
    super.isAnswered = false,
    super.isSkipped = false,
    required super.createdAt,
  });

  factory InterviewQuestionModel.fromEntity(InterviewQuestion entity) {
    return InterviewQuestionModel(
      id: entity.id,
      question: entity.question,
      answer: entity.answer,
      order: entity.order,
      isAnswered: entity.isAnswered,
      isSkipped: entity.isSkipped,
      createdAt: entity.createdAt,
    );
  }

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      order: json['order'] as int,
      isAnswered: _parseBool(json['isAnswered']),
      isSkipped: _parseBool(json['isSkipped']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 解析布尔值，支持int和bool类型
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'order': order,
      'isAnswered': isAnswered,
      'isSkipped': isSkipped,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
