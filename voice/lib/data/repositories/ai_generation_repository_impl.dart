import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../domain/repositories/ai_generation_repository.dart';
import '../../domain/entities/voice_record.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/autobiography.dart';
import '../../domain/services/autobiography_structure_service.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../services/doubao_ai_service.dart';

/// AI生成仓库实现
@LazySingleton(as: AiGenerationRepository)
class AiGenerationRepositoryImpl implements AiGenerationRepository {
  final DoubaoAiService _aiService;

  AiGenerationRepositoryImpl(this._aiService);

  @override
  Future<Either<Failure, String>> generateAutobiography({
    required List<VoiceRecord> voiceRecords,
    AutobiographyStyle style = AutobiographyStyle.narrative,
    int? wordCount,
  }) async {
    try {
      // 提取语音记录的文本内容
      // 优先使用content字段(包含问题和回答),如果没有则使用transcription
      final voiceContents = voiceRecords
          .where((record) =>
              (record.content.isNotEmpty) ||
              (record.transcription != null && record.transcription!.isNotEmpty))
          .map((record) => record.content.isNotEmpty == true
              ? record.content
              : record.transcription!)
          .toList();

      if (voiceContents.isEmpty) {
        return Left(AiGenerationFailure.contentGenerationFailed());
      }

      // 调用AI服务生成自传
      final content = await _aiService.generateAutobiography(
        voiceContents: voiceContents,
        style: style,
        wordCount: wordCount,
      );

      return Right(content);
    } on AiGenerationException catch (e) {
      if (e.message.contains('API密钥')) {
        return Left(AiGenerationFailure.invalidApiKey());
      } else if (e.message.contains('次数已超限')) {
        return Left(AiGenerationFailure.quotaExceeded());
      } else if (e.message.contains('服务暂时不可用')) {
        return Left(AiGenerationFailure.serviceUnavailable());
      } else {
        return Left(AiGenerationFailure.contentGenerationFailed());
      }
    } on NetworkException catch (e) {
      if (e.message.contains('服务器错误')) {
        return Left(AiGenerationFailure.serviceUnavailable());
      } else if (e.message.contains('网络连接')) {
        return Left(AiGenerationFailure.serviceUnavailable());
      } else {
        return Left(AiGenerationFailure.serviceUnavailable());
      }
    } catch (e) {
      return Left(AiGenerationFailure.contentGenerationFailed());
    }
  }

  @override
  Future<Either<Failure, String>> optimizeAutobiography({
    required String content,
    OptimizationType optimizationType = OptimizationType.clarity,
  }) async {
    try {
      if (content.trim().isEmpty) {
        return Left(AiGenerationFailure.contentGenerationFailed());
      }

      final optimizedContent = await _aiService.optimizeAutobiography(
        originalContent: content,
        optimizationType: optimizationType,
      );

      return Right(optimizedContent);
    } on AiGenerationException catch (e) {
      if (e.message.contains('API密钥')) {
        return Left(AiGenerationFailure.invalidApiKey());
      } else if (e.message.contains('次数已超限')) {
        return Left(AiGenerationFailure.quotaExceeded());
      } else {
        return Left(AiGenerationFailure.contentGenerationFailed());
      }
    } catch (e) {
      return Left(AiGenerationFailure.contentGenerationFailed());
    }
  }

  @override
  Future<Either<Failure, String>> generateTitle({
    required String content,
  }) async {
    try {
      if (content.trim().isEmpty) {
        return const Right('我的自传'); // 返回默认标题
      }

      final title = await _aiService.generateTitle(content);

      return Right(title);
    } on AiGenerationException catch (e) {
      if (e.message.contains('API密钥')) {
        return Left(AiGenerationFailure.invalidApiKey());
      } else if (e.message.contains('次数已超限')) {
        return Left(AiGenerationFailure.quotaExceeded());
      } else {
        return const Right('我的自传'); // 返回默认标题
      }
    } catch (e) {
      return const Right('我的自传'); // 返回默认标题
    }
  }

  @override
  Future<Either<Failure, String>> generateSummary({
    required String content,
  }) async {
    try {
      if (content.trim().isEmpty) {
        return const Right(''); // 摘要可以为空
      }

      final summary = await _aiService.generateSummary(content);

      return Right(summary);
    } on AiGenerationException catch (e) {
      if (e.message.contains('API密钥')) {
        return Left(AiGenerationFailure.invalidApiKey());
      } else if (e.message.contains('次数已超限')) {
        return Left(AiGenerationFailure.quotaExceeded());
      } else {
        return const Right(''); // 摘要可以为空
      }
    } catch (e) {
      return const Right(''); // 摘要可以为空
    }
  }

  @override
  Future<Either<Failure, StructureUpdatePlan>> analyzeStructure({
    required String newContent,
    required List<Chapter> currentChapters,
  }) async {
    try {
      // 转换章节列表为 Map 格式，供 AI 分析
      final chaptersMap = currentChapters
          .map((c) => <String, dynamic>{
                'index': c.order,
                'title': c.title,
                'summary': c.summary ?? c.contentPreview,
              })
          .toList();

      final result = await _aiService.analyzeAutobiographyStructure(
        newContent: newContent,
        currentChapters: chaptersMap,
      );

      final actionStr = result['action'] as String;
      final targetIndex = result['targetChapterIndex'] as int?;
      final newTitle = result['newChapterTitle'] as String?;
      final reasoning = result['reasoning'] as String?;

      StructureAction action;
      switch (actionStr) {
        case 'createNew':
          action = StructureAction.createNew;
          break;
        case 'updateExisting':
          action = StructureAction.updateExisting;
          break;
        case 'ignore':
        default:
          action = StructureAction.ignore;
          break;
      }

      return Right(StructureUpdatePlan(
        action: action,
        targetChapterIndex: targetIndex,
        newChapterTitle: newTitle,
        reasoning: reasoning,
      ));
    } catch (e) {
      return Left(
          AiGenerationFailure.contentGenerationFailed(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateChapterContent({
    String? originalContent,
    required String newVoiceContent,
  }) async {
    try {
      final content = await _aiService.generateChapterContent(
        originalContent: originalContent,
        newVoiceContent: newVoiceContent,
      );
      return Right(content);
    } on AiGenerationException catch (e) {
      return Left(
          AiGenerationFailure.contentGenerationFailed(message: e.message));
    } catch (e) {
      return Left(
          AiGenerationFailure.contentGenerationFailed(message: e.toString()));
    }
  }
}
