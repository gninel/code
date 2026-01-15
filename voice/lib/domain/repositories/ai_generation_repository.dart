import 'package:dartz/dartz.dart';

import '../entities/voice_record.dart';
import '../entities/chapter.dart';
import '../entities/autobiography.dart';
import '../services/autobiography_structure_service.dart';
import '../../core/errors/failures.dart';

/// AI生成仓库接口
abstract class AiGenerationRepository {
  /// 生成自传
  Future<Either<Failure, String>> generateAutobiography({
    required List<VoiceRecord> voiceRecords,
    AutobiographyStyle style,
    int? wordCount,
  });

  /// 优化自传内容
  Future<Either<Failure, String>> optimizeAutobiography({
    required String content,
    OptimizationType optimizationType,
  });

  /// 生成自传标题
  Future<Either<Failure, String>> generateTitle({
    required String content,
  });

  /// 生成自传摘要
  Future<Either<Failure, String>> generateSummary({
    required String content,
  });

  /// 分析自传结构
  Future<Either<Failure, StructureUpdatePlan>> analyzeStructure({
    required String newContent,
    required List<Chapter> currentChapters,
  });

  /// 生成或合并章节内容
  Future<Either<Failure, String>> generateChapterContent({
    String? originalContent,
    required String newVoiceContent,
  });
}