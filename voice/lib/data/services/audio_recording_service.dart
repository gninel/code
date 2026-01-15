import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// 音频录制服务
@singleton
class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _subscription;
  Timer? _timer;

  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentFilePath;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 是否已暂停
  bool get isPaused => _isPaused;

  /// 当前录音文件路径
  String? get currentFilePath => _currentFilePath;

  /// 开始录音
  Future<String> startRecording() async {
    try {
      // 检查是否已有录音在进行
      if (_isRecording && !_isPaused) {
        throw RecordingException.recordingFailed();
      }

      // 如果是暂停状态，恢复录音
      if (_isPaused) {
        return await resumeRecording();
      }

      // 检查录音权限
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw PermissionException.microphoneDenied();
      }

      // 创建录音文件路径
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/${AppConstants.audioRecordingsDir}');

      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'recording_$timestamp.${AppConstants.audioFormat}';
      _currentFilePath = '${recordingsDir.path}/$fileName';

      // 配置录音参数
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: AppConstants.bitRate,
        sampleRate: AppConstants.sampleRate,
      );

      // 开始录音
      await _audioRecorder.start(config, path: _currentFilePath!);

      _isRecording = true;
      _isPaused = false;

      return _currentFilePath!;
    } catch (e) {
      if (e is RecordingException || e is PermissionException) {
        rethrow;
      }
      throw RecordingException.recordingFailed();
    }
  }

  /// 停止录音
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return _currentFilePath;
      }

      _timer?.cancel();
      _subscription?.cancel();

      final filePath = await _audioRecorder.stop();

      _isRecording = false;
      _isPaused = false;

      return filePath ?? _currentFilePath;
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) {
        return;
      }

      await _audioRecorder.pause();
      _isPaused = true;
      _timer?.cancel();
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 恢复录音
  Future<String> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) {
        throw RecordingException.recordingFailed();
      }

      await _audioRecorder.resume();
      _isPaused = false;

      return _currentFilePath!;
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    try {
      _timer?.cancel();
      _subscription?.cancel();

      if (_isRecording) {
        await _audioRecorder.stop();

        // 删除录音文件
        if (_currentFilePath != null) {
          final file = File(_currentFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      _isRecording = false;
      _isPaused = false;
      _currentFilePath = null;
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 获取音频振幅流
  Stream<double> getAudioAmplitudeStream() {
    return _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 200)).map((amplitude) {
      return amplitude.current;
    });
  }

  /// 启动计时器，定期更新录音时长
  void startTimer(Function(Duration) onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      onTick(Duration(milliseconds: timer.tick * 100));
    });
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    _audioRecorder.dispose();
  }
}