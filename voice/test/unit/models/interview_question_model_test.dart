import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/models/interview_question_model.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_question.dart';

void main() {
  group('InterviewQuestionModel', () {
    const tId = 'question-1';
    const tQuestion = '您还记得童年时最难忘的一次经历吗？';
    const tOrder = 0;
    final tCreatedAt = DateTime.utc(2025, 1, 1, 12, 0, 0);
    const tJson = {
      'id': tId,
      'question': tQuestion,
      'answer': null,
      'order': tOrder,
      'isAnswered': false,
      'isSkipped': false,
      'createdAt': '2025-01-01T12:00:00.000Z',
    };

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = InterviewQuestion(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        final model = InterviewQuestionModel.fromEntity(entity);

        expect(model.id, tId);
        expect(model.question, tQuestion);
        expect(model.order, tOrder);
        expect(model.createdAt, tCreatedAt);
      });
    });

    group('fromJson', () {
      test('should create model from JSON', () {
        final model = InterviewQuestionModel.fromJson(tJson);

        expect(model.id, tId);
        expect(model.question, tQuestion);
        expect(model.answer, isNull);
        expect(model.order, tOrder);
        expect(model.isAnswered, false);
        expect(model.isSkipped, false);
        expect(model.createdAt, DateTime.utc(2025, 1, 1, 12, 0, 0));
      });

      test('should handle null optional fields', () {
        final json = {
          'id': tId,
          'question': tQuestion,
          'order': tOrder,
          'isAnswered': 0,
          'isSkipped': 0,
          'createdAt': '2025-01-01T12:00:00.000Z',
        };

        final model = InterviewQuestionModel.fromJson(json);

        expect(model.answer, isNull);
        expect(model.isAnswered, false);
        expect(model.isSkipped, false);
      });

      test('should parse boolean integers correctly', () {
        final json = {
          'id': tId,
          'question': tQuestion,
          'answer': '回答内容',
          'order': tOrder,
          'isAnswered': 1,
          'isSkipped': 1,
          'createdAt': '2025-01-01T12:00:00.000Z',
        };

        final model = InterviewQuestionModel.fromJson(json);

        expect(model.isAnswered, true);
        expect(model.isSkipped, true);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final model = InterviewQuestionModel(
          id: tId,
          question: tQuestion,
          order: tOrder,
          createdAt: tCreatedAt,
        );

        final json = model.toJson();

        expect(json['id'], tId);
        expect(json['question'], tQuestion);
        expect(json['order'], tOrder);
        expect(json['isAnswered'], false);
        expect(json['isSkipped'], false);
        expect(json['createdAt'], tCreatedAt.toIso8601String());
      });

      test('should include answer when present', () {
        final model = InterviewQuestionModel(
          id: tId,
          question: tQuestion,
          answer: '回答内容',
          order: tOrder,
          createdAt: tCreatedAt,
        );

        final json = model.toJson();

        expect(json['answer'], '回答内容');
      });
    });

    group('Serialization round-trip', () {
      test('should maintain data integrity through serialize/deserialize', () {
        final original = InterviewQuestionModel(
          id: tId,
          question: tQuestion,
          answer: '回答内容',
          order: tOrder,
          isAnswered: true,
          isSkipped: false,
          createdAt: tCreatedAt,
        );

        final json = original.toJson();
        final deserialized = InterviewQuestionModel.fromJson(json);

        expect(deserialized.id, original.id);
        expect(deserialized.question, original.question);
        expect(deserialized.answer, original.answer);
        expect(deserialized.order, original.order);
        expect(deserialized.isAnswered, original.isAnswered);
        expect(deserialized.isSkipped, original.isSkipped);
        expect(deserialized.createdAt, original.createdAt);
      });
    });
  });
}
