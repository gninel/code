import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../../domain/services/autobiography_structure_service.dart';
import '../../domain/entities/chapter.dart';
import 'doubao_ai_service.dart';

/// 结构分析服务实现
@Injectable(as: AutobiographyStructureService)
class AutobiographyStructureServiceImpl implements AutobiographyStructureService {
  final DoubaoAiService _aiService;

  AutobiographyStructureServiceImpl(this._aiService);

  @override
  Future<Either<Failure, StructureUpdatePlan>> analyzeStructure({
    required String newContent,
    required List<Chapter> currentChapters,
  }) async {
    try {
      // 转换章节列表为 Map 格式，供 AI 分析
      final chaptersMap = currentChapters.map((c) => {
        'index': c.order,
        'title': c.title,
        'summary': c.summary ?? c.contentPreview,
      }).toList();

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
      return Left(AiGenerationFailure.contentGenerationFailed(message: e.toString()));
    }
  }
}
