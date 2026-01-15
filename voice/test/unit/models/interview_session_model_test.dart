import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/models/interview_session_model.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_session.dart';
import 'package:voice_autobiography_flutter/domain/entities/interview_question.dart';

void main() {
  group('InterviewSessionModel', () {
    late InterviewSession session;
    late List<InterviewQuestion> questions;

    setUp(() {
      questions = [
        InterviewQuestion(
          id: 'q1',
          question: '问题1',
          order: 0,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
        ),
        InterviewQuestion(
          id: 'q2',
          question: '问题2',
          order: 1,
          createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
          answer: '回答2',
          isAnswered: true,
        ),
      ];

      session = InterviewSession(
        id: 'session-1',
        questions: questions,
        currentQuestionIndex: 1,
        isActive: true,
        createdAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
      );
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final model = InterviewSessionModel.fromEntity(session);

        expect(model.id, session.id);
        expect(model.questions, hasLength(session.questions.length));
        expect(model.currentQuestionIndex, session.currentQuestionIndex);
        expect(model.isActive, session.isActive);
        expect(model.createdAt, session.createdAt);
      });
    });

    group('fromJson', () {
      final tJson = {
        'id': 'session-1',
        'questions': [
          {
            'id': 'q1',
            'question': '问题1',
            'answer': null,
            'order': 0,
            'isAnswered': 0,
            'isSkipped': 0,
            'createdAt': '2025-01-01T12:00:00.000Z',
          },
          {
            'id': 'q2',
            'question': '问题2',
            'answer': '回答2',
            'order': 1,
            'isAnswered': 1,
            'isSkipped': 0,
            'createdAt': '2025-01-01T12:00:00.000Z',
          },
        ],
        'currentQuestionIndex': 1,
        'isActive': 1,
        'createdAt': '2025-01-01T12:00:00.000Z',
        'updatedAt': '2025-01-02T12:00:00.000Z',
      };

      test('should create model from JSON', () {
        final model = InterviewSessionModel.fromJson(tJson);

        expect(model.id, 'session-1');
        expect(model.questions, hasLength(2));
        expect(model.currentQuestionIndex, 1);
        expect(model.isActive, true);
        expect(model.createdAt, DateTime.utc(2025, 1, 1, 12, 0, 0));
        expect(model.updatedAt, DateTime.utc(2025, 1, 2, 12, 0, 0));
      });

      test('should handle null questions list', () {
        final json = {
          'id': 'session-empty',
          'questions': null,
          'currentQuestionIndex': 0,
          'isActive': 1,
          'createdAt': '2025-01-01T12:00:00.000Z',
        };

        final model = InterviewSessionModel.fromJson(json);

        expect(model.questions, isEmpty);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'session-min',
          'currentQuestionIndex': 0,
          'isActive': 1,
          'createdAt': '2025-01-01T12:00:00.000Z',
        };

        final model = InterviewSessionModel.fromJson(json);

        expect(model.questions, isEmpty);
        expect(model.updatedAt, isNull);
      });

      test('should parse boolean integers correctly', () {
        final json = {
          'id': 'session-min',
          'currentQuestionIndex': 0,
          'isActive': 0,
          'createdAt': '2025-01-01T12:00:00.000Z',
        };

        final model = InterviewSessionModel.fromJson(json);

        expect(model.isActive, false);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final model = InterviewSessionModel.fromEntity(session);
        final json = model.toJson();

        expect(json['id'], session.id);
        expect(json['questions'], isList);
        expect(json['currentQuestionIndex'], session.currentQuestionIndex);
        expect(json['isActive'], session.isActive);
        expect(json['createdAt'], session.createdAt.toIso8601String());
      });

      test('should include updatedAt when present', () {
        final sessionWithUpdate = session.copyWith(
          updatedAt: DateTime.utc(2025, 1, 2, 12, 0, 0),
        );

        final model = InterviewSessionModel.fromEntity(sessionWithUpdate);
        final json = model.toJson();

        expect(json['updatedAt'], '2025-01-02T12:00:00.000Z');
      });
    });

    group('Serialization round-trip', () {
      test('should maintain data integrity through serialize/deserialize', () {
        final original = InterviewSessionModel.fromEntity(session);
        final json = original.toJson();
        final deserialized = InterviewSessionModel.fromJson(json);

        expect(deserialized.id, original.id);
        expect(deserialized.questions, hasLength(original.questions.length));
        expect(deserialized.currentQuestionIndex, original.currentQuestionIndex);
        expect(deserialized.isActive, original.isActive);
        expect(deserialized.createdAt, original.createdAt);
      });
    });
  });
}
