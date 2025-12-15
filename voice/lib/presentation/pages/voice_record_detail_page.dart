import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/voice_record.dart';
import '../bloc/voice_record/voice_record_bloc.dart';
import '../bloc/voice_record/voice_record_event.dart';

/// 录音记录详情页（深色主题风格）
class VoiceRecordDetailPage extends StatefulWidget {
  final VoiceRecord record;

  const VoiceRecordDetailPage({super.key, required this.record});

  @override
  State<VoiceRecordDetailPage> createState() => _VoiceRecordDetailPageState();
}

class _VoiceRecordDetailPageState extends State<VoiceRecordDetailPage> {
  late TextEditingController _transcriptionController;
  bool _isEditing = false;
  
  // 深色主题颜色（与首页保持一致）
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _saveButtonColor = Color(0xFF4CAF50);
  static const Color _cancelButtonColor = Color(0xFF424242);
  static const Color _textColor = Colors.white;
  static const Color _hintColor = Color(0xFF888888);
  
  // Audio Player
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _transcriptionController = TextEditingController(text: widget.record.transcription ?? '');
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    try {
      final filePath = widget.record.audioFilePath;
      if (filePath != null) {
        await _audioPlayer.setFilePath(filePath);
        _duration = _audioPlayer.duration ?? Duration.zero;
      }
      
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _position = Duration.zero;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 根据内容自动生成标题
  String _generateTitle() {
    final content = _transcriptionController.text.trim();
    if (content.isEmpty) {
      return widget.record.title;
    }
    if (content.length <= 20) {
      return content;
    }
    return '${content.substring(0, 20)}...';
  }

  /// 根据内容自动生成标签
  List<String> _generateTags() {
    final content = _transcriptionController.text.trim();
    if (content.isEmpty) return widget.record.tags;
    
    final tags = <String>[];
    if (content.contains('童年') || content.contains('小时候')) tags.add('童年');
    if (content.contains('家') || content.contains('父母') || content.contains('爸') || content.contains('妈')) tags.add('家庭');
    if (content.contains('工作') || content.contains('公司')) tags.add('工作');
    if (content.contains('朋友') || content.contains('同学')) tags.add('社交');
    
    return tags.isEmpty ? widget.record.tags : tags;
  }

  void _saveChanges() {
    final updatedRecord = widget.record.copyWith(
      title: _generateTitle(),
      transcription: _transcriptionController.text.trim(),
      tags: _generateTags(),
    );

    context.read<VoiceRecordBloc>().add(UpdateVoiceRecord(updatedRecord));

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('记录已更新'),
        backgroundColor: _saveButtonColor,
      ),
    );
  }

  void _deleteRecord() {
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
              context.read<VoiceRecordBloc>().add(DeleteVoiceRecord(widget.record.id));
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditing ? '编辑记录' : '记录详情',
          style: const TextStyle(
            color: _textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: _saveButtonColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit, color: _textColor),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteRecord,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 音频播放器
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // 时间信息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: _hintColor),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(widget.record.timestamp),
                          style: const TextStyle(color: _hintColor, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: _hintColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(Duration(milliseconds: widget.record.duration)),
                          style: const TextStyle(color: _hintColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 播放控制
                Row(
                  children: [
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _saveButtonColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _saveButtonColor,
                              inactiveTrackColor: _hintColor.withOpacity(0.3),
                              thumbColor: _saveButtonColor,
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                              min: 0.0,
                              max: _duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(fontSize: 11, color: _hintColor),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(fontSize: 11, color: _hintColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 标签显示
          if (widget.record.tags.isNotEmpty && !_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: widget.record.tags.map((tag) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _saveButtonColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: _saveButtonColor, fontSize: 12),
                  ),
                )).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 转写内容区
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '转写内容',
                    style: TextStyle(color: _hintColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isEditing
                        ? TextField(
                            controller: _transcriptionController,
                            style: const TextStyle(
                              color: _textColor,
                              fontSize: 16,
                              height: 1.6,
                            ),
                            decoration: InputDecoration(
                              hintText: '编辑转写内容...',
                              hintStyle: TextStyle(color: _hintColor.withOpacity(0.5)),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                          )
                        : SingleChildScrollView(
                            child: Text(
                              widget.record.transcription?.isNotEmpty == true
                                  ? widget.record.transcription!
                                  : '无转写内容',
                              style: const TextStyle(
                                color: _textColor,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // 底部按钮（编辑模式）
          if (_isEditing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border(
                  top: BorderSide(color: _hintColor.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isEditing = false;
                        _transcriptionController.text = widget.record.transcription ?? '';
                      }),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _cancelButtonColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            '取消',
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
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveChanges,
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
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
