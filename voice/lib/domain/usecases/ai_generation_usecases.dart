import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../entities/voice_record.dart';
import '../entities/autobiography.dart';
import '../entities/chapter.dart';
import '../repositories/ai_generation_repository.dart';
import '../services/autobiography_structure_service.dart';
import '../../core/errors/failures.dart';
import '../../data/services/doubao_ai_service.dart';

/// AI生成用例集合
@injectable
class AiGenerationUseCases {
  final AiGenerationRepository _repository;

  AiGenerationUseCases(this._repository);

  /// 生成自传
  Future<Either<Failure, String>> generateAutobiography({
    required List<VoiceRecord> voiceRecords,
    AutobiographyStyle style = AutobiographyStyle.narrative,
    int? wordCount,
  }) {
    return _repository.generateAutobiography(
      voiceRecords: voiceRecords,
      style: style,
      wordCount: wordCount,
    );
  }

  /// 优化自传内容
  Future<Either<Failure, String>> optimizeAutobiography({
    required String content,
    OptimizationType optimizationType = OptimizationType.clarity,
  }) {
    return _repository.optimizeAutobiography(
      content: content,
      optimizationType: optimizationType,
    );
  }

  /// 生成自传标题
  Future<Either<Failure, String>> generateTitle({
    required String content,
  }) {
    return _repository.generateTitle(content: content);
  }

  /// 生成自传摘要
  Future<Either<Failure, String>> generateSummary({
    required String content,
  }) {
    return _repository.generateSummary(content: content);
  }

  /// 完整生成自传（包含标题和摘要）
  Future<Either<Failure, AutobiographyGenerationResult>> generateCompleteAutobiography({
    required List<VoiceRecord> voiceRecords,
    AutobiographyStyle style = AutobiographyStyle.narrative,
    int? wordCount,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      print('AiGenerationUseCases: Starting complete generation flow');

      // 1. 生成自传内容
      print('AiGenerationUseCases: Step 1 - Generating Content...');
      final contentStart = stopwatch.elapsedMilliseconds;
      final contentResult = await generateAutobiography(
        voiceRecords: voiceRecords,
        style: style,
        wordCount: wordCount,
      );
      final contentEnd = stopwatch.elapsedMilliseconds;
      print('AiGenerationUseCases: Content generation took ${contentEnd - contentStart}ms');

      return contentResult.fold(
        (failure) => Left(failure),
        (content) async {
          // 2. 生成标题
          print('AiGenerationUseCases: Step 2 - Generating Title...');
          final titleStart = stopwatch.elapsedMilliseconds;
          final titleResult = await generateTitle(content: content);
          final titleEnd = stopwatch.elapsedMilliseconds;
          print('AiGenerationUseCases: Title generation took ${titleEnd - titleStart}ms');

          // 3. 生成摘要
          print('AiGenerationUseCases: Step 3 - Generating Summary...');
          final summaryStart = stopwatch.elapsedMilliseconds;
          final summaryResult = await generateSummary(content: content);
          final summaryEnd = stopwatch.elapsedMilliseconds;
          print('AiGenerationUseCases: Summary generation took ${summaryEnd - summaryStart}ms');

          stopwatch.stop();
          print('AiGenerationUseCases: Total generation took ${stopwatch.elapsedMilliseconds}ms');

          // 处理生成结果
          String title = '';
          String summary = '';

          titleResult.fold(
            (failure) => title = '我的自传', // 使用默认标题
            (generatedTitle) => title = generatedTitle,
          );

          summaryResult.fold(
            (failure) => summary = '', // 摘要可选
            (generatedSummary) => summary = generatedSummary,
          );

          return Right(AutobiographyGenerationResult(
            content: content,
            title: title,
            summary: summary,
            wordCount: content.length,
            style: style,
          ));
        },
      );
    } catch (e) {
      return Left(AiGenerationFailure.contentGenerationFailed());
    }
  }

  /// 增量更新自传（智能章节管理）
  /// [newVoiceContent] 新的语音转写内容
  /// [currentAutobiography] 当前的自传实体（可为null表示全新生成）
  /// 返回：更新后的自传生成结果，包含更新位置信息
  Future<Either<Failure, IncrementalUpdateResult>> incrementalUpdateAutobiography({
    required String newVoiceContent,
    Autobiography? currentAutobiography,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      print('AiGenerationUseCases: Starting incremental update flow');

      // 获取当前章节列表
      final currentChapters = currentAutobiography?.chapters ?? [];

      // Step 1: 结构分析 - 决定如何处理新内容
      print('AiGenerationUseCases: Step 1 - Analyzing structure...');
      final structureResult = await _repository.analyzeStructure(
        newContent: newVoiceContent,
        currentChapters: currentChapters,
      );

      return structureResult.fold(
        (failure) => Left(failure),
        (plan) async {
          print('AiGenerationUseCases: Structure plan: ${plan.action}, reason: ${plan.reasoning}');

          // Step 2: 根据计划生成或更新内容
          print('AiGenerationUseCases: Step 2 - Generating/updating content...');
          
          Chapter? updatedChapter;
          int updateIndex = -1;
          
          switch (plan.action) {
            case StructureAction.createNew:
              // 创建新章节
              final contentResult = await _repository.generateChapterContent(
                originalContent: null,
                newVoiceContent: newVoiceContent,
              );
              
              return contentResult.fold(
                (failure) => Left(failure),
                (content) {
                  final newOrder = currentChapters.isEmpty ? 0 : currentChapters.length;
                  updatedChapter = Chapter(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: plan.newChapterTitle ?? '第${newOrder + 1}章',
                    content: content,
                    order: newOrder,
                    sourceRecordIds: [],
                    lastModifiedAt: DateTime.now(),
                  );
                  updateIndex = newOrder;

                  stopwatch.stop();
                  print('AiGenerationUseCases: Incremental update took ${stopwatch.elapsedMilliseconds}ms');

                  return Right(IncrementalUpdateResult(
                    updatedChapter: updatedChapter!,
                    updateType: UpdateType.newChapter,
                    updateIndex: updateIndex,
                  ));
                },
              );

            case StructureAction.updateExisting:
              // 更新现有章节
              final targetIndex = plan.targetChapterIndex ?? 0;
              if (targetIndex >= currentChapters.length) {
                return Left(AiGenerationFailure.contentGenerationFailed(message: 'Invalid chapter index'));
              }
              
              final existingChapter = currentChapters[targetIndex];
              final contentResult = await _repository.generateChapterContent(
                originalContent: existingChapter.content,
                newVoiceContent: newVoiceContent,
              );
              
              return contentResult.fold(
                (failure) => Left(failure),
                (content) {
                  updatedChapter = existingChapter.copyWith(
                    content: content,
                    lastModifiedAt: DateTime.now(),
                  );
                  updateIndex = targetIndex;

                  stopwatch.stop();
                  print('AiGenerationUseCases: Incremental update took ${stopwatch.elapsedMilliseconds}ms');

                  return Right(IncrementalUpdateResult(
                    updatedChapter: updatedChapter!,
                    updateType: UpdateType.chapterUpdated,
                    updateIndex: updateIndex,
                  ));
                },
              );

            case StructureAction.ignore:
              // 无实质内容，忽略
              stopwatch.stop();
              return Right(IncrementalUpdateResult(
                updatedChapter: null,
                updateType: UpdateType.ignored,
                updateIndex: -1,
              ));
          }
        },
      );
    } catch (e) {
      print('AiGenerationUseCases: Incremental update error: $e');
      return Left(AiGenerationFailure.contentGenerationFailed(message: e.toString()));
    }
  }
}

/// 增量更新结果
class IncrementalUpdateResult {
  final Chapter? updatedChapter;
  final UpdateType updateType;
  final int updateIndex;

  IncrementalUpdateResult({
    this.updatedChapter,
    required this.updateType,
    required this.updateIndex,
  });
}

enum UpdateType {
  newChapter,
  chapterUpdated,
  ignored,
}

/// 自传生成结果
class AutobiographyGenerationResult {
  final String content;
  final String title;
  final String summary;
  final int wordCount;
  final AutobiographyStyle style;
  final DateTime generatedAt;

  AutobiographyGenerationResult({
    required this.content,
    required this.title,
    required this.summary,
    required this.wordCount,
    required this.style,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// 获取阅读时长（估算）
  int get estimatedReadingMinutes => (wordCount / 200).ceil();

  /// 获取内容预览
  String get contentPreview {
    if (content.length <= 100) {
      return content;
    }
    return '${content.substring(0, 100)}...';
  }

  /// 转换为Autobiography实体
  Autobiography toAutobiography({
    required String id,
    List<String> voiceRecordIds = const [],
    List<String> tags = const [],
  }) {
    return Autobiography(
      id: id,
      title: title,
      content: content,
      generatedAt: generatedAt,
      lastModifiedAt: generatedAt,
      wordCount: wordCount,
      voiceRecordIds: voiceRecordIds,
      summary: summary.isNotEmpty ? summary : null,
      tags: tags,
      status: AutobiographyStatus.draft,
    );
  }

  AutobiographyGenerationResult copyWith({
    String? content,
    String? title,
    String? summary,
    int? wordCount,
    AutobiographyStyle? style,
    DateTime? generatedAt,
  }) {
    return AutobiographyGenerationResult(
      content: content ?? this.content,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      wordCount: wordCount ?? this.wordCount,
      style: style ?? this.style,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}