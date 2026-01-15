import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';

void main() {
  group('Autobiography Entity', () {
    late Autobiography autobiography;

    setUp(() {
      autobiography = Autobiography(
        id: 'bio-1',
        title: '我的自传',
        content: '这是自传的内容...' * 100, // 约1500字
        chapters: [
          Chapter(
            id: 'ch-1',
            title: '第一章：童年',
            content: '童年内容...',
            order: 1,
            sourceRecordIds: const ['vr-1', 'vr-2'],
            lastModifiedAt: DateTime(2024, 12, 26, 10, 0),
          ),
          Chapter(
            id: 'ch-2',
            title: '第二章：少年',
            content: '少年内容...',
            order: 2,
            sourceRecordIds: const ['vr-3'],
            lastModifiedAt: DateTime(2024, 12, 26, 10, 0),
          ),
        ],
        generatedAt: DateTime(2024, 12, 26, 10, 0),
        lastModifiedAt: DateTime(2024, 12, 26, 12, 0),
        version: 2,
        wordCount: 1500,
        voiceRecordIds: const ['vr-1', 'vr-2', 'vr-3'],
        summary: '这是摘要',
        tags: const ['回忆', '成长'],
        status: AutobiographyStatus.draft,
        style: AutobiographyStyle.narrative,
      );
    });

    test('should create Autobiography with all fields', () {
      expect(autobiography.id, 'bio-1');
      expect(autobiography.title, '我的自传');
      expect(autobiography.wordCount, 1500);
      expect(autobiography.version, 2);
      expect(autobiography.chapters.length, 2);
    });

    test('should calculate estimated reading minutes', () {
      expect(autobiography.estimatedReadingMinutes, (1500 / 200).ceil());
    });

    test('should return content preview for long content', () {
      final preview = autobiography.contentPreview;
      expect(preview.length, lessThanOrEqualTo(103)); // 100 + '...'
      expect(preview, endsWith('...'));
    });

    test('should return full content for short content', () {
      final shortBio = autobiography.copyWith(content: '短内容');
      expect(shortBio.contentPreview, '短内容');
    });

    test('should determine if content is empty', () {
      final emptyBio = autobiography.copyWith(content: '   ');
      expect(emptyBio.isEmpty, true);
      expect(emptyBio.hasContent, false);
    });

    test('should determine if content exists', () {
      expect(autobiography.isEmpty, false);
      expect(autobiography.hasContent, true);
    });

    test('should create copy with updated values', () {
      final updated = autobiography.copyWith(
        title: '新标题',
        version: 3,
        status: AutobiographyStatus.published,
      );

      expect(updated.id, autobiography.id);
      expect(updated.title, '新标题');
      expect(updated.version, 3);
      expect(updated.status, AutobiographyStatus.published);
      expect(updated.content, autobiography.content);
    });

    test('should implement equality correctly', () {
      final sameTime = DateTime(2024, 12, 26, 10, 0);

      final bio1 = Autobiography(
        id: 'bio',
        title: 'Test',
        content: 'Content',
        generatedAt: sameTime,
        lastModifiedAt: sameTime,
      );

      final bio2 = Autobiography(
        id: 'bio',
        title: 'Test',
        content: 'Content',
        generatedAt: sameTime,
        lastModifiedAt: sameTime,
      );

      expect(bio1, equals(bio2));
    });

    group('AutobiographyStatus', () {
      test('should return correct display name for each status', () {
        expect(AutobiographyStatus.draft.displayName, '草稿');
        expect(AutobiographyStatus.published.displayName, '已发布');
        expect(AutobiographyStatus.archived.displayName, '已归档');
        expect(AutobiographyStatus.editing.displayName, '编辑中');
        expect(AutobiographyStatus.generating.displayName, '生成中');
        expect(AutobiographyStatus.generationFailed.displayName, '生成失败');
      });

      test('should determine if status is editable', () {
        expect(AutobiographyStatus.draft.isEditable, true);
        expect(AutobiographyStatus.editing.isEditable, true);
        expect(AutobiographyStatus.generationFailed.isEditable, true);
        expect(AutobiographyStatus.published.isEditable, false);
        expect(AutobiographyStatus.archived.isEditable, false);
        expect(AutobiographyStatus.generating.isEditable, false);
      });

      test('should determine if status is deletable', () {
        expect(AutobiographyStatus.draft.isDeletable, true);
        expect(AutobiographyStatus.editing.isDeletable, true);
        expect(AutobiographyStatus.generationFailed.isDeletable, true);
        expect(AutobiographyStatus.archived.isDeletable, true);
        expect(AutobiographyStatus.published.isDeletable, false);
        expect(AutobiographyStatus.generating.isDeletable, false);
      });
    });

    group('Edge Cases', () {
      test('should handle empty chapters list', () {
        final bio = autobiography.copyWith(chapters: []);
        expect(bio.chapters, isEmpty);
      });

      test('should handle zero word count', () {
        final bio = autobiography.copyWith(wordCount: 0);
        expect(bio.estimatedReadingMinutes, 0);
      });

      test('should handle large word count', () {
        final bio = autobiography.copyWith(wordCount: 100000);
        expect(bio.estimatedReadingMinutes, (100000 / 200).ceil());
      });

      test('should handle empty voice record IDs', () {
        final bio = autobiography.copyWith(voiceRecordIds: []);
        expect(bio.voiceRecordIds, isEmpty);
      });

      test('should handle null optional fields', () {
        final bio = Autobiography(
          id: 'test',
          title: 'Test',
          content: 'Content',
          generatedAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );
        expect(bio.summary, null);
        expect(bio.style, null);
        expect(bio.tags, isEmpty);
      });
    });
  });
}
