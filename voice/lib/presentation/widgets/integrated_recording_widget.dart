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
  State<IntegratedRecordingWidget> createState() =>
      _IntegratedRecordingWidgetState();
}

class _IntegratedRecordingWidgetState extends State<IntegratedRecordingWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSaving = false;

  // 移除硬编码的深色主题颜色，使用 AppTheme 中定义的颜色
  // static const Color _backgroundColor = Color(0xFF121212);
  // static const Color _recordButtonColor = Color(0xFFE53935);
  // static const Color _saveButtonColor = Color(0xFF4CAF50);
  // static const Color _cancelButtonColor = Color(0xFF424242);

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
      final currentDuration =
          context.read<IntegratedRecordingBloc>().state.duration + 100;
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
            // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Default
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0, // 隐藏AppBar，只保留状态栏空间
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 实时转写区域（移到录音区域上方）
                  _buildTranscriptionBox(state),

                  const SizedBox(height: 16),

                  // 录音区域容器
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // 中央录音按钮
                    _buildRecordingButton(state),

                    const SizedBox(height: 8),

                    // 提示文字
                    Text(
                      state.isRecording
                          ? (state.isFileUpload ? '上传录音识别中...' : '录音中...')
                          : '点击开始录音',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 录音时长（弱化显示）
                    Text(
                      _formatDuration(state.duration),
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'wav',
                              'mp3',
                              'm4a',
                              'aac',
                              'flac'
                            ],
                          );

                          if (result != null &&
                              result.files.single.path != null) {
                            if (context.mounted) {
                              context.read<IntegratedRecordingBloc>().add(
                                  UploadRecordingFile(
                                      result.files.single.path!));
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
                      icon: Icon(Icons.upload_file,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                          size: 20),
                      label: Text(
                        '上传录音',
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 底部按钮
                _buildBottomButtons(state),

                const SizedBox(height: 32),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  /// 构建实时转写内容框（与AI采访样式一致，但高度支持6行文字）
  Widget _buildTranscriptionBox(IntegratedRecordingState state) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 150,
        maxHeight: 180,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '实时转写',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (state.hasRecognizedText) ...[
                const Spacer(),
                Text(
                  state.confidencePercentage,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: GestureDetector(
                onTap: () {
                  if (state.recognizedText.isNotEmpty) {
                    _showTranscriptionEditor(context, state.recognizedText);
                  }
                },
                child: Text(
                  state.hasRecognizedText
                      ? state.recognizedText
                      : '开始录音后，这里将实时显示语音识别的文字内容...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: state.hasRecognizedText
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.4),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(IntegratedRecordingState state) {
    final isRecording = state.isRecording;
    // 使用主题中的强调色，或者保留红色但调整为更复古的红色
    const buttonColor = Color(0xFFD32F2F); // 保持红色，作为强调

    return GestureDetector(
      onTap: () {
        if (state.canStart) {
          context
              .read<IntegratedRecordingBloc>()
              .add(const StartIntegratedRecording());
        } else if (state.canPause) {
          context
              .read<IntegratedRecordingBloc>()
              .add(const PauseIntegratedRecording());
        } else if (state.canResume) {
          context
              .read<IntegratedRecordingBloc>()
              .add(const ResumeIntegratedRecording());
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 56, // 从70缩小到56
              height: 56,
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3), // 降低阴影透明度
                    blurRadius: isRecording ? 20 : 15, // 减小模糊半径
                    spreadRadius: isRecording ? 3 : 0, // 减小扩散范围
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isRecording ? Icons.pause : Icons.mic,
                  color: Colors.white,
                  size: 20, // 从24缩小到20
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
      child: Card(
        // 使用 Card+主题样式替换原来的 Container
        elevation: 2,
        // color: 已经在 Theme 中定义了 cardTheme.color (0xFFFBF8F1)
        margin: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '实时转写',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (state.recognizedText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.5),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text('编辑',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5),
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    state.hasRecognizedText
                        ? state.recognizedText
                        : '等待录音开始后,这里将实时显示语音转写的文字内容...',
                    style: TextStyle(
                      color: state.hasRecognizedText
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColor.withOpacity(0.4),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTranscriptionEditor(BuildContext context, String currentText) {
    final TextEditingController controller =
        TextEditingController(text: currentText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 使用复古背景
          borderRadius: const BorderRadius.only(
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
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
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
                    child: Text(
                      '取消',
                      style: TextStyle(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.5)),
                    ),
                  ),
                  Text(
                    '编辑转写内容',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context
                          .read<IntegratedRecordingBloc>()
                          .add(UpdateRecognizedText(controller.text));
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '完成',
                      style: TextStyle(color: Color(0xFFD32F2F)),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Theme.of(context).dividerColor),

            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintText: '暂无内容...',
                    hintStyle: TextStyle(
                        color: Theme.of(context).primaryColor.withOpacity(0.3)),
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
          // 保存按钮 - 2/3大小 (约33px高度)
          Expanded(
            child: ElevatedButton(
              onPressed: state.canStop
                  ? () {
                      context
                          .read<IntegratedRecordingBloc>()
                          .add(const StopIntegratedRecording());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10), // 减小padding达到2/3高度
                textStyle: const TextStyle(fontSize: 15),
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF388E3C).withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
              ),
              child: const Text('保存'),
            ),
          ),

          const SizedBox(width: 16),

          // 取消按钮 - 2/3大小
          Expanded(
            child: OutlinedButton(
              onPressed: state.canStop
                  ? () {
                      context
                          .read<IntegratedRecordingBloc>()
                          .add(const CancelIntegratedRecording());
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10), // 减小padding达到2/3高度
                textStyle: const TextStyle(fontSize: 15),
              ),
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPreview(
      BuildContext context, IntegratedRecordingState state) {
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
          context
              .read<IntegratedRecordingBloc>()
              .add(const CancelIntegratedRecording());
        }
      }
    });
  }
}
