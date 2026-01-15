import 'package:equatable/equatable.dart';
import '../../../domain/usecases/ai_generation_usecases.dart';
import '../../../domain/entities/voice_record.dart';
import '../../../domain/entities/autobiography.dart';

/// AI生成状态
class AiGenerationState extends Equatable {
  final AiGenerationStatus status;
  final String? generatedContent;
  final String? generatedTitle;
  final String? generatedSummary;
  final AutobiographyGenerationResult? generationResult;
  final String? error;
  final DateTime? lastUpdateTime;
  
  // 用于恢复会话的数据
  final List<VoiceRecord> activeVoiceRecords;
  final Autobiography? baseAutobiography;

  const AiGenerationState({
    this.status = AiGenerationStatus.idle,
    this.generatedContent,
    this.generatedTitle,
    this.generatedSummary,
    this.generationResult,
    this.error,
    this.lastUpdateTime,
    this.activeVoiceRecords = const [],
    this.baseAutobiography,
  });

  /// 创建新状态
  AiGenerationState copyWith({
    AiGenerationStatus? status,
    String? generatedContent,
    String? generatedTitle,
    String? generatedSummary,
    AutobiographyGenerationResult? generationResult,
    String? error,
    DateTime? lastUpdateTime,
    List<VoiceRecord>? activeVoiceRecords,
    Autobiography? baseAutobiography,
  }) {
    return AiGenerationState(
      status: status ?? this.status,
      generatedContent: generatedContent ?? this.generatedContent,
      generatedTitle: generatedTitle ?? this.generatedTitle,
      generatedSummary: generatedSummary ?? this.generatedSummary,
      generationResult: generationResult ?? this.generationResult,
      error: error ?? this.error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      activeVoiceRecords: activeVoiceRecords ?? this.activeVoiceRecords,
      baseAutobiography: baseAutobiography ?? this.baseAutobiography,
    );
  }

  /// 是否正在生成
  bool get isGenerating => status == AiGenerationStatus.generating;

  /// 是否正在优化
  bool get isOptimizing => status == AiGenerationStatus.optimizing;

  /// 是否已完成
  bool get isCompleted => status == AiGenerationStatus.completed;

  /// 是否已优化
  bool get isOptimized => status == AiGenerationStatus.optimized;

  /// 是否有错误
  bool get hasError => status == AiGenerationStatus.error;

  /// 是否空闲
  bool get isIdle => status == AiGenerationStatus.idle;

  /// 是否有生成内容
  bool get hasGeneratedContent => generatedContent != null && generatedContent!.isNotEmpty;

  /// 是否有标题
  bool get hasTitle => generatedTitle != null && generatedTitle!.isNotEmpty;

  /// 是否有摘要
  bool get hasSummary => generatedSummary != null && generatedSummary!.isNotEmpty;

  /// 获取生成进度描述
  String get progressDescription {
    switch (status) {
      case AiGenerationStatus.idle:
        return '准备生成自传';
      case AiGenerationStatus.generating:
        return '正在生成自传内容...';
      case AiGenerationStatus.optimizing:
        return '正在优化内容...';
      case AiGenerationStatus.completed:
        return '自传生成完成';
      case AiGenerationStatus.optimized:
        return '内容优化完成';
      case AiGenerationStatus.error:
        return '生成失败';
    }
  }

  /// 获取状态颜色
  int get statusColor {
    switch (status) {
      case AiGenerationStatus.idle:
        return 0xFF9E9E9E; // Grey
      case AiGenerationStatus.generating:
        return 0xFF1976D2; // Blue
      case AiGenerationStatus.optimizing:
        return 0xFF9C27B0; // Purple
      case AiGenerationStatus.completed:
        return 0xFF4CAF50; // Green
      case AiGenerationStatus.optimized:
        return 0xFF2196F3; // Light Blue
      case AiGenerationStatus.error:
        return 0xFFF44336; // Red
    }
  }

  /// 获取字数统计
  int get wordCount => hasGeneratedContent ? generatedContent!.length : 0;

  /// 获取预估阅读时间
  int get estimatedReadingMinutes => (wordCount / 200).ceil();

  @override
  List<Object?> get props => [
        status,
        generatedContent,
        generatedTitle,
        generatedSummary,
        generationResult,
        error,
        lastUpdateTime,
      ];

  @override
  String toString() {
    return 'AiGenerationState{status: $status, hasContent: $hasGeneratedContent, wordCount: $wordCount}';
  }
}

/// AI生成状态枚举
enum AiGenerationStatus {
  /// 空闲状态
  idle,

  /// 正在生成
  generating,

  /// 正在优化
  optimizing,

  /// 生成完成
  completed,

  /// 优化完成
  optimized,

  /// 生成错误
  error,
}

/// AI生成状态扩展方法
extension AiGenerationStatusExtension on AiGenerationStatus {
  /// 获取状态显示名称
  String get displayName {
    switch (this) {
      case AiGenerationStatus.idle:
        return '准备就绪';
      case AiGenerationStatus.generating:
        return '生成中';
      case AiGenerationStatus.optimizing:
        return '优化中';
      case AiGenerationStatus.completed:
        return '生成完成';
      case AiGenerationStatus.optimized:
        return '优化完成';
      case AiGenerationStatus.error:
        return '生成失败';
    }
  }

  /// 获取状态图标名称
  String get iconName {
    switch (this) {
      case AiGenerationStatus.idle:
        return 'auto_stories';
      case AiGenerationStatus.generating:
        return 'psychology';
      case AiGenerationStatus.optimizing:
        return 'tune';
      case AiGenerationStatus.completed:
        return 'check_circle';
      case AiGenerationStatus.optimized:
        return 'verified';
      case AiGenerationStatus.error:
        return 'error';
    }
  }

  /// 是否可以开始新的生成
  bool get canStart => this == AiGenerationStatus.idle || this == AiGenerationStatus.error;

  /// 是否可以优化
  bool get canOptimize => this == AiGenerationStatus.completed || this == AiGenerationStatus.optimized;

  /// 是否可以重新生成
  bool get canRegenerate => this != AiGenerationStatus.generating;
}