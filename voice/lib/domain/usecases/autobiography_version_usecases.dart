import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../core/errors/failures.dart';
import '../entities/autobiography.dart';
import '../entities/autobiography_version.dart';
import '../repositories/autobiography_version_repository.dart';

/// 自传版本管理用例
@injectable
class AutobiographyVersionUseCases {
  final AutobiographyVersionRepository _repository;

  AutobiographyVersionUseCases(this._repository);

  /// 保存当前自传为新版本
  Future<Either<Failure, AutobiographyVersion>> saveCurrentAsVersion({
    required Autobiography autobiography,
    String? customName,
  }) async {
    // 如果未提供自定义名称,使用当前日期时间作为默认名称
    final versionName = customName ??
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    return await _repository.saveVersion(
      autobiographyId: autobiography.id,
      versionName: versionName,
      content: autobiography.content,
      chapters: autobiography.chapters.map((chapter) {
        return {
          'id': chapter.id,
          'title': chapter.title,
          'content': chapter.content,
          'order': chapter.order,
          'sourceRecordIds': chapter.sourceRecordIds,
          'lastModifiedAt': chapter.lastModifiedAt.millisecondsSinceEpoch,
        };
      }).toList(),
      wordCount: autobiography.wordCount,
      summary: autobiography.summary,
    );
  }

  /// 获取自传的所有版本
  Future<Either<Failure, List<AutobiographyVersion>>> getVersionsForAutobiography({
    required String autobiographyId,
  }) async {
    return await _repository.getVersions(autobiographyId: autobiographyId);
  }

  /// 获取版本详情
  Future<Either<Failure, AutobiographyVersion>> getVersionDetail({
    required String versionId,
  }) async {
    return await _repository.getVersion(versionId: versionId);
  }

  /// 删除版本
  Future<Either<Failure, void>> deleteVersion({
    required String versionId,
  }) async {
    return await _repository.deleteVersion(versionId: versionId);
  }

  /// 获取版本数量
  Future<Either<Failure, int>> getVersionCount({
    required String autobiographyId,
  }) async {
    return await _repository.getVersionCount(autobiographyId: autobiographyId);
  }
}
