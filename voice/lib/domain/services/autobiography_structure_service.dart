import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/chapter.dart';

/// 结构分析服务
/// 负责分析新内容应该如何融入现有自传结构
abstract class AutobiographyStructureService {
  /// 分析结构更新计划
  /// [newContent] 新的语音转写内容
  /// [currentChapters] 当前章节列表
  /// 返回：更新计划（可能是新建章节，或者是合并到某个章节）
  Future<Either<Failure, StructureUpdatePlan>> analyzeStructure({
    required String newContent,
    required List<Chapter> currentChapters,
  });
}

/// 结构更新计划
class StructureUpdatePlan {
  final StructureAction action;
  final int? targetChapterIndex; // 如果是 update 或 insert，目标索引
  final String? newChapterTitle; // 如果是 create，新章节标题
  final String? reasoning; // AI的决策理由

  StructureUpdatePlan({
    required this.action,
    this.targetChapterIndex,
    this.newChapterTitle,
    this.reasoning,
  });
}

enum StructureAction {
  /// 创建新章节
  createNew,

  /// 更新现有章节
  updateExisting,

  /// 忽略（无实质内容）
  ignore,
}
