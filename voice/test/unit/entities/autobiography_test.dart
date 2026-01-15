import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';

void main() {
  group('Autobiography Entity', () {
    late DateTime now;
    late Autobiography autobiography;

    setUp(() {
      now = DateTime.now();
      autobiography = Autobiography(
        id: 'bio-id-123',
        title: '我的自传',
        content: '这是自传内容',
        chapters: const [],
        generatedAt: now,
        lastModifiedAt: now.add(const Duration(days: 1)),
        version: 1,
        wordCount: 1000,
        voiceRecordIds: const ['record1', 'record2'],
        summary: '这是摘要',
        tags: const ['传记', '回忆'],
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );
    });

    test('应该正确创建Autobiography实例', () {
      expect(autobiography.id, 'bio-id-123');
      expect(autobiography.title, '我的自传');
      expect(autobiography.content, '这是自传内容');
      expect(autobiography.version, 1);
      expect(autobiography.wordCount, 1000);
      expect(autobiography.status, AutobiographyStatus.draft);
      expect(autobiography.style, AutobiographyStyle.narrative);
    });

    test('应该正确处理默认值', () {
      final bio = Autobiography(
        id: 'test-id',
        title: '标题',
        content: '内容',
        generatedAt: now,
        lastModifiedAt: now,
      );

      expect(bio.chapters, isEmpty);
      expect(bio.version, isNull);
      expect(bio.wordCount, isNull);
      expect(bio.voiceRecordIds, isEmpty);
      expect(bio.summary, isNull);
      expect(bio.tags, isEmpty);
      expect(bio.status, AutobiographyStatus.draft);
      expect(bio.style, isNull);
    });

    group('AutobiographyStatus', () {
      test('所有状态值应该正确定义', () {
        expect(AutobiographyStatus.draft, isNotNull);
        expect(AutobiographyStatus.published, isNotNull);
        expect(AutobiographyStatus.archived, isNotNull);
        expect(AutobiographyStatus.editing, isNotNull);
        expect(AutobiographyStatus.generating, isNotNull);
        expect(AutobiographyStatus.generationFailed, isNotNull);
      });

      test('状态应该可以比较', () {
        expect(AutobiographyStatus.draft, AutobiographyStatus.draft);
        expect(AutobiographyStatus.draft, isNot(AutobiographyStatus.published));
      });
    });

    group('AutobiographyStyle', () {
      test('所有风格值应该正确定义', () {
        expect(AutobiographyStyle.narrative, isNotNull);
        expect(AutobiographyStyle.emotional, isNotNull);
        expect(AutobiographyStyle.achievement, isNotNull);
        expect(AutobiographyStyle.chronological, isNotNull);
        expect(AutobiographyStyle.reflection, isNotNull);
      });

      test('风格应该可以比较', () {
        expect(AutobiographyStyle.narrative, AutobiographyStyle.narrative);
        expect(AutobiographyStyle.narrative, isNot(AutobiographyStyle.emotional));
      });
    });

    group('Chapter', () {
      test('应该正确创建Chapter实例', () {
        final chapter = Chapter(
          id: 'chapter-1',
          title: '第一章',
          content: '章节内容',
          order: 1,
          sourceRecordIds: const ['record1'],
          summary: '章节摘要',
          lastModifiedAt: now,
        );

        expect(chapter.id, 'chapter-1');
        expect(chapter.title, '第一章');
        expect(chapter.order, 1);
      });

      test('Chapter应该处理默认值', () {
        final chapter = Chapter(
          id: 'test',
          title: 'test',
          content: 'content',
          order: 0,
          lastModifiedAt: DateTime.now(),
        );

        expect(chapter.sourceRecordIds, isEmpty);
        expect(chapter.summary, isNull);
      });

      test('Chapter应该支持copyWith', () {
        const chapter = Chapter(
          id: 'test',
          title: '原始标题',
          content: '内容',
          order: 1,
        );

        final updated = chapter.copyWith(
          title: '新标题',
          order: 2,
        );

        expect(updated.id, chapter.id);
        expect(updated.title, '新标题');
        expect(updated.order, 2);
        expect(updated.content, chapter.content);
      });
    });

    group('copyWith', () {
      test('应该正确复制并修改属性', () {
        final copied = autobiography.copyWith(
          title: '新标题',
          version: 2,
        );

        expect(copied.id, autobiography.id);
        expect(copied.title, '新标题');
        expect(copied.version, 2);
        expect(copied.content, autobiography.content);
      });

      test('应该支持列表更新', () {
        final copied = autobiography.copyWith(
          voiceRecordIds: ['newRecord'],
          tags: ['新标签'],
        );

        expect(copied.voiceRecordIds, ['newRecord']);
        expect(copied.tags, ['新标签']);
      });

      test('应该支持状态和风格更新', () {
        final copied = autobiography.copyWith(
          status: AutobiographyStatus.published,
          style: AutobiographyStyle.reflection,
        );

        expect(copied.status, AutobiographyStatus.published);
        expect(copied.style, AutobiographyStyle.reflection);
      });
    });

    group('Equatable', () {
      test('相同属性的Autobiography应该相等', () {
        final bio1 = Autobiography(
          id: 'test',
          title: 'test',
          content: 'content',
          generatedAt: now,
          lastModifiedAt: now,
        );
        final bio2 = Autobiography(
          id: 'test',
          title: 'test',
          content: 'content',
          generatedAt: now,
          lastModifiedAt: now,
        );

        expect(bio1, equals(bio2));
      });

      test('不同属性的Autobiography应该不相等', () {
        final bio1 = Autobiography(
          id: 'test1',
          title: 'test',
          content: 'content',
          generatedAt: now,
          lastModifiedAt: now,
        );
        final bio2 = Autobiography(
          id: 'test2',
          title: 'test',
          content: 'content',
          generatedAt: now,
          lastModifiedAt: now,
        );

        expect(bio1, isNot(equals(bio2)));
      });

      test('chapters应该影响相等性', () {
        const chapter1 = Chapter(
          id: 'c1',
          title: '第一章',
          content: '内容',
          order: 1,
        );

        final bio1 = Autobiography(
          id: 'test',
          title: 'test',
          content: 'content',
          generatedAt: now,
          lastModifiedAt: now,
          chapters: const [chapter1],
        );

        final bio2 = Autobiography(
          id: 'test',
          title: 'test',
          content: 'content',
          generatedAt: now,
          lastModifiedAt: now,
          chapters: const [],
        );

        expect(bio1, isNot(equals(bio2)));
      });
    });

    group('边界情况', () {
      test('应该处理空chapters列表', () {
        final bio = autobiography.copyWith(chapters: []);
        expect(bio.chapters, isEmpty);
      });

      test('应该处理大量chapters', () {
        final chapters = List.generate(
          100,
          (index) => Chapter(
            id: 'chapter-$index',
            title: '章节$index',
            content: '内容$index',
            order: index,
          ),
        );

        final bio = autobiography.copyWith(chapters: chapters);
        expect(bio.chapters.length, 100);
      });

      test('应该处理很大的wordCount', () {
        final bio = autobiography.copyWith(wordCount: 1000000);
        expect(bio.wordCount, 1000000);
      });

      test('应该处理很长的voiceRecordIds列表', () {
        final ids = List.generate(1000, (index) => 'record-$index');
        final bio = autobiography.copyWith(voiceRecordIds: ids);
        expect(bio.voiceRecordIds.length, 1000);
      });

      test('应该处理多个tags', () {
        final tags = List.generate(50, (index) => 'tag-$index');
        final bio = autobiography.copyWith(tags: tags);
        expect(bio.tags.length, 50);
      });
    });

    group('时间相关', () {
      test('generatedAt应该早于lastModifiedAt', () {
        expect(
          autobiography.generatedAt.isBefore(autobiography.lastModifiedAt),
          true,
        );
      });

      test('应该处理相同的时间', () {
        final sameTime = DateTime.now();
        final bio = Autobiography(
          id: 'test',
          title: 'test',
          content: 'content',
          generatedAt: sameTime,
          lastModifiedAt: sameTime,
        );

        expect(bio.generatedAt, sameTime);
        expect(bio.lastModifiedAt, sameTime);
      });
    });

    group('Chapter Equatable', () {
      test('相同属性的Chapter应该相等', () {
        const chapter1 = Chapter(
          id: 'test',
          title: 'test',
          content: 'content',
          order: 1,
        );
        const chapter2 = Chapter(
          id: 'test',
          title: 'test',
          content: 'content',
          order: 1,
        );

        expect(chapter1, equals(chapter2));
      });

      test('sourceRecordIds应该影响相等性', () {
        const chapter1 = Chapter(
          id: 'test',
          title: 'test',
          content: 'content',
          order: 1,
          sourceRecordIds: ['record1'],
        );
        const chapter2 = Chapter(
          id: 'test',
          title: 'test',
          content: 'content',
          order: 1,
          sourceRecordIds: ['record2'],
        );

        expect(chapter1, isNot(equals(chapter2)));
      });
    });
  });
}
