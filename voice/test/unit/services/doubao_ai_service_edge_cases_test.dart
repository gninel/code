import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';
import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';

import 'doubao_ai_service_edge_cases_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('豆包AI服务边界情况测试', () {
    late MockDio mockDio;
    late DoubaoAiService aiService;

    setUp(() {
      mockDio = MockDio();
      // 注意：这里需要修改DoubaoAiService构造函数以接受自定义Dio实例
      // 或者使用依赖注入框架
    });

    group('TC9: AI响应格式处理', () {
      test('TC9.1 - 应该正确处理content为空但reasoning_content有内容的响应', () async {
        // 准备测试数据 - 模拟真实的豆包AI响应格式
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'finish_reason': 'length',
                'index': 0,
                'logprobs': null,
                'message': {
                  'content': '', // content为空
                  'reasoning_content': '''
我现在需要生成一个填补空白型的问题，因为处于采访初期。
用户提到童年在湖南小镇，但没提父母的情况。
那问题可以具体点："你童年在湖南小镇的日子无忧无虑，那当时你的父母是做什么工作的？他们平时和你相处的时间多吗？"
这样既问了家庭环境，又问了相处情况。
''',
                  'role': 'assistant',
                }
              }
            ],
            'created': 1766927240,
            'id': 'test-id',
            'model': 'doubao-seed-1-6-251015',
            'usage': {
              'completion_tokens': 400,
              'prompt_tokens': 1007,
              'total_tokens': 1407,
            }
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // 执行测试
        final question = await aiService.generateInterviewQuestion(
          userContentSummary: '测试内容',
          answeredQuestions: [],
        );

        // 验证
        expect(question, isNotNull);
        expect(question, isNotEmpty);
        expect(question.contains('父母'), isTrue);
        expect(question.contains('？'), isTrue);
        print('成功从reasoning_content提取问题: $question');
      });

      test('TC9.2 - 应该正确处理content有内容的正常响应', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {
                  'content': '你童年时最好的朋友是谁？你们之间有什么难忘的故事吗？',
                  'role': 'assistant',
                }
              }
            ],
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        final question = await aiService.generateInterviewQuestion(
          userContentSummary: '测试内容',
          answeredQuestions: [],
        );

        expect(question, equals('你童年时最好的朋友是谁？你们之间有什么难忘的故事吗？'));
      });

      test('TC9.3 - 应该在content和reasoning_content都为空时抛出异常', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'finish_reason': 'length',
                'message': {
                  'content': '',
                  'reasoning_content': '',
                  'role': 'assistant',
                }
              }
            ],
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        expect(
          () => aiService.generateInterviewQuestion(
            userContentSummary: '测试内容',
            answeredQuestions: [],
          ),
          throwsA(isA<AiGenerationException>()),
        );
      });
    });

    group('TC10: Token限制处理', () {
      test('TC10.1 - 应该使用足够大的max_completion_tokens避免截断', () async {
        // 验证请求参数
        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((invocation) async {
          final data = invocation.namedArguments[const Symbol('data')] as Map;
          final maxTokens = data['max_completion_tokens'] as int;

          // 验证token限制足够大
          expect(maxTokens, greaterThanOrEqualTo(1000),
              reason: '应该设置足够大的token限制以避免问题被截断');

          return Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
            data: {
              'choices': [
                {
                  'finish_reason': 'stop', // 没有被截断
                  'message': {
                    'content': '测试问题',
                    'role': 'assistant',
                  }
                }
              ],
            },
          );
        });

        await aiService.generateInterviewQuestion(
          userContentSummary: '测试内容',
          answeredQuestions: [],
        );

        verify(mockDio.post(any, data: anyNamed('data'))).called(1);
      });

      test('TC10.2 - 应该能处理因token限制导致的截断响应', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'finish_reason': 'length', // 因长度限制而停止
                'message': {
                  'content': '',
                  'reasoning_content': '这是一个被截断的思考过程，最后的问题是："你"',
                  'role': 'assistant',
                }
              }
            ],
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // 应该能从不完整的reasoning_content中提取有效内容或抛出异常
        try {
          final question = await aiService.generateInterviewQuestion(
            userContentSummary: '测试内容',
            answeredQuestions: [],
          );
          // 如果成功提取，验证不为空
          expect(question, isNotEmpty);
        } catch (e) {
          // 如果无法提取，应该抛出明确的异常
          expect(e, isA<AiGenerationException>());
        }
      });
    });

    group('TC11: 问题提取策略', () {
      test('TC11.1 - 应该从中文引号中提取问题', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'finish_reason': 'length',
                'message': {
                  'content': '',
                  'reasoning_content': '''
用户没提父母，这个是家庭环境的空白点。所以选父母相关的问题更好。
再调整语气，更亲切："你童年在湖南小镇的日子无忧无虑，那当时你的父母是做什么工作的？他们平时和你相处的时间多吗？有没有什么他们带你做的事让你至今印象深刻？"
''',
                  'role': 'assistant',
                }
              }
            ],
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        final question = await aiService.generateInterviewQuestion(
          userContentSummary: '测试内容',
          answeredQuestions: [],
        );

        expect(question, contains('父母'));
        expect(question, contains('？'));
        expect(question.length, greaterThan(20)); // 应该是完整的问题
      });

      test('TC11.2 - 应该从英文引号中提取问题', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {
                  'content': '',
                  'reasoning_content': 'Let me ask: "What was your favorite childhood memory?"',
                  'role': 'assistant',
                }
              }
            ],
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        final question = await aiService.generateInterviewQuestion(
          userContentSummary: '测试内容',
          answeredQuestions: [],
        );

        expect(question, contains('childhood memory'));
        expect(question, contains('?'));
      });

      test('TC11.3 - 应该从无引号的句子中提取问题', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {
                  'content': '',
                  'reasoning_content': '那问题可以是：你在大学时有没有参加过什么社团或活动？',
                  'role': 'assistant',
                }
              }
            ],
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        final question = await aiService.generateInterviewQuestion(
          userContentSummary: '测试内容',
          answeredQuestions: [],
        );

        expect(question, contains('社团'));
        expect(question, contains('活动'));
        expect(question, contains('？'));
      });
    });

    group('TC12: 错误处理增强', () {
      test('TC12.1 - 应该在响应格式错误时提供详细的错误信息', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'choices': [], // 空的choices数组
          },
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        expect(
          () => aiService.generateInterviewQuestion(
            userContentSummary: '测试内容',
            answeredQuestions: [],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('TC12.2 - 应该在网络超时时正确重试或抛出异常', () async {
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        ));

        expect(
          () => aiService.generateInterviewQuestion(
            userContentSummary: '测试内容',
            answeredQuestions: [],
          ),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
