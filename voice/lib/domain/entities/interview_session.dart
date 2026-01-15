import 'package:equatable/equatable.dart';
import 'interview_question.dart';

/// 采访会话实体
class InterviewSession extends Equatable {
  final String id;
  final List<InterviewQuestion> questions; // 问题列表
  final int currentQuestionIndex; // 当前问题索引
  final bool isActive; // 会话是否活跃
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InterviewSession({
    required this.id,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// 获取当前问题
  InterviewQuestion? get currentQuestion {
    print('[InterviewSession] currentQuestion getter called:');
    print('  - currentQuestionIndex: $currentQuestionIndex');
    print('  - questions.length: ${questions.length}');

    if (currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      print('[InterviewSession] Index out of range! Returning null');
      return null;
    }

    final question = questions[currentQuestionIndex];
    print('[InterviewSession] Returning question: ${question.question}');
    return question;
  }

  /// 获取已回答的问题
  List<InterviewQuestion> get answeredQuestions {
    return questions.where((q) => q.isAnswered).toList();
  }

  /// 获取未回答的问题（包括跳过的）
  List<InterviewQuestion> get unansweredQuestions {
    return questions.where((q) => !q.isAnswered).toList();
  }

  /// 获取已跳过的问题
  List<InterviewQuestion> get skippedQuestions {
    return questions.where((q) => q.isSkipped).toList();
  }

  /// 是否有下一个问题
  bool get hasNextQuestion {
    return currentQuestionIndex < questions.length - 1;
  }

  /// 进度百分比
  double get progress {
    if (questions.isEmpty) return 0.0;
    return answeredQuestions.length / questions.length;
  }

  InterviewSession copyWith({
    String? id,
    List<InterviewQuestion>? questions,
    int? currentQuestionIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterviewSession(
      id: id ?? this.id,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questions,
        currentQuestionIndex,
        isActive,
        createdAt,
        updatedAt,
      ];
}
