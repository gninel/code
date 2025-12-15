import 'package:dartz/dartz.dart';
import '../../domain/entities/autobiography.dart';
import '../../domain/repositories/autobiography_repository.dart';
import '../../core/errors/failures.dart';

/// Mock implementation - 不再注册为默认实现
/// 真正的实现在 file_autobiography_repository.dart
class MockAutobiographyRepository implements AutobiographyRepository {
  @override
  Future<Either<Failure, List<Autobiography>>> getAllAutobiographies() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Autobiography>> getAutobiographyById(String id) async {
    return Left(CacheFailure.cacheMiss());
  }

  @override
  Future<Either<Failure, void>> insertAutobiography(Autobiography autobiography) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateAutobiography(Autobiography autobiography) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteAutobiography(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Autobiography>>> searchAutobiographies(String query) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByStatus(AutobiographyStatus status) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByDateRange(DateTime startDate, DateTime endDate) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Autobiography?>> getLatestAutobiography() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getDraftAutobiographies() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getPublishedAutobiographies() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getArchivedAutobiographies() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> updateAutobiographyStatus(String id, AutobiographyStatus status) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteAutobiographies(List<String> ids) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAutobiographyStatistics() async {
    return const Right({});
  }

  @override
  Future<Either<Failure, String>> exportAutobiography(String id, String format) async {
    return const Right("path/to/exported/file");
  }

  @override
  Future<Either<Failure, Autobiography>> importAutobiography(String filePath) async {
    return Left(PlatformFailure.notSupported());
  }

  @override
  Future<Either<Failure, String>> backupAutobiographies() async {
    return const Right("path/to/backup");
  }

  @override
  Future<Either<Failure, void>> restoreAutobiographies(String backupPath) async {
    return const Right(null);
  }
}
