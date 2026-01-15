import 'package:dartz/dartz.dart';

import '../entities/voice_record.dart';
import '../../core/errors/failures.dart';

/// 语音记录仓库接口
abstract class VoiceRecordRepository {
  /// 获取所有语音记录
  Future<Either<Failure, List<VoiceRecord>>> getAllVoiceRecords();

  /// 根据ID获取语音记录
  Future<Either<Failure, VoiceRecord>> getVoiceRecordById(String id);

  /// 插入语音记录
  Future<Either<Failure, void>> insertVoiceRecord(VoiceRecord voiceRecord);

  /// 更新语音记录
  Future<Either<Failure, void>> updateVoiceRecord(VoiceRecord voiceRecord);

  /// 删除语音记录
  Future<Either<Failure, void>> deleteVoiceRecord(String id);

  /// 搜索语音记录
  Future<Either<Failure, List<VoiceRecord>>> searchVoiceRecords(String query);

  /// 根据日期范围获取语音记录
  Future<Either<Failure, List<VoiceRecord>>> getVoiceRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// 获取处理过的语音记录
  Future<Either<Failure, List<VoiceRecord>>> getProcessedVoiceRecords();

  /// 获取未处理的语音记录
  Future<Either<Failure, List<VoiceRecord>>> getUnprocessedVoiceRecords();

  /// 标记语音记录为已处理
  Future<Either<Failure, void>> markAsProcessed(String id);

  /// 标记语音记录为未处理
  Future<Either<Failure, void>> markAsUnprocessed(String id);

  /// 批量删除语音记录
  Future<Either<Failure, void>> deleteVoiceRecords(List<String> ids);

  /// 获取录音统计信息
  Future<Either<Failure, Map<String, dynamic>>> getRecordingStatistics();
}