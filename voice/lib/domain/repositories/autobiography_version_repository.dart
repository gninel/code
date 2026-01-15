import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/autobiography_version.dart';

/// 自传版本管理仓库接口
abstract class AutobiographyVersionRepository {
  /// 保存自传版本
  Future<Either<Failure, AutobiographyVersion>> saveVersion({
    required String autobiographyId,
    required String versionName,
    required String content,
    required List<Map<String, dynamic>> chapters,
    required int wordCount,
    String? summary,
  });

  /// 获取某个自传的所有版本
  Future<Either<Failure, List<AutobiographyVersion>>> getVersions({
    required String autobiographyId,
  });

  /// 获取单个版本
  Future<Either<Failure, AutobiographyVersion>> getVersion({
    required String versionId,
  });

  /// 删除版本
  Future<Either<Failure, void>> deleteVersion({
    required String versionId,
  });

  /// 获取版本数量
  Future<Either<Failure, int>> getVersionCount({
    required String autobiographyId,
  });

  /// 删除最旧的版本(用于维护版本数量限制)
  Future<Either<Failure, void>> deleteOldestVersion({
    required String autobiographyId,
  });
}
