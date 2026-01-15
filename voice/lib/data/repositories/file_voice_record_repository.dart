import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/voice_record.dart';
import '../../domain/repositories/voice_record_repository.dart';
import '../models/voice_record_model.dart';

@LazySingleton(as: VoiceRecordRepository)
class FileVoiceRecordRepository implements VoiceRecordRepository {
  static const String _fileName = 'voice_records.json';
  List<VoiceRecord>? _cachedRecords;

  Future<File> _getFile() async {
    Directory directory;

    if (Platform.isMacOS) {
      // macOS: 使用用户真实的 Documents 目录，而非沙盒目录
      // 这样即使卸载应用数据也会保留
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty) {
        directory = Directory('$home/Documents');

        // 检查是否需要从旧的 Container 目录迁移数据
        await _migrateFromContainerIfNeeded(home, directory);
      } else {
        // Fallback 到沙盒目录
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
            'VoiceRecordRepository: Failed to access public storage, fallback to app storage. Error: $e');
        directory = (await getExternalStorageDirectory())!;
      }
    } else {
      // iOS 及其他平台: 使用应用文档目录
      directory = await getApplicationDocumentsDirectory();
    }

    // 创建 VoiceAutobiography 子目录
    final appDir = Directory('${directory.path}/VoiceAutobiography');
    if (!await appDir.exists()) {
      try {
        await appDir.create(recursive: true);
      } catch (e) {
        print('VoiceRecordRepository: Failed to create directory: $e');
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
    print('VoiceRecordRepository: File path: $path');
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
              'VoiceRecordRepository: Found old data at ${oldFile.path}, migrating...');

          // 确保新目录存在
          if (!await newDir.exists()) {
            await newDir.create(recursive: true);
          }

          // 复制数据文件
          await oldFile.copy(newFile.path);
          print(
              'VoiceRecordRepository: Migration completed: ${oldFile.path} -> ${newFile.path}');

          // 迁移录音文件夹（如果存在）
          final oldRecordingsDir = Directory('${oldDir.path}/voice_recordings');
          if (await oldRecordingsDir.exists()) {
            final newRecordingsDir =
                Directory('${newDir.path}/voice_recordings');
            if (!await newRecordingsDir.exists()) {
              await newRecordingsDir.create(recursive: true);
            }
            await for (final entity in oldRecordingsDir.list()) {
              if (entity is File) {
                final newPath =
                    '${newRecordingsDir.path}/${entity.uri.pathSegments.last}';
                await entity.copy(newPath);
              }
            }
            print('VoiceRecordRepository: Recordings migration completed');
          }

          break; // 找到并迁移后跳出循环
        }
      }
    } catch (e) {
      print('VoiceRecordRepository: Migration failed: $e');
      // 迁移失败不影响正常使用
    }
  }

  Future<void> _saveRecords(List<VoiceRecord> records) async {
    try {
      final file = await _getFile();
      final models =
          records.map((r) => VoiceRecordModel.fromEntity(r).toJson()).toList();
      print(
          'VoiceRecordRepository: Saving ${records.length} records to ${file.path}');
      await file.writeAsString(jsonEncode(models));
      _cachedRecords = records;
    } catch (e) {
      print('VoiceRecordRepository: Save failed: $e');
      throw const CacheException();
    }
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> getAllVoiceRecords() async {
    if (_cachedRecords != null) {
      print(
          'VoiceRecordRepository: Returning cached records (${_cachedRecords!.length})');
      return Right(_cachedRecords!);
    }

    try {
      final file = await _getFile();
      if (!await file.exists()) {
        print('VoiceRecordRepository: File does not exist');
        _cachedRecords = [];
        return const Right([]);
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        print('VoiceRecordRepository: File is empty');
        _cachedRecords = [];
        return const Right([]);
      }

      final List<dynamic> jsonList = jsonDecode(content);
      final records = <VoiceRecord>[];

      for (final json in jsonList) {
        try {
          records.add(VoiceRecordModel.fromJson(json));
        } catch (e) {
          print(
              'VoiceRecordRepository: Failed to parse record: $e\nRecord data: $json');
          // Skip invalid records to prevent entire list failure
        }
      }

      // Sort by timestamp descending
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print(
          'VoiceRecordRepository: Loaded ${records.length} records from file (Original count: ${jsonList.length})');
      _cachedRecords = records;
      return Right(records);
    } catch (e) {
      print('VoiceRecordRepository: Load failed: $e');
      return Left(CacheFailure('读取缓存失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VoiceRecord>> getVoiceRecordById(String id) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) {
        try {
          final record = records.firstWhere((r) => r.id == id);
          return Right(record);
        } catch (e) {
          return Left(CacheFailure.cacheMiss());
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> insertVoiceRecord(
      VoiceRecord voiceRecord) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) async {
        final newRecords = List<VoiceRecord>.from(records)
          ..insert(0, voiceRecord);
        await _saveRecords(newRecords);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateVoiceRecord(
      VoiceRecord voiceRecord) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) async {
        final index = records.indexWhere((r) => r.id == voiceRecord.id);
        if (index == -1) return Left(CacheFailure.cacheMiss());

        final newRecords = List<VoiceRecord>.from(records)
          ..[index] = voiceRecord;
        await _saveRecords(newRecords);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> deleteVoiceRecord(String id) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) async {
        final newRecords = List<VoiceRecord>.from(records)
          ..removeWhere((r) => r.id == id);
        await _saveRecords(newRecords);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> searchVoiceRecords(
      String query) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) {
        final lowerQuery = query.toLowerCase();
        final filtered = records.where((r) {
          return r.title.toLowerCase().contains(lowerQuery) ||
              r.content.toLowerCase().contains(lowerQuery) ||
              (r.transcription?.toLowerCase().contains(lowerQuery) ?? false) ||
              r.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
        return Right(filtered);
      },
    );
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> getVoiceRecordsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) {
        final filtered = records.where((r) {
          return r.timestamp.isAfter(startDate) &&
              r.timestamp.isBefore(endDate);
        }).toList();
        return Right(filtered);
      },
    );
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> getProcessedVoiceRecords() async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) => Right(records.where((r) => r.isProcessed).toList()),
    );
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>>
      getUnprocessedVoiceRecords() async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) => Right(records.where((r) => !r.isProcessed).toList()),
    );
  }

  @override
  Future<Either<Failure, void>> markAsProcessed(String id) async {
    final recordResult = await getVoiceRecordById(id);
    return recordResult.fold(
      (failure) => Left(failure),
      (record) => updateVoiceRecord(record.copyWith(isProcessed: true)),
    );
  }

  @override
  Future<Either<Failure, void>> markAsUnprocessed(String id) async {
    final recordResult = await getVoiceRecordById(id);
    return recordResult.fold(
      (failure) => Left(failure),
      (record) => updateVoiceRecord(record.copyWith(isProcessed: false)),
    );
  }

  @override
  Future<Either<Failure, void>> deleteVoiceRecords(List<String> ids) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) async {
        final newRecords = List<VoiceRecord>.from(records)
          ..removeWhere((r) => ids.contains(r.id));
        await _saveRecords(newRecords);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRecordingStatistics() async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) {
        final totalCount = records.length;
        final totalDuration = records.fold(0, (sum, r) => sum + r.duration);
        return Right({
          'totalCount': totalCount,
          'totalDuration': totalDuration,
        });
      },
    );
  }
}
