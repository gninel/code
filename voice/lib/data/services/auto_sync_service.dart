import 'dart:async';
import 'package:injectable/injectable.dart';

import 'cloud_sync_service.dart';
import '../../domain/entities/voice_record.dart';
import '../../domain/entities/autobiography.dart';
import '../../domain/repositories/voice_record_repository.dart';
import '../../domain/repositories/autobiography_repository.dart';

/// 自动同步服务
@singleton
class AutoSyncService {
  final CloudSyncService _cloudSyncService;
  final VoiceRecordRepository _voiceRecordRepository;
  final AutobiographyRepository _autobiographyRepository;

  Timer? _syncTimer;
  bool _autoSyncEnabled = false;
  static const _syncInterval = Duration(minutes: 30); // 30分钟自动同步一次

  AutoSyncService(
    this._cloudSyncService,
    this._voiceRecordRepository,
    this._autobiographyRepository,
  );

  /// 启用自动同步
  void enableAutoSync() {
    if (_autoSyncEnabled) return;

    _autoSyncEnabled = true;
    _startPeriodicSync();
  }

  /// 禁用自动同步
  void disableAutoSync() {
    _autoSyncEnabled = false;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// 开始定时同步
  void _startPeriodicSync() {
    _syncTimer?.cancel();

    // 立即执行一次同步
    _performSync();

    // 定时同步
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_autoSyncEnabled && _cloudSyncService.isLoggedIn) {
        _performSync();
      }
    });
  }

  /// 执行同步
  Future<void> _performSync() async {
    if (!_cloudSyncService.isLoggedIn) {
      return;
    }

    try {
      print('[AutoSync] 开始自动同步...');

      // 获取本地数据
      final voiceRecordsResult =
          await _voiceRecordRepository.getAllVoiceRecords();
      final autobiographiesResult =
          await _autobiographyRepository.getAllAutobiographies();

      final voiceRecords = voiceRecordsResult.fold(
        (failure) {
          print('[AutoSync] 获取语音记录失败: ${failure.message}');
          return <VoiceRecord>[];
        },
        (records) => records,
      );

      final autobiographies = autobiographiesResult.fold(
        (failure) {
          print('[AutoSync] 获取自传失败: ${failure.message}');
          return <Autobiography>[];
        },
        (autos) => autos,
      );

      // 上传到云端
      await _cloudSyncService.uploadData(
        voiceRecords: voiceRecords,
        autobiographies: autobiographies,
      );

      print('[AutoSync] 自动同步完成');
    } catch (e) {
      print('[AutoSync] 自动同步失败: $e');
    }
  }

  /// 手动触发同步（数据变更时调用）
  Future<void> syncNow() async {
    if (!_autoSyncEnabled || !_cloudSyncService.isLoggedIn) {
      return;
    }

    await _performSync();
  }

  /// 释放资源
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
