import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_question.dart';

void main() {
  group('InterviewQuestion', () {
    const tId = 'question-1';
    const tQuestion = '您还记得童年时最难忘的一次经历吗？';
    const tOrder = 0;
    final tCreatedAt = DateTime.utc(2025, 1, 1, 12, 0, 0);

    group('Constructor', () {
      test('should create instance with required parameters', () {
        final question = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        expect(question.id, tId);
        expect(question.question, tQuestion);
        expect(question.order, tOrder);
        expect(question.createdAt, tCreatedAt);
        expect(question.answer, isNull);
        expect(question.isAnswered, false);
        expect(question.isSkipped, false);
      });
    });

    group('copyWith', () {
      test('should create new instance with updated values', () {
        final original = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        final updated = original.copyWith(
          answer: '这是我的回答',
          isAnswered: true,
        );

        expect(updated.id, original.id);
        expect(updated.question, original.question);
        expect(updated.answer, '这是我的回答');
        expect(updated.isAnswered, true);
        expect(updated.isSkipped, false);
      });

      test('should preserve original instance', () {
        final original = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        original.copyWith(
          answer: '这是我的回答',
          isAnswered: true,
        );

        expect(original.answer, isNull);
        expect(original.isAnswered, false);
      });
    });

    group('Equatable', () {
      test('should consider instances with same values as equal', () {
        final question1 = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        final question2 = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        expect(question1, equals(question2));
        expect(question1.hashCode, equals(question2.hashCode));
      });

      test('should consider instances with different values as not equal', () {
        final question1 = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        final question2 = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
          isAnswered: true,
        );

        expect(question1, isNot(equals(question2)));
      });
    });
  });
}
