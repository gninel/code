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
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';

import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/core/utils/injection.dart';

class AiGenerationWidget extends StatelessWidget {
  final List<VoiceRecord> voiceRecords;
  final Autobiography? currentAutobiography;

  const AiGenerationWidget({
    super.key,
    required this.voiceRecords,
    this.currentAutobiography,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AiGenerationBloc>()..add(
        currentAutobiography != null
            ? IncrementalUpdateAutobiography(
                newVoiceRecords: voiceRecords,
                currentAutobiography: currentAutobiography!,
              )
            : GenerateCompleteAutobiography(voiceRecords: voiceRecords),
      ),
      child: AiGenerationView(
        voiceRecords: voiceRecords,
        currentAutobiography: currentAutobiography,
      ),
    );
  }
}

class AiGenerationView extends StatelessWidget {
  final List<VoiceRecord> voiceRecords;
  final Autobiography? currentAutobiography;

  const AiGenerationView({
    super.key, 
    required this.voiceRecords,
    this.currentAutobiography,
  });

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
      },
      child: BlocBuilder<AiGenerationBloc, AiGenerationState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 状态指示器
                _buildStatusIndicator(context, state),
                const SizedBox(height: 24),

                // 生成进度
                _buildGenerationProgress(context, state),
                const SizedBox(height: 24),

                // 生成结果
                if (state.hasGeneratedContent) ...[
                  _buildGenerationResult(context, state),
                  const SizedBox(height: 16),
                ],

                // 操作按钮
                _buildActionButtons(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, AiGenerationState state) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(state.statusColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForStatus(state.status),
              color: Color(state.statusColor),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.status.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Color(state.statusColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.progressDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (state.isGenerating || state.isOptimizing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerationProgress(BuildContext context, AiGenerationState state) {
    if (!state.isGenerating && !state.isOptimizing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                state.isGenerating ? Icons.psychology : Icons.tune,
                color: Color(state.statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(state.statusColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.isGenerating
              ? 'AI正在根据您的语音记录生成个性化自传，请稍候...'
              : 'AI正在优化您的内容，使其更加流畅和生动...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
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
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和统计信息
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: Theme.of(context).colorScheme.primary,
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
                  label: Text('${state.wordCount}字', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                state.generatedContent!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AiGenerationState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 保存按钮
        if (state.hasGeneratedContent)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: 240, // Constraint width
              child: ElevatedButton.icon(
                onPressed: () => _saveAutobiography(context, state),
                icon: const Icon(Icons.check),
                label: Text(currentAutobiography == null ? '保存自传' : '保存更新'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),

        // 主要操作按钮
        if (state.hasGeneratedContent) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
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
                    label: const Text('优化内容'),
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
                            context.read<AiGenerationBloc>().add(
                              const GenerateCompleteAutobiography(voiceRecords: []),
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
          ),
          const SizedBox(height: 16),
        ],

        // 次要操作按钮
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  _showStyleSelectionDialog(context, state);
                },
                icon: const Icon(Icons.style, size: 18),
                label: const Text('更改风格'),
              ),
              Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
              TextButton.icon(
                onPressed: state.hasGeneratedContent
                    ? () {
                        _showWordCountDialog(context, state);
                      }
                    : null,
                icon: const Icon(Icons.format_size, size: 18),
                label: const Text('调整字数'),
              ),
              Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
              TextButton.icon(
                onPressed: state.hasGeneratedContent
                    ? () {
                        _exportContent(context, state);
                      }
                    : null,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('分享'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveAutobiography(BuildContext context, AiGenerationState state) {
    final result = state.generationResult;
    if (result == null) return;
    
    final now = DateTime.now();
    // 合并 ID：如果是增量更新，则保留原有的 ID 并添加新的
    final Set<String> allRecordIds = {
      if (currentAutobiography != null) ...currentAutobiography!.voiceRecordIds,
      ...voiceRecords.map((e) => e.id),
    };
    
    final newAutobiography = currentAutobiography?.copyWith(
      title: result.title,
      content: result.content,
      // 使用生成的摘要，如果为空则保持原样
      summary: result.summary.isNotEmpty ? result.summary : currentAutobiography!.summary,
      wordCount: result.wordCount,
      lastModifiedAt: now,
      voiceRecordIds: allRecordIds.toList(),
    ) ?? Autobiography(
      id: const Uuid().v4(),
      title: result.title,
      content: result.content,
      summary: result.summary,
      wordCount: result.wordCount,
      generatedAt: now,
      lastModifiedAt: now,
      voiceRecordIds: voiceRecords.map((e) => e.id).toList(),
      status: AutobiographyStatus.draft,
      style: result.style,
    );
    
    if (currentAutobiography != null) {
      context.read<AutobiographyBloc>().add(UpdateAutobiography(newAutobiography));
    } else {
      context.read<AutobiographyBloc>().add(AddAutobiography(newAutobiography));
    }
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('自传已保存')),
    );
  }

  void _showStyleSelectionDialog(BuildContext context, AiGenerationState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择写作风格'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AutobiographyStyle.values.map((style) {
            return RadioListTile<AutobiographyStyle>(
              title: Text(_getStyleDisplayName(style)),
              subtitle: Text(_getStyleDescription(style)),
              value: style,
              groupValue: state.generationResult?.style ?? AutobiographyStyle.narrative,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop();
                  // 重新生成使用新风格
                  context.read<AiGenerationBloc>().add(
                    GenerateCompleteAutobiography(
                      voiceRecords: voiceRecords,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showWordCountDialog(BuildContext context, AiGenerationState state) {
    final controller = TextEditingController(text: state.wordCount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final wordCount = int.tryParse(controller.text);
              if (wordCount != null && wordCount > 0) {
                Navigator.of(context).pop();
                // 重新生成使用新字数
                context.read<AiGenerationBloc>().add(
                  GenerateCompleteAutobiography(
                    voiceRecords: voiceRecords,
                    style: state.generationResult?.style ?? AutobiographyStyle.narrative,
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