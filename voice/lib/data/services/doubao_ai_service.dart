
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/autobiography.dart';

/// 豆包AI服务
@singleton
class DoubaoAiService {
  late final Dio _dio;

  DoubaoAiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.doubaoBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.doubaoApiKey}',
      },
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 300000), // 5 minutes
      sendTimeout: const Duration(milliseconds: 60000),
    ));

    // 添加拦截器用于日志记录
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          // 开发环境下打印日志
          // 开发环境下打印日志
          print('DoubaoAiService Log: $object');
        },
      ),
    );
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
      print('DoubaoAiService: Structure Analysis duration: ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null && content.isNotEmpty) {
          try {
            // 解析JSON
            // 注意：某些模型可能返回Markdown包裹的代码块，需要清理
            String jsonStr = content.replaceAll('```json', '').replaceAll('```', '').trim();
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
    } catch (e) {
      print('DoubaoAiService: Structure Analysis Exception: $e');
      throw AiGenerationException.serviceUnavailable();
    }
  }

  String _buildStructureAnalysisSystemPrompt() {
    return '''
你是一个专业的自传架构师。你的任务是分析新的语音记录内容，并决定其在现有自传中的位置。
你需要判断是创建一个全新的章节，还是将其合并到现有的某个章节中。
决策逻辑：
1. 如果新内容是一个全新的生活阶段、并没有在现有章节中出现过的主题（如"工作经历"相对于"童年"），则建议[创建新章节]。
2. 如果新内容是对现有章节主题在该时间段的补充（如"童年趣事"的补充细节），则建议[合并到现有章节]。
3. 严禁虚构。
请以严格的 JSON 格式输出你的决策。
''';
  }

  String _buildStructureAnalysisPrompt(String newContent, List<Map<String, dynamic>> currentChapters) {
    // 构建现有章节列表的简要描述
    final chaptersDesc = currentChapters.map((c) => 
      'Index: ${c['index']}, Title: ${c['title']}, Summary: ${c['summary']}'
    ).join('\n');

    return '''
现有章节结构：
$chaptersDesc

新的语音内容：
$newContent

请分析并输出 JSON 结果：
{
  "action": "createNew" | "updateExisting" | "ignore",
  "targetChapterIndex": <number, 仅在 updateExisting 时需要>,
  "newChapterTitle": "<string, 仅在 createNew 时需要>",
  "reasoning": "<string, 简短的决策理由>"
}
''';
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
        'temperature': 0.7,
      };

      final stopwatch = Stopwatch()..start();
      final response = await _dio.post(
        AppConstants.doubaoChatCompletions,
        data: request,
      );
      stopwatch.stop();
      print('DoubaoAiService: API call duration: ${stopwatch.elapsedMilliseconds}ms');

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
    } on DioException catch (e) {
      print('DoubaoAiService DioException: ${e.message}, Response: ${e.response?.data}');
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
      final prompt = _buildOptimizationPrompt(originalContent, optimizationType);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': AppConstants.doubaoMaxTokens,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的文本编辑和优化专家，擅长改进文章的流畅性、可读性和表达效果。',
          },
          {
            'role': 'user',
            'content': prompt,
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
      final prompt = _buildChapterGenerationPrompt(originalContent, newVoiceContent);

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 2000,
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
      print('DoubaoAiService: Chapter Generation duration: ${stopwatch.elapsedMilliseconds}ms');

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
      print('DoubaoAiService: Chapter Generation Exception: $e');
      throw AiGenerationException.serviceUnavailable();
    }
  }

  String _buildChapterGenerationSystemPrompt() {
    return '''
你是一个专业的自传作家。你的任务是根据用户提供的语音记录，撰写或更新自传章节。
**核心原则（必须严格遵守）：**
1. **严禁虚构**：所有的人物、时间、地点、事件必须完全基于提供的语音内容。绝对不允许编造语音中未提到的细节。
2. **第一人称**：始终使用"我"的视角。
3. **自然融合**：如果是更新现有章节，请将新信息自然地融入，保持上下文连贯，不要生硬拼接。
4. **文学润色**：在保证事实准确的前提下，可以优化语言表达，使其更具文学性和感染力。
''';
  }

  String _buildChapterGenerationPrompt(String? originalContent, String newVoiceContent) {
    if (originalContent == null || originalContent.isEmpty) {
      // 新建章节
      return '''
这是新的语音记录：
$newVoiceContent

请根据以上内容撰写一个新的自传章节。确保内容充实，条理清晰。
''';
    } else {
      // 更新章节
      return '''
这是现有章节内容：
$originalContent

这是新的补充语音记录：
$newVoiceContent

请将新语音记录中的信息，自然、流畅地融入到现有章节中。
注意：
1. 保持原有内容的完整性，不要随意删除重要信息。
2. 将新信息插入到逻辑上合适的位置，或者作为新的段落接续。
3. 确保更新后的文章风格统一，过渡自然。
''';
    }
  }

  /// 生成自传标题
  Future<String> generateTitle(String content) async {
    try {
      final prompt = '请为以下自传内容生成一个合适的标题（不超过20字）：\n\n$content';

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 100,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的标题生成专家，擅长为文章和自传创建简洁、有吸引力的标题。',
          },
          {
            'role': 'user',
            'content': prompt,
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
          return content.replaceAll(RegExp(r'[#*"\\\''\n\r]'), '').trim();
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
      final prompt = '请为以下自传内容生成一个简短的摘要（100-150字）：\n\n$content';

      final request = {
        'model': AppConstants.doubaoModel,
        'max_completion_tokens': 200,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的文本摘要专家，擅长提取文章的核心内容并生成简洁准确的摘要。',
          },
          {
            'role': 'user',
            'content': prompt,
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

  /// 构建自传生成提示词
  String _buildAutobiographyPrompt(List<String> voiceContents, AutobiographyStyle style, int? wordCount) {
    final targetWordCount = wordCount ?? 2000;
    final combinedContent = voiceContents.join('\n\n');

    String stylePrompt;
    switch (style) {
      case AutobiographyStyle.narrative:
        stylePrompt = '以叙事的方式，像讲故事一样流畅地叙述经历';
        break;
      case AutobiographyStyle.emotional:
        stylePrompt = '注重情感表达，深入描述内心的感受和情感变化';
        break;
      case AutobiographyStyle.achievement:
        stylePrompt = '突出成就和重要的人生里程碑，以积极向上的语调';
        break;
      case AutobiographyStyle.chronological:
        stylePrompt = '按照时间顺序，系统性地整理人生经历';
        break;
      case AutobiographyStyle.reflection:
        stylePrompt = '包含深度的自我反思和人生感悟';
        break;
    }

    return '''
根据以下语音转录的内容，请帮我生成一篇完整的个人自传。语音内容是用户通过录音讲述的个人信息：

语音转录内容：
$combinedContent

请按照以下要求生成自传：

**【核心原则 - 必须严格遵守】**
1. **严禁虚构**：绝对不允许添加、编造、推测任何语音中没有提到的人物、事件、时间、地点或细节。
2. **只做润色**：你的任务仅仅是将口语化的表达整理成书面语，优化语言表达，但不能改变或增加任何事实。
3. **忠于原文**：如果语音内容简短或信息有限，生成的自传也应该简短，不要为了凑字数而编造内容。

**格式要求：**
1. 使用第一人称视角
2. 语言自然流畅
3. 适当分段，保持条理清晰
4. 写作风格：$stylePrompt

请直接生成自传内容，不需要额外的说明文字。如果输入内容过于简短或不适合生成自传，请如实说明。
''';
  }

  /// 获取系统提示词
  String _getSystemPrompt(AutobiographyStyle style) {
    const basePrompt = '''你是一个专业的自传整理助手。你的核心职责是将用户的语音记录整理成书面自传。

**绝对禁止事项：**
- 禁止编造任何语音中没有提到的人物、事件、时间、地点
- 禁止添加任何推测性的细节或情节
- 禁止为了"丰富内容"而虚构任何信息
- 禁止添加"我想"、"大概"等推测性表述来掩盖编造

**你的任务：**
- 仅对原始语音内容进行语言润色和结构整理
- 将口语转为书面语
- 保持所有事实的准确性''';

    return basePrompt;
  }

  /// 构建优化提示词
  String _buildOptimizationPrompt(String content, OptimizationType optimizationType) {
    String optimizationPrompt;
    switch (optimizationType) {
      case OptimizationType.clarity:
        optimizationPrompt = '请优化这篇文章的清晰度和可读性，使表达更加明确易懂。';
        break;
      case OptimizationType.fluency:
        optimizationPrompt = '请优化这篇文章的流畅性，使语言更加自然连贯。';
        break;
      case OptimizationType.style:
        optimizationPrompt = '请优化这篇文章的写作风格，使其更具文学性和感染力。';
        break;
      case OptimizationType.structure:
        optimizationPrompt = '请优化这篇文章的结构，使其逻辑更清晰，组织更合理。';
        break;
      case OptimizationType.conciseness:
        optimizationPrompt = '请精简这篇文章，删除冗余内容，使表达更加简洁有力。';
        break;
    }

    return '''
$optimizationPrompt

原文内容：
$content

请保持原文的核心意思不变，只进行语言表达和结构上的优化。
''';
  }
}