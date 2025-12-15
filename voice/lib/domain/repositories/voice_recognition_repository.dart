import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../usecases/recognition_usecases.dart';
import '../../core/errors/failures.dart';

/// 语音识别仓库接口
abstract class VoiceRecognitionRepository {
  /// 开始语音识别
  /// 返回识别结果的流
  Stream<Either<Failure, RecognitionResult>> startRecognition();

  /// 发送音频数据
  /// [audioData] 音频数据 (PCM格式)
  /// [isEnd] 是否为结束帧
  Future<Either<Failure, void>> sendAudioData(Uint8List audioData, {bool isEnd = false});

  /// 停止语音识别
  Future<Either<Failure, void>> stopRecognition();

  /// 取消语音识别
  Future<Either<Failure, void>> cancelRecognition();

  /// 检查连接状态
  bool get isConnected;
}