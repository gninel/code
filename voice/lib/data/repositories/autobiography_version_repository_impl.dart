import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/autobiography_version.dart';
import '../../domain/repositories/autobiography_version_repository.dart';
import '../services/database_service.dart';

/// 自传版本管理仓库实现
@LazySingleton(as: AutobiographyVersionRepository)
class AutobiographyVersionRepositoryImpl
    implements AutobiographyVersionRepository {
  final DatabaseService _databaseService;

  AutobiographyVersionRepositoryImpl(this._databaseService);

  @override
  Future<Either<Failure, AutobiographyVersion>> saveVersion({
    required String autobiographyId,
    required String versionName,
    required String content,
    required List<Map<String, dynamic>> chapters,
    required int wordCount,
    String? summary,
  }) async {
    try {
      print('[AutobiographyVersionRepo] 开始保存版本: $versionName');
      print('[AutobiographyVersionRepo] autobiographyId: $autobiographyId');

      // 检查版本数量,如果已达上限,删除最旧的版本
      final countResult =
          await getVersionCount(autobiographyId: autobiographyId);
      await countResult.fold(
        (failure) => Future.value(),
        (count) async {
          print('[AutobiographyVersionRepo] 当前版本数量: $count');
          if (count >= AppConstants.maxAutobiographyVersions) {
            print('[AutobiographyVersionRepo] 已达版本上限,删除最旧版本');
            await deleteOldestVersion(autobiographyId: autobiographyId);
          }
        },
      );

      final version = AutobiographyVersion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        autobiographyId: autobiographyId,
        versionName: versionName,
        content: content,
        chapters: chapters,
        createdAt: DateTime.now(),
        wordCount: wordCount,
        summary: summary,
      );

      final data = {
        'id': version.id,
        'autobiography_id': version.autobiographyId,
        'version_name': version.versionName,
        'content': version.content,
        'chapters': jsonEncode(version.chapters),
        'word_count': version.wordCount,
        'summary': version.summary,
        'created_at': version.createdAt.millisecondsSinceEpoch,
      };

      print(
          '[AutobiographyVersionRepo] 准备插入数据库, version.id: ${version.id}, autoId: $autobiographyId');
      final id = await _databaseService.insert(
          DatabaseTables.autobiographyVersions, data);
      print('[AutobiographyVersionRepo] 数据库插入返回ID: $id');

      // 立即验证读取
      final verify = await _databaseService.query(
          DatabaseTables.autobiographyVersions,
          where: 'id = ?',
          whereArgs: [version.id]);
      print(
          '[AutobiographyVersionRepo] 立即验证插入结果: ${verify.isNotEmpty ? "Found" : "Not Found"}');

      return Right(version);
    } on DatabaseException {
      return Left(DatabaseFailure.insertFailed());
    } catch (e) {
      return Left(UnknownFailure.unexpected(error: e));
    }
  }

  @override
  Future<Either<Failure, List<AutobiographyVersion>>> getVersions({
    required String autobiographyId,
  }) async {
    try {
      print(
          '[AutobiographyVersionRepo] 开始加载版本列表, autobiographyId: $autobiographyId');

      // 打印所有版本以调试
      final allVersions =
          await _databaseService.query(DatabaseTables.autobiographyVersions);
      print('[AutobiographyVersionRepo] 数据库中总共有 ${allVersions.length} 个版本记录');
      if (allVersions.isNotEmpty) {
        print(
            '[AutobiographyVersionRepo] 第一条记录的 autoId: ${allVersions.first['autobiography_id']}');
      }

      final results = await _databaseService.query(
        DatabaseTables.autobiographyVersions,
        where: 'autobiography_id = ?',
        whereArgs: [autobiographyId],
        orderBy: 'created_at DESC',
      );

      print('[AutobiographyVersionRepo] 查询到 ${results.length} 个版本');

      final versions = results.map((data) {
        return AutobiographyVersion(
          id: data['id'] as String,
          autobiographyId: data['autobiography_id'] as String,
          versionName: data['version_name'] as String,
          content: data['content'] as String,
          chapters: (jsonDecode(data['chapters'] as String) as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
          wordCount: data['word_count'] as int,
          summary: data['summary'] as String?,
        );
      }).toList();

      return Right(versions);
    } on DatabaseException {
      return Left(DatabaseFailure.queryFailed());
    } catch (e) {
      return Left(UnknownFailure.unexpected(error: e));
    }
  }

  @override
  Future<Either<Failure, AutobiographyVersion>> getVersion({
    required String versionId,
  }) async {
    try {
      final result = await _databaseService.querySingle(
        DatabaseTables.autobiographyVersions,
        where: 'id = ?',
        whereArgs: [versionId],
      );

      if (result == null) {
        return Left(DatabaseFailure.queryFailed());
      }

      final version = AutobiographyVersion(
        id: result['id'] as String,
        autobiographyId: result['autobiography_id'] as String,
        versionName: result['version_name'] as String,
        content: result['content'] as String,
        chapters: (jsonDecode(result['chapters'] as String) as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(result['created_at'] as int),
        wordCount: result['word_count'] as int,
        summary: result['summary'] as String?,
      );

      return Right(version);
    } on DatabaseException {
      return Left(DatabaseFailure.queryFailed());
    } catch (e) {
      return Left(UnknownFailure.unexpected(error: e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVersion({
    required String versionId,
  }) async {
    try {
      await _databaseService.delete(
        DatabaseTables.autobiographyVersions,
        where: 'id = ?',
        whereArgs: [versionId],
      );

      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure.deleteFailed());
    } catch (e) {
      return Left(UnknownFailure.unexpected(error: e));
    }
  }

  @override
  Future<Either<Failure, int>> getVersionCount({
    required String autobiographyId,
  }) async {
    try {
      final count = await _databaseService.getCount(
        DatabaseTables.autobiographyVersions,
        where: 'autobiography_id = ?',
        whereArgs: [autobiographyId],
      );

      return Right(count);
    } on DatabaseException {
      return Left(DatabaseFailure.queryFailed());
    } catch (e) {
      return Left(UnknownFailure.unexpected(error: e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOldestVersion({
    required String autobiographyId,
  }) async {
    try {
      // 获取最旧的版本
      final results = await _databaseService.query(
        DatabaseTables.autobiographyVersions,
        where: 'autobiography_id = ?',
        whereArgs: [autobiographyId],
        orderBy: 'created_at ASC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        final oldestId = results.first['id'] as String;
        await _databaseService.delete(
          DatabaseTables.autobiographyVersions,
          where: 'id = ?',
          whereArgs: [oldestId],
        );
      }

      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure.deleteFailed());
    } catch (e) {
      return Left(UnknownFailure.unexpected(error: e));
    }
  }
}
