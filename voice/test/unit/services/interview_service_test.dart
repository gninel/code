import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:voice_autobiography_flutter/data/services/interview_service.dart';
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';
import 'package:voice_autobiography_flutter/data/services/database_service.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';

import 'interview_service_test.mocks.dart';

@GenerateMocks([
  DoubaoAiService,
  VoiceRecordRepository,
  DatabaseService,
])
void main() {
  InterviewService createService() {
    return InterviewService(
      MockDoubaoAiService(),
      MockVoiceRecordRepository(),
      MockDatabaseService(),
    );
  }

  group('InterviewService', () {
    // 移除共享的service和mock实例
    // 每个测试将创建自己的实例以避免mock状态污染

    group('startNewSession', () {
      late InterviewService service;
      late MockDoubaoAiService mockAiService;
      late MockVoiceRecordRepository mockRecordRepo;
      late MockDatabaseService mockDbService;

      setUp(() {
        mockAiService = MockDoubaoAiService();
        mockRecordRepo = MockVoiceRecordRepository();
        mockDbService = MockDatabaseService();

        service = InterviewService(
          mockAiService,
          mockRecordRepo,
          mockDbService,
        );
      });

      test('should create new session with first question', () async {
        when(mockRecordRepo.getAllVoiceRecords())
            .thenAnswer((_) => Future.value(const Right([])));

        when(mockAiService.generateInterviewQuestion(
          userContentSummary: anyNamed('userContentSummary'),
          answeredQuestions: [],
        )).thenAnswer((_) async => '第一个问题');

        when(mockDbService.transaction(any))
            .thenAnswer((invocation) async {
              final callback = invocation.positionalArguments[0] as dynamic;
              return await callback(null);
            });

        final result = await service.startNewSession();

        expect(result.isActive, true);
        expect(result.questions, hasLength(1));
        expect(result.questions.first.question, '第一个问题');
        expect(result.currentQuestionIndex, 0);
      });

      test('should save session to database', () async {
        when(mockRecordRepo.getAllVoiceRecords())
            .thenAnswer((_) => Future.value(const Right([])));

        when(mockAiService.generateInterviewQuestion(
          userContentSummary: anyNamed('userContentSummary'),
          answeredQuestions: [],
        )).thenAnswer((_) async => '第一个问题');

        when(mockDbService.transaction(any))
            .thenAnswer((invocation) async {
              final callback = invocation.positionalArguments[0] as dynamic;
              return await callback(null);
            });

        await service.startNewSession();

        verify(mockDbService.transaction(any)).called(1);
      });
    });

    group('loadLastSession', () {
      late InterviewService service;
      late MockDatabaseService mockDbService;

      setUp(() {
        mockDbService = MockDatabaseService();
        service = InterviewService(
          MockDoubaoAiService(),
          MockVoiceRecordRepository(),
          mockDbService,
        );
      });

      test('should return null when no session exists', () async {
        when(mockDbService.querySingle(any, orderBy: any))
            .thenAnswer((_) async => null);

        final result = await service.loadLastSession();

        expect(result, isNull);
      });

      test('should return null when session is inactive', () async {
        when(mockDbService.querySingle(any, orderBy: any))
            .thenAnswer((_) async => {
          'id': 'session-1',
          'current_question_index': 0,
          'is_active': 0,
          'created_at': 1704096000000,
        });

        when(mockDbService.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: any,
        )).thenAnswer((_) async => []);

        final result = await service.loadLastSession();

        expect(result, isNull);
      });

      test('should load and return active session', () async {
        final questionsJson = [
          {
            'id': 'q1',
            'question': '问题1',
            'answer': null,
            'order_index': 0,
            'is_answered': 1,
            'is_skipped': 0,
            'created_at': 1704096000000,
          },
        ];

        when(mockDbService.querySingle(any, orderBy: any))
            .thenAnswer((_) async => {
          'id': 'session-1',
          'current_question_index': 0,
          'is_active': 1,
          'created_at': 1704096000000,
        });

        when(mockDbService.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: any,
        )).thenAnswer((_) async => questionsJson);

        final result = await service.loadLastSession();

        expect(result, isNotNull);
        expect(result!.isActive, true);
        expect(result.questions, hasLength(1));
      });
    });

    group('endSession', () {
      late InterviewService service;
      late MockDoubaoAiService mockAiService;
      late MockVoiceRecordRepository mockRecordRepo;
      late MockDatabaseService mockDbService;

      setUp(() {
        mockAiService = MockDoubaoAiService();
        mockRecordRepo = MockVoiceRecordRepository();
        mockDbService = MockDatabaseService();

        service = InterviewService(
          mockAiService,
          mockRecordRepo,
          mockDbService,
        );
      });

      test('should mark session as inactive', () async {
        when(mockRecordRepo.getAllVoiceRecords())
            .thenAnswer((_) => Future.value(const Right([])));

        when(mockAiService.generateInterviewQuestion(
          userContentSummary: anyNamed('userContentSummary'),
          answeredQuestions: [],
        )).thenAnswer((_) async => '测试问题');

        when(mockDbService.transaction(any))
            .thenAnswer((invocation) async {
              final callback = invocation.positionalArguments[0] as dynamic;
              return await callback(null);
            });

        await service.startNewSession();
        await service.endSession();

        expect(service.currentSession, isNull);
      });

      test('should do nothing when no session exists', () async {
        await service.endSession();

        verifyNever(mockDbService.transaction(any));
      });
    });

    group('_buildContentSummary', () {
      late InterviewService service;
      late MockDoubaoAiService mockAiService;
      late MockVoiceRecordRepository mockRecordRepo;
      late MockDatabaseService mockDbService;

      setUp(() {
        mockAiService = MockDoubaoAiService();
        mockRecordRepo = MockVoiceRecordRepository();
        mockDbService = MockDatabaseService();

        service = InterviewService(
          mockAiService,
          mockRecordRepo,
          mockDbService,
        );
      });

      test('should return message when no records', () async {
        when(mockRecordRepo.getAllVoiceRecords())
            .thenAnswer((_) => Future.value(const Right([])));

        when(mockAiService.generateInterviewQuestion(
          userContentSummary: anyNamed('userContentSummary'),
          answeredQuestions: [],
        )).thenAnswer((_) async => '测试问题');

        when(mockDbService.transaction(any))
            .thenAnswer((invocation) async {
              final callback = invocation.positionalArguments[0] as dynamic;
              return await callback(null);
            });

        await service.startNewSession();

        // 验证生成的摘要
        final capturedArg = verify(mockAiService.generateInterviewQuestion(
          userContentSummary: captureAny,
          answeredQuestions: captureAny,
        )).captured.single;

        final summary = capturedArg.named['userContentSummary'] as String;
        expect(summary, contains('用户还没有任何录音记录'));
      });

      test('should build summary from voice records', () async {
        final records = [
          VoiceRecord(
            id: 'r1',
            title: '录音1',
            content: '这是录音内容1',
            timestamp: DateTime.now(),
            transcription: '转写内容1',
          ),
          VoiceRecord(
            id: 'r2',
            title: '录音2',
            content: '这是录音内容2',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRecordRepo.getAllVoiceRecords())
            .thenAnswer((_) => Future.value(Right(records)));

        when(mockAiService.generateInterviewQuestion(
          userContentSummary: anyNamed('userContentSummary'),
          answeredQuestions: [],
        )).thenAnswer((_) async => '测试问题');

        when(mockDbService.transaction(any))
            .thenAnswer((invocation) async {
              final callback = invocation.positionalArguments[0] as dynamic;
              return await callback(null);
            });

        await service.startNewSession();

        final capturedArg = verify(mockAiService.generateInterviewQuestion(
          userContentSummary: captureAny,
          answeredQuestions: captureAny,
        )).captured.single;

        final summary = capturedArg.named['userContentSummary'] as String;
        expect(summary, contains('共有 2 条录音记录'));
        expect(summary, contains('录音1'));
        expect(summary, contains('录音2'));
      });
    });
  });
}
