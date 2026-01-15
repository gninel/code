import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_session.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_question.dart';

void main() {
  group('InterviewSession', () {
    late InterviewSession session;
    late List<InterviewQuestion> questions;

    setUp(() {
      questions = [
        InterviewQuestion(
          id: 'q1',
          question: '问题1',
          order: 0,
          createdAt: DateTime(2025, 1, 1),
        ),
        InterviewQuestion(
          id: 'q2',
          question: '问题2',
          order: 1,
          createdAt: DateTime(2025, 1, 1),
          answer: '回答2',
          isAnswered: true,
        ),
        InterviewQuestion(
          id: 'q3',
          question: '问题3',
          order: 2,
          createdAt: DateTime(2025, 1, 1),
          isSkipped: true,
        ),
      ];

      session = InterviewSession(
        id: 'session-1',
        questions: questions,
        currentQuestionIndex: 1,
        isActive: true,
        createdAt: DateTime(2025, 1, 1),
      );
    });

    group('Constructor and basic properties', () {
      test('should create instance with required parameters', () {
        expect(session.id, 'session-1');
        expect(session.questions, hasLength(3));
        expect(session.currentQuestionIndex, 1);
        expect(session.isActive, true);
        expect(session.createdAt, DateTime(2025, 1, 1));
      });

      test('should default currentQuestionIndex to 0', () {
        final defaultSession = InterviewSession(
          id: 'session-2',
          questions: questions,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(defaultSession.currentQuestionIndex, 0);
      });

      test('should default isActive to true', () {
        final defaultSession = InterviewSession(
          id: 'session-2',
          questions: questions,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(defaultSession.isActive, true);
      });
    });

    group('currentQuestion getter', () {
      test('should return current question', () {
        expect(session.currentQuestion?.id, 'q2');
        expect(session.currentQuestion?.question, '问题2');
      });

      test('should return null when index out of bounds', () {
        final outOfBoundsSession = session.copyWith(
          currentQuestionIndex: 10,
        );

        expect(outOfBoundsSession.currentQuestion, isNull);
      });

      test('should return null when index negative', () {
        final negativeSession = session.copyWith(
          currentQuestionIndex: -1,
        );

        expect(negativeSession.currentQuestion, isNull);
      });
    });

    group('answeredQuestions getter', () {
      test('should return only answered questions', () {
        final answered = session.answeredQuestions;

        expect(answered, hasLength(1));
        expect(answered.first.id, 'q2');
        expect(answered.first.isAnswered, true);
      });
    });

    group('unansweredQuestions getter', () {
      test('should return unanswered questions including skipped', () {
        final unanswered = session.unansweredQuestions;

        expect(unanswered, hasLength(2));
        expect(unanswered.any((q) => q.id == 'q1'), true);
        expect(unanswered.any((q) => q.id == 'q3'), true);
      });
    });

    group('skippedQuestions getter', () {
      test('should return only skipped questions', () {
        final skipped = session.skippedQuestions;

        expect(skipped, hasLength(1));
        expect(skipped.first.id, 'q3');
        expect(skipped.first.isSkipped, true);
      });
    });

    group('hasNextQuestion getter', () {
      test('should return true when there are more questions', () {
        expect(session.hasNextQuestion, true);
      });

      test('should return false when at last question', () {
        final lastQuestionSession = session.copyWith(
          currentQuestionIndex: 2,
        );

        expect(lastQuestionSession.hasNextQuestion, false);
      });

      test('should return false when no questions', () {
        final emptySession = InterviewSession(
          id: 'session-empty',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(emptySession.hasNextQuestion, false);
      });
    });

    group('progress getter', () {
      test('should calculate progress correctly', () {
        expect(session.progress, 1 / 3);
      });

      test('should return 0 when no questions', () {
        final emptySession = InterviewSession(
          id: 'session-empty',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(emptySession.progress, 0.0);
      });

      test('should return 1 when all answered', () {
        final allAnsweredSession = InterviewSession(
          id: 'session-all',
          questions: [
            InterviewQuestion(
              id: 'q1',
              question: '问题1',
              order: 0,
              isAnswered: true,
              createdAt: DateTime(2025, 1, 1),
            ),
          ],
          createdAt: DateTime(2025, 1, 1),
        );

        expect(allAnsweredSession.progress, 1.0);
      });
    });

    group('copyWith', () {
      test('should create new instance with updated values', () {
        final updated = session.copyWith(
          currentQuestionIndex: 2,
          isActive: false,
          updatedAt: DateTime(2025, 1, 2),
        );

        expect(updated.id, session.id);
        expect(updated.currentQuestionIndex, 2);
        expect(updated.isActive, false);
        expect(updated.updatedAt, DateTime(2025, 1, 2));
        expect(session.isActive, true); // 原实例不变
      });
    });

    group('Equatable', () {
      test('should consider instances with same values as equal', () {
        final session1 = InterviewSession(
          id: 'session-1',
          questions: questions,
          currentQuestionIndex: 1,
          createdAt: DateTime(2025, 1, 1),
        );

        final session2 = InterviewSession(
          id: 'session-1',
          questions: questions,
          currentQuestionIndex: 1,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(session1, equals(session2));
        expect(session1.hashCode, equals(session2.hashCode));
      });

      test('should consider instances with different values as not equal', () {
        final session1 = InterviewSession(
          id: 'session-1',
          questions: questions,
          currentQuestionIndex: 1,
          createdAt: DateTime(2025, 1, 1),
        );

        final session2 = InterviewSession(
          id: 'session-2',
          questions: questions,
          currentQuestionIndex: 1,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(session1, isNot(equals(session2)));
      });
    });
  });
}
