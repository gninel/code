import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/interview/interview_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/interview/interview_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/interview/interview_state.dart';
import 'package:voice_autobiography_flutter/data/services/interview_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_session.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_question.dart';

import 'interview_bloc_test.mocks.dart';

@GenerateMocks([InterviewService])
void main() {
  group('InterviewBloc', () {
    late InterviewBloc bloc;
    late MockInterviewService mockService;

    setUp(() {
      mockService = MockInterviewService();
      bloc = InterviewBloc(mockService);
    });

    tearDown(() {
      bloc.close();
    });

    group('初始状态', () {
      test('应该返回初始状态', () {
        expect(bloc.state, equals(const InterviewState()));
      });

      test('状态应该为idle', () {
        expect(bloc.state.status, equals(InterviewStatus.idle));
      });

      test('不应该有活跃会话', () {
        expect(bloc.state.hasActiveSession, false);
      });
    });

    group('StartInterviewSession', () {
      final testSession = InterviewSession(
        id: 'session-1',
        questions: [
          InterviewQuestion(
            id: 'q1',
            question: '第一个问题',
            order: 0,
            createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          ),
        ],
        currentQuestionIndex: 0,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );

      test('成功时应该发出loading和ready状态', () async {
        when(mockService.startNewSession())
            .thenAnswer((_) async => testSession);

        final expected = [
          const InterviewState(status: InterviewStatus.loading),
          InterviewState(
            status: InterviewStatus.ready,
            currentSession: testSession,
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const StartInterviewSession());
      });

      test('失败时应该发出error状态', () async {
        when(mockService.startNewSession())
            .thenThrow(Exception('启动失败'));

        final expected = [
          const InterviewState(status: InterviewStatus.loading),
          const InterviewState(
            status: InterviewStatus.error,
            errorMessage: '启动采访会话失败: Exception: 启动失败',
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const StartInterviewSession());
      });

      test('成功后应该有活跃会话', () async {
        when(mockService.startNewSession())
            .thenAnswer((_) async => testSession);

        bloc.add(const StartInterviewSession());
        await bloc.stream.skip(1).first;

        expect(bloc.state.hasActiveSession, true);
        expect(bloc.state.currentSession, equals(testSession));
      });
    });

    group('LoadLastInterviewSession', () {
      final testSession = InterviewSession(
        id: 'session-last',
        questions: [
          InterviewQuestion(
            id: 'q1',
            question: '上次的第一个问题',
            order: 0,
            createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          ),
        ],
        currentQuestionIndex: 0,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );

      test('成功加载会话时应该发出ready状态', () async {
        when(mockService.loadLastSession())
            .thenAnswer((_) async => testSession);

        final expected = [
          const InterviewState(status: InterviewStatus.loading),
          InterviewState(
            status: InterviewStatus.ready,
            currentSession: testSession,
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const LoadLastInterviewSession());
      });

      test('没有会话时应该发出idle状态', () async {
        when(mockService.loadLastSession())
            .thenAnswer((_) async => null);

        final expected = [
          const InterviewState(status: InterviewStatus.loading),
          const InterviewState(status: InterviewStatus.idle),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const LoadLastInterviewSession());
      });

      test('失败时应该发出error状态', () async {
        when(mockService.loadLastSession())
            .thenThrow(Exception('加载失败'));

        final expected = [
          const InterviewState(status: InterviewStatus.loading),
          const InterviewState(
            status: InterviewStatus.error,
            errorMessage: '加载会话失败: Exception: 加载失败',
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const LoadLastInterviewSession());
      });
    });

    group('AnswerQuestion', () {
      final testSession = InterviewSession(
        id: 'session-1',
        questions: [
          InterviewQuestion(
            id: 'q1',
            question: '第一个问题',
            order: 0,
            createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          ),
        ],
        currentQuestionIndex: 0,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );

      final answeredSession = InterviewSession(
        id: 'session-1',
        questions: [
          InterviewQuestion(
            id: 'q1',
            question: '第一个问题',
            answer: '这是我的回答',
            order: 0,
            isAnswered: true,
            createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          ),
        ],
        currentQuestionIndex: 1,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );

      test('成功回答时应该发出saving和ready状态', () async {
        when(mockService.answerCurrentQuestion(
          any,
          audioFilePath: anyNamed('audioFilePath'),
          duration: anyNamed('duration'),
        )).thenAnswer((_) async => answeredSession);

        // 先设置有会话的状态
        bloc.emit(bloc.state.copyWith(currentSession: testSession));

        final expected = [
          InterviewState(
            status: InterviewStatus.saving,
            currentSession: testSession,
          ),
          InterviewState(
            status: InterviewStatus.ready,
            currentSession: answeredSession,
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const AnswerQuestion(
          answerText: '这是我的回答',
          audioFilePath: '/path/to/audio.m4a',
          duration: 5000,
        ));
      });

      test('失败时应该发出error状态', () async {
        when(mockService.answerCurrentQuestion(
          any,
          audioFilePath: anyNamed('audioFilePath'),
          duration: anyNamed('duration'),
        )).thenThrow(Exception('保存失败'));

        bloc.emit(bloc.state.copyWith(currentSession: testSession));

        final expected = [
          InterviewState(
            status: InterviewStatus.saving,
            currentSession: testSession,
          ),
          InterviewState(
            status: InterviewStatus.error,
            currentSession: testSession,
            errorMessage: '保存回答失败: Exception: 保存失败',
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const AnswerQuestion(
          answerText: '回答',
          audioFilePath: '/path/to/audio.m4a',
          duration: 5000,
        ));
      });

      test('没有当前问题时应该发出error状态', () async {
        final emptySession = InterviewSession(
          id: 'session-empty',
          questions: const [],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: emptySession));

        bloc.add(const AnswerQuestion(
          answerText: '回答',
          audioFilePath: '/path/to/audio.m4a',
          duration: 5000,
        ));

        // 等待事件处理完成
        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state.status, equals(InterviewStatus.error));
        expect(bloc.state.errorMessage, equals('没有当前问题可回答'));
      });
    });

    group('SkipQuestion', () {
      final testSession = InterviewSession(
        id: 'session-1',
        questions: [
          InterviewQuestion(
            id: 'q1',
            question: '第一个问题',
            order: 0,
            createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          ),
        ],
        currentQuestionIndex: 0,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );

      final skippedSession = InterviewSession(
        id: 'session-1',
        questions: [
          InterviewQuestion(
            id: 'q1',
            question: '第一个问题',
            order: 0,
            isSkipped: true,
            createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          ),
        ],
        currentQuestionIndex: 1,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );

      test('成功跳过时应该发出saving和ready状态', () async {
        when(mockService.skipCurrentQuestion())
            .thenAnswer((_) async => skippedSession);

        bloc.emit(bloc.state.copyWith(currentSession: testSession));

        final expected = [
          InterviewState(
            status: InterviewStatus.saving,
            currentSession: testSession,
          ),
          InterviewState(
            status: InterviewStatus.ready,
            currentSession: skippedSession,
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const SkipQuestion());
      });

      test('失败时应该发出error状态', () async {
        when(mockService.skipCurrentQuestion())
            .thenThrow(Exception('跳过失败'));

        bloc.emit(bloc.state.copyWith(currentSession: testSession));

        final expected = [
          InterviewState(
            status: InterviewStatus.saving,
            currentSession: testSession,
          ),
          InterviewState(
            status: InterviewStatus.error,
            currentSession: testSession,
            errorMessage: '跳过问题失败: Exception: 跳过失败',
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const SkipQuestion());
      });
    });

    group('EndInterviewSession', () {
      test('成功结束时应该发出completed状态', () async {
        when(mockService.endSession())
            .thenAnswer((_) async => {});

        final testSession = InterviewSession(
          id: 'session-1',
          questions: const [],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: testSession));

        final expected = [
          const InterviewState(
            status: InterviewStatus.completed,
            currentSession: null,
            errorMessage: null,
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder(expected),
        );

        bloc.add(const EndInterviewSession());
      });

      test('失败时应该发出error状态', () async {
        when(mockService.endSession())
            .thenThrow(Exception('结束失败'));

        final testSession = InterviewSession(
          id: 'session-1',
          questions: const [],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: testSession));

        bloc.add(const EndInterviewSession());

        // 等待事件处理
        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state.status, equals(InterviewStatus.error));
        expect(bloc.state.errorMessage, contains('结束会话失败'));
      });
    });

    group('ClearCurrentSession', () {
      test('应该清除当前会话并回到idle状态', () async {
        final testSession = InterviewSession(
          id: 'session-1',
          questions: const [],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(
          currentSession: testSession,
          status: InterviewStatus.ready,
        ));

        bloc.add(const ClearCurrentSession());

        // 等待事件处理
        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state.status, equals(InterviewStatus.idle));
        expect(bloc.state.currentSession, isNull);
      });
    });

    group('UpdateInterviewError', () {
      test('应该更新错误消息', () async {
        bloc.add(const UpdateInterviewError('自定义错误'));

        // 等待事件处理
        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state.status, equals(InterviewStatus.error));
        expect(bloc.state.errorMessage, equals('自定义错误'));
      });
    });

    group('状态计算属性', () {
      test('hasCurrentQuestion应该正确反映是否有当前问题', () async {
        final sessionWithQuestion = InterviewSession(
          id: 'session-1',
          questions: [
            InterviewQuestion(
              id: 'q1',
              question: '问题1',
              order: 0,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
          ],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: sessionWithQuestion));
        // emit() 同步设置状态，无需等待stream
        expect(bloc.state.hasCurrentQuestion, true);

        final emptySession = InterviewSession(
          id: 'session-empty',
          questions: const [],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: emptySession));
        // emit() 同步设置状态，无需等待stream
        expect(bloc.state.hasCurrentQuestion, false);
      });

      test('progress应该正确计算进度', () async {
        final session = InterviewSession(
          id: 'session-1',
          questions: [
            InterviewQuestion(
              id: 'q1',
              question: '问题1',
              order: 0,
              isAnswered: true,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
            InterviewQuestion(
              id: 'q2',
              question: '问题2',
              order: 1,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
          ],
          currentQuestionIndex: 1,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: session));
        // emit() 同步设置状态，无需等待stream
        expect(bloc.state.progress, equals(0.5));
      });

      test('answeredCount应该正确计算已回答数量', () async {
        final session = InterviewSession(
          id: 'session-1',
          questions: [
            InterviewQuestion(
              id: 'q1',
              question: '问题1',
              order: 0,
              isAnswered: true,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
            InterviewQuestion(
              id: 'q2',
              question: '问题2',
              order: 1,
              isAnswered: true,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
            InterviewQuestion(
              id: 'q3',
              question: '问题3',
              order: 2,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
          ],
          currentQuestionIndex: 2,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: session));
        // emit() 同步设置状态，无需等待stream
        expect(bloc.state.answeredCount, equals(2));
        expect(bloc.state.totalQuestions, equals(3));
      });

      test('currentQuestion应该返回当前问题文本', () async {
        final session = InterviewSession(
          id: 'session-1',
          questions: [
            InterviewQuestion(
              id: 'q1',
              question: '这是第一个问题',
              order: 0,
              createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
            ),
          ],
          currentQuestionIndex: 0,
          isActive: true,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        );

        bloc.emit(bloc.state.copyWith(currentSession: session));
        // emit() 同步设置状态，无需等待stream
        expect(bloc.state.currentQuestion, equals('这是第一个问题'));
      });
    });
  });
}
