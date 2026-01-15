import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../bloc/voice_record/voice_record_bloc.dart';
import '../bloc/voice_record/voice_record_event.dart';
import '../bloc/integrated_recording/integrated_recording_bloc.dart';
import '../bloc/integrated_recording/integrated_recording_event.dart';
import '../../domain/entities/voice_record.dart';

/// 录音预览和编辑页面（Vintage Theme）
class RecordingPreviewPage extends StatefulWidget {
  final String filePath;
  final int duration;
  final String recognizedText;
  final double confidence;

  const RecordingPreviewPage({
    super.key,
    required this.filePath,
    required this.duration,
    required this.recognizedText,
    required this.confidence,
  });

  @override
  State<RecordingPreviewPage> createState() => _RecordingPreviewPageState();
}

class _RecordingPreviewPageState extends State<RecordingPreviewPage> {
  late TextEditingController _transcriptionController;
  late TextEditingController _tagsController;

  // Removed hardcoded colors. Using Theme.of(context) instead.

  @override
  void initState() {
    super.initState();
    _transcriptionController =
        TextEditingController(text: widget.recognizedText);
    // 初始化标签控制器，根据内容自动生成初始标签
    _tagsController = TextEditingController(text: _generateInitialTags());
  }

  /// 根据内容生成初始标签字符串
  String _generateInitialTags() {
    final content = widget.recognizedText.trim();
    if (content.isEmpty) return '';

    final tags = <String>[];
    if (content.contains('童年') || content.contains('小时候')) tags.add('童年');
    if (content.contains('家') ||
        content.contains('父母') ||
        content.contains('爸') ||
        content.contains('妈')) {
      tags.add('家庭');
    }
    if (content.contains('工作') || content.contains('公司')) tags.add('工作');
    if (content.contains('朋友') || content.contains('同学')) tags.add('社交');

    return tags.join('、');
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// 根据内容自动生成标题
  String _generateTitle() {
    final content = _transcriptionController.text.trim();
    if (content.isEmpty) {
      final now = DateTime.now();
      return '录音 ${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    }
    // 取前20个字符作为标题
    if (content.length <= 20) {
      return content;
    }
    return '${content.substring(0, 20)}...';
  }

  /// 解析用户输入的标签
  List<String> _parseTags() {
    final tagsText = _tagsController.text.trim();
    if (tagsText.isEmpty) return [];

    // 支持中文顿号、逗号、空格分隔
    return tagsText
        .split(RegExp(r'[、,，\s]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void _saveRecording() {
    print('PreviewPage: _saveRecording called');
    final title = _generateTitle();
    final tags = _parseTags();

    final voiceRecord = VoiceRecord(
      id: const Uuid().v4(),
      title: title,
      audioFilePath: widget.filePath,
      duration: widget.duration,
      timestamp: DateTime.now(),
      transcription: _transcriptionController.text.trim().isNotEmpty
          ? _transcriptionController.text.trim()
          : null,
      confidence: widget.confidence > 0 ? widget.confidence : null,
      content: _transcriptionController.text.trim(),
      tags: tags,
    );

    print(
        'PreviewPage: Created record: ${voiceRecord.id}, title: ${voiceRecord.title}');

    // 保存录音
    context.read<VoiceRecordBloc>().add(AddVoiceRecord(voiceRecord));

    // 重置录音状态
    context
        .read<IntegratedRecordingBloc>()
        .add(const CancelIntegratedRecording());

    // 显示成功提示并返回
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('录音已保存: $title'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  void _discardRecording() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // backgroundColor: Theme.of(context).cardColor, // Default
        title: Text('确认删除', style: Theme.of(context).textTheme.titleLarge),
        content: Text('确定要删除这条录音吗？此操作不可恢复。',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 重置录音状态
              context
                  .read<IntegratedRecordingBloc>()
                  .add(const CancelIntegratedRecording());
              Navigator.of(dialogContext).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回
            },
            child: Text('删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Helper accessors for readibility
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final hintColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
            Colors.grey;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _discardRecording();
      },
      child: Scaffold(
        // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Default
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            '编辑录音',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
            onPressed: _discardRecording,
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 转写文本编辑区
                    Text(
                      '转写内容',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _transcriptionController,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6),
                        decoration: InputDecoration(
                          hintText: '点击编辑转写内容...',
                          hintStyle:
                              TextStyle(color: hintColor.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: null,
                        minLines: 10,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 标签编辑区
                    Text(
                      '标签',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _tagsController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: '输入标签，用顿号或逗号分隔...',
                          hintStyle:
                              TextStyle(color: hintColor.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(Icons.label_outline,
                              color: primaryColor, size: 20),
                        ),
                        maxLines: 1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 提示信息
                    Text(
                      '标题将根据内容自动生成',
                      style: TextStyle(
                        color: hintColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部按钮区
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  // 删除按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _discardRecording,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .disabledColor
                              .withOpacity(0.2), // Lighter for cancel
                          borderRadius: BorderRadius.circular(25),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: Text(
                            '删除',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 保存按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveRecording,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            '保存',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
