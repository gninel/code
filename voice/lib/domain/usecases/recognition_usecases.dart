import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../repositories/voice_recognition_repository.dart';
import '../../core/errors/failures.dart';

/// 语音识别用例集合
@injectable
class RecognitionUseCases {
  final VoiceRecognitionRepository _repository;

  RecognitionUseCases(this._repository);

  /// 开始语音识别
  Stream<Either<Failure, RecognitionResult>> startRecognition() {
    return _repository.startRecognition();
  }

  /// 发送音频数据
  Future<Either<Failure, void>> sendAudioData(Uint8List audioData, {bool isEnd = false}) {
    return _repository.sendAudioData(audioData, isEnd: isEnd);
  }

  /// 停止语音识别
  Future<Either<Failure, void>> stopRecognition() {
    return _repository.stopRecognition();
  }

  /// 取消语音识别
  Future<Either<Failure, void>> cancelRecognition() {
    return _repository.cancelRecognition();
  }
}

/// 语音识别结果
class RecognitionResult {
  final String text;
  final double confidence;
  final bool isFinal;
  final DateTime timestamp;

  const RecognitionResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognitionResult &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          confidence == other.confidence &&
          isFinal == other.isFinal &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      text.hashCode ^ confidence.hashCode ^ isFinal.hashCode ^ timestamp.hashCode;

  @override
  String toString() {
    return 'RecognitionResult{text: $text, confidence: $confidence, isFinal: $isFinal}';
  }

  RecognitionResult copyWith({
    String? text,
    double? confidence,
    bool? isFinal,
    DateTime? timestamp,
  }) {
    return RecognitionResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// 语音识别会话
class RecognitionSession {
  final String id;
  final DateTime startTime;
  final List<RecognitionResult> results;
  bool isActive;

  RecognitionSession({
    required this.id,
    required this.startTime,
    this.results = const [],
    this.isActive = true,
  });

  void addResult(RecognitionResult result) {
    if (result.isFinal) {
      // 如果是最终结果，移除之前的临时结果
      results.removeWhere((r) => !r.isFinal && r.timestamp.isBefore(result.timestamp));
    }
    results.add(result);
  }

  String get fullText {
    final finalResults = results.where((r) => r.isFinal).toList();
    if (finalResults.isNotEmpty) {
      return finalResults.map((r) => r.text).join();
    }
    // 如果没有最终结果，返回最后一个结果
    final lastResult = results.isNotEmpty ? results.last : null;
    return lastResult?.text ?? '';
  }

  double get averageConfidence {
    if (results.isEmpty) return 0.0;
    final totalConfidence = results.fold<double>(0.0, (sum, r) => sum + r.confidence);
    return totalConfidence / results.length;
  }

  Duration get duration => DateTime.now().difference(startTime);

  RecognitionSession copyWith({
    String? id,
    DateTime? startTime,
    List<RecognitionResult>? results,
    bool? isActive,
  }) {
    return RecognitionSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      results: results ?? this.results,
      isActive: isActive ?? this.isActive,
    );
  }
}