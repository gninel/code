// 豆包 AI 服务扩展测试 - 提高覆盖率
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';
import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/core/services/prompt_loader_service.dart';

import 'doubao_ai_service_extended_test.mocks.dart';

@GenerateMocks([Dio, Response, PromptLoaderService])
void main() {
  late DoubaoAiService service;
  late MockDio mockDio;
  late MockPromptLoaderService mockPromptLoader;

  setUp(() {
    mockDio = MockDio();
    mockPromptLoader = MockPromptLoaderService();

    // Default interceptors behavior
    when(mockDio.interceptors).thenReturn(Interceptors());
    when(mockDio.httpClientAdapter).thenReturn(HttpClientAdapter());
    when(mockDio.options).thenReturn(BaseOptions());

    // Mock all PromptLoaderService methods
    when(mockPromptLoader.getAutobiographyGenerationSystemPrompt())
        .thenReturn('System prompt');
    when(mockPromptLoader.getAutobiographyGenerationPrompt(
      combinedContent: anyNamed('combinedContent'),
      style: anyNamed('style'),
      targetWordCount: anyNamed('targetWordCount'),
    )).thenReturn('User prompt');
    when(mockPromptLoader.getStructureAnalysisSystemPrompt())
        .thenReturn('Structure system prompt');
    when(mockPromptLoader.getStructureAnalysisPrompt(any, any))
        .thenReturn('Structure user prompt');
    when(mockPromptLoader.getChapterGenerationSystemPrompt())
        .thenReturn('Chapter system prompt');
    when(mockPromptLoader.getNewChapterPrompt(any))
        .thenReturn('New chapter prompt');
    when(mockPromptLoader.getMergeChapterPrompt(any, any))
        .thenReturn('Merge chapter prompt');
    when(mockPromptLoader.getTitleGenerationPrompt(any))
        .thenReturn(('Title system', 'Title user'));
    when(mockPromptLoader.getSummaryGenerationPrompt(any))
        .thenReturn(('Summary system', 'Summary user'));
    when(mockPromptLoader.getContentOptimizationPrompt(
      content: anyNamed('content'),
      optimizationType: anyNamed('optimizationType'),
    )).thenReturn(('Optimization system', 'Optimization user'));
    when(mockPromptLoader.getInterviewQuestionPrompt(
      userContentSummary: anyNamed('userContentSummary'),
      answeredQuestions: anyNamed('answeredQuestions'),
    )).thenReturn(('Interview system', 'Interview user'));

    service = DoubaoAiService(mockPromptLoader, dio: mockDio);
  });

  group('DoubaoAiService - optimizeAutobiography', () {
    const successResponse = {
      'choices': [
        {
          'message': {'content': '优化后的内容'}
        }
      ]
    };

    test('应该成功优化自传内容 - clarity', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.optimizeAutobiography(
        originalContent: '原始内容',
        optimizationType: OptimizationType.clarity,
      );

      expect(result, equals('优化后的内容'));
    });

    test('应该成功优化自传内容 - fluency', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.optimizeAutobiography(
        originalContent: '原始内容',
        optimizationType: OptimizationType.fluency,
      );

      expect(result, equals('优化后的内容'));
    });

    test('应该成功优化自传内容 - style', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.optimizeAutobiography(
        originalContent: '原始内容',
        optimizationType: OptimizationType.style,
      );

      expect(result, equals('优化后的内容'));
    });

    test('应该成功优化自传内容 - structure', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.optimizeAutobiography(
        originalContent: '原始内容',
        optimizationType: OptimizationType.structure,
      );

      expect(result, equals('优化后的内容'));
    });

    test('应该成功优化自传内容 - conciseness', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.optimizeAutobiography(
        originalContent: '原始内容',
        optimizationType: OptimizationType.conciseness,
      );

      expect(result, equals('优化后的内容'));
    });

    test('空内容时应抛出异常', () async {
      const emptyResponse = {
        'choices': [
          {
            'message': {'content': ''}
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(emptyResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      expect(
        () => service.optimizeAutobiography(originalContent: '原始内容'),
        throwsA(isA<AiGenerationException>()),
      );
    });
  });

  group('DoubaoAiService - generateChapterContent', () {
    const successResponse = {
      'choices': [
        {
          'message': {'content': '生成的章节内容'}
        }
      ]
    };

    test('应该生成新章节内容', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateChapterContent(
        newVoiceContent: '语音内容',
      );

      expect(result, equals('生成的章节内容'));
    });

    test('应该合并现有章节内容', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateChapterContent(
        originalContent: '现有内容',
        newVoiceContent: '新语音内容',
      );

      expect(result, equals('生成的章节内容'));
    });

    test('应该处理带思考标签的响应', () async {
      const responseWithThinkTags = {
        'choices': [
          {
            'message': {
              'content':
                  '<think>思考过程</think>实际内容<think_never_used_123>更多思考</think_never_used_123>'
            }
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(responseWithThinkTags);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateChapterContent(
        newVoiceContent: '语音内容',
      );

      expect(result, equals('实际内容'));
      expect(result.contains('<think>'), false);
    });
  });

  group('DoubaoAiService - generateTitle', () {
    test('应该成功生成标题', () async {
      const successResponse = {
        'choices': [
          {
            'message': {'content': '我的人生故事'}
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateTitle('自传内容');

      expect(result, equals('我的人生故事'));
    });

    test('应该清理标题中的特殊字符', () async {
      const responseWithSpecialChars = {
        'choices': [
          {
            'message': {'content': '# "我的人生故事" *\n'}
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(responseWithSpecialChars);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateTitle('自传内容');

      expect(result, equals('我的人生故事'));
      expect(result.contains('#'), false);
      expect(result.contains('"'), false);
      expect(result.contains('*'), false);
      expect(result.contains('\n'), false);
    });
  });

  group('DoubaoAiService - generateSummary', () {
    test('应该成功生成摘要', () async {
      const successResponse = {
        'choices': [
          {
            'message': {'content': '这是一段精彩的人生经历摘要'}
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateSummary('自传内容');

      expect(result, equals('这是一段精彩的人生经历摘要'));
    });
  });

  group('DoubaoAiService - generateInterviewQuestion', () {
    test('应该成功生成采访问题', () async {
      const successResponse = {
        'choices': [
          {
            'message': {'content': '你最难忘的童年记忆是什么？'}
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateInterviewQuestion(
        userContentSummary: '用户已经分享了童年的故事',
        answeredQuestions: ['你的家乡在哪里？'],
      );

      expect(result, equals('你最难忘的童年记忆是什么？'));
    });

    test('应该从reasoning_content中提取问题', () async {
      const responseWithReasoningContent = {
        'choices': [
          {
            'message': {
              'content': null,
              'reasoning_content':
                  '我需要问一个关于用户家庭的问题。最好的问题是："你的父母是做什么工作的？"这个问题可以了解用户的家庭背景。'
            }
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(responseWithReasoningContent);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateInterviewQuestion(
        userContentSummary: '用户分享了童年',
        answeredQuestions: [],
      );

      expect(result, contains('？'));
      expect(result.length, greaterThan(5));
    });

    test('DioException 401 应该抛出 invalidApiKey', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
        ),
      );

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenThrow(dioException);

      expect(
        () => service.generateInterviewQuestion(
          userContentSummary: '测试',
          answeredQuestions: [],
        ),
        throwsA(isA<AiGenerationException>().having(
          (e) => e.code,
          'code',
          'INVALID_API_KEY',
        )),
      );
    });

    test('DioException 429 应该抛出 quotaExceeded', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 429,
        ),
      );

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenThrow(dioException);

      expect(
        () => service.generateInterviewQuestion(
          userContentSummary: '测试',
          answeredQuestions: [],
        ),
        throwsA(isA<AiGenerationException>().having(
          (e) => e.code,
          'code',
          'QUOTA_EXCEEDED',
        )),
      );
    });
  });

  group('DoubaoAiService - generateAutobiography 不同风格', () {
    const successResponse = {
      'choices': [
        {
          'message': {'content': '生成的自传内容'}
        }
      ]
    };

    test('narrative 风格应该成功', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateAutobiography(
        voiceContents: ['内容'],
        style: AutobiographyStyle.narrative,
      );

      expect(result, isNotNull);
    });

    test('emotional 风格应该成功', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateAutobiography(
        voiceContents: ['内容'],
        style: AutobiographyStyle.emotional,
      );

      expect(result, isNotNull);
    });

    test('achievement 风格应该成功', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateAutobiography(
        voiceContents: ['内容'],
        style: AutobiographyStyle.achievement,
      );

      expect(result, isNotNull);
    });

    test('chronological 风格应该成功', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateAutobiography(
        voiceContents: ['内容'],
        style: AutobiographyStyle.chronological,
      );

      expect(result, isNotNull);
    });

    test('应该支持自定义字数', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.generateAutobiography(
        voiceContents: ['内容'],
        wordCount: 5000,
      );

      expect(result, isNotNull);
    });
  });
}
