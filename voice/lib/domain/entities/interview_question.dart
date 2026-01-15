import 'package:equatable/equatable.dart';

/// 采访问题实体
class InterviewQuestion extends Equatable {
  final String id;
  final String question; // 问题内容
  final String? answer; // 回答内容（可选）
  final int order; // 问题顺序
  final bool isAnswered; // 是否已回答
  final bool isSkipped; // 是否已跳过
  final DateTime createdAt;

  const InterviewQuestion({
    required this.id,
    required this.question,
    this.answer,
    required this.order,
    this.isAnswered = false,
    this.isSkipped = false,
    required this.createdAt,
  });

  InterviewQuestion copyWith({
    String? id,
    String? question,
    String? answer,
    int? order,
    bool? isAnswered,
    bool? isSkipped,
    DateTime? createdAt,
  }) {
    return InterviewQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      order: order ?? this.order,
      isAnswered: isAnswered ?? this.isAnswered,
      isSkipped: isSkipped ?? this.isSkipped,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        answer,
        order,
        isAnswered,
        isSkipped,
        createdAt,
      ];
}
