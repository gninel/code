// 豆包 AI 服务综合测试
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';
import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';
import 'package:voice_autobiography_flutter/core/services/prompt_loader_service.dart';

import 'doubao_ai_service_comprehensive_test.mocks.dart';

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
    // Default HttpClientAdapter
    when(mockDio.httpClientAdapter).thenReturn(HttpClientAdapter());
    // Default options
    when(mockDio.options).thenReturn(BaseOptions());

    // Mock PromptLoaderService methods
    when(mockPromptLoader.getAutobiographyGenerationSystemPrompt())
        .thenReturn('System prompt for autobiography generation');
    when(mockPromptLoader.getAutobiographyGenerationPrompt(
      combinedContent: anyNamed('combinedContent'),
      style: anyNamed('style'),
      targetWordCount: anyNamed('targetWordCount'),
    )).thenReturn('User prompt for autobiography generation');
    when(mockPromptLoader.getStructureAnalysisSystemPrompt())
        .thenReturn('System prompt for structure analysis');
    when(mockPromptLoader.getStructureAnalysisPrompt(any, any))
        .thenReturn('User prompt for structure analysis');

    service = DoubaoAiService(mockPromptLoader, dio: mockDio);
  });

  group('DoubaoAiService', () {
    const successResponse = {
      'choices': [
        {
          'message': {'content': '生成的内容'}
        }
      ]
    };

    const structureAnalysisResponse = {
      'choices': [
        {
          'message': {
            'content':
                '{"action": "createNew", "newChapterTitle": "新章节", "reasoning": "全新主题"}'
          }
        }
      ]
    };

    test('generateAutobiography 应该在成功时返回内容', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(successResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result =
          await service.generateAutobiography(voiceContents: ['语音内容']);

      expect(result, equals('生成的内容'));
      verify(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).called(1);
    });

    test('generateAutobiography 应该在API错误时抛出异常', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(500);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      // 实际上会先抛出 NetworkException, 然后被catch块捕获并转换为 AiGenerationException
      expect(
        () => service.generateAutobiography(voiceContents: ['语音内容']),
        throwsA(isA<AiGenerationException>()),
      );
    });

    test('generateAutobiography 应该在Dio异常时正确处理 401', () async {
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
        () => service.generateAutobiography(voiceContents: ['语音内容']),
        throwsA(isA<AiGenerationException>().having(
          (e) => e.code,
          'code',
          'INVALID_API_KEY',
        )),
      );
    });

    test('analyzeAutobiographyStructure 应该正确解析JSON响应', () async {
      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(structureAnalysisResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      final result = await service.analyzeAutobiographyStructure(
        newContent: '新内容',
        currentChapters: [],
      );

      expect(result['action'], equals('createNew'));
      expect(result['newChapterTitle'], equals('新章节'));
    });

    test('analyzeAutobiographyStructure 应该在JSON解析失败时抛出异常', () async {
      const invalidJsonResponse = {
        'choices': [
          {
            'message': {'content': 'invalid json'}
          }
        ]
      };

      final response = MockResponse();
      when(response.statusCode).thenReturn(200);
      when(response.data).thenReturn(invalidJsonResponse);

      when(mockDio.post(
        AppConstants.doubaoChatCompletions,
        data: anyNamed('data'),
      )).thenAnswer((_) async => response);

      expect(
        () => service.analyzeAutobiographyStructure(
          newContent: '新内容',
          currentChapters: [],
        ),
        throwsA(isA<AiGenerationException>().having(
          (e) => e.code,
          'code',
          'CONTENT_GENERATION_FAILED',
        )),
      );
    });
  });
}
