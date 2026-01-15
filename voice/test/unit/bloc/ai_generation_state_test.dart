// AI 生成 Bloc 状态测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_state.dart';
import 'package:voice_autobiography_flutter/domain/usecases/ai_generation_usecases.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';

void main() {
  group('AiGenerationState', () {
    test('初始状态应该是 idle', () {
      const state = AiGenerationState();
      expect(state.status, AiGenerationStatus.idle);
      expect(state.isIdle, isTrue);
      expect(state.isGenerating, isFalse);
      expect(state.hasGeneratedContent, isFalse);
    });

    test('copyWith 应该正确复制并修改属性', () {
      const state = AiGenerationState();
      final updated = state.copyWith(
        status: AiGenerationStatus.generating,
        generatedContent: '测试内容',
      );

      expect(updated.status, AiGenerationStatus.generating);
      expect(updated.generatedContent, '测试内容');
      expect(updated.isGenerating, isTrue);
    });

    test('isGenerating 应该正确判断生成状态', () {
      const idle = AiGenerationState();
      expect(idle.isGenerating, isFalse);

      const generating =
          AiGenerationState(status: AiGenerationStatus.generating);
      expect(generating.isGenerating, isTrue);
    });

    test('isOptimizing 应该正确判断优化状态', () {
      const optimizing =
          AiGenerationState(status: AiGenerationStatus.optimizing);
      expect(optimizing.isOptimizing, isTrue);
    });

    test('isCompleted 应该正确判断完成状态', () {
      const completed = AiGenerationState(status: AiGenerationStatus.completed);
      expect(completed.isCompleted, isTrue);
    });

    test('hasError 应该正确判断错误状态', () {
      const error = AiGenerationState(status: AiGenerationStatus.error);
      expect(error.hasError, isTrue);
    });

    test('hasGeneratedContent 应该正确判断内容', () {
      const noContent = AiGenerationState();
      expect(noContent.hasGeneratedContent, isFalse);

      const emptyContent = AiGenerationState(generatedContent: '');
      expect(emptyContent.hasGeneratedContent, isFalse);

      const hasContent = AiGenerationState(generatedContent: '有内容');
      expect(hasContent.hasGeneratedContent, isTrue);
    });

    test('hasTitle 应该正确判断标题', () {
      const noTitle = AiGenerationState();
      expect(noTitle.hasTitle, isFalse);

      const hasTitle = AiGenerationState(generatedTitle: '标题');
      expect(hasTitle.hasTitle, isTrue);
    });

    test('hasSummary 应该正确判断摘要', () {
      const noSummary = AiGenerationState();
      expect(noSummary.hasSummary, isFalse);

      const hasSummary = AiGenerationState(generatedSummary: '摘要');
      expect(hasSummary.hasSummary, isTrue);
    });

    test('wordCount 应该正确计算字数', () {
      const noContent = AiGenerationState();
      expect(noContent.wordCount, 0);

      const hasContent = AiGenerationState(generatedContent: '测试内容12345');
      expect(hasContent.wordCount, 9); // '测试内容12345' = 9个字符
    });

    test('estimatedReadingMinutes 应该正确计算阅读时间', () {
      final longContent = 'A' * 400;
      final state = AiGenerationState(generatedContent: longContent);
      expect(state.estimatedReadingMinutes, 2); // 400/200 = 2
    });

    test('progressDescription 应该返回正确描述', () {
      expect(
          const AiGenerationState(status: AiGenerationStatus.idle)
              .progressDescription,
          '准备生成自传');
      expect(
          const AiGenerationState(status: AiGenerationStatus.generating)
              .progressDescription,
          '正在生成自传内容...');
      expect(
          const AiGenerationState(status: AiGenerationStatus.optimizing)
              .progressDescription,
          '正在优化内容...');
      expect(
          const AiGenerationState(status: AiGenerationStatus.completed)
              .progressDescription,
          '自传生成完成');
      expect(
          const AiGenerationState(status: AiGenerationStatus.error)
              .progressDescription,
          '生成失败');
    });

    test('statusColor 应该返回正确颜色', () {
      expect(
          const AiGenerationState(status: AiGenerationStatus.idle).statusColor,
          0xFF9E9E9E);
      expect(
          const AiGenerationState(status: AiGenerationStatus.generating)
              .statusColor,
          0xFF1976D2);
      expect(
          const AiGenerationState(status: AiGenerationStatus.completed)
              .statusColor,
          0xFF4CAF50);
      expect(
          const AiGenerationState(status: AiGenerationStatus.error).statusColor,
          0xFFF44336);
    });
  });

  group('AiGenerationStatus', () {
    test('displayName 应该返回正确的中文名称', () {
      expect(AiGenerationStatus.idle.displayName, '准备就绪');
      expect(AiGenerationStatus.generating.displayName, '生成中');
      expect(AiGenerationStatus.optimizing.displayName, '优化中');
      expect(AiGenerationStatus.completed.displayName, '生成完成');
      expect(AiGenerationStatus.optimized.displayName, '优化完成');
      expect(AiGenerationStatus.error.displayName, '生成失败');
    });

    test('canStart 应该正确判断可开始状态', () {
      expect(AiGenerationStatus.idle.canStart, isTrue);
      expect(AiGenerationStatus.error.canStart, isTrue);
      expect(AiGenerationStatus.generating.canStart, isFalse);
      expect(AiGenerationStatus.completed.canStart, isFalse);
    });

    test('canOptimize 应该正确判断可优化状态', () {
      expect(AiGenerationStatus.completed.canOptimize, isTrue);
      expect(AiGenerationStatus.optimized.canOptimize, isTrue);
      expect(AiGenerationStatus.idle.canOptimize, isFalse);
      expect(AiGenerationStatus.generating.canOptimize, isFalse);
    });

    test('canRegenerate 应该正确判断可重新生成状态', () {
      expect(AiGenerationStatus.idle.canRegenerate, isTrue);
      expect(AiGenerationStatus.completed.canRegenerate, isTrue);
      expect(AiGenerationStatus.error.canRegenerate, isTrue);
      expect(AiGenerationStatus.generating.canRegenerate, isFalse);
    });
  });

  group('AutobiographyGenerationResult', () {
    test('应该正确创建生成结果', () {
      final result = AutobiographyGenerationResult(
        content: '自传内容',
        title: '自传标题',
        summary: '自传摘要',
        wordCount: 100,
        style: AutobiographyStyle.narrative,
      );

      expect(result.content, '自传内容');
      expect(result.title, '自传标题');
      expect(result.summary, '自传摘要');
      expect(result.wordCount, 100);
      expect(result.style, AutobiographyStyle.narrative);
    });
  });
}
