import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography_version.dart';

void main() {
  group('AutobiographyVersion Entity Tests', () {
    test('应该能正确创建AutobiographyVersion实例', () {
      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '这是测试内容',
        chapters: const [
          {'id': 'ch1', 'title': '第一章', 'content': '第一章内容'},
        ],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 6,
        summary: '测试摘要',
      );

      expect(version.id, 'test-id-001');
      expect(version.autobiographyId, 'auto-id-001');
      expect(version.versionName, '测试版本');
      expect(version.content, '这是测试内容');
      expect(version.chapters.length, 1);
      expect(version.wordCount, 6);
      expect(version.summary, '测试摘要');
    });

    test('应该能正确转换为JSON', () {
      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [
          {
            'id': 'ch1',
            'title': '第一章',
            'content': '第一章内容',
            'order': 0,
            'sourceRecordIds': ['rec1'],
            'lastModifiedAt': 1000000,
          },
        ],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 4,
        summary: '测试摘要',
      );

      final json = version.toJson();

      expect(json['id'], 'test-id-001');
      expect(json['autobiography_id'], 'auto-id-001');
      expect(json['version_name'], '测试版本');
      expect(json['content'], '测试内容');
      expect(json['word_count'], 4);
      expect(json['summary'], '测试摘要');
      // toJson 返回 List，repository 会将其转为 JSON 字符串存储
      expect(json['chapters'], isA<List>());
      expect(json['created_at'], isA<int>());
    });

    test('应该能从JSON正确反序列化', () {
      final json = {
        'id': 'test-id-001',
        'autobiography_id': 'auto-id-001',
        'version_name': '测试版本',
        'content': '测试内容',
        'chapters': '[{"id":"ch1","title":"第一章","content":"第一章内容"}]',
        'word_count': 4,
        'summary': '测试摘要',
        'created_at': DateTime(2025, 1, 1).millisecondsSinceEpoch,
      };

      final version = AutobiographyVersion.fromJson(json);

      expect(version.id, 'test-id-001');
      expect(version.autobiographyId, 'auto-id-001');
      expect(version.versionName, '测试版本');
      expect(version.content, '测试内容');
      expect(version.chapters.length, 1);
      expect(version.chapters[0]['id'], 'ch1');
      expect(version.wordCount, 4);
      expect(version.summary, '测试摘要');
    });

    test('应该能正确处理空章节列表', () {
      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 0,
      );

      final json = version.toJson();
      final recovered = AutobiographyVersion.fromJson(json);

      expect(recovered.chapters, []);
    });

    test('应该能正确处理null summary', () {
      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 0,
      );

      expect(version.summary, null);

      final json = version.toJson();
      expect(json['summary'], null);
    });

    test('应该能正确处理特殊字符', () {
      const specialContent = '''
这是包含特殊字符的内容：
1. emoji: 😊🎉👍
2. 中文标点：「」『』【】
3. 英文标点："'`
4. 换行和制表符
5. 数学符号：≈≠±
''';

      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '特殊字符版本 "测试"',
        content: specialContent,
        chapters: const [
          {
            'id': 'ch1',
            'title': '特殊章节 【测试】',
            'content': specialContent,
          },
        ],
        createdAt: DateTime(2025, 1, 1),
        wordCount: specialContent.length,
      );

      final json = version.toJson();
      final recovered = AutobiographyVersion.fromJson(json);

      expect(recovered.versionName, version.versionName);
      expect(recovered.content, version.content);
      expect(recovered.chapters[0]['title'], version.chapters[0]['title']);
      expect(recovered.chapters[0]['content'], version.chapters[0]['content']);
    });

    test('应该能正确处理大量章节', () {
      final chapters = List.generate(
        50,
        (i) => {
          'id': 'ch$i',
          'title': '第${i + 1}章',
          'content': '章节内容 $i' * 10,
        },
      );

      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '大量章节版本',
        content: '总内容',
        chapters: chapters,
        createdAt: DateTime(2025, 1, 1),
        wordCount: 1000,
      );

      final json = version.toJson();
      final recovered = AutobiographyVersion.fromJson(json);

      expect(recovered.chapters.length, 50);
      expect(recovered.chapters[0]['id'], 'ch0');
      expect(recovered.chapters[49]['id'], 'ch49');
    });

    test('应该支持相等性比较', () {
      final version1 = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 4,
      );

      final version2 = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 4,
      );

      final version3 = AutobiographyVersion(
        id: 'test-id-002', // 不同的ID
        autobiographyId: 'auto-id-001',
        versionName: '测试版本',
        content: '测试内容',
        chapters: const [],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 4,
      );

      expect(version1, version2);
      expect(version1 == version3, false);
      expect(version1.hashCode, version2.hashCode);
    });

    test('应该能正确序列化复杂章节数据', () {
      final complexChapter = {
        'id': 'ch1',
        'title': '复杂章节',
        'content': '章节内容',
        'order': 0,
        'sourceRecordIds': ['rec1', 'rec2', 'rec3'],
        'lastModifiedAt': 1704067200000,
        'metadata': {
          'wordCount': 100,
          'tags': ['童年', '家乡'],
        },
      };

      final version = AutobiographyVersion(
        id: 'test-id-001',
        autobiographyId: 'auto-id-001',
        versionName: '复杂数据版本',
        content: '测试内容',
        chapters: [complexChapter],
        createdAt: DateTime(2025, 1, 1),
        wordCount: 4,
      );

      final json = version.toJson();
      final recovered = AutobiographyVersion.fromJson(json);

      expect(recovered.chapters.length, 1);
      final recoveredChapter = recovered.chapters[0];
      expect(recoveredChapter['id'], 'ch1');
      expect(recoveredChapter['title'], '复杂章节');
      expect((recoveredChapter['sourceRecordIds'] as List).length, 3);
      expect(recoveredChapter['metadata'], isA<Map>());
    });
  });
}
