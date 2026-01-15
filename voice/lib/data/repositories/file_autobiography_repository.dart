import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/autobiography.dart';
import '../../domain/repositories/autobiography_repository.dart';
import '../models/autobiography_model.dart';

/// 自传仓库实现 - 使用文件存储
@LazySingleton(as: AutobiographyRepository)
class FileAutobiographyRepository implements AutobiographyRepository {
  static const String _fileName = 'autobiographies.json';
  List<Autobiography>? _cachedAutobiographies;

  Future<File> _getFile() async {
    Directory directory;

    if (Platform.isMacOS) {
      // macOS: 使用用户真实的 Documents 目录
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty) {
        directory = Directory('$home/Documents');

        // 检查是否需要从旧的 Container 目录迁移数据
        await _migrateFromContainerIfNeeded(home, directory);
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isAndroid) {
      // Android: 使用公共 Download 目录，确保卸载后数据保留
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = (await getExternalStorageDirectory())!;
        }
      } catch (e) {
        print(
            'AutobiographyRepository: Failed to access public storage, fallback to app storage. Error: $e');
        directory = (await getExternalStorageDirectory())!;
      }
    } else {
      // iOS 及其他平台
      directory = await getApplicationDocumentsDirectory();
    }

    // 创建 VoiceAutobiography 子目录
    final appDir = Directory('${directory.path}/VoiceAutobiography');
    if (!await appDir.exists()) {
      try {
        await appDir.create(recursive: true);
      } catch (e) {
        print('AutobiographyRepository: Failed to create public directory: $e');
        // Fallback to app documents if creation fails
        final fallbackDir = await getApplicationDocumentsDirectory();
        final fallbackAppDir =
            Directory('${fallbackDir.path}/VoiceAutobiography');
        if (!await fallbackAppDir.exists()) {
          await fallbackAppDir.create(recursive: true);
        }
        return File('${fallbackAppDir.path}/$_fileName');
      }
    }

    final path = '${appDir.path}/$_fileName';
    print('AutobiographyRepository: File path: $path');
    return File(path);
  }

  /// macOS: 从旧的 Container 目录迁移数据到用户 Documents 目录
  Future<void> _migrateFromContainerIfNeeded(
      String home, Directory newBaseDir) async {
    try {
      final newDir = Directory('${newBaseDir.path}/VoiceAutobiography');
      final newFile = File('${newDir.path}/$_fileName');

      // 如果新目录已经有数据，跳过迁移
      if (await newFile.exists()) {
        return;
      }

      // 查找旧的 Container 目录
      final containersDir = Directory('$home/Library/Containers');
      if (!await containersDir.exists()) return;

      // 可能的 Container 名称
      final possibleContainers = [
        'com.voiceautobiography.voiceAutobiographyFlutter',
        'com.example.voiceAutobiographyFlutter',
      ];

      for (final containerName in possibleContainers) {
        final oldDir = Directory(
            '${containersDir.path}/$containerName/Data/Documents/VoiceAutobiography');
        final oldFile = File('${oldDir.path}/$_fileName');

        if (await oldFile.exists()) {
          print(
              'AutobiographyRepository: Found old data at ${oldFile.path}, migrating...');

          // 确保新目录存在
          if (!await newDir.exists()) {
            await newDir.create(recursive: true);
          }

          // 复制数据文件
          await oldFile.copy(newFile.path);
          print(
              'AutobiographyRepository: Migration completed: ${oldFile.path} -> ${newFile.path}');
          break;
        }
      }
    } catch (e) {
      print('AutobiographyRepository: Migration failed: $e');
    }
  }

  Future<void> _saveAutobiographies(List<Autobiography> autobiographies) async {
    try {
      final file = await _getFile();
      final models = autobiographies
          .map((a) => AutobiographyModel.fromEntity(a).toJson())
          .toList();
      print(
          'AutobiographyRepository: Saving ${autobiographies.length} autobiographies to ${file.path}');
      await file.writeAsString(jsonEncode(models));
      _cachedAutobiographies = autobiographies;
    } catch (e) {
      print('AutobiographyRepository: Save failed: $e');
      throw const CacheException();
    }
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getAllAutobiographies() async {
    if (_cachedAutobiographies != null) {
      print(
          'AutobiographyRepository: Returning cached autobiographies (${_cachedAutobiographies!.length})');
      return Right(_cachedAutobiographies!);
    }

    try {
      final file = await _getFile();
      if (!await file.exists()) {
        print('AutobiographyRepository: File does not exist');
        _cachedAutobiographies = [];
        return const Right([]);
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        print('AutobiographyRepository: File is empty');
        _cachedAutobiographies = [];
        return const Right([]);
      }

      final List<dynamic> jsonList = jsonDecode(content);
      final autobiographies =
          jsonList.map((json) => AutobiographyModel.fromJson(json)).toList();

      // Sort by lastModifiedAt descending
      autobiographies
          .sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));

      print(
          'AutobiographyRepository: Loaded ${autobiographies.length} autobiographies from file');
      _cachedAutobiographies = autobiographies;
      return Right(autobiographies);
    } catch (e) {
      print('AutobiographyRepository: Load failed: $e');
      return Left(CacheFailure('读取缓存失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Autobiography>> getAutobiographyById(String id) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) {
        try {
          final autobiography = autobiographies.firstWhere((a) => a.id == id);
          return Right(autobiography);
        } catch (e) {
          return Left(CacheFailure.cacheMiss());
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> insertAutobiography(
      Autobiography autobiography) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) async {
        final newAutobiographies = List<Autobiography>.from(autobiographies)
          ..insert(0, autobiography);
        await _saveAutobiographies(newAutobiographies);
        print(
            'AutobiographyRepository: Inserted autobiography: ${autobiography.title}');
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateAutobiography(
      Autobiography autobiography) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) async {
        final index =
            autobiographies.indexWhere((a) => a.id == autobiography.id);
        if (index == -1) return Left(CacheFailure.cacheMiss());

        final newAutobiographies = List<Autobiography>.from(autobiographies)
          ..[index] = autobiography;
        await _saveAutobiographies(newAutobiographies);
        print(
            'AutobiographyRepository: Updated autobiography: ${autobiography.title}');
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> deleteAutobiography(String id) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) async {
        final newAutobiographies = List<Autobiography>.from(autobiographies)
          ..removeWhere((a) => a.id == id);
        await _saveAutobiographies(newAutobiographies);
        print('AutobiographyRepository: Deleted autobiography: $id');
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, List<Autobiography>>> searchAutobiographies(
      String query) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) {
        final lowerQuery = query.toLowerCase();
        final filtered = autobiographies.where((a) {
          return a.title.toLowerCase().contains(lowerQuery) ||
              a.content.toLowerCase().contains(lowerQuery) ||
              (a.summary?.toLowerCase().contains(lowerQuery) ?? false) ||
              a.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
        return Right(filtered);
      },
    );
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByStatus(
      AutobiographyStatus status) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) =>
          Right(autobiographies.where((a) => a.status == status).toList()),
    );
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByDateRange(
      DateTime startDate, DateTime endDate) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) {
        final filtered = autobiographies.where((a) {
          return a.generatedAt.isAfter(startDate) &&
              a.generatedAt.isBefore(endDate);
        }).toList();
        return Right(filtered);
      },
    );
  }

  @override
  Future<Either<Failure, Autobiography?>> getLatestAutobiography() async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) {
        if (autobiographies.isEmpty) return const Right(null);
        return Right(autobiographies.first);
      },
    );
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getDraftAutobiographies() async {
    return getAutobiographiesByStatus(AutobiographyStatus.draft);
  }

  @override
  Future<Either<Failure, List<Autobiography>>>
      getPublishedAutobiographies() async {
    return getAutobiographiesByStatus(AutobiographyStatus.published);
  }

  @override
  Future<Either<Failure, List<Autobiography>>>
      getArchivedAutobiographies() async {
    return getAutobiographiesByStatus(AutobiographyStatus.archived);
  }

  @override
  Future<Either<Failure, void>> updateAutobiographyStatus(
      String id, AutobiographyStatus status) async {
    final autobiographyResult = await getAutobiographyById(id);
    return autobiographyResult.fold(
      (failure) => Left(failure),
      (autobiography) =>
          updateAutobiography(autobiography.copyWith(status: status)),
    );
  }

  @override
  Future<Either<Failure, void>> deleteAutobiographies(List<String> ids) async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) async {
        final newAutobiographies = List<Autobiography>.from(autobiographies)
          ..removeWhere((a) => ids.contains(a.id));
        await _saveAutobiographies(newAutobiographies);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      getAutobiographyStatistics() async {
    final result = await getAllAutobiographies();
    return result.fold(
      (failure) => Left(failure),
      (autobiographies) {
        final totalCount = autobiographies.length;
        final totalWordCount =
            autobiographies.fold(0, (sum, a) => sum + a.wordCount);
        final draftCount = autobiographies
            .where((a) => a.status == AutobiographyStatus.draft)
            .length;
        final publishedCount = autobiographies
            .where((a) => a.status == AutobiographyStatus.published)
            .length;
        return Right({
          'totalCount': totalCount,
          'totalWordCount': totalWordCount,
          'draftCount': draftCount,
          'publishedCount': publishedCount,
        });
      },
    );
  }

  @override
  Future<Either<Failure, String>> exportAutobiography(
      String id, String format) async {
    return const Right('export_not_implemented');
  }

  @override
  Future<Either<Failure, Autobiography>> importAutobiography(
      String filePath) async {
    return Left(PlatformFailure.notSupported());
  }

  @override
  Future<Either<Failure, String>> backupAutobiographies() async {
    return const Right('backup_not_implemented');
  }

  @override
  Future<Either<Failure, void>> restoreAutobiographies(
      String backupPath) async {
    return const Right(null);
  }
}
