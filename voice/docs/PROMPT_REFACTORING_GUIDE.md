# 提示词解耦重构指南

## 概述

本文档说明如何将AI提示词从代码中解耦，使其可以通过配置文件独立管理和更新。

## 已完成的工作

### 1. 提示词配置文件

创建了 [`assets/prompts/ai_prompts.yaml`](../assets/prompts/ai_prompts.yaml)，包含所有AI提示词：

- 章节生成系统提示词
- 章节生成用户提示词
- 结构分析提示词
- 自传生成提示词
- 采访问题生成提示词
- 标题/摘要生成提示词
- 内容优化提示词
- 写作风格配置

### 2. 提示词加载服务

创建了 [`PromptLoaderService`](../lib/core/services/prompt_loader_service.dart)：

```dart
@singleton
class PromptLoaderService {
  // 初始化：从YAML文件加载配置
  Future<void> init() async

  // 获取各类提示词
  String getChapterGenerationSystemPrompt()
  String getNewChapterPrompt(String newContent)
  String getMergeChapterPrompt(String originalContent, String newContent)
  String getStructureAnalysisSystemPrompt()
  String getAutobiographyGenerationSystemPrompt()

  // ... 更多方法
}
```

### 3. DoubaoAiService重构

修改了 [`DoubaoAiService`](../lib/data/services/doubao_ai_service.dart) 的构造函数：

```dart
class DoubaoAiService {
  final PromptLoaderService _promptLoader;

  DoubaoAiService(this._promptLoader, {Dio? dio}) {
    // ...
  }
}
```

## 需要完成的重构步骤

### 步骤1：修改 `_buildChapterGenerationSystemPrompt` 方法

**原代码：**
```dart
String _buildChapterGenerationSystemPrompt() {
  return '''
你是一位专业的自传作家，擅长将口述回忆转化为专业、真实的传记文本。
...
''';
}
```

**新代码：**
```dart
String _buildChapterGenerationSystemPrompt() {
  return _promptLoader.getChapterGenerationSystemPrompt();
}
```

### 步骤2：修改 `_buildChapterGenerationPrompt` 方法

**原代码：**
```dart
String _buildChapterGenerationPrompt(
    String? originalContent, String newVoiceContent) {
  if (originalContent == null || originalContent.isEmpty) {
    return '''
这是新的语音记录：
$newVoiceContent
...
''';
  } else {
    return '''
**现有自传内容：**
$originalContent
...
''';
  }
}
```

**新代码：**
```dart
String _buildChapterGenerationPrompt(
    String? originalContent, String newVoiceContent) {
  if (originalContent == null || originalContent.isEmpty) {
    return _promptLoader.getNewChapterPrompt(newVoiceContent);
  } else {
    return _promptLoader.getMergeChapterPrompt(originalContent, newVoiceContent);
  }
}
```

### 步骤3：修改 `_buildStructureAnalysisSystemPrompt` 方法

**原代码：**
```dart
String _buildStructureAnalysisSystemPrompt() {
  return '''
你是一个专业的自传架构师。...
''';
}
```

**新代码：**
```dart
String _buildStructureAnalysisSystemPrompt() {
  return _promptLoader.getStructureAnalysisSystemPrompt();
}
```

### 步骤4：修改 `_buildStructureAnalysisPrompt` 方法

**原代码：**
```dart
String _buildStructureAnalysisPrompt(
    String newContent, List<Map<String, dynamic>> currentChapters) {
  final chaptersDesc = currentChapters...;

  return '''
现有章节结构：
$chaptersDesc
...
''';
}
```

**新代码：**
```dart
String _buildStructureAnalysisPrompt(
    String newContent, List<Map<String, dynamic>> currentChapters) {
  final chaptersDesc = currentChapters
      .map((c) =>
          'Index: ${c['index']}, Title: ${c['title']}, Summary: ${c['summary']}')
      .join('\n');

  return _promptLoader.getStructureAnalysisPrompt(chaptersDesc, newContent);
}
```

### 步骤5：修改 `_getSystemPrompt` 方法

**原代码：**
```dart
String _getSystemPrompt(AutobiographyStyle style) {
  const basePrompt = '''你是一位专业的自传作家...''';
  return basePrompt;
}
```

**新代码：**
```dart
String _getSystemPrompt(AutobiographyStyle style) {
  return _promptLoader.getAutobiographyGenerationSystemPrompt();
}
```

### 步骤6：修改 `_buildAutobiographyPrompt` 方法

**原代码：**
```dart
String _buildAutobiographyPrompt(
    List<String> voiceContents, AutobiographyStyle style, int? wordCount) {
  final targetWordCount = wordCount ?? 2000;
  final combinedContent = voiceContents.join('\n\n');

  String stylePrompt;
  switch (style) {
    case AutobiographyStyle.narrative:
      stylePrompt = '按时间或事件顺序...';
      break;
    // ...
  }

  return '''
根据以下语音转录的内容...
$combinedContent
...
风格定位：$stylePrompt
...
''';
}
```

**新代码：**
```dart
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
```

### 步骤7：修改 `generateTitle` 方法

**原代码：**
```dart
Future<String> generateTitle(String content) async {
  final prompt = '请为以下自传内容生成一个合适的标题（不超过20字）：\n\n$content';

  final request = {
    'model': AppConstants.doubaoModel,
    'max_completion_tokens': 100,
    'messages': [
      {
        'role': 'system',
        'content': '你是一个专业的标题生成专家...',
      },
      {
        'role': 'user',
        'content': prompt,
      }
    ],
    'temperature': 0.3,
  };
  // ...
}
```

**新代码：**
```dart
Future<String> generateTitle(String content) async {
  final (systemPrompt, userPrompt) = _promptLoader.getTitleGenerationPrompt(content);

  final request = {
    'model': AppConstants.doubaoModel,
    'max_completion_tokens': _promptLoader.getMaxTokens('title'),
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
    'temperature': _promptLoader.getTemperature('title'),
  };
  // ...
}
```

### 步骤8：修改 `generateSummary` 方法

**新代码：**
```dart
Future<String> generateSummary(String content) async {
  final (systemPrompt, userPrompt) = _promptLoader.getSummaryGenerationPrompt(content);

  final request = {
    'model': AppConstants.doubaoModel,
    'max_completion_tokens': _promptLoader.getMaxTokens('summary'),
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
    'temperature': _promptLoader.getTemperature('summary'),
  };
  // ...
}
```

### 步骤9：修改 `generateInterviewQuestion` 方法

**新代码：**
```dart
Future<String> generateInterviewQuestion({
  required String userContentSummary,
  required List<String> answeredQuestions,
}) async {
  final (systemPrompt, userPrompt) = _promptLoader.getInterviewQuestionPrompt(
    userContentSummary: userContentSummary,
    answeredQuestions: answeredQuestions,
  );

  final request = {
    'model': AppConstants.doubaoModel,
    'max_completion_tokens': _promptLoader.getMaxTokens('interview'),
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
    'temperature': _promptLoader.getTemperature('interview'),
  };
  // ...
}
```

### 步骤10：修改 `_buildOptimizationPrompt` 方法

**新代码：**
```dart
String _buildOptimizationPrompt(
    String content, OptimizationType optimizationType) {
  String typeStr;
  switch (optimizationType) {
    case OptimizationType.clarity:
      typeStr = 'clarity';
      break;
    case OptimizationType.fluency:
      typeStr = 'fluency';
      break;
    case OptimizationType.style:
      typeStr = 'style';
      break;
    case OptimizationType.structure:
      typeStr = 'structure';
      break;
    case OptimizationType.conciseness:
      typeStr = 'conciseness';
      break;
  }

  final (systemPrompt, userPrompt) = _promptLoader.getContentOptimizationPrompt(
    content: content,
    optimizationType: typeStr,
  );

  // 这个方法可能需要返回tuple或者直接在调用处处理
  return userPrompt; // 或者修改返回类型
}
```

## 初始化流程

在应用启动时需要初始化PromptLoaderService：

```dart
// 在main.dart或应用初始化代码中
Future<void> initializeServices() async {
  final promptLoader = GetIt.I<PromptLoaderService>();
  await promptLoader.init();
}
```

## 优势

1. **易于维护**：提示词统一管理在YAML文件中
2. **灵活调整**：无需重新编译即可调整提示词
3. **版本控制**：提示词变更可以独立追踪
4. **团队协作**：非开发人员也可以优化提示词
5. **A/B测试**：可以轻松创建不同版本的提示词配置

## 测试

修改完成后，需要测试：

1. 章节生成功能
2. 结构分析功能
3. 自传生成功能
4. 采访问题生成
5. 标题和摘要生成

## 后续优化

1. 支持多语言提示词
2. 支持从远程服务器加载提示词配置
3. 添加提示词版本管理
4. 实现提示词热更新

---

**文档版本：** 1.0.0
**最后更新：** 2025-12-29
