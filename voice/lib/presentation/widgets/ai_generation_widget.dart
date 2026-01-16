import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';

class AiGenerationWidget extends StatefulWidget {
  final List<VoiceRecord> voiceRecords;
  final Autobiography? currentAutobiography;
  final bool skipAutoTrigger;

  const AiGenerationWidget({
    super.key,
    required this.voiceRecords,
    this.currentAutobiography,
    this.skipAutoTrigger = false,
  });

  @override
  State<AiGenerationWidget> createState() => _AiGenerationWidgetState();
}

class _AiGenerationWidgetState extends State<AiGenerationWidget> {
  @override
  void initState() {
    super.initState();
    print('DEBUG: AiGenerationWidget.initState called');
    print('DEBUG: skipAutoTrigger=${widget.skipAutoTrigger}');
    print('DEBUG: voiceRecords.length=${widget.voiceRecords.length}');
    print(
        'DEBUG: currentAutobiography=${widget.currentAutobiography?.id ?? "null"}');

    // 如果跳过自动触发，则不执行任何操作
    if (widget.skipAutoTrigger) {
      print('DEBUG: Skipping auto trigger');
      return;
    }

    // 检查状态，如果未开始则触发生成
    // 使用 addPostFrameCallback 确保在构建完成后获取 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG: PostFrameCallback executing');
      final bloc = context.read<AiGenerationBloc>();
      print('DEBUG: bloc.state.isGenerating=${bloc.state.isGenerating}');
      print('DEBUG: bloc.state.isOptimizing=${bloc.state.isOptimizing}');
      print(
          'DEBUG: bloc.state.hasGeneratedContent=${bloc.state.hasGeneratedContent}');

      if (!bloc.state.isGenerating &&
          !bloc.state.isOptimizing &&
          !bloc.state.hasGeneratedContent) {
        print('DEBUG: Conditions met, dispatching event');
        if (widget.currentAutobiography != null) {
          print('DEBUG: Dispatching IncrementalUpdateAutobiography event');
          bloc.add(
            IncrementalUpdateAutobiography(
              newVoiceRecords: widget.voiceRecords,
              currentAutobiography: widget.currentAutobiography!,
            ),
          );
        } else {
          print('DEBUG: Dispatching GenerateCompleteAutobiography event');
          bloc.add(
              GenerateCompleteAutobiography(voiceRecords: widget.voiceRecords));
        }
      } else {
        print('DEBUG: Conditions NOT met, skipping event dispatch');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 不再这里创建 BlocProvider，而是使用全局的
    return AiGenerationView(
      voiceRecords: widget.voiceRecords,
      currentAutobiography: widget.currentAutobiography,
    );
  }
}

class AiGenerationView extends StatefulWidget {
  final List<VoiceRecord> voiceRecords;
  final Autobiography? currentAutobiography;

  const AiGenerationView({
    super.key,
    required this.voiceRecords,
    this.currentAutobiography,
  });

  @override
  State<AiGenerationView> createState() => _AiGenerationViewState();
}

class _AiGenerationViewState extends State<AiGenerationView> {
  bool _hasAutoSaved = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiGenerationBloc, AiGenerationState>(
      listener: (context, state) {
        if (state.hasError && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }

        // 如果是重新生成完成(baseAutobiography为null表示是完整重新生成),自动保存
        if (state.status == AiGenerationStatus.completed &&
            state.baseAutobiography == null &&
            state.generationResult != null &&
            !_hasAutoSaved) {
          // 标记已自动保存,防止重复触发
          _hasAutoSaved = true;
          // 延迟执行以避免在build期间调用
          Future.delayed(Duration.zero, () {
            if (context.mounted) {
              _autoSaveAfterRegeneration(context, state);
            }
          });
        }
      },
      child: BlocBuilder<AiGenerationBloc, AiGenerationState>(
        builder: (context, state) {
          // 使用 Column + Expanded 布局确保底部按钮可见
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 状态指示器
                      _buildStatusIndicator(context, state),
                      const SizedBox(height: 24),

                      // 生成进度
                      _buildGenerationProgress(context, state),

                      // 成功时直接显示结果（更简洁）
                      if (state.hasGeneratedContent) ...[
                        const SizedBox(height: 16),
                        _buildGenerationResult(context, state),
                      ],
                    ],
                  ),
                ),
              ),

              // 底部操作区 (固定在底部)
              if (!state.isGenerating && !state.isOptimizing)
                _buildBottomActionArea(context, state),
            ],
          );
        },
      ),
    );
  }

  // 移除了独立的成功提示，改为在结果卡片中显示
  // Widget _buildSuccessMessage 已弃用

  Widget _buildStatusIndicator(BuildContext context, AiGenerationState state) {
    // 只有在空闲状态且已有内容时才隐藏状态指示器
    // 在生成中、完成、错误状态都应该显示
    if (state.isIdle && state.hasGeneratedContent) return const SizedBox.shrink();

    // 完成状态使用简洁的一行提示
    if (state.isCompleted || state.isOptimized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF4CAF50),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              state.progressDescription,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 生成中和错误状态保持原有的卡片样式
    return Card(
      elevation: 4,
      color: const Color(0xFFFBF8F1), // 纸张色
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD7CCC8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            // 图标区域
            SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                _getIconForStatus(state.status),
                color: const Color(0xFF5D4037),
                size: 48,
              ),
            ),
            const SizedBox(width: 24),
            // 文字区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.status.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                      letterSpacing: 1,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.progressDescription,
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF5D4037).withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (state.isGenerating || state.isOptimizing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8D6E63)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationProgress(
      BuildContext context, AiGenerationState state) {
    if (!state.isGenerating && !state.isOptimizing) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: const Color(0xFFFBF8F1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD7CCC8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_alt, // 类似截图中的脑袋图标
                  color: Color(0xFF5D4037),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBE0), // 轨道颜色
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF5D4037)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              state.isGenerating
                  ? 'AI正在后台为您生成自传，您可以暂时离开此页面...'
                  : 'AI正在后台优化内容，请稍候...',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF5D4037).withValues(alpha: 0.9),
                height: 1.5,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationResult(BuildContext context, AiGenerationState state) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和统计信息 (带微小成功指示器)
          Row(
            children: [
              // 用小绿勾替换图标以暗示成功，但不突兀
              Stack(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.hasTitle ? state.generatedTitle! : '生成的自传',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (state.wordCount > 0)
                Chip(
                  label: Text('${state.wordCount}字',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 摘要
          if (state.hasSummary) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '摘要',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.generatedSummary!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 内容预览
          Container(
            width: double.infinity,
            // 移除固定高度限制，让它自适应 Expanded
            // constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.generatedContent!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea(BuildContext context, AiGenerationState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 主要操作按钮
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: state.status.canOptimize
                        ? () {
                            context.read<AiGenerationBloc>().add(
                                  OptimizeAutobiography(
                                    content: state.generatedContent!,
                                    optimizationType: OptimizationType.fluency,
                                  ),
                                );
                          }
                        : null,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('优化'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.status.canRegenerate
                        ? () {
                            print(
                                'AiGenerationView: Regenerate clicked, voiceRecords: ${widget.voiceRecords.length}');
                            // 使用RegenerateCompleteAutobiography确保删除旧数据
                            context.read<AiGenerationBloc>().add(
                                  RegenerateCompleteAutobiography(
                                    allVoiceRecords: widget.voiceRecords,
                                    style: state.generationResult?.style ?? AutobiographyStyle.narrative,
                                    wordCount: state.generationResult?.wordCount,
                                  ),
                                );
                          }
                        : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重新生成'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 保存按钮 (最重要)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _saveAutobiography(context, state),
                icon: const Icon(Icons.check),
                label: Text(widget.currentAutobiography == null ? '保存到我的自传' : '保存更新'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 自动保存重新生成的内容(不关闭页面,不清除状态)
  void _autoSaveAfterRegeneration(BuildContext context, AiGenerationState state) async {
    print('DEBUG: Auto-saving after regeneration');
    await _saveAutobiographyInternal(context, state, autoSave: true);
  }

  void _saveAutobiography(BuildContext context, AiGenerationState state) async {
    await _saveAutobiographyInternal(context, state, autoSave: false);
  }

  Future<void> _saveAutobiographyInternal(
    BuildContext context,
    AiGenerationState state, {
    required bool autoSave,
  }) async {
    final result = state.generationResult;
    if (result == null) return;

    final now = DateTime.now();
    // 合并 ID：如果是增量更新，则保留原有的 ID 并添加新的
    final Set<String> allRecordIds = {
      if (widget.currentAutobiography != null) ...widget.currentAutobiography!.voiceRecordIds,
      ...widget.voiceRecords.map((e) => e.id),
    };

    // 将内容包装为 Chapter 对象
    final Chapter mainChapter = Chapter(
      id: widget.currentAutobiography?.chapters.isNotEmpty == true
          ? widget.currentAutobiography!.chapters.first.id
          : const Uuid().v4(),
      title: result.title,
      content: result.content,
      order: 0,
      sourceRecordIds: widget.voiceRecords.map((e) => e.id).toList(),
      lastModifiedAt: now,
    );

    final newAutobiography = widget.currentAutobiography?.copyWith(
          title: result.title,
          content: result.content,
          chapters: [mainChapter], // 设置 chapters 字段
          // 使用生成的摘要，如果为空则保持原样
          summary: result.summary.isNotEmpty
              ? result.summary
              : widget.currentAutobiography!.summary,
          wordCount: result.wordCount,
          lastModifiedAt: now,
          voiceRecordIds: allRecordIds.toList(),
        ) ??
        Autobiography(
          id: const Uuid().v4(),
          title: result.title,
          content: result.content,
          chapters: [mainChapter], // 设置 chapters 字段
          summary: result.summary,
          wordCount: result.wordCount,
          generatedAt: now,
          lastModifiedAt: now,
          voiceRecordIds: widget.voiceRecords.map((e) => e.id).toList(),
          status: AutobiographyStatus.draft,
          style: result.style,
        );

    if (widget.currentAutobiography != null) {
      context
          .read<AutobiographyBloc>()
          .add(UpdateAutobiography(newAutobiography));
    } else {
      context.read<AutobiographyBloc>().add(AddAutobiography(newAutobiography));
    }

    // 等待一小段时间确保数据库更新完成
    await Future.delayed(const Duration(milliseconds: 300));

    if (!autoSave) {
      // 只有手动保存时才清除状态并关闭页面
      context.read<AiGenerationBloc>().add(const ClearGenerationResult());

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('自传已保存')),
        );
      }
    } else {
      // 自动保存时只显示提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('自传已自动保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showStyleSelectionDialog(
      BuildContext context, AiGenerationState state) {
    // 捕获 Bloc 实例，避免在 Dialog Context 中查找失败
    final bloc = context.read<AiGenerationBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('选择写作风格'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AutobiographyStyle.values.map((style) {
            return RadioListTile<AutobiographyStyle>(
              title: Text(_getStyleDisplayName(style)),
              subtitle: Text(_getStyleDescription(style)),
              value: style,
              groupValue:
                  state.generationResult?.style ?? AutobiographyStyle.narrative,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(dialogContext).pop();
                  // 重新生成使用新风格
                  bloc.add(
                    GenerateCompleteAutobiography(
                      voiceRecords: widget.voiceRecords,
                      style: value,
                      wordCount: state.generationResult?.wordCount,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showWordCountDialog(BuildContext context, AiGenerationState state) {
    final controller = TextEditingController(text: state.wordCount.toString());
    // 捕获 Bloc 实例
    final bloc = context.read<AiGenerationBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('调整字数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '目标字数',
            hintText: '1000-10000字',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final wordCount = int.tryParse(controller.text);
              if (wordCount != null && wordCount > 0) {
                Navigator.of(dialogContext).pop();
                // 重新生成使用新字数
                bloc.add(
                  GenerateCompleteAutobiography(
                    voiceRecords: widget.voiceRecords,
                    style: state.generationResult?.style ??
                        AutobiographyStyle.narrative,
                    wordCount: wordCount,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _exportContent(BuildContext context, AiGenerationState state) {
    if (state.generatedContent != null) {
      Clipboard.setData(ClipboardData(text: state.generatedContent!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容已复制到剪贴板')),
      );
    }
  }

  IconData _getIconForStatus(AiGenerationStatus status) {
    switch (status) {
      case AiGenerationStatus.idle:
        return Icons.auto_stories;
      case AiGenerationStatus.generating:
        return Icons.psychology;
      case AiGenerationStatus.optimizing:
        return Icons.tune;
      case AiGenerationStatus.completed:
        return Icons.check_circle;
      case AiGenerationStatus.optimized:
        return Icons.verified;
      case AiGenerationStatus.error:
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStyleDisplayName(AutobiographyStyle style) {
    switch (style) {
      case AutobiographyStyle.narrative:
        return '叙事风格';
      case AutobiographyStyle.emotional:
        return '情感风格';
      case AutobiographyStyle.achievement:
        return '成就风格';
      case AutobiographyStyle.chronological:
        return '编年体风格';
      case AutobiographyStyle.reflection:
        return '反思风格';
    }
  }

  String _getStyleDescription(AutobiographyStyle style) {
    switch (style) {
      case AutobiographyStyle.narrative:
        return '以讲故事的方式流畅叙述经历';
      case AutobiographyStyle.emotional:
        return '注重情感表达和内心感受';
      case AutobiographyStyle.achievement:
        return '突出成就和重要人生里程碑';
      case AutobiographyStyle.chronological:
        return '按照时间顺序系统整理经历';
      case AutobiographyStyle.reflection:
        return '包含深度自我反思和人生感悟';
    }
  }
}
