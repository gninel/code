import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../domain/repositories/voice_recognition_repository.dart';
import '../../domain/usecases/recognition_usecases.dart';
import '../../core/errors/failures.dart';
import '../services/xunfei_asr_service.dart';

/// 语音识别仓库实现
@LazySingleton(as: VoiceRecognitionRepository)
class VoiceRecognitionRepositoryImpl implements VoiceRecognitionRepository {
  final XunfeiAsrService _asrService;
  StreamController<Either<Failure, RecognitionResult>>? _resultController;
  StreamSubscription? _recognitionSubscription;
  bool _isActive = false;

  VoiceRecognitionRepositoryImpl(this._asrService);

  @override
  Stream<Either<Failure, RecognitionResult>> startRecognition() {
    if (_isActive) {
      return _resultController!.stream;
    }

    // 创建结果控制器
    _resultController = StreamController<Either<Failure, RecognitionResult>>.broadcast();

    // 开始语音识别
    _asrService.startRecognition().then((_) {
      _isActive = true;

      // 监听识别结果
      _recognitionSubscription = _asrService.recognitionResultStream.listen(
        (result) {
          _handleRecognitionResult(result);
        },
        onError: (error) {
          _resultController?.add(Left(AsrFailure.recognitionFailed()));
        },
        onDone: () {
          _isActive = false;
          _resultController?.close();
        },
      );
    }).catchError((error) {
      _resultController?.add(Left(AsrFailure.websocketConnectionFailed()));
      _resultController?.close();
    });

    return _resultController!.stream;
  }

  @override
  Future<Either<Failure, void>> sendAudioData(Uint8List audioData, {bool isEnd = false}) async {
    try {
      if (!_isActive) {
        return Left(AsrFailure.websocketConnectionFailed());
      }

  await _asrService.sendAudioData(audioData, isEnd: isEnd);
  return const Right(null);
    } catch (e) {
      return Left(AsrFailure.recognitionFailed());
    }
  }

  @override
  Future<Either<Failure, void>> stopRecognition() async {
    try {
      await _recognitionSubscription?.cancel();
      await _asrService.stopRecognition();
      await _resultController?.close();

  _isActive = false;
  return const Right(null);
    } catch (e) {
      return Left(AsrFailure.recognitionFailed());
    }
  }

  @override
  Future<Either<Failure, void>> cancelRecognition() async {
    try {
      await _recognitionSubscription?.cancel();
      await _asrService.stopRecognition();
      await _resultController?.close();

  _isActive = false;
  return const Right(null);
    } catch (e) {
      return Left(AsrFailure.recognitionFailed());
    }
  }

  @override
  bool get isConnected => _isActive;

  /// 处理语音识别结果
  void _handleRecognitionResult(Map<String, dynamic> result) {
    try {
      // 解析识别文本
      final text = XunfeiAsrService.parseRecognitionResult(result);
      if (text.isEmpty) {
        return; // 跳过空结果
      }

      // 获取置信度
      final confidence = XunfeiAsrService.getRecognitionConfidence(result);

      // 判断是否为最终结果
      final isFinal = XunfeiAsrService.isFinalResult(result);

      // 创建识别结果对象
      final recognitionResult = RecognitionResult(
        text: text,
        confidence: confidence,
        isFinal: isFinal,
        timestamp: DateTime.now(),
      );

      // 发送结果
      _resultController?.add(Right(recognitionResult));

      // 如果是最终结果，关闭识别
      if (isFinal) {
        Timer(const Duration(milliseconds: 500), () {
          _isActive = false;
          _resultController?.close();
        });
      }
    } catch (e) {
      _resultController?.add(Left(AsrFailure.recognitionFailed()));
    }
  }

  /// 释放资源
  void dispose() {
    _recognitionSubscription?.cancel();
    _asrService.stopRecognition();
    _resultController?.close();
  }
}