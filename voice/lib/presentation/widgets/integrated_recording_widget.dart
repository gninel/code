import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/integrated_recording/integrated_recording_event.dart';
import 'package:voice_autobiography_flutter/domain/entities/recording_state.dart';
import 'package:voice_autobiography_flutter/presentation/pages/recording_preview_page.dart';
import 'package:file_picker/file_picker.dart';

class IntegratedRecordingWidget extends StatefulWidget {
  const IntegratedRecordingWidget({super.key});

  @override
  State<IntegratedRecordingWidget> createState() => _IntegratedRecordingWidgetState();
}

class _IntegratedRecordingWidgetState extends State<IntegratedRecordingWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSaving = false;

  // 深色主题颜色
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _recordButtonColor = Color(0xFFE53935);
  static const Color _saveButtonColor = Color(0xFF4CAF50);
  static const Color _cancelButtonColor = Color(0xFF424242);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final currentDuration = context.read<IntegratedRecordingBloc>().state.duration + 100;
      context
          .read<IntegratedRecordingBloc>()
          .add(UpdateRecordingDuration(currentDuration));
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IntegratedRecordingBloc, IntegratedRecordingState>(
      listener: (context, state) {
        // 只在实时录音模式下启动计时器和动画
        if (state.isRecording && !state.isFileUpload) {
          _startTimer();
          _pulseController.repeat();
        } else {
          _stopTimer();
          _pulseController.stop();
          _pulseController.reset();
        }

        if (state.status == RecordingStatus.completed && 
            state.filePath != null && 
            !_isSaving) {
          _navigateToPreview(context, state);
        }

        if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<IntegratedRecordingBloc, IntegratedRecordingState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              backgroundColor: _backgroundColor,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                '语音自传',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {
                    // 设置按钮
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                const Spacer(flex: 1),
                
                // 中央录音按钮
                _buildRecordingButton(state),
                
                const SizedBox(height: 16),
                
                // 提示文字
                Text(
                  state.isRecording ? '录音中...' : '点击开始录音',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // 录音时长
                Text(
                  _formatDuration(state.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextButton.icon(
                  onPressed: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['wav'],
                      );

                      if (result != null && result.files.single.path != null) {
                        if (context.mounted) {
                          context.read<IntegratedRecordingBloc>().add(
                            UploadRecordingFile(result.files.single.path!)
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('选择文件失败: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.white70),
                  label: const Text(
                    '上传录音',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // 实时转写区域
                _buildTranscriptionCard(state),
                
                const SizedBox(height: 24),
                
                // 底部按钮
                _buildBottomButtons(state),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingButton(IntegratedRecordingState state) {
    final isRecording = state.isRecording;
    
    return GestureDetector(
      onTap: () {
        if (state.canStart) {
          context.read<IntegratedRecordingBloc>().add(const StartIntegratedRecording());
        } else if (state.canPause) {
          context.read<IntegratedRecordingBloc>().add(const PauseIntegratedRecording());
        } else if (state.canResume) {
          context.read<IntegratedRecordingBloc>().add(const ResumeIntegratedRecording());
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _recordButtonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _recordButtonColor.withOpacity(0.4),
                    blurRadius: isRecording ? 30 : 20,
                    spreadRadius: isRecording ? 5 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isRecording ? Icons.pause : Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionCard(IntegratedRecordingState state) {
    return GestureDetector(
      onTap: () {
        if (state.recognizedText.isNotEmpty) {
          _showTranscriptionEditor(context, state.recognizedText);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '实时转写',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state.recognizedText.isNotEmpty)
                  const Icon(
                    Icons.edit,
                    color: Colors.white54,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.hasRecognizedText 
                  ? state.recognizedText 
                  : '等待录音开始后,这里将实时显示语音转写的文字内容...',
              style: TextStyle(
                color: state.hasRecognizedText ? Colors.white : Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showTranscriptionEditor(BuildContext context, String currentText) {
    final TextEditingController controller = TextEditingController(text: currentText);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Text(
                    '编辑转写内容',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<IntegratedRecordingBloc>().add(
                        UpdateRecognizedText(controller.text)
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '完成',
                      style: TextStyle(color: Color(0xFFE53935)),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white10),
            
            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '暂无内容...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(IntegratedRecordingState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 保存按钮
          Expanded(
            child: GestureDetector(
              onTap: state.canStop
                  ? () {
                      context.read<IntegratedRecordingBloc>().add(const StopIntegratedRecording());
                    }
                  : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: state.canStop ? _saveButtonColor : _saveButtonColor.withOpacity(0.3),
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
          
          const SizedBox(width: 16),
          
          // 取消按钮
          Expanded(
            child: GestureDetector(
              onTap: state.canStop
                  ? () {
                      context.read<IntegratedRecordingBloc>().add(const CancelIntegratedRecording());
                    }
                  : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: state.canStop ? _cancelButtonColor : _cancelButtonColor.withOpacity(0.3),
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
        ],
      ),
    );
  }

  void _navigateToPreview(BuildContext context, IntegratedRecordingState state) {
    if (_isSaving) return;
    _isSaving = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingPreviewPage(
          filePath: state.filePath!,
          duration: state.duration,
          recognizedText: state.recognizedText,
          confidence: state.confidence,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        final currentState = context.read<IntegratedRecordingBloc>().state;
        if (currentState.status == RecordingStatus.completed) {
          context.read<IntegratedRecordingBloc>().add(const CancelIntegratedRecording());
        }
      }
    });
  }
}