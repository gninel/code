import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';

import '../../../domain/usecases/ai_generation_usecases.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/autobiography.dart';
import '../../../domain/repositories/autobiography_repository.dart';
import '../../../data/services/background_ai_service.dart';
import '../../../data/services/ai_generation_persistence_service.dart';

import 'ai_generation_event.dart';
import 'ai_generation_state.dart';

@injectable
class AiGenerationBloc extends Bloc<AiGenerationEvent, AiGenerationState> {
  final AiGenerationUseCases _aiGenerationUseCases;
  final AutobiographyRepository _autobiographyRepository;
  final BackgroundAiService _backgroundAiService;
  final AiGenerationPersistenceService _persistenceService;

  AiGenerationBloc(
    this._aiGenerationUseCases,
    this._autobiographyRepository,
    this._backgroundAiService,
    this._persistenceService,
  ) : super(const AiGenerationState()) {
    on<GenerateAutobiography>(_onGenerateAutobiography);
    on<OptimizeAutobiography>(_onOptimizeAutobiography);
    on<GenerateTitle>(_onGenerateTitle);
    on<GenerateSummary>(_onGenerateSummary);
    on<GenerateCompleteAutobiography>(_onGenerateCompleteAutobiography);
    on<IncrementalUpdateAutobiography>(_onIncrementalUpdateAutobiography);
    on<RegenerateCompleteAutobiography>(_onRegenerateCompleteAutobiography);
    on<ClearGenerationResult>(_onClearGenerationResult);
    on<CheckRestorableState>(_onCheckRestorableState);

    // 初始化时检查是否有可恢复的状态 (仅非Web平台)
    if (!kIsWeb) {
      add(const CheckRestorableState());
    }
  }

  Future<void> _onCheckRestorableState(
    CheckRestorableState event,
    Emitter<AiGenerationState> emit,
  ) async {
    final info = _persistenceService.getUnfinishedTaskInfo();
    if (info == null) return;

    final status = info['status'] as String?;
    final generatedContent = info['generatedContent'] as String?;
    final generatedTitle = info['generatedTitle'] as String?;
    final generatedSummary = info['generatedSummary'] as String?;
    // generationType and voiceRecordIds are unused for now
    // final generationType = info['generationType'] as String?;
    // final voiceRecordIds =
    //     (info['voiceRecordIds'] as List<dynamic>?)?.cast<String>() ?? [];

    print('AiGenerationBloc: Checking restorable state. Status: $status');

    if (status == 'completed' && generatedContent != null) {
      print('AiGenerationBloc: Restoring completed state');

      final style = AutobiographyStyle.values.firstWhere(
        (e) => e.toString() == info['style'],
        orElse: () => AutobiographyStyle.narrative,
      );

      final result = AutobiographyGenerationResult(
        content: generatedContent,
        title: generatedTitle ?? '生成的自传',
        summary: generatedSummary ?? '',
        wordCount: generatedContent.length,
        style: style,
      );

      emit(state.copyWith(
        status: AiGenerationStatus.completed,
        generationResult: result,
        generatedContent: generatedContent,
        generatedTitle: generatedTitle,
        generatedSummary: generatedSummary,
        error: null,
      ));
    } else if (status == 'generating') {
      // 如果目前还在生成状态（实际上APP已重启），说明任务被中断或仍在后台（不太可能，因为Isolate已死）
      // 检查是否超时
      if (_persistenceService.isTaskTimeout()) {
        await _persistenceService.clearGenerationState();
        emit(state.copyWith(
          status: AiGenerationStatus.error,
          error: '后台生成任务超时，请重试',
        ));
      } else {
        // 视为中断
        await _persistenceService.clearGenerationState();
        emit(state.copyWith(
          status: AiGenerationStatus.error,
          error: '后台生成任务意外中断，请重试',
        ));
      }
    }
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
      activeVoiceRecords: event.newVoiceRecords,
      baseAutobiography: event.currentAutobiography,
    ));

    // 启动后台服务，确保切换应用时任务继续执行 (仅非Web平台)
    if (!kIsWeb) {
      await _backgroundAiService.startBackgroundTask(
        taskDescription: '正在增量更新自传内容...',
      );

      // 保存生成任务状态
      await _persistenceService.saveGenerationState(
        generationType: 'incremental',
        voiceRecordIds: event.newVoiceRecords.map((r) => r.id).toList(),
        currentAutobiographyId: event.currentAutobiography.id,
        status: 'generating',
      );
    }

    try {
      print('AiGenerationBloc: Starting incremental update...');
      // 提取新录音的文本内容
      // 优先使用content字段(包含问题和回答),如果没有则使用transcription
      final newContent = event.newVoiceRecords
          .where((r) =>
              (r.content.isNotEmpty) ||
              (r.transcription != null && r.transcription!.isNotEmpty))
          .map((r) =>
              r.content.isNotEmpty == true ? r.content : r.transcription!)
          .join('\n\n');

      if (newContent.isEmpty) {
        if (!kIsWeb) await _backgroundAiService.stopBackgroundTask();
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

      if (result.isLeft()) {
        final failure = result.fold((l) => l, (r) => throw Exception());
        if (!kIsWeb) {
          await _backgroundAiService.stopBackgroundTask();
          await _persistenceService.clearGenerationState();
        }
        emit(state.copyWith(
          status: AiGenerationStatus.error,
          error: failure.message,
        ));
      } else {
        final updateResult = result.fold((l) => throw Exception(), (r) => r);
        print('AiGenerationBloc: Incremental update success');

        // 构建更新后的完整内容
        String fullContent = '';
        final currentChapters =
            List<Chapter>.from(event.currentAutobiography.chapters);

        if (updateResult.updateType == UpdateType.newChapter) {
          currentChapters.add(updateResult.updatedChapter!);
        } else if (updateResult.updateType == UpdateType.chapterUpdated) {
          currentChapters[updateResult.updateIndex] =
              updateResult.updatedChapter!;
        } else if (updateResult.updateType == UpdateType.fullReplacement) {
          // 全量替换模式：清除所有现有章节，使用新生成的一个完整章节
          print('AiGenerationBloc: Handling Full Replacement update');
          currentChapters.clear();
          currentChapters.add(updateResult.updatedChapter!);
        }

        fullContent = currentChapters.map((c) => c.content).join('\n\n');

        // 构造一个临时的 generationResult 用于展示
        final generationResult = AutobiographyGenerationResult(
          content: fullContent,
          title: event.currentAutobiography.title,
          summary: event.currentAutobiography.summary ?? '',
          wordCount: fullContent.length,
          style:
              event.currentAutobiography.style ?? AutobiographyStyle.narrative,
        );

        if (!kIsWeb) {
          await _backgroundAiService.stopBackgroundTask();
          await _persistenceService.updateGenerationProgress(
            generatedContent: fullContent,
            generatedTitle: generationResult.title,
            generatedSummary: generationResult.summary,
            status: 'completed',
          );
        }
        emit(state.copyWith(
          status: AiGenerationStatus.completed,
          generationResult: generationResult,
          generatedContent: fullContent,
          generatedTitle: generationResult.title,
          generatedSummary: generationResult.summary,
          error: null,
        ));
      }
    } catch (e) {
      print('AiGenerationBloc: Exception caught during incremental update: $e');
      // 停止后台服务并清除状态
      if (!kIsWeb) {
        await _backgroundAiService.stopBackgroundTask();
        await _persistenceService.clearGenerationState();
      }
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
      activeVoiceRecords: event.voiceRecords,
      baseAutobiography: null, // Clear base for complete generation
    ));

    // 启动后台服务，确保切换应用时任务继续执行 (仅非Web平台)
    if (!kIsWeb) {
      await _backgroundAiService.startBackgroundTask(
        taskDescription: '正在生成完整自传...',
      );

      // 保存生成任务状态
      await _persistenceService.saveGenerationState(
        generationType: 'complete',
        voiceRecordIds: event.voiceRecords.map((r) => r.id).toList(),
        status: 'generating',
      );
    }

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
          // 停止后台服务并清除状态
          if (!kIsWeb) {
            _backgroundAiService.stopBackgroundTask();
            _persistenceService.clearGenerationState();
          }
          emit(state.copyWith(
            status: AiGenerationStatus.error,
            error: failure.message,
          ));
        },
        (generationResult) {
          print('AiGenerationBloc: Generation success');
          // 停止后台服务并更新状态（不立即清除，等待用户保存）
          if (!kIsWeb) {
            _backgroundAiService.stopBackgroundTask();
            _persistenceService.updateGenerationProgress(
              generatedContent: generationResult.content,
              generatedTitle: generationResult.title,
              generatedSummary: generationResult.summary,
              status: 'completed',
            );
          }
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
      // 停止后台服务并清除状态
      if (!kIsWeb) {
        await _backgroundAiService.stopBackgroundTask();
        await _persistenceService.clearGenerationState();
      }
      emit(state.copyWith(
        status: AiGenerationStatus.error,
        error: '生成完整自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRegenerateCompleteAutobiography(
    RegenerateCompleteAutobiography event,
    Emitter<AiGenerationState> emit,
  ) async {
    if (state.isGenerating) {
      print(
          'AiGenerationBloc: Blocked regeneration because state is already generating: ${state.status}');
      return;
    }

    emit(state.copyWith(
      status: AiGenerationStatus.generating,
      error: null,
    ));

    // 启动后台服务
    if (!kIsWeb) {
      await _backgroundAiService.startBackgroundTask(
        taskDescription: '正在重新生成完整自传...',
      );
    }

    try {
      print('AiGenerationBloc: Starting complete regeneration...');

      // Step 1: 获取所有现有自传
      final existingResult =
          await _autobiographyRepository.getAllAutobiographies();

      // Step 2: 删除所有现有自传
      await existingResult.fold(
        (failure) async {
          print(
              'AiGenerationBloc: Warning - Failed to get existing autobiographies: ${failure.message}');
        },
        (autobiographies) async {
          if (autobiographies.isNotEmpty) {
            final ids = autobiographies.map((a) => a.id).toList();
            final deleteResult =
                await _autobiographyRepository.deleteAutobiographies(ids);
            deleteResult.fold(
              (failure) {
                print(
                    'AiGenerationBloc: Failed to delete autobiographies: ${failure.message}');
              },
              (_) {
                print(
                    'AiGenerationBloc: Deleted ${autobiographies.length} existing autobiographies');
              },
            );
          }
        },
      );

      // Step 3: 生成新的完整自传
      final result = await _aiGenerationUseCases.generateCompleteAutobiography(
        voiceRecords: event.allVoiceRecords,
        style: event.style,
        wordCount: event.wordCount,
      );

      if (!kIsWeb) await _backgroundAiService.stopBackgroundTask();

      result.fold(
        (failure) {
          print(
              'AiGenerationBloc: Regeneration failed with ${failure.message}');
          emit(state.copyWith(
            status: AiGenerationStatus.error,
            error: failure.message,
          ));
        },
        (generationResult) {
          print('AiGenerationBloc: Regeneration success');
          emit(state.copyWith(
            status: AiGenerationStatus.completed,
            generationResult: generationResult,
            generatedContent: generationResult.content,
            generatedTitle: generationResult.title,
            generatedSummary: generationResult.summary,
            activeVoiceRecords: event.allVoiceRecords,
            baseAutobiography: null,
            error: null,
          ));
        },
      );
    } catch (e) {
      print('AiGenerationBloc: Exception caught during regeneration: $e');
      if (!kIsWeb) await _backgroundAiService.stopBackgroundTask();
      emit(state.copyWith(
        status: AiGenerationStatus.error,
        error: '完整重新生成失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearGenerationResult(
    ClearGenerationResult event,
    Emitter<AiGenerationState> emit,
  ) async {
    // 清除持久化的生成状态
    if (!kIsWeb) {
      await _persistenceService.clearGenerationState();
    }
    emit(const AiGenerationState());
  }
}
