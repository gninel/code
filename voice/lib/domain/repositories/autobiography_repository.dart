import 'package:dartz/dartz.dart';

import '../entities/autobiography.dart';
import '../../core/errors/failures.dart';

/// 自传仓库接口
abstract class AutobiographyRepository {
  /// 获取所有自传
  Future<Either<Failure, List<Autobiography>>> getAllAutobiographies();

  /// 根据ID获取自传
  Future<Either<Failure, Autobiography>> getAutobiographyById(String id);

  /// 插入自传
  Future<Either<Failure, void>> insertAutobiography(Autobiography autobiography);

  /// 更新自传
  Future<Either<Failure, void>> updateAutobiography(Autobiography autobiography);

  /// 删除自传
  Future<Either<Failure, void>> deleteAutobiography(String id);

  /// 搜索自传
  Future<Either<Failure, List<Autobiography>>> searchAutobiographies(String query);

  /// 根据状态获取自传
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByStatus(AutobiographyStatus status);

  /// 根据日期范围获取自传
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// 获取最新自传
  Future<Either<Failure, Autobiography?>> getLatestAutobiography();

  /// 获取自传草稿
  Future<Either<Failure, List<Autobiography>>> getDraftAutobiographies();

  /// 获取已发布的自传
  Future<Either<Failure, List<Autobiography>>> getPublishedAutobiographies();

  /// 获取已归档的自传
  Future<Either<Failure, List<Autobiography>>> getArchivedAutobiographies();

  /// 更新自传状态
  Future<Either<Failure, void>> updateAutobiographyStatus(
    String id,
    AutobiographyStatus status,
  );

  /// 批量删除自传
  Future<Either<Failure, void>> deleteAutobiographies(List<String> ids);

  /// 获取自传统计信息
  Future<Either<Failure, Map<String, dynamic>>> getAutobiographyStatistics();

  /// 导出自传
  Future<Either<Failure, String>> exportAutobiography(String id, String format);

  /// 导入自传
  Future<Either<Failure, Autobiography>> importAutobiography(String filePath);

  /// 备份自传数据
  Future<Either<Failure, String>> backupAutobiographies();

  /// 恢复自传数据
  Future<Either<Failure, void>> restoreAutobiographies(String backupPath);
}