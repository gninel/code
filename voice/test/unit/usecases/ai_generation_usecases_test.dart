// AI 生成 UseCase 测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/domain/services/autobiography_structure_service.dart';

void main() {
  group('AutobiographyGenerationResult', () {
    test('应该正确创建实例', () {
      final result = AutobiographyGenerationResult(
        content: '测试内容',
        title: '测试标题',
        summary: '测试摘要',
        wordCount: 100,
        style: AutobiographyStyle.narrative,
      );

      expect(result.content, '测试内容');
      expect(result.title, '测试标题');
      expect(result.summary, '测试摘要');
      expect(result.wordCount, 100);
      expect(result.style, AutobiographyStyle.narrative);
    });
  });

  group('IncrementalUpdateResult', () {
    test('创建新章节结果', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: '1',
        title: '新章节',
        content: '章节内容',
        order: 0,
        lastModifiedAt: now,
      );

      final result = IncrementalUpdateResult(
        updateType: UpdateType.newChapter,
        updatedChapter: chapter,
        updateIndex: 0,
      );

      expect(result.updateType, UpdateType.newChapter);
      expect(result.updatedChapter, isNotNull);
      expect(result.updateIndex, 0);
    });

    test('更新现有章节结果', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: '1',
        title: '更新的章节',
        content: '更新的内容',
        order: 1,
        lastModifiedAt: now,
      );

      final result = IncrementalUpdateResult(
        updateType: UpdateType.chapterUpdated,
        updatedChapter: chapter,
        updateIndex: 1,
      );

      expect(result.updateType, UpdateType.chapterUpdated);
      expect(result.updateIndex, 1);
    });

    test('全量替换结果', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: '1',
        title: '完整自传',
        content: '完整内容',
        order: 0,
        lastModifiedAt: now,
      );

      final result = IncrementalUpdateResult(
        updateType: UpdateType.fullReplacement,
        updatedChapter: chapter,
        updateIndex: 0,
      );

      expect(result.updateType, UpdateType.fullReplacement);
    });
  });

  group('UpdateType', () {
    test('所有更新类型应该存在', () {
      expect(UpdateType.values.length, 4);
      expect(UpdateType.values, contains(UpdateType.newChapter));
      expect(UpdateType.values, contains(UpdateType.chapterUpdated));
      expect(UpdateType.values, contains(UpdateType.fullReplacement));
      expect(UpdateType.values, contains(UpdateType.ignored));
    });
  });

  group('StructureUpdatePlan', () {
    test('创建新章节计划', () {
      final plan = StructureUpdatePlan(
        action: StructureAction.createNew,
        newChapterTitle: '新章节标题',
        reasoning: '这是一个全新的主题',
      );

      expect(plan.action, StructureAction.createNew);
      expect(plan.newChapterTitle, '新章节标题');
      expect(plan.reasoning, isNotNull);
    });

    test('更新现有章节计划', () {
      final plan = StructureUpdatePlan(
        action: StructureAction.updateExisting,
        targetChapterIndex: 2,
        reasoning: '内容与第三章相关',
      );

      expect(plan.action, StructureAction.updateExisting);
      expect(plan.targetChapterIndex, 2);
    });

    test('忽略计划', () {
      final plan = StructureUpdatePlan(
        action: StructureAction.ignore,
        reasoning: '内容无效',
      );

      expect(plan.action, StructureAction.ignore);
    });
  });

  group('StructureAction', () {
    test('所有操作类型应该存在', () {
      expect(StructureAction.values.length, 3);
      expect(StructureAction.values, contains(StructureAction.createNew));
      expect(StructureAction.values, contains(StructureAction.updateExisting));
      expect(StructureAction.values, contains(StructureAction.ignore));
    });
  });
}
