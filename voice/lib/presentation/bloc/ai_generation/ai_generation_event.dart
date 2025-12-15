import 'package:equatable/equatable.dart';

import '../../../domain/entities/voice_record.dart';
import '../../../domain/entities/autobiography.dart';
import '../../../data/services/doubao_ai_service.dart';

abstract class AiGenerationEvent extends Equatable {
  const AiGenerationEvent();

  @override
  List<Object?> get props => [];
}

/// 生成自传事件
class GenerateAutobiography extends AiGenerationEvent {
  final List<VoiceRecord> voiceRecords;
  final AutobiographyStyle style;
  final int? wordCount;

  const GenerateAutobiography({
    required this.voiceRecords,
    this.style = AutobiographyStyle.narrative,
    this.wordCount,
  });

  @override
  List<Object?> get props => [voiceRecords, style, wordCount];
}

/// 优化自传事件
class OptimizeAutobiography extends AiGenerationEvent {
  final String content;
  final OptimizationType optimizationType;

  const OptimizeAutobiography({
    required this.content,
    this.optimizationType = OptimizationType.clarity,
  });

  @override
  List<Object?> get props => [content, optimizationType];
}

/// 生成标题事件
class GenerateTitle extends AiGenerationEvent {
  final String content;

  const GenerateTitle({required this.content});

  @override
  List<Object?> get props => [content];
}

/// 生成摘要事件
class GenerateSummary extends AiGenerationEvent {
  final String content;

  const GenerateSummary({required this.content});

  @override
  List<Object?> get props => [content];
}

/// 生成完整自传事件（包含标题和摘要）
class GenerateCompleteAutobiography extends AiGenerationEvent {
  final List<VoiceRecord> voiceRecords;
  final AutobiographyStyle style;
  final int? wordCount;

  const GenerateCompleteAutobiography({
    required this.voiceRecords,
    this.style = AutobiographyStyle.narrative,
    this.wordCount,
  });

  @override
  List<Object?> get props => [voiceRecords, style, wordCount];
}

/// 增量更新自传事件
class IncrementalUpdateAutobiography extends AiGenerationEvent {
  final List<VoiceRecord> newVoiceRecords;
  final Autobiography currentAutobiography;

  const IncrementalUpdateAutobiography({
    required this.newVoiceRecords,
    required this.currentAutobiography,
  });

  @override
  List<Object?> get props => [newVoiceRecords, currentAutobiography];
}

/// 清除生成结果事件
class ClearGenerationResult extends AiGenerationEvent {
  const ClearGenerationResult();
}