import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../data/services/interview_service.dart';
import 'interview_event.dart';
import 'interview_state.dart';

/// 采访模式 BLoC
@injectable
class InterviewBloc extends Bloc<InterviewEvent, InterviewState> {
  final InterviewService _interviewService;

  InterviewBloc(this._interviewService) : super(const InterviewState()) {
    on<StartInterviewSession>(_onStartSession);
    on<LoadLastInterviewSession>(_onLoadLastSession);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<SkipQuestion>(_onSkipQuestion);
    on<EndInterviewSession>(_onEndSession);
    on<ClearCurrentSession>(_onClearSession);
    on<UpdateInterviewError>(_onUpdateError);
  }

  Future<void> _onStartSession(
    StartInterviewSession event,
    Emitter<InterviewState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: InterviewStatus.loading,
        errorMessage: null,
      ));

      final session = await _interviewService.startNewSession();

      emit(state.copyWith(
        currentSession: session,
        status: InterviewStatus.ready,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '启动采访会话失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadLastSession(
    LoadLastInterviewSession event,
    Emitter<InterviewState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: InterviewStatus.loading,
        errorMessage: null,
      ));

      final session = await _interviewService.loadLastSession();

      if (session != null) {
        emit(state.copyWith(
          currentSession: session,
          status: InterviewStatus.ready,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: InterviewStatus.idle,
          errorMessage: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '加载会话失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAnswerQuestion(
    AnswerQuestion event,
    Emitter<InterviewState> emit,
  ) async {
    print('[InterviewBloc] _onAnswerQuestion called:');
    print('  - answerText: ${event.answerText}');
    print('  - audioFilePath: ${event.audioFilePath}');
    print('  - duration: ${event.duration}');
    print('  - hasCurrentQuestion: ${state.hasCurrentQuestion}');

    if (!state.hasCurrentQuestion) {
      print('[InterviewBloc] No current question to answer');
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '没有当前问题可回答',
      ));
      return;
    }

    try {
      print('[InterviewBloc] Setting status to saving...');
      emit(state.copyWith(
        status: InterviewStatus.saving,
        errorMessage: null,
      ));

      print('[InterviewBloc] Calling InterviewService.answerCurrentQuestion...');
      final updatedSession = await _interviewService.answerCurrentQuestion(
        event.answerText,
        audioFilePath: event.audioFilePath,
        duration: event.duration,
      );

      print('[InterviewBloc] Answer saved successfully!');
      print('  - Updated session questions: ${updatedSession.questions.length}');
      print('  - Current question index: ${updatedSession.currentQuestionIndex}');
      print('  - Answered questions: ${updatedSession.answeredQuestions.length}');

      emit(state.copyWith(
        currentSession: updatedSession,
        status: InterviewStatus.ready,
        errorMessage: null,
      ));

      print('[InterviewBloc] State updated with new session');
    } catch (e) {
      print('[InterviewBloc] ERROR saving answer: $e');
      print('[InterviewBloc] Stack trace: ${StackTrace.current}');
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '保存回答失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSkipQuestion(
    SkipQuestion event,
    Emitter<InterviewState> emit,
  ) async {
    if (!state.hasCurrentQuestion) {
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '没有当前问题可跳过',
      ));
      return;
    }

    try {
      emit(state.copyWith(
        status: InterviewStatus.saving,
        errorMessage: null,
      ));

      final updatedSession = await _interviewService.skipCurrentQuestion();

      emit(state.copyWith(
        currentSession: updatedSession,
        status: InterviewStatus.ready,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '跳过问题失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEndSession(
    EndInterviewSession event,
    Emitter<InterviewState> emit,
  ) async {
    try {
      await _interviewService.endSession();

      emit(state.copyWith(
        clearCurrentSession: true,
        status: InterviewStatus.completed,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InterviewStatus.error,
        errorMessage: '结束会话失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearSession(
    ClearCurrentSession event,
    Emitter<InterviewState> emit,
  ) async {
    emit(const InterviewState(
      status: InterviewStatus.idle,
      errorMessage: null,
    ));
  }

  Future<void> _onUpdateError(
    UpdateInterviewError event,
    Emitter<InterviewState> emit,
  ) async {
    emit(state.copyWith(
      status: InterviewStatus.error,
      errorMessage: event.error,
    ));
  }
}
