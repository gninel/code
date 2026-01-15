import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:yaml/yaml.dart';

import '../../domain/entities/autobiography.dart';

/// 提示词加载服务
/// 从YAML配置文件中加载和管理所有AI提示词
@singleton
class PromptLoaderService {
  Map<String, dynamic>? _prompts;
  bool _isLoaded = false;

  /// 初始化并加载提示词配置
  Future<void> init() async {
    if (_isLoaded) return;

    try {
      // 从assets加载YAML文件
      final yamlString =
          await rootBundle.loadString('assets/prompts/ai_prompts.yaml');
      final yamlMap = loadYaml(yamlString);

      // 转换为Map
      _prompts = _convertYamlToMap(yamlMap);
      _isLoaded = true;

      print('[PromptLoader] 提示词配置加载成功');
    } catch (e) {
      print('[PromptLoader] 加载提示词配置失败: $e');
      rethrow;
    }
  }

  /// 将YamlMap递归转换为Map<String, dynamic>
  dynamic _convertYamlToMap(dynamic yamlData) {
    if (yamlData is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        yamlData.entries.map(
          (entry) => MapEntry(
            entry.key.toString(),
            _convertYamlToMap(entry.value),
          ),
        ),
      );
    } else if (yamlData is YamlList) {
      return yamlData.map((item) => _convertYamlToMap(item)).toList();
    } else {
      return yamlData;
    }
  }

  /// 获取章节生成系统提示词
  String getChapterGenerationSystemPrompt() {
    _ensureLoaded();

    final config = _prompts!['chapter_generation_system'] as Map<String, dynamic>;
    final role = config['role'] as String;
    final styleReqs = config['style_requirements'] as List;
    final examples = config['examples'] as Map<String, dynamic>;
    final principles = config['principles'] as List;
    final closing = config['closing'] as String;

    final buffer = StringBuffer();
    buffer.writeln(role);
    buffer.writeln();
    buffer.writeln('**写作风格要求：**');

    for (final req in styleReqs) {
      final item = req as Map<String, dynamic>;
      buffer.writeln('${styleReqs.indexOf(req) + 1}. **${item['name']}**：${item['description']}');
    }

    buffer.writeln();
    buffer.writeln('**文风示例对比：**');
    buffer.writeln('❌ 散文化（过度抒情）："${examples['bad']}"');
    buffer.writeln('✓ 专业传记风格："${examples['good']}"');

    buffer.writeln();
    buffer.writeln('**原则：**');
    for (final principle in principles) {
      final item = principle as Map<String, dynamic>;
      buffer.writeln(
          '${principles.indexOf(principle) + 1}. **${item['name']}**：${item['description']}');
    }

    buffer.writeln();
    buffer.writeln(closing);

    return buffer.toString();
  }

  /// 获取章节生成用户提示词（新章节）
  String getNewChapterPrompt(String newContent) {
    _ensureLoaded();

    final config = _prompts!['chapter_generation_prompt'] as Map<String, dynamic>;
    final template = (config['new_chapter'] as Map<String, dynamic>)['template'] as String;

    return template.replaceAll('{new_content}', newContent);
  }

  /// 获取章节生成用户提示词（合并章节）
  String getMergeChapterPrompt(String originalContent, String newContent) {
    _ensureLoaded();

    final config = _prompts!['chapter_generation_prompt'] as Map<String, dynamic>;
    final template =
        (config['merge_chapter'] as Map<String, dynamic>)['template'] as String;

    return template
        .replaceAll('{original_content}', originalContent)
        .replaceAll('{new_content}', newContent);
  }

  /// 获取结构分析系统提示词
  String getStructureAnalysisSystemPrompt() {
    _ensureLoaded();

    final config = _prompts!['structure_analysis_system'] as Map<String, dynamic>;
    final role = config['role'] as String;
    final logic = config['decision_logic'] as List;
    final forbidden = config['forbidden'] as String;
    final outputFormat = config['output_format'] as String;

    final buffer = StringBuffer();
    buffer.writeln(role);
    buffer.writeln();
    buffer.writeln('决策逻辑：');

    for (final item in logic) {
      final logicItem = item as Map<String, dynamic>;
      buffer.writeln('${logic.indexOf(item) + 1}. ${logicItem['condition']}，则${logicItem['action']}。');
    }

    buffer.writeln('3. $forbidden');
    buffer.writeln(outputFormat);

    return buffer.toString();
  }

  /// 获取结构分析用户提示词
  String getStructureAnalysisPrompt(
    String chaptersDescription,
    String newContent,
  ) {
    _ensureLoaded();

    final config = _prompts!['structure_analysis_prompt'] as Map<String, dynamic>;
    final template = config['template'] as String;

    return template
        .replaceAll('{chapters_description}', chaptersDescription)
        .replaceAll('{new_content}', newContent);
  }

  /// 获取自传生成系统提示词
  String getAutobiographyGenerationSystemPrompt() {
    _ensureLoaded();

    final config =
        _prompts!['autobiography_generation_system'] as Map<String, dynamic>;
    final role = config['role'] as String;
    final principles = config['core_principles'] as List;
    final style = config['writing_style'] as Map<String, dynamic>;
    final examples = config['examples'] as Map<String, dynamic>;
    final closing = config['closing'] as String;

    final buffer = StringBuffer();
    buffer.writeln(role);
    buffer.writeln();
    buffer.writeln('**核心原则：**');

    for (final principle in principles) {
      final item = principle as Map<String, dynamic>;
      buffer.writeln(
          '${principles.indexOf(principle) + 1}. **${item['name']}**：${item['description']}');
    }

    buffer.writeln();
    buffer.writeln('**写作风格：**');

    // 语言转化
    buffer.writeln('1. **语言转化**：');
    final langTrans = style['language_transformation'] as List;
    for (final item in langTrans) {
      buffer.writeln('   - $item');
    }

    // 叙事手法
    buffer.writeln();
    buffer.writeln('2. **叙事手法**：');
    final narrative = style['narrative_technique'] as List;
    for (final item in narrative) {
      buffer.writeln('   - $item');
    }

    // 情感处理
    buffer.writeln();
    buffer.writeln('3. **情感处理**：');
    final emotion = style['emotion_handling'] as List;
    for (final item in emotion) {
      buffer.writeln('   - $item');
    }

    buffer.writeln();
    buffer.writeln('**文风示例：**');
    buffer.writeln('❌ 散文化："${examples['bad']}"');
    buffer.writeln('✓ 传记风格："${examples['good']}"');

    // 禁止模式
    if (config.containsKey('forbidden_patterns')) {
      buffer.writeln();
      buffer.writeln('**严格禁止的表达模式：**');
      final forbiddenPatterns = config['forbidden_patterns'] as List;
      for (final item in forbiddenPatterns) {
        final pattern = item as Map<String, dynamic>;
        buffer.writeln('• ${pattern['pattern']}：');
        buffer.writeln('  ${pattern['example']}');
        buffer.writeln('  ${pattern['correct']}');
      }
    }

    buffer.writeln();
    buffer.writeln(closing);

    return buffer.toString();
  }

  /// 获取自传生成用户提示词
  String getAutobiographyGenerationPrompt({
    required String combinedContent,
    required AutobiographyStyle? style,
    required int targetWordCount,
  }) {
    _ensureLoaded();

    final config =
        _prompts!['autobiography_generation_prompt'] as Map<String, dynamic>;
    final template = config['template'] as String;

    // 获取风格描述
    final stylePrompt = _getStylePrompt(style);

    return template
        .replaceAll('{combined_content}', combinedContent)
        .replaceAll('{style_prompt}', stylePrompt)
        .replaceAll('{target_word_count}', targetWordCount.toString());
  }

  /// 获取写作风格提示词
  String _getStylePrompt(AutobiographyStyle? style) {
    final styles = _prompts!['writing_styles'] as Map<String, dynamic>;

    switch (style) {
      case AutobiographyStyle.narrative:
        return (styles['narrative'] as Map<String, dynamic>)['prompt'] as String;
      case AutobiographyStyle.emotional:
        return (styles['emotional'] as Map<String, dynamic>)['prompt'] as String;
      case AutobiographyStyle.achievement:
        return (styles['achievement'] as Map<String, dynamic>)['prompt']
            as String;
      case AutobiographyStyle.chronological:
        return (styles['chronological'] as Map<String, dynamic>)['prompt']
            as String;
      case AutobiographyStyle.reflection:
        return (styles['reflection'] as Map<String, dynamic>)['prompt'] as String;
      default:
        return (styles['narrative'] as Map<String, dynamic>)['prompt'] as String;
    }
  }

  /// 获取标题生成提示词
  (String system, String user) getTitleGenerationPrompt(String content) {
    _ensureLoaded();

    final config = _prompts!['title_generation'] as Map<String, dynamic>;
    final system = config['system'] as String;
    final template = config['user_template'] as String;

    return (system, template.replaceAll('{content}', content));
  }

  /// 获取摘要生成提示词
  (String system, String user) getSummaryGenerationPrompt(String content) {
    _ensureLoaded();

    final config = _prompts!['summary_generation'] as Map<String, dynamic>;
    final system = config['system'] as String;
    final template = config['user_template'] as String;

    return (system, template.replaceAll('{content}', content));
  }

  /// 获取采访问题生成提示词
  (String system, String user) getInterviewQuestionPrompt({
    required String userContentSummary,
    required List<String> answeredQuestions,
  }) {
    _ensureLoaded();

    final config =
        _prompts!['interview_question_generation'] as Map<String, dynamic>;
    final system = config['system'] as String;
    final template = config['user_template'] as String;

    final questionCount = answeredQuestions.length;
    final isEarlyStage = questionCount < 5;
    final stage = isEarlyStage ? '初期' : '中后期';

    // 获取策略
    final strategy = isEarlyStage
        ? config['early_stage_strategy'] as String
        : config['later_stage_strategy'] as String;

    // 格式化已回答问题
    final answeredQuestionsStr = answeredQuestions.isNotEmpty
        ? answeredQuestions.map((q) => '- $q').join('\n')
        : '（暂无）';

    final userPrompt = template
        .replaceAll('{user_content_summary}', userContentSummary)
        .replaceAll('{answered_count}', questionCount.toString())
        .replaceAll('{answered_questions}', answeredQuestionsStr)
        .replaceAll('{stage}', stage)
        .replaceAll('{strategy}', strategy);

    return (system, userPrompt);
  }

  /// 获取内容优化提示词
  (String system, String user) getContentOptimizationPrompt({
    required String content,
    required String optimizationType,
  }) {
    _ensureLoaded();

    final config = _prompts!['content_optimization'] as Map<String, dynamic>;
    final system = config['system'] as String;
    final types = config['types'] as Map<String, dynamic>;
    final template = config['user_template'] as String;

    // 获取优化类型对应的提示词
    final typePrompt = (types[optimizationType] as Map<String, dynamic>)['prompt'] as String;

    final userPrompt = template
        .replaceAll('{optimization_prompt}', typePrompt)
        .replaceAll('{content}', content);

    return (system, userPrompt);
  }

  /// 获取配置的temperature值
  double getTemperature(String promptType) {
    _ensureLoaded();

    switch (promptType) {
      case 'title':
        return (_prompts!['title_generation'] as Map<String, dynamic>)['temperature']
            as double;
      case 'summary':
        return (_prompts!['summary_generation'] as Map<String, dynamic>)['temperature']
            as double;
      case 'interview':
        return (_prompts!['interview_question_generation']
            as Map<String, dynamic>)['temperature'] as double;
      case 'optimization':
        return (_prompts!['content_optimization'] as Map<String, dynamic>)['temperature']
            as double;
      default:
        return 0.3;
    }
  }

  /// 获取配置的max_tokens值
  int getMaxTokens(String promptType) {
    _ensureLoaded();

    switch (promptType) {
      case 'title':
        return (_prompts!['title_generation'] as Map<String, dynamic>)['max_tokens']
            as int;
      case 'summary':
        return (_prompts!['summary_generation'] as Map<String, dynamic>)['max_tokens']
            as int;
      case 'interview':
        return (_prompts!['interview_question_generation']
            as Map<String, dynamic>)['max_tokens'] as int;
      default:
        return 1000;
    }
  }

  /// 获取Prompt配置版本号
  String getPromptVersion() {
    _ensureLoaded();

    try {
      final metadata = _prompts!['metadata'] as Map<String, dynamic>?;
      if (metadata != null && metadata.containsKey('version')) {
        return metadata['version'] as String;
      }
    } catch (e) {
      print('[PromptLoader] 获取版本号失败: $e');
    }

    // 降级返回默认版本
    return '1.0.0';
  }

  /// 确保配置已加载
  void _ensureLoaded() {
    if (!_isLoaded || _prompts == null) {
      throw StateError('提示词配置未加载，请先调用 init()');
    }
  }
}
