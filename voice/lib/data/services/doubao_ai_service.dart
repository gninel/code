import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/prompt_loader_service.dart';
import '../../domain/entities/autobiography.dart';

/// 豆包AI服务
@singleton
class DoubaoAiService {
  late final Dio _dio;
  final PromptLoaderService _promptLoader;

  @factoryMethod
  DoubaoAiService.init(PromptLoaderService promptLoader) : this(promptLoader);

  DoubaoAiService(this._promptLoader, {Dio? dio}) {
    _dio = dio ??
        Dio(BaseOptions(
          baseUrl: AppConstants.doubaoBaseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConstants.doubaoApiKey}',
          },
          connectTimeout: const Duration(milliseconds: 60000), // 增加到60秒，支持采访问题连续生成
          receiveTimeout: const Duration(milliseconds: 300000), // 5 minutes
          sendTimeout: const Duration(milliseconds: 60000),
        ));

    if (dio == null) {
      // 添加拦截器用于日志记录
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) {
            // 开发环境下打印日志
            print('DoubaoAiService Log: $object');
          },
        ),
      );
    }
  }

  /// 分析自传结构
  Future<Map<String, dynamic>> analyzeAutobiographyStructure({
    required String newContent,
    required List<Map<String, dynamic>> currentChapters,
  }) async {
    try {
      final prompt = _buildStructureAnalysisPrompt(newContent, currentChapters);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 1000,
        'messages': [
          {
            'role': 'system',
            'content': _buildStructureAnalysisSystemPrompt(),
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.1, // 低温度以保证结构化输出的稳定性
        'response_format': {'type': 'json_object'}, // 强制JSON输出
      };

      final stopwatch = Stopwatch()..start();
      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );
      stopwatch.stop();
      print(
          'DoubaoAiService: Structure Analysis duration: ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          try {
            // 解析JSON
            // 注意：某些模型可能返回Markdown包裹的代码块，需要清理
            String jsonStr =
                content.replaceAll('```json', '').replaceAll('```', '').trim();
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          } catch (e) {
            print('DoubaoAiService: JSON parse error: $e');
            throw AiGenerationException.contentGenerationFailed();
          }
        } else {
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print(
          'DoubaoAiService: Structure Analysis DioException: ${e.message}, Response: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw AiGenerationException.invalidApiKey();
      } else if (e.response?.statusCode == 429) {
        throw AiGenerationException.quotaExceeded();
      } else {
        throw NetworkException.requestTimeout();
      }
    } on AiGenerationException {
      rethrow; // 重新抛出已知的 AI 异常
    } on NetworkException {
      rethrow; // 重新抛出已知的网络异常
    } catch (e) {
      print('DoubaoAiService: Structure Analysis Exception: $e');
      throw AiGenerationException.serviceUnavailable();
    }
  }

  String _buildStructureAnalysisSystemPrompt() {
    return _promptLoader.getStructureAnalysisSystemPrompt();
  }

  String _buildStructureAnalysisPrompt(
      String newContent, List<Map<String, dynamic>> currentChapters) {
    // 构建现有章节列表的简要描述
    final chaptersDesc = currentChapters
        .map((c) =>
            'Index: ${c['index']}, Title: ${c['title']}, Summary: ${c['summary']}')
        .join('\n');

    return _promptLoader.getStructureAnalysisPrompt(
      chaptersDesc,
      newContent,
    );
  }

  /// 生成自传内容
  Future<String> generateAutobiography({
    required List<String> voiceContents,
    AutobiographyStyle style = AutobiographyStyle.narrative,
    int? wordCount,
  }) async {
    try {
      final prompt = _buildAutobiographyPrompt(voiceContents, style, wordCount);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': AppConstants.doubaoMaxTokens,
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt(style),
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'reasoning_effort': 'medium',
        'temperature': 0.3,
      };

      final stopwatch = Stopwatch()..start();
      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );
      stopwatch.stop();
      print(
          'DoubaoAiService: API call duration: ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          // 清理AI响应中的思考标签和重复内容
          return _cleanAiResponse(content);
        } else {
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print(
          'DoubaoAiService DioException: ${e.message}, Response: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw AiGenerationException.invalidApiKey();
      } else if (e.response?.statusCode == 429) {
        throw AiGenerationException.quotaExceeded();
      } else {
        throw NetworkException.requestTimeout();
      }
    } catch (e) {
      print('DoubaoAiService Exception: $e');
      throw AiGenerationException.serviceUnavailable();
    }
  }

  /// 优化自传内容
  Future<String> optimizeAutobiography({
    required String originalContent,
    OptimizationType optimizationType = OptimizationType.clarity,
  }) async {
    try {
      String typeString;
      switch (optimizationType) {
        case OptimizationType.clarity:
          typeString = 'clarity';
          break;
        case OptimizationType.fluency:
          typeString = 'fluency';
          break;
        case OptimizationType.style:
          typeString = 'style';
          break;
        case OptimizationType.structure:
          typeString = 'structure';
          break;
        case OptimizationType.conciseness:
          typeString = 'conciseness';
          break;
      }

      final (systemPrompt, userPrompt) = _promptLoader.getContentOptimizationPrompt(
        content: originalContent,
        optimizationType: typeString,
      );

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': AppConstants.doubaoMaxTokens,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          }
        ],
        'temperature': 0.5,
      };

      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          return content;
        } else {
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } catch (e) {
      throw AiGenerationException.serviceUnavailable();
    }
  }

  /// 生成或合并章节内容
  /// [originalContent] 原有章节内容（如果是新建章节则为null）
  /// [newVoiceContent] 新的语音内容
  Future<String> generateChapterContent({
    String? originalContent,
    required String newVoiceContent,
  }) async {
    try {
      final prompt =
          _buildChapterGenerationPrompt(originalContent, newVoiceContent);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 8000, // 增大 token 限制以容纳完整的融合自传
        'messages': [
          {
            'role': 'system',
            'content': _buildChapterGenerationSystemPrompt(),
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.3, // 稍微降低温度，保证事实准确性
      };

      final stopwatch = Stopwatch()..start();
      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );
      stopwatch.stop();
      print(
          'DoubaoAiService: Chapter Generation duration: ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          print(
              'DoubaoAiService: AI generated content length: ${content.length}');

          // 清理AI响应中的思考标签和重复内容
          String cleanedContent = _cleanAiResponse(content);
          print(
              'DoubaoAiService: Cleaned content length: ${cleanedContent.length}');

          // 如果 originalContent 不为空，说明我们使用了"融合模式"Prompt，
          // AI 返回的是完整的、已融合的内容，所以直接返回 content 即可。
          // 不要再拼接 originalContent，否则会导致重复。
          if (originalContent != null && originalContent.isNotEmpty) {
            print(
                'DoubaoAiService: Returning merged content (Timeline Integration Mode)');
          } else {
            print('DoubaoAiService: Returning new content (New Chapter Mode)');
          }

          return cleanedContent;
        } else {
          print(
              'DoubaoAiService: Content is null or empty. Response choices: ${data['choices']}');
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } catch (e) {
      print('DoubaoAiService: Chapter Generation Exception: $e');
      throw AiGenerationException.serviceUnavailable();
    }
  }

  String _buildChapterGenerationSystemPrompt() {
    return _promptLoader.getChapterGenerationSystemPrompt();
  }

  String _buildChapterGenerationPrompt(
      String? originalContent, String newVoiceContent) {
    if (originalContent == null || originalContent.isEmpty) {
      return _promptLoader.getNewChapterPrompt(newVoiceContent);
    } else {
      return _promptLoader.getMergeChapterPrompt(
        originalContent,
        newVoiceContent,
      );
    }
  }

  /// 生成自传标题
  Future<String> generateTitle(String content) async {
    try {
      final (systemPrompt, userPrompt) = _promptLoader.getTitleGenerationPrompt(content);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 100,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          }
        ],
        'temperature': 0.3,
      };

      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          // 清理标题格式
          return content.replaceAll(RegExp(r'[#*"\\\' '\n\r]'), '').trim();
        } else {
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } catch (e) {
      throw AiGenerationException.serviceUnavailable();
    }
  }

  /// 生成自传摘要
  Future<String> generateSummary(String content) async {
    try {
      final (systemPrompt, userPrompt) = _promptLoader.getSummaryGenerationPrompt(content);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 200,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          }
        ],
        'temperature': 0.3,
      };

      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          return content.trim();
        } else {
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } catch (e) {
      throw AiGenerationException.serviceUnavailable();
    }
  }

  /// 生成采访问题
  /// [userContentSummary] 用户已有录音内容的简要分析
  /// [answeredQuestions] 已回答过的问题列表
  Future<String> generateInterviewQuestion({
    required String userContentSummary,
    required List<String> answeredQuestions,
  }) async {
    try {
      final (systemPrompt, userPrompt) = _promptLoader.getInterviewQuestionPrompt(
        userContentSummary: userContentSummary,
        answeredQuestions: answeredQuestions,
      );

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 2000, // 增加token限制，避免问题被截断
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          }
        ],
        'temperature': 0.8, // 更高的温度以增加问题多样性
      };

      final stopwatch = Stopwatch()..start();
      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );
      stopwatch.stop();
      print(
          'DoubaoAiService: Interview Question Generation duration: ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = response.data;
        final message = data['choices']?[0]?['message'];

        // 优先使用 content 字段，如果为空则尝试 reasoning_content
        String? content = message?['content'] as String?;

        if (content == null || content.isEmpty) {
          // 尝试从 reasoning_content 提取
          final reasoningContent = message?['reasoning_content'] as String?;
          print('[DoubaoAiService] content为空，尝试从reasoning_content提取问题');
          print(
              '[DoubaoAiService] reasoning_content: ${reasoningContent?.substring(0, reasoningContent.length > 200 ? 200 : reasoningContent.length)}...');

          if (reasoningContent != null && reasoningContent.isNotEmpty) {
            // 策略1: 查找引号内的问题（中文引号或英文引号）
            final quotePatterns = [
              RegExp(r'"([^"]{10,}[？?])"'), // 中文双引号
              RegExp(r'"([^"]{10,}[？?])"'), // 英文双引号
              RegExp(r'「([^」]{10,}[？?])」'), // 日式引号
            ];

            for (final pattern in quotePatterns) {
              final matches = pattern.allMatches(reasoningContent);
              if (matches.isNotEmpty) {
                // 取最后一个匹配（通常是最终的问题）
                content = matches.last.group(1);
                print('[DoubaoAiService] 从引号中提取的问题: $content');
                break;
              }
            }

            // 策略2: 如果没有找到引号，查找包含"问题"、"你"、"您"等关键词的完整句子
            if (content == null || content.isEmpty) {
              final sentences = reasoningContent.split(RegExp(r'[。！\n]'));
              for (int i = sentences.length - 1; i >= 0; i--) {
                final sentence = sentences[i].trim();
                if (sentence.contains(RegExp(r'[？?]')) &&
                    sentence.length > 10 &&
                    sentence.length < 200 &&
                    (sentence.contains('你') ||
                        sentence.contains('您') ||
                        sentence.contains('吗') ||
                        sentence.contains('呢'))) {
                  content = sentence;
                  print('[DoubaoAiService] 从句子中提取的问题: $content');
                  break;
                }
              }
            }
          }
        }

        if (content != null && content.isNotEmpty) {
          // 清理问题文本，移除可能的前缀和引号
          String question = content.trim();
          // 移除常见的引号
          question = question
              .replaceAll(RegExp(r'^["「『]'), '')
              .replaceAll(RegExp(r'["」』]$'), '');
          // 移除可能的前缀如 "问题："
          question = question.replaceAll(RegExp(r'^(问题：|Question:)\s*'), '');
          return question.trim();
        } else {
          print('[DoubaoAiService] 无法从content或reasoning_content中提取有效问题');
          print('[DoubaoAiService] Response data: $data');
          throw AiGenerationException.contentGenerationFailed();
        }
      } else {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print(
          'DoubaoAiService: Interview Question DioException: ${e.message}, Response: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw AiGenerationException.invalidApiKey();
      } else if (e.response?.statusCode == 429) {
        throw AiGenerationException.quotaExceeded();
      } else {
        throw NetworkException.requestTimeout();
      }
    } on AiGenerationException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      print('DoubaoAiService: Interview Question Exception: $e');
      throw AiGenerationException.serviceUnavailable();
    }
  }

  /// 构建自传生成提示词
  String _buildAutobiographyPrompt(
      List<String> voiceContents, AutobiographyStyle style, int? wordCount) {
    final targetWordCount = wordCount ?? 2000;
    final combinedContent = voiceContents.join('\n\n');

    return _promptLoader.getAutobiographyGenerationPrompt(
      combinedContent: combinedContent,
      style: style,
      targetWordCount: targetWordCount,
    );
  }

  /// 获取系统提示词
  String _getSystemPrompt(AutobiographyStyle style) {
    return _promptLoader.getAutobiographyGenerationSystemPrompt();
  }

  /// 清理AI响应内容
  /// 移除思考标签、重复内容等
  String _cleanAiResponse(String content) {
    // 1. 移除可能的思考标签（各种变体）
    final thinkingPatterns = [
      RegExp(r'</?think[^>]*>.*?</think[^>]*>', dotAll: true),
      RegExp(r'</think_never_used_[a-f0-9]+>', dotAll: true),
      RegExp(r'<think_never_used_[a-f0-9]+>.*?</think_never_used_[a-f0-9]+>', dotAll: true),
    ];

    String cleaned = content;
    for (final pattern in thinkingPatterns) {
      cleaned = cleaned.replaceAll(pattern, '');
    }

    // 2. 检测并移除重复的段落
    // 如果内容被分成两半且完全相同，只保留前半部分
    final lines = cleaned.split('\n');
    final halfLength = lines.length ~/ 2;

    if (halfLength > 10) { // 只对足够长的内容进行检测
      final firstHalf = lines.sublist(0, halfLength).join('\n');
      final secondHalf = lines.sublist(halfLength).join('\n');

      // 计算相似度
      if (_calculateSimilarity(firstHalf, secondHalf) > 0.9) {
        print('DoubaoAiService: Detected duplicate content, keeping first half only');
        cleaned = firstHalf;
      }
    }

    // 3. 清理多余的空行
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  /// 计算两个文本的相似度（简单的字符匹配）
  double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    final len1 = text1.length;
    final len2 = text2.length;
    final maxLen = len1 > len2 ? len1 : len2;
    final minLen = len1 < len2 ? len1 : len2;

    // 计算前N个字符的匹配度
    final compareLen = minLen < 500 ? minLen : 500;
    int matches = 0;

    for (int i = 0; i < compareLen; i++) {
      if (text1[i] == text2[i]) matches++;
    }

    return matches / compareLen;
  }

}
