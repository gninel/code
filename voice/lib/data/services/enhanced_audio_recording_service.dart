import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/wav_header_writer.dart';
import 'xunfei_asr_service.dart';
import 'xunfei_speed_transcription_service.dart';

/// 增强版录音服务，集成语音识别
@singleton
class EnhancedAudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final XunfeiAsrService _asrService;

  // 录音状态
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isFileUpload = false; // 标记是否为文件上传模式
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;
  bool _isReconnecting = false; // 标记是否正在重连 ASR
  final List<Uint8List> _audioBuffer = []; // 重连期间的音频缓冲

  // 流式录音相关
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  IOSink? _fileSink;
  File? _currentFile;

  // 转写文本累积
  String _accumulatedText = '';

  // 回调函数
  Function(String text, double confidence)? onRecognitionResult;
  Function(String error)? onError;
  Function()? onStarted;
  Function()? onCompleted;

  EnhancedAudioRecordingService(this._asrService);

  /// 当前是否正在录音
  bool get isRecording => _isRecording;

  /// 当前是否暂停
  bool get isPaused => _isPaused;

  /// 当前是否为文件上传模式
  bool get isFileUpload => _isFileUpload;

  /// 获取当前录音时长
  Duration get recordingDuration {
    if (!_isRecording || _recordingStartTime == null) {
      return Duration.zero;
    }

    if (_isPaused && _pauseStartTime != null) {
      return _pauseStartTime!.difference(_recordingStartTime!) -
          _pausedDuration;
    }

    return DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
  }

  /// 开始录音并进行语音识别
  Future<void> startRecordingWithRecognition({
    required Function(String text, double confidence) onResult,
    Function(String error)? onError,
    Function()? onStarted,
    Function()? onCompleted,
  }) async {
    onRecognitionResult = onResult;
    this.onError = onError;
    this.onStarted = onStarted;
    this.onCompleted = onCompleted;

    try {
      // 检查权限
      if (!await _checkPermissions()) {
        throw PermissionException.microphoneDenied();
      }

      // 初始化录音
      await _startRecording();

      // 初始化语音识别
      await _asrService.startRecognition();

      // 监听识别结果
      _listenToAsrStream();

      _isRecording = true;
      _isPaused = false;
      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _accumulatedText = '';
      _audioBuffer.clear();

      onStarted?.call();
    } catch (e) {
      _isRecording = false;
      onError?.call(e.toString());
      throw RecordingException.recordingFailed();
    }
  }

  /// 监听 ASR 结果流，支持自动重连
  void _listenToAsrStream() {
    _asrService.recognitionResultStream.listen(
      (result) {
        // 使用累积文本，与文件上传模式保持一致
        final accumulatedText = result['accumulatedText'] as String?;
        final confidence = XunfeiAsrService.getRecognitionConfidence(result);

        if (accumulatedText != null && accumulatedText.isNotEmpty) {
          _accumulatedText = accumulatedText;
          onRecognitionResult?.call(accumulatedText, confidence);
        }
      },
      onError: (error) {
        print('RecordingService: ASR stream error: $error');
        onError?.call(error.toString());
      },
      onDone: () {
        // ASR 连接被关闭（通常是讯飞服务端在收到最终结果后关闭）
        print('RecordingService: ASR stream closed');
        if (_isRecording && !_isPaused) {
          // 录音仍在进行，需要重连
          print(
              'RecordingService: Recording still active, reconnecting ASR...');
          _reconnectAsr();
        }
      },
    );
  }

  /// ASR 重连逻辑
  Future<void> _reconnectAsr() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    try {
      print('RecordingService: Starting ASR reconnection...');
      // 归档当前已识别的文本，防止丢失
      _asrService.archiveText();
      // 重新开始识别，保留历史记录
      await _asrService.startRecognition(clearHistory: false);
      // 重新监听流
      _listenToAsrStream();
      print('RecordingService: ASR reconnected successfully');

      // 发送缓冲的数据
      if (_audioBuffer.isNotEmpty) {
        print(
            'RecordingService: Flushing ${_audioBuffer.length} buffered audio chunks...');
        for (final data in _audioBuffer) {
          try {
            await _asrService.sendAudioData(data);
            // 简单的限速，避免瞬间发送太快
            await Future.delayed(const Duration(milliseconds: 5));
          } catch (e) {
            print('RecordingService: Error flushing buffer: $e');
            // 如果发送失败，重新抛出异常，触发外层的 catch 重试
            rethrow;
          }
        }
        _audioBuffer.clear();
        print('RecordingService: Buffer flushed.');
      }
    } catch (e) {
      print('RecordingService: Failed to reconnect ASR: $e');
      // 等待一段时间后重试
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isRecording && !_isPaused) {
        // 重置标志让重试可以进行
        _isReconnecting = false;
        await _reconnectAsr();
        return; // 下一次调用会负责设置标志
      }
    } finally {
      // 确保在成功或放弃后重置标志
      _isReconnecting = false;
    }
  }

  /// 识别本地音频文件（使用极速转写 API）
  Future<void> recognizeFile(
    String filePath, {
    required Function(String text, double confidence) onResult,
    Function(String error)? onError,
    Function()? onStarted,
    Function()? onCompleted,
  }) async {
    print('Service: recognizeFile called for $filePath');
    onRecognitionResult = onResult;
    this.onError = onError;
    this.onStarted = onStarted;
    this.onCompleted = onCompleted;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const FileSystemException('File not found');
      }

      onStarted?.call();
      _isRecording = true;
      _isPaused = false;
      _isFileUpload = true;
      _currentRecordingPath = filePath;
      _recordingStartTime = DateTime.now();

      // 使用极速转写服务
      final speedTranscriptionService = XunfeiSpeedTranscriptionService();

      print('Service: Starting speed transcription...');
      final result = await speedTranscriptionService.transcribeFile(
        filePath,
        onProgress: (status) {
          print('Service: Speed transcription progress: $status');
          // 可以通过某种方式通知 UI 更新状态
        },
      );

      print(
          'Service: Speed transcription completed, result length: ${result.length}');

      if (result.isNotEmpty) {
        _accumulatedText = result;
        onRecognitionResult?.call(result, 0.95);
      }

      _isRecording = false;
      onCompleted?.call();
    } catch (e) {
      print('Service: Exception in recognizeFile: $e');
      _isRecording = false;
      onError?.call(e.toString());
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;

    try {
      // 暂停录音流处理
      _isPaused = true;
      _pauseStartTime = DateTime.now();
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 恢复录音
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;

    try {
      if (_pauseStartTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }

      _isPaused = false;
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 停止录音
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _isRecording = false;
      _isPaused = false;

      final wasFileUpload = _isFileUpload;
      _isFileUpload = false; // 重置标记

      if (wasFileUpload) {
        // 文件上传模式：获取最终文本后停止ASR
        final finalText = _asrService.getFinalText();
        if (finalText.isNotEmpty) {
          _accumulatedText = finalText;
          onRecognitionResult?.call(_accumulatedText, 0.9);
        }
        await _asrService.stopRecognition();
        onCompleted?.call();
        return _currentRecordingPath;
      }

      // 实时录音模式：完整停止流程
      // 停止录音流
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // 关闭文件流
      await _fileSink?.close();
      _fileSink = null;

      // 清空音频缓冲
      _audioBuffer.clear();

      // 更新 WAV 头
      if (_currentFile != null) {
        await WavHeaderWriter.updateHeader(_currentFile!);
      }

      // 停止录音器
      await _audioRecorder.stop();

      // 发送结束帧并等待最终结果
      try {
        await _asrService.sendAudioData(Uint8List(0), isEnd: true);
        // 等待一段时间让最终结果返回
        await Future.delayed(const Duration(milliseconds: 500));

        // 获取最终累积的文本
        final finalText = _asrService.getFinalText();
        if (finalText.isNotEmpty &&
            finalText.length > _accumulatedText.length) {
          _accumulatedText = finalText;
          onRecognitionResult?.call(_accumulatedText, 0.9);
        }
      } catch (e) {
        // 忽略发送结束帧的错误
        print('Service: Error sending end frame: $e');
      }

      // 停止语音识别
      await _asrService.stopRecognition();

      onCompleted?.call();

      return _currentRecordingPath;
    } catch (e) {
      throw RecordingException.recordingFailed();
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    try {
      await stopRecording();

      // 删除录音文件
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // 忽略取消时的错误
    }
  }

  /// 检查权限
  Future<bool> _checkPermissions() async {
    // macOS平台跳过权限检查，因为permission_handler插件可能不支持macOS
    if (Platform.isMacOS) {
      return true;
    }

    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 开始录音内部实现
  Future<void> _startRecording() async {
    Directory baseDirectory;

    if (Platform.isAndroid) {
      // Android: 使用公共 Download 目录，确保卸载后录音保留
      try {
        baseDirectory = Directory('/storage/emulated/0/Download');
        if (!await baseDirectory.exists()) {
          baseDirectory = (await getExternalStorageDirectory())!;
        }
      } catch (e) {
        baseDirectory = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isMacOS) {
      // macOS: 使用用户真实的 Documents 目录
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty) {
        baseDirectory = Directory('$home/Documents');
      } else {
        baseDirectory = await getApplicationDocumentsDirectory();
      }
    } else {
      baseDirectory = await getApplicationDocumentsDirectory();
    }

    final recordingsDir = Directory(
        '${baseDirectory.path}/VoiceAutobiography/${AppConstants.audioRecordingsDir}');

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}.wav';
    _currentRecordingPath = '${recordingsDir.path}/$fileName';
    _currentFile = File(_currentRecordingPath!);

    // 写入初始 WAV 头
    await WavHeaderWriter.writeHeader(_currentFile!);

    // 打开文件写入流 (追加模式，因为已经写入了头部)
    _fileSink = _currentFile!.openWrite(mode: FileMode.append);

    // 配置录音参数
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      bitRate: 128000,
      sampleRate: 16000,
      numChannels: 1,
    );

    // 获取音频流
    final stream = await _audioRecorder.startStream(config);

    // 处理音频流
    _audioStreamSubscription = stream.listen((data) async {
      if (_isPaused) return;

      // 写入文件
      _fileSink?.add(data);

      // 发送给 ASR
      // 如果正在重连、会话未激活或正在建立连接，先缓冲
      if (_isReconnecting ||
          !_asrService.isSessionActive ||
          _asrService.isConnecting) {
        _audioBuffer.add(Uint8List.fromList(data));

        // 如果会话未激活、不在重连中且不在连接中，才触发重连
        if (!_isReconnecting &&
            !_asrService.isSessionActive &&
            !_asrService.isConnecting &&
            _isRecording) {
          print(
              'RecordingService: Session inactive, triggering reconnection...');
          await _reconnectAsr();
        }
        return;
      }

      // 发送音频数据，返回 false 表示需要重连
      final sent = await _asrService.sendAudioData(Uint8List.fromList(data));
      if (!sent) {
        // 发送失败，加入缓冲并触发重连
        print(
            'RecordingService: Send failed, buffering data and reconnecting...');
        _audioBuffer.add(Uint8List.fromList(data));
        await _reconnectAsr();
      }
    });
  }

  /// 获取音频振幅流
  Stream<double> getAudioAmplitudeStream() {
    return _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .map((amplitude) {
      return amplitude.current;
    });
  }

  /// 释放资源
  Future<void> dispose() async {
    await _audioRecorder.dispose();
    await _asrService.stopRecognition();
  }
}
