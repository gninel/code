import 'package:equatable/equatable.dart';

/// 采访模式事件基类
abstract class InterviewEvent extends Equatable {
  const InterviewEvent();

  @override
  List<Object?> get props => [];
}

/// 开始新的采访会话
class StartInterviewSession extends InterviewEvent {
  const StartInterviewSession();
}

/// 加载上次的采访会话
class LoadLastInterviewSession extends InterviewEvent {
  const LoadLastInterviewSession();
}

/// 回答当前问题
class AnswerQuestion extends InterviewEvent {
  final String answerText;
  final String? audioFilePath;
  final int? duration;

  const AnswerQuestion({
    required this.answerText,
    this.audioFilePath,
    this.duration,
  });

  @override
  List<Object?> get props => [answerText, audioFilePath, duration];
}

/// 跳过当前问题
class SkipQuestion extends InterviewEvent {
  const SkipQuestion();
}

/// 结束采访会话
class EndInterviewSession extends InterviewEvent {
  const EndInterviewSession();
}

/// 清除当前会话
class ClearCurrentSession extends InterviewEvent {
  const ClearCurrentSession();
}

/// 更新错误状态
class UpdateInterviewError extends InterviewEvent {
  final String error;

  const UpdateInterviewError(this.error);

  @override
  List<Object?> get props => [error];
}
