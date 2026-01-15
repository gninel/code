// 实体测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';

void main() {
  group('Autobiography', () {
    test('应该正确创建自传实例', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: '1',
        title: '测试标题',
        content: '测试内容',
        generatedAt: now,
        lastModifiedAt: now,
      );

      expect(autobiography.id, '1');
      expect(autobiography.title, '测试标题');
      expect(autobiography.content, '测试内容');
      expect(autobiography.status, AutobiographyStatus.draft);
      expect(autobiography.chapters, isEmpty);
    });

    test('copyWith 应该正确复制并修改属性', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: '1',
        title: '原标题',
        content: '原内容',
        generatedAt: now,
        lastModifiedAt: now,
      );

      final updated = autobiography.copyWith(
        title: '新标题',
        content: '新内容',
        status: AutobiographyStatus.published,
      );

      expect(updated.id, '1'); // 保持不变
      expect(updated.title, '新标题');
      expect(updated.content, '新内容');
      expect(updated.status, AutobiographyStatus.published);
    });

    test('estimatedReadingMinutes 应该正确计算阅读时长', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: '1',
        title: '测试',
        content: 'A' * 400, // 400字
        wordCount: 400,
        generatedAt: now,
        lastModifiedAt: now,
      );

      expect(autobiography.estimatedReadingMinutes, 2); // 400/200 = 2分钟
    });

    test('contentPreview 应该返回前100字符加省略号', () {
      final now = DateTime.now();
      final longContent = 'A' * 200;
      final autobiography = Autobiography(
        id: '1',
        title: '测试',
        content: longContent,
        generatedAt: now,
        lastModifiedAt: now,
      );

      expect(autobiography.contentPreview.length, 103); // 100 + "..."
      expect(autobiography.contentPreview.endsWith('...'), isTrue);
    });

    test('contentPreview 短内容不加省略号', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: '1',
        title: '测试',
        content: '短内容',
        generatedAt: now,
        lastModifiedAt: now,
      );

      expect(autobiography.contentPreview, '短内容');
    });

    test('isEmpty 和 hasContent 应该正确判断', () {
      final now = DateTime.now();

      final emptyAutobiography = Autobiography(
        id: '1',
        title: '测试',
        content: '   ',
        generatedAt: now,
        lastModifiedAt: now,
      );
      expect(emptyAutobiography.isEmpty, isTrue);
      expect(emptyAutobiography.hasContent, isFalse);

      final nonEmptyAutobiography = Autobiography(
        id: '2',
        title: '测试',
        content: '有内容',
        generatedAt: now,
        lastModifiedAt: now,
      );
      expect(nonEmptyAutobiography.isEmpty, isFalse);
      expect(nonEmptyAutobiography.hasContent, isTrue);
    });
  });

  group('AutobiographyStatus', () {
    test('displayName 应该返回正确的中文名称', () {
      expect(AutobiographyStatus.draft.displayName, '草稿');
      expect(AutobiographyStatus.published.displayName, '已发布');
      expect(AutobiographyStatus.archived.displayName, '已归档');
      expect(AutobiographyStatus.editing.displayName, '编辑中');
      expect(AutobiographyStatus.generating.displayName, '生成中');
      expect(AutobiographyStatus.generationFailed.displayName, '生成失败');
    });

    test('isEditable 应该正确判断可编辑状态', () {
      expect(AutobiographyStatus.draft.isEditable, isTrue);
      expect(AutobiographyStatus.editing.isEditable, isTrue);
      expect(AutobiographyStatus.generationFailed.isEditable, isTrue);
      expect(AutobiographyStatus.published.isEditable, isFalse);
      expect(AutobiographyStatus.generating.isEditable, isFalse);
    });

    test('isDeletable 应该正确判断可删除状态', () {
      expect(AutobiographyStatus.draft.isDeletable, isTrue);
      expect(AutobiographyStatus.archived.isDeletable, isTrue);
      expect(AutobiographyStatus.published.isDeletable, isFalse);
      expect(AutobiographyStatus.generating.isDeletable, isFalse);
    });
  });

  group('AutobiographyStyle', () {
    test('所有风格枚举值应该存在', () {
      expect(AutobiographyStyle.values.length, 5);
      expect(AutobiographyStyle.values, contains(AutobiographyStyle.narrative));
      expect(AutobiographyStyle.values, contains(AutobiographyStyle.emotional));
      expect(
          AutobiographyStyle.values, contains(AutobiographyStyle.achievement));
      expect(AutobiographyStyle.values,
          contains(AutobiographyStyle.chronological));
      expect(
          AutobiographyStyle.values, contains(AutobiographyStyle.reflection));
    });
  });

  group('VoiceRecord', () {
    test('应该正确创建语音记录实例', () {
      final now = DateTime.now();
      final record = VoiceRecord(
        id: '1',
        title: '测试录音',
        timestamp: now,
      );

      expect(record.id, '1');
      expect(record.title, '测试录音');
      expect(record.duration, 0);
      expect(record.isProcessed, isFalse);
      expect(record.tags, isEmpty);
    });

    test('copyWith 应该正确复制并修改属性', () {
      final now = DateTime.now();
      final record = VoiceRecord(
        id: '1',
        title: '原标题',
        timestamp: now,
      );

      final updated = record.copyWith(
        title: '新标题',
        transcription: '转写内容',
        isProcessed: true,
      );

      expect(updated.id, '1');
      expect(updated.title, '新标题');
      expect(updated.transcription, '转写内容');
      expect(updated.isProcessed, isTrue);
    });

    test('formattedDuration 应该正确格式化时长', () {
      final now = DateTime.now();

      // 小于1分钟
      final shortRecord = VoiceRecord(
        id: '1',
        title: '短录音',
        duration: 30000, // 30秒
        timestamp: now,
      );
      expect(shortRecord.formattedDuration, '30秒');

      // 1-60分钟
      final mediumRecord = VoiceRecord(
        id: '2',
        title: '中等录音',
        duration: 125000, // 2分5秒
        timestamp: now,
      );
      expect(mediumRecord.formattedDuration, '2:05');

      // 超过1小时
      final longRecord = VoiceRecord(
        id: '3',
        title: '长录音',
        duration: 3725000, // 1小时2分5秒
        timestamp: now,
      );
      expect(longRecord.formattedDuration, '1:02:05');
    });

    test('isValidRecording 应该正确判断有效录音', () {
      final now = DateTime.now();

      final invalidRecord = VoiceRecord(
        id: '1',
        title: '无效录音',
        duration: 500, // 0.5秒
        timestamp: now,
      );
      expect(invalidRecord.isValidRecording, isFalse);

      final validRecord = VoiceRecord(
        id: '2',
        title: '有效录音',
        duration: 1000, // 1秒
        timestamp: now,
      );
      expect(validRecord.isValidRecording, isTrue);
    });
  });

  group('Chapter', () {
    test('应该正确创建章节实例', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: '1',
        title: '第一章',
        content: '章节内容',
        order: 0,
        lastModifiedAt: now,
      );

      expect(chapter.id, '1');
      expect(chapter.title, '第一章');
      expect(chapter.content, '章节内容');
      expect(chapter.order, 0);
    });

    test('copyWith 应该正确复制并修改属性', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: '1',
        title: '原标题',
        content: '原内容',
        order: 0,
        lastModifiedAt: now,
      );

      final updated = chapter.copyWith(
        title: '新标题',
        content: '新内容',
      );

      expect(updated.id, '1');
      expect(updated.title, '新标题');
      expect(updated.content, '新内容');
      expect(updated.order, 0);
    });

    test('wordCount 应该正确计算字数', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: '1',
        title: '测试章节',
        content: '这是一个测试章节的内容', // 11个字符
        order: 0,
        lastModifiedAt: now,
      );

      expect(chapter.wordCount, 11);
    });

    test('contentPreview 应该返回内容预览', () {
      final now = DateTime.now();
      final longContent = 'A' * 200;
      final chapter = Chapter(
        id: '1',
        title: '测试',
        content: longContent,
        order: 0,
        lastModifiedAt: now,
      );

      expect(chapter.contentPreview.length, lessThanOrEqualTo(103));
    });
  });
}
