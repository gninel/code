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
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$_fileName';
    print('VoiceRecordRepository: File path: $path');
    return File(path);
  }

  Future<void> _saveRecords(List<VoiceRecord> records) async {
    try {
      final file = await _getFile();
      final models = records.map((r) => VoiceRecordModel.fromEntity(r).toJson()).toList();
      print('VoiceRecordRepository: Saving ${records.length} records to ${file.path}');
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
      print('VoiceRecordRepository: Returning cached records (${_cachedRecords!.length})');
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
      final records = jsonList.map((json) => VoiceRecordModel.fromJson(json)).toList();
      
      // Sort by timestamp descending
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('VoiceRecordRepository: Loaded ${records.length} records from file');
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
  Future<Either<Failure, void>> insertVoiceRecord(VoiceRecord voiceRecord) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) async {
        final newRecords = List<VoiceRecord>.from(records)..insert(0, voiceRecord);
        await _saveRecords(newRecords);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateVoiceRecord(VoiceRecord voiceRecord) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) async {
        final index = records.indexWhere((r) => r.id == voiceRecord.id);
        if (index == -1) return Left(CacheFailure.cacheMiss());

        final newRecords = List<VoiceRecord>.from(records)..[index] = voiceRecord;
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
        final newRecords = List<VoiceRecord>.from(records)..removeWhere((r) => r.id == id);
        await _saveRecords(newRecords);
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> searchVoiceRecords(String query) async {
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
  Future<Either<Failure, List<VoiceRecord>>> getVoiceRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    final recordsResult = await getAllVoiceRecords();
    return recordsResult.fold(
      (failure) => Left(failure),
      (records) {
        final filtered = records.where((r) {
          return r.timestamp.isAfter(startDate) && r.timestamp.isBefore(endDate);
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
  Future<Either<Failure, List<VoiceRecord>>> getUnprocessedVoiceRecords() async {
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
        final newRecords = List<VoiceRecord>.from(records)..removeWhere((r) => ids.contains(r.id));
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
