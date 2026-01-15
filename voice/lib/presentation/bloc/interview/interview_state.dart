import 'package:equatable/equatable.dart';
import '../../../../domain/entities/interview_session.dart';

/// 采访模式状态
class InterviewState extends Equatable {
  /// 当前会话
  final InterviewSession? currentSession;

  /// 加载状态
  final InterviewStatus status;

  /// 错误消息
  final String? errorMessage;

  const InterviewState({
    this.currentSession,
    this.status = InterviewStatus.idle,
    this.errorMessage,
  });

  /// 是否有活跃会话
  bool get hasActiveSession =>
      currentSession != null && currentSession!.isActive;

  /// 是否有当前问题
  bool get hasCurrentQuestion =>
      hasActiveSession && currentSession!.currentQuestion != null;

  /// 当前问题
  String? get currentQuestion {
    final question = currentSession?.currentQuestion?.question;
    print('[InterviewState] currentQuestion getter called:');
    print('  - Has session: ${currentSession != null}');
    print('  - Questions count: ${currentSession?.questions.length}');
    print('  - Current index: ${currentSession?.currentQuestionIndex}');
    print('  - Current question object: ${currentSession?.currentQuestion}');
    print('  - Question text: $question');
    return question;
  }

  /// 会话进度
  double get progress => currentSession?.progress ?? 0.0;

  /// 已回答数量
  int get answeredCount => currentSession?.answeredQuestions.length ?? 0;

  /// 问题总数
  int get totalQuestions => currentSession?.questions.length ?? 0;

  InterviewState copyWith({
    InterviewSession? currentSession,
    InterviewStatus? status,
    String? errorMessage,
    bool clearCurrentSession = false,
  }) {
    return InterviewState(
      currentSession: clearCurrentSession ? null : (currentSession ?? this.currentSession),
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [currentSession, status, errorMessage];
}

/// 采访状态枚举
enum InterviewStatus {
  /// 空闲
  idle,

  /// 加载中
  loading,

  /// 生成问题中
  generating,

  /// 保存中
  saving,

  /// 就绪（有活跃会话）
  ready,

  /// 错误
  error,

  /// 已完成
  completed,
}
