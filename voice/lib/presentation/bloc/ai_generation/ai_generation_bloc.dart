import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/usecases/ai_generation_usecases.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/autobiography.dart';

import 'ai_generation_event.dart';
import 'ai_generation_state.dart';

@injectable
class AiGenerationBloc extends Bloc<AiGenerationEvent, AiGenerationState> {
  final AiGenerationUseCases _aiGenerationUseCases;

  AiGenerationBloc(this._aiGenerationUseCases) : super(const AiGenerationState()) {
    on<GenerateAutobiography>(_onGenerateAutobiography);
    on<OptimizeAutobiography>(_onOptimizeAutobiography);
    on<GenerateTitle>(_onGenerateTitle);
    on<GenerateSummary>(_onGenerateSummary);
    on<GenerateCompleteAutobiography>(_onGenerateCompleteAutobiography);
    on<IncrementalUpdateAutobiography>(_onIncrementalUpdateAutobiography);
    on<ClearGenerationResult>(_onClearGenerationResult);
  }

  Future<void> _onGenerateAutobiography(
    GenerateAutobiography event,
    Emitter<AiGenerationState> emit,
  ) async {
    if (state.isGenerating) return;

    emit(state.copyWith(
      status: AiGenerationStatus.generating,
      error: null,
    ));

    try {
      final result = await _aiGenerationUseCases.generateAutobiography(
        voiceRecords: event.voiceRecords,
        style: event.style,
        wordCount: event.wordCount,
      );

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: AiGenerationStatus.error,
            error: failure.message,
          ));
        },
        (content) {
          emit(state.copyWith(
            status: AiGenerationStatus.completed,
            generatedContent: content,
            error: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AiGenerationStatus.error,
        error: '生成自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onOptimizeAutobiography(
    OptimizeAutobiography event,
    Emitter<AiGenerationState> emit,
  ) async {
    if (state.isOptimizing) return;

    emit(state.copyWith(
      status: AiGenerationStatus.optimizing,
      error: null,
    ));

    try {
      final result = await _aiGenerationUseCases.optimizeAutobiography(
        content: event.content,
        optimizationType: event.optimizationType,
      );

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: AiGenerationStatus.error,
            error: failure.message,
          ));
        },
        (optimizedContent) {
          emit(state.copyWith(
            status: AiGenerationStatus.optimized,
            generatedContent: optimizedContent,
            error: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AiGenerationStatus.error,
        error: '优化内容失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGenerateTitle(
    GenerateTitle event,
    Emitter<AiGenerationState> emit,
  ) async {
    try {
      final result = await _aiGenerationUseCases.generateTitle(
        content: event.content,
      );

      result.fold(
        (failure) {
          // 标题生成失败不影响主要流程，静默处理
        },
        (title) {
          emit(state.copyWith(generatedTitle: title));
        },
      );
    } catch (e) {
      // 标题生成失败不影响主要流程，静默处理
    }
  }

  Future<void> _onGenerateSummary(
    GenerateSummary event,
    Emitter<AiGenerationState> emit,
  ) async {
    try {
      final result = await _aiGenerationUseCases.generateSummary(
        content: event.content,
      );

      result.fold(
        (failure) {
          // 摘要生成失败不影响主要流程，静默处理
        },
        (summary) {
          emit(state.copyWith(generatedSummary: summary));
        },
      );
    } catch (e) {
      // 摘要生成失败不影响主要流程，静默处理
    }
  }

  Future<void> _onIncrementalUpdateAutobiography(
    IncrementalUpdateAutobiography event,
    Emitter<AiGenerationState> emit,
  ) async {
    if (state.isGenerating) return;

    emit(state.copyWith(
      status: AiGenerationStatus.generating,
      error: null,
    ));

    try {
      print('AiGenerationBloc: Starting incremental update...');
      // 提取新录音的文本内容
      final newContent = event.newVoiceRecords
          .where((r) => r.transcription != null && r.transcription!.isNotEmpty)
          .map((r) => r.transcription!)
          .join('\n\n');

      if (newContent.isEmpty) {
        emit(state.copyWith(
          status: AiGenerationStatus.error,
          error: '新录音没有有效的转录内容',
        ));
        return;
      }

      final result = await _aiGenerationUseCases.incrementalUpdateAutobiography(
        newVoiceContent: newContent,
        currentAutobiography: event.currentAutobiography,
      );

      result.fold(
        (failure) {
          emit(state.copyWith(
            status: AiGenerationStatus.error,
            error: failure.message,
          ));
        },
        (updateResult) {
          print('AiGenerationBloc: Incremental update success');
          
          // 构建更新后的完整内容
          String fullContent = '';
          final currentChapters = List<Chapter>.from(event.currentAutobiography.chapters);
          
          if (updateResult.updateType == UpdateType.newChapter) {
            currentChapters.add(updateResult.updatedChapter!);
          } else if (updateResult.updateType == UpdateType.chapterUpdated) {
             currentChapters[updateResult.updateIndex] = updateResult.updatedChapter!;
          }
          
          fullContent = currentChapters.map((c) => c.content).join('\n\n');

          // 重新生成标题和摘要（可选，但这简化了流程）
          // 暂时复用旧的，或者标记为需要刷新
          // 为了 UI 简单，我们先展示更新后的内容
          
          // 构造一个临时的 generationResult 用于展示
          final generationResult = AutobiographyGenerationResult(
            content: fullContent,
            title: event.currentAutobiography.title,
            summary: event.currentAutobiography.summary ?? '',
            wordCount: fullContent.length,
            style: event.currentAutobiography.style ?? AutobiographyStyle.narrative,
          );

          emit(state.copyWith(
            status: AiGenerationStatus.completed,
            generationResult: generationResult,
            generatedContent: fullContent,
            generatedTitle: generationResult.title,
            generatedSummary: generationResult.summary,
            error: null,
          ));
        },
      );
    } catch (e) {
      print('AiGenerationBloc: Exception caught during incremental update: $e');
      emit(state.copyWith(
        status: AiGenerationStatus.error,
        error: '增量更新失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGenerateCompleteAutobiography(
    GenerateCompleteAutobiography event,
    Emitter<AiGenerationState> emit,
  ) async {
    if (state.isGenerating) return;

    emit(state.copyWith(
      status: AiGenerationStatus.generating,
      error: null,
    ));

    try {
      print('AiGenerationBloc: Starting generation...');
      final result = await _aiGenerationUseCases.generateCompleteAutobiography(
        voiceRecords: event.voiceRecords,
        style: event.style,
        wordCount: event.wordCount,
      );
      print('AiGenerationBloc: Generation result received');

      result.fold(
        (failure) {
          print('AiGenerationBloc: Generation failed with ${failure.message}');
          emit(state.copyWith(
            status: AiGenerationStatus.error,
            error: failure.message,
          ));
        },
        (generationResult) {
          print('AiGenerationBloc: Generation success');
          emit(state.copyWith(
            status: AiGenerationStatus.completed,
            generationResult: generationResult,
            generatedContent: generationResult.content,
            generatedTitle: generationResult.title,
            generatedSummary: generationResult.summary,
            error: null,
          ));
        },
      );
    } catch (e) {
      print('AiGenerationBloc: Exception caught: $e');
      emit(state.copyWith(
        status: AiGenerationStatus.error,
        error: '生成完整自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearGenerationResult(
    ClearGenerationResult event,
    Emitter<AiGenerationState> emit,
  ) async {
    emit(const AiGenerationState());
  }
}