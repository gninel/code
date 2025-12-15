# 豆包AI服务集成说明

## 概述

本项目完整集成了字节跳动豆包AI服务，用于基于语音识别结果生成高质量的个人自传。支持多种写作风格、内容优化、标题生成和摘要生成等功能。

## 技术实现

### 1. API配置

使用豆包AI的Chat Completions API进行文本生成：

```dart
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
  'temperature': 0.7,
};
```

### 2. 认证机制

使用Bearer Token进行API认证：

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer ${AppConstants.doubaoApiKey}',
}
```

### 3. 错误处理

完善的错误处理机制：

```dart
try {
  final response = await _dio.post(endpoint, data: request);
  // 处理成功响应
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    throw const AiGenerationException.invalidApiKey();
  } else if (e.response?.statusCode == 429) {
    throw const AiGenerationException.quotaExceeded();
  }
  // 处理其他错误
}
```

## API配置

在 `lib/core/constants/app_constants.dart` 中配置：

```dart
class AppConstants {
  // 豆包AI配置
  static const String doubaoApiKey = '405fe7f2-f603-4c4c-b04b-bdea5d441319';
  static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
  static const String doubaoChatCompletions = '/chat/completions';
  static const String doubaoModel = 'doubao-seed-1-6-251015';
  static const int doubaoMaxTokens = 65535;
}
```

## 核心功能

### 1. 自传生成

#### 基础生成
```dart
final aiService = DoubaoAiService();

final content = await aiService.generateAutobiography(
  voiceContents: ['语音转录内容1', '语音转录内容2'],
  style: AutobiographyStyle.narrative,
  wordCount: 2000,
);
```

#### 完整生成（包含标题和摘要）
```dart
final result = await aiService.generateAutobiography(
  voiceContents: voiceContents,
  style: AutobiographyStyle.emotional,
  wordCount: 3000,
);

// 同时生成标题和摘要
final title = await aiService.generateTitle(content);
final summary = await aiService.generateSummary(content);
```

### 2. 内容优化

```dart
final optimizedContent = await aiService.optimizeAutobiography(
  originalContent: originalText,
  optimizationType: OptimizationType.fluency,
);
```

### 3. 支持的写作风格

#### 叙事风格 (narrative)
- 特点：以讲故事的方式流畅叙述经历
- 适用：注重故事性和可读性的自传

#### 情感风格 (emotional)
- 特点：注重情感表达和内心感受
- 适用：强调个人成长和情感历程的自传

#### 成就风格 (achievement)
- 特点：突出成就和重要人生里程碑
- 适用：职业发展或事业成就相关的自传

#### 编年体风格 (chronological)
- 特点：按照时间顺序系统整理经历
- 适用：时间线清晰的人生历程记录

#### 反思风格 (reflection)
- 特点：包含深度自我反思和人生感悟
- 适用：哲学思考或人生智慧总结

### 4. 支持的优化类型

#### 清晰度优化 (clarity)
- 提升表达明确性和可读性
- 修正模糊不清的表达

#### 流畅性优化 (fluency)
- 改善语言流畅性和连贯性
- 优化句式和段落结构

#### 风格优化 (style)
- 增强文学性和感染力
- 提升写作艺术效果

#### 结构优化 (structure)
- 优化逻辑结构和组织方式
- 改善段落安排和内容层次

#### 简洁性优化 (conciseness)
- 精简内容，删除冗余
- 使表达更加简洁有力

## 使用方法

### 1. 基础使用

```dart
// 1. 创建AI生成用例
final aiUseCases = AiGenerationUseCases(aiRepository);

// 2. 生成自传
final result = await aiUseCases.generateAutobiography(
  voiceRecords: voiceRecords,
  style: AutobiographyStyle.narrative,
  wordCount: 2000,
);

result.fold(
  (failure) => print('生成失败: ${failure.message}'),
  (content) => print('生成成功: $content'),
);
```

### 2. BLoC状态管理

```dart
BlocProvider(
  create: (context) => AiGenerationBloc(aiUseCases),
  child: AiGenerationWidget(voiceRecords: voiceRecords),
)
```

### 3. UI组件集成

```dart
// 显示AI生成组件
AiGenerationWidget(voiceRecords: voiceRecords)

// 或在现有页面中嵌入
BlocBuilder<AiGenerationBloc, AiGenerationState>(
  builder: (context, state) {
    if (state.isGenerating) {
      return const CircularProgressIndicator();
    }
    if (state.hasGeneratedContent) {
      return Text(state.generatedContent!);
    }
    return const SizedBox.shrink();
  },
)
```

## 提示词工程

### 1. 系统提示词

```dart
String getSystemPrompt(AutobiographyStyle style) {
  String basePrompt = '你是一个专业的自传撰写专家，擅长根据用户的语音内容生成高质量的个人自传。';

  switch (style) {
    case AutobiographyStyle.narrative:
      return '$basePrompt 你特别擅长用生动的故事情节来展现人物的经历。';
    case AutobiographyStyle.emotional:
      return '$basePrompt 你特别注重情感表达和内心世界的描述。';
    // ... 其他风格
  }
}
```

### 2. 用户提示词

```dart
String buildAutibiographyPrompt(List<String> voiceContents, AutobiographyStyle style, int wordCount) {
  final targetWordCount = wordCount ?? 2000;
  final combinedContent = voiceContents.join('\n\n');

  return '''
根据以下语音转录的内容，请帮我生成一篇完整的个人自传：

语音转录内容：
$combinedContent

请按照以下要求生成自传：
1. 字数控制在 $targetWordCount 字左右
2. 写作风格：${getStylePrompt(style)}
3. 保持内容完整性和连贯性
4. 补充必要的信息使内容更加完整
5. 使用第一人称视角
6. 语言要自然流畅，富有感染力

请直接生成自传内容，不需要额外的说明文字。
''';
}
```

## 性能优化

### 1. 请求优化

- **并发控制**: 限制同时进行的API请求数量
- **缓存机制**: 缓存标题和摘要生成结果
- **重试机制**: 实现指数退避重试策略

### 2. 内容处理

- **内容预处理**: 清理和格式化语音转录内容
- **分段处理**: 对长内容进行分段处理
- **结果验证**: 验证生成内容的质量和完整性

### 3. 内存管理

- **流式处理**: 使用Stream处理大量文本数据
- **资源清理**: 及时释放不需要的对象
- **垃圾回收**: 优化内存使用

## 错误处理

### 1. 网络错误

```dart
try {
  final response = await _dio.post(endpoint, data: request);
  // 处理响应
} on DioException catch (e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      throw const NetworkException.requestTimeout();
    case DioExceptionType.receiveTimeout:
      throw const NetworkException.requestTimeout();
    case DioExceptionType.connectionError:
      throw const NetworkException.noConnection();
    default:
      throw NetworkException.serverError();
  }
}
```

### 2. API错误

```dart
if (e.response?.statusCode == 401) {
  throw const AiGenerationException.invalidApiKey();
} else if (e.response?.statusCode == 429) {
  throw const AiGenerationException.quotaExceeded();
} else if (e.response?.statusCode == 500) {
  throw const AiGenerationException.serviceUnavailable();
}
```

### 3. 内容验证

```dart
if (content.trim().isEmpty) {
  throw const AiGenerationException.contentGenerationFailed();
}

if (content.length < 100) {
  // 内容太短，可能生成失败
  Logger.warning('Generated content is too short');
}
```

## 测试

### 1. 单元测试

```bash
flutter test test/unit/services/doubao_ai_service_test.dart
```

### 2. 组件测试

```bash
flutter test test/widget/ai_generation_widget_test.dart
```

### 3. 集成测试

```bash
flutter test integration_test/ai_generation_test.dart
```

## 配置说明

### 1. 豆包控制台配置

1. 登录[火山引擎控制台](https://console.volcengine.com/)
2. 进入"机器学习平台PAI"
3. 创建豆包AI应用
4. 获取API密钥
5. 配置模型和调用限额

### 2. 环境变量配置

```bash
export DOUBAO_API_KEY=your_api_key_here
export DOUBAO_MODEL=doubao-seed-1-6-251015
export DOUBAO_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
```

### 3. 权限配置

确保应用具有网络访问权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 常见问题

### Q1: 生成的内容质量不高怎么办？

**A**: 尝试以下方法：
- 优化语音转录内容的质量
- 调整生成参数（temperature、max_tokens）
- 使用更具体的提示词
- 尝试不同的写作风格

### Q2: API调用失败怎么办？

**A**: 检查以下方面：
- API密钥是否正确
- 网络连接是否正常
- 是否超过调用限额
- 模型是否可用

### Q3: 生成速度较慢怎么办？

**A**: 优化策略：
- 减少max_tokens数量
- 使用更简洁的提示词
- 启用内容缓存
- 优化网络连接

### Q4: 如何控制生成内容的长度？

**A**: 调整以下参数：
- max_completion_tokens
- 提示词中的字数要求
- content内容的复杂度

## 版本更新

- **v1.0.0**: 基础自传生成功能
- **v1.1.0**: 多风格支持和内容优化
- **v1.2.0**: 标题和摘要生成
- **v1.3.0**: 完整生成流程和错误处理优化

## 技术支持

- 豆包AI文档: https://console.volcengine.com/ark/
- OpenAI API规范参考: https://platform.openai.com/docs/api-reference
- Flutter HTTP客户端: https://pub.dev/packages/dio

---

*最后更新: 2025-11-23*