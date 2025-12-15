import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../bloc/voice_record/voice_record_bloc.dart';
import '../bloc/voice_record/voice_record_event.dart';
import '../bloc/integrated_recording/integrated_recording_bloc.dart';
import '../bloc/integrated_recording/integrated_recording_event.dart';
import '../../domain/entities/voice_record.dart';

/// 录音预览和编辑页面（深色主题风格）
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

  // 深色主题颜色（与首页保持一致）
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _saveButtonColor = Color(0xFF4CAF50);
  static const Color _cancelButtonColor = Color(0xFF424242);
  static const Color _textColor = Colors.white;
  static const Color _hintColor = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _transcriptionController = TextEditingController(text: widget.recognizedText);
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
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

  /// 根据内容自动生成标签（简单实现：提取关键词）
  List<String> _generateTags() {
    final content = _transcriptionController.text.trim();
    if (content.isEmpty) return [];
    
    // 简单实现：如果内容包含某些关键词，添加相应标签
    final tags = <String>[];
    if (content.contains('童年') || content.contains('小时候')) tags.add('童年');
    if (content.contains('家') || content.contains('父母') || content.contains('爸') || content.contains('妈')) tags.add('家庭');
    if (content.contains('工作') || content.contains('公司')) tags.add('工作');
    if (content.contains('朋友') || content.contains('同学')) tags.add('社交');
    
    return tags;
  }

  void _saveRecording() {
    print('PreviewPage: _saveRecording called');
    final title = _generateTitle();
    final tags = _generateTags();
    
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
    
    print('PreviewPage: Created record: ${voiceRecord.id}, title: ${voiceRecord.title}');

    // 保存录音
    context.read<VoiceRecordBloc>().add(AddVoiceRecord(voiceRecord));

    // 重置录音状态
    context.read<IntegratedRecordingBloc>().add(const CancelIntegratedRecording());

    // 显示成功提示并返回
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('录音已保存: $title'),
        backgroundColor: _saveButtonColor,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  void _discardRecording() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('确认删除', style: TextStyle(color: _textColor)),
        content: const Text('确定要删除这条录音吗？此操作不可恢复。', 
            style: TextStyle(color: _hintColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消', style: TextStyle(color: _hintColor)),
          ),
          TextButton(
            onPressed: () {
              // 重置录音状态
              context.read<IntegratedRecordingBloc>().add(const CancelIntegratedRecording());
              Navigator.of(dialogContext).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _discardRecording();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            '编辑录音',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: _textColor),
            onPressed: _discardRecording,
          ),
          actions: [
            TextButton(
              onPressed: _saveRecording,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: _saveButtonColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
                    const Text(
                      '转写内容',
                      style: TextStyle(
                        color: _hintColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _transcriptionController,
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: '点击编辑转写内容...',
                          hintStyle: TextStyle(color: _hintColor.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: null,
                        minLines: 10,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 自动生成信息提示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _hintColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: _saveButtonColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '标题和标签将根据内容自动生成',
                              style: TextStyle(
                                color: _hintColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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
                color: _backgroundColor,
                border: Border(
                  top: BorderSide(color: _hintColor.withOpacity(0.2)),
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
                          color: _cancelButtonColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            '删除',
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
                  
                  const SizedBox(width: 16),
                  
                  // 保存按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveRecording,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _saveButtonColor,
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
