# 讯飞语音识别集成说明

## 概述

本项目完整集成了讯飞语音识别服务，支持实时语音转文字功能。基于WebSocket协议实现低延迟的语音识别，提供高精度的中文、英文及方言识别能力。

## 技术实现

### 1. 认证机制

使用HMAC-SHA256签名认证确保API调用安全：

```dart
String _generateAuthUrl() {
  // 生成时间戳
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // 生成签名字符串
  final signatureOrigin = 'host: $host\ndate: $timestamp\nGET $path HTTP/1.1';

  // 计算签名
  final hmacSha256 = Hmac(sha256, utf8.encode(AppConstants.xunfeiApiSecret));
  final digest = hmacSha256.convert(utf8.encode(signatureOrigin));
  final signature = hex.encode(digest.bytes);

  // 构建认证URL
  // ...
}
```

### 2. WebSocket连接

建立安全的WebSocket连接：

```dart
WebSocketChannel.connect(Uri.parse(authUrl));
```

### 3. 音频数据处理

- **音频格式**: PCM 16-bit，16kHz采样率，单声道
- **数据编码**: Base64编码传输
- **帧类型**:
  - 首帧 (status=0): 握手和参数配置
  - 中间帧 (status=1): 音频数据
  - 结束帧 (status=2): 结束标志

### 4. 识别结果解析

```dart
static String parseRecognitionResult(Map<String, dynamic> result) {
  final ws = result['ws'] as List<dynamic>?;
  if (ws == null || ws.isEmpty) return '';

  final sentences = <String>[];
  for (final wsItem in ws) {
    final cw = wsItem['cw'] as List<dynamic>?;
    if (cw != null && cw.isNotEmpty) {
      final word = cw[0]['w'] as String?;
      if (word != null && word.isNotEmpty) {
        sentences.add(word);
      }
    }
  }
  return sentences.join();
}
```

## API配置

在 `lib/core/constants/app_constants.dart` 中配置：

```dart
class AppConstants {
  // 讯飞语音识别配置
  static const String xunfeiAppId = '2e72f06c';
  static const String xunfeiApiKey = '390583124637d47a099fdd5a59860bde';
  static const String xunfeiApiSecret = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
  static const String websocketUrl = 'wss://iat-api.xfyun.cn/v2/iat';
}
```

## 使用方法

### 1. 基础使用

```dart
// 创建语音识别服务
final asrService = XunfeiAsrService();

// 开始语音识别
await asrService.startRecognition();

// 监听识别结果
asrService.recognitionResultStream.listen((result) {
  final text = XunfeiAsrService.parseRecognitionResult(result);
  print('识别结果: $text');
});

// 发送音频数据
await asrService.sendAudioData(audioData);

// 停止识别
await asrService.stopRecognition();
```

### 2. 集成录音功能

使用 `EnhancedAudioRecordingService` 集成录音和识别：

```dart
final enhancedService = EnhancedAudioRecordingService(asrService);

await enhancedService.startRecordingWithRecognition(
  onResult: (text, confidence) {
    print('实时识别: $text (置信度: $confidence)');
  },
  onError: (error) {
    print('识别错误: $error');
  },
  onStarted: () {
    print('录音和识别开始');
  },
  onCompleted: () {
    print('录音和识别完成');
  },
);
```

### 3. BLoC状态管理

使用 `IntegratedRecordingBloc` 管理录音和识别状态：

```dart
BlocProvider(
  create: (context) => getIt<IntegratedRecordingBloc>(),
  child: IntegratedRecordingWidget(),
)
```

## 识别参数配置

### 音频参数
```dart
final config = RecordConfig(
  encoder: AudioEncoder.pcm16bit,  // PCM格式便于识别
  bitRate: 128000,               // 码率
  sampleRate: 16000,             // 采样率
  channels: 1,                   // 单声道
);
```

### 识别参数
```dart
final handshakeMessage = {
  'parameter': {
    'result': {
      'encoding': 'utf8',
      'punc': 1,          // 标点符号
      'pt': 0,            // 英文转写
      'speed': 50,        // 语速
      'vad_eos': 4800,    // 静音检测
    },
    'result_type': 'plain',     // 结果格式
    'cache_time': 1500,         // 缓存时间
    'ssm': 1,                   // 子句间隔
  }
};
```

## 错误处理

### 常见错误类型

1. **连接错误**
   ```
   AsrException.websocketConnectionFailed()
   ```

2. **认证错误**
   ```
   AsrException.authenticationFailed()
   ```

3. **识别失败**
   ```
   AsrException.recognitionFailed()
   ```

4. **无语音输入**
   ```
   AsrException.noSpeechDetected()
   ```

### 错误处理示例

```dart
try {
  await asrService.startRecognition();
} on AsrException catch (e) {
  switch (e.runtimeType) {
    case AsrException.websocketConnectionFailed():
      print('WebSocket连接失败');
      break;
    case AsrException.authenticationFailed():
      print('API认证失败，请检查密钥配置');
      break;
    case AsrException.noSpeechDetected():
      print('未检测到语音输入');
      break;
    default:
      print('语音识别失败: ${e.message}');
  }
}
```

## 性能优化

### 1. 音频数据发送

- **发送频率**: 200ms间隔
- **数据大小**: 每次发送适当大小的音频数据
- **延迟处理**: 避免发送过快导致识别延迟

### 2. 连接管理

- **连接复用**: 在录音会话中保持连接
- **自动重连**: 连接断开时自动重新连接
- **资源释放**: 及时释放连接和相关资源

### 3. 内存优化

- **流式处理**: 使用Stream处理音频数据
- **缓冲管理**: 合理设置音频缓冲区大小
- **垃圾回收**: 及时清理不需要的音频数据

## 测试

### 单元测试

```bash
flutter test test/unit/services/xunfei_asr_service_test.dart
```

### 组件测试

```bash
flutter test test/widget/integrated_recording_widget_test.dart
```

### 集成测试

```bash
flutter test integration_test/voice_recognition_test.dart
```

## 配置说明

### 1. 讯飞控制台配置

1. 登录[讯飞开放平台](https://www.xfyun.cn/)
2. 创建语音识别应用
3. 获取 APPID、APIKey、APISecret
4. 配置应用权限和调用限额

### 2. 网络权限

确保应用具有网络访问权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 3. 音频权限

确保应用具有录音权限：

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## 常见问题

### Q1: 识别延迟较高怎么办？

**A**: 调整以下参数：
- 减少音频数据发送间隔
- 启用VAD静音检测
- 优化网络连接质量

### Q2: 识别准确率不高？

**A**: 检查以下方面：
- 音频质量（采样率、比特率）
- 环境噪音
- 说话语速和清晰度
- 识别语言配置

### Q3: WebSocket连接失败？

**A**: 检查以下配置：
- API密钥是否正确
- 网络连接是否正常
- 服务器地址是否正确
- 时间戳是否有效

### Q4: 如何处理方言识别？

**A**: 在识别参数中配置方言：
```dart
'parameter': {
  'result': {
    'rlang': 'zh-cmn', // 普通话
    // 其他方言配置
  }
}
```

## 版本更新

- **v1.0.0**: 基础语音识别功能
- **v1.1.0**: 实时识别优化
- **v1.2.0**: 多语言支持
- **v1.3.0**: 错误处理增强

## 技术支持

- 讯飞语音识别文档: https://www.xfyun.cn/doc/spark/spark_zh_iat.html
- WebSocket API规范: https://tools.ietf.org/html/rfc6455
- Flutter音频处理: https://pub.dev/packages/record

---

*最后更新: 2025-11-23*