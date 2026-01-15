import 'package:flutter_test/flutter_test.dart';

/// 测试辅助工具类
class TestHelpers {
  /// 创建测试用的VoiceRecord
  static Map<String, dynamic> createTestVoiceRecordJson({
    String? id,
    String? title,
    String? content,
    String? audioFilePath,
    int? duration,
    String? timestamp,
    bool? isProcessed,
    List<String>? tags,
    String? transcription,
    double? confidence,
    String? note,
    bool? isIncludedInBio,
  }) {
    return {
      'id': id ?? 'test-id-123',
      'title': title ?? '测试录音',
      'content': content ?? '测试内容',
      'audioFilePath': audioFilePath ?? '/path/to/audio.wav',
      'duration': duration ?? 5000,
      'timestamp': timestamp ?? '2024-01-01T00:00:00.000Z',
      'isProcessed': isProcessed ?? false,
      'tags': tags ?? ['tag1', 'tag2'],
      'transcription': transcription ?? '这是转写内容',
      'confidence': confidence ?? 0.95,
      'note': note ?? '测试备注',
      'isIncludedInBio': isIncludedInBio ?? false,
    };
  }

  /// 创建测试用的Autobiography
  static Map<String, dynamic> createTestAutobiographyJson({
    String? id,
    String? title,
    String? content,
    String? generatedAt,
    String? lastModifiedAt,
    int? version,
    int? wordCount,
    List<String>? voiceRecordIds,
    String? summary,
    List<String>? tags,
    String? status,
    String? style,
  }) {
    return {
      'id': id ?? 'bio-id-123',
      'title': title ?? '我的自传',
      'content': content ?? '这是自传内容',
      'chapters': [],
      'generatedAt': generatedAt ?? '2024-01-01T00:00:00.000Z',
      'lastModifiedAt': lastModifiedAt ?? '2024-01-01T01:00:00.000Z',
      'version': version ?? 1,
      'wordCount': wordCount ?? 1000,
      'voiceRecordIds': voiceRecordIds ?? ['record1', 'record2'],
      'summary': summary ?? '这是摘要',
      'tags': tags ?? ['传记', '回忆'],
      'status': status ?? 'draft',
      'style': style ?? 'narrative',
    };
  }

  /// 创建测试用的Chapter
  static Map<String, dynamic> createTestChapterJson({
    String? id,
    String? title,
    String? content,
    int? order,
    List<String>? sourceRecordIds,
    String? summary,
    String? lastModifiedAt,
  }) {
    return {
      'id': id ?? 'chapter-1',
      'title': title ?? '第一章',
      'content': content ?? '章节内容',
      'order': order ?? 1,
      'sourceRecordIds': sourceRecordIds ?? ['record1'],
      'summary': summary ?? '章节摘要',
      'lastModifiedAt': lastModifiedAt ?? '2024-01-01T00:00:00.000Z',
    };
  }

  /// 等待异步操作完成
  static Future<void> delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// 验证是否抛出特定类型的异常
  static Future<void> expectThrows<T>({
    required Future<void> Function() fn,
    String? messageContains,
  }) async {
    try {
      await fn();
      fail('Expected to throw $T but no exception was thrown');
    } catch (e) {
      expect(e, isA<T>());
      if (messageContains != null) {
        expect(e.toString(), contains(messageContains));
      }
    }
  }
}

/// Mock数据生成器
class MockDataGenerator {
  /// 生成随机ID
  static String randomId() {
    return 'id-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 生成随机标题
  static String randomTitle() {
    return '测试标题-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 生成随机内容
  static String randomContent({int length = 100}) {
    return '测试内容 ' * (length ~/ 5);
  }

  /// 生成随机标签
  static List<String> randomTags({int count = 3}) {
    return List.generate(
      count,
      (index) => '标签${index + 1}',
    );
  }
}

/// 测试配置常量
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
}
