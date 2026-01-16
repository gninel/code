import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/interview/interview_bloc.dart';
import '../bloc/interview/interview_event.dart';
import '../bloc/interview/interview_state.dart';
import '../bloc/integrated_recording/integrated_recording_bloc.dart';
import '../bloc/integrated_recording/integrated_recording_event.dart';
import '../bloc/integrated_recording/integrated_recording_state.dart';
import '../../../../domain/entities/recording_state.dart';

class InterviewWidget extends StatefulWidget {
  const InterviewWidget({super.key});

  @override
  State<InterviewWidget> createState() => _InterviewWidgetState();
}

class _InterviewWidgetState extends State<InterviewWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    _pulseController.forward();
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
      listener: (context, recordingState) {
        if (recordingState.isRecording) {
          _startTimer();
          _pulseController.repeat();
        } else {
          _stopTimer();
          _pulseController.stop();
          _pulseController.reset();
        }

        // 当录音完成时，保存回答
        print(
            '[InterviewWidget] Recording state changed: status=${recordingState.status}, filePath=${recordingState.filePath}, recognizedText=${recordingState.recognizedText}');

        if (recordingState.status == RecordingStatus.completed &&
            recordingState.filePath != null) {
          print(
              '[InterviewWidget] Calling _saveAnswer with recognized text: ${recordingState.recognizedText}');
          _saveAnswer(recordingState);
        } else {
          print(
              '[InterviewWidget] Not saving: status=${recordingState.status}, hasFilePath=${recordingState.filePath != null}');
        }

        if (recordingState.hasError && recordingState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(recordingState.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<InterviewBloc, InterviewState>(
        buildWhen: (previous, current) {
          // 强制在以下情况重建UI：
          // 1. 状态变化
          // 2. 会话对象引用变化
          // 3. 当前问题索引变化
          // 4. 问题列表长度变化
          final shouldRebuild = previous.status != current.status ||
              previous.currentSession != current.currentSession ||
              previous.currentSession?.currentQuestionIndex !=
                  current.currentSession?.currentQuestionIndex ||
              previous.currentSession?.questions.length !=
                  current.currentSession?.questions.length;

          if (shouldRebuild) {
            print('[InterviewWidget] BlocBuilder will rebuild:');
            print(
                '  - Status changed: ${previous.status} -> ${current.status}');
            print(
                '  - Session changed: ${previous.currentSession?.id} -> ${current.currentSession?.id}');
            print(
                '  - Index changed: ${previous.currentSession?.currentQuestionIndex} -> ${current.currentSession?.currentQuestionIndex}');
            print(
                '  - Questions count changed: ${previous.currentSession?.questions.length} -> ${current.currentSession?.questions.length}');
          }

          return shouldRebuild;
        },
        builder: (context, state) {
          print(
              '[InterviewWidget] Building UI with question: ${state.currentQuestion?.substring(0, state.currentQuestion!.length > 30 ? 30 : state.currentQuestion!.length)}...');
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0, // 隐藏AppBar，去掉右上角叉
            ),
            body: SafeArea(
              child: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, InterviewState state) {
    if (state.status == InterviewStatus.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载...'),
          ],
        ),
      );
    }

    if (state.status == InterviewStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.errorMessage ?? '发生错误',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<InterviewBloc>().add(const ClearCurrentSession());
              },
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }

    if (!state.hasActiveSession) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.question_answer_outlined,
                size: 64, // 从80缩小
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16), // 从24缩小
              Text(
                'AI将作为自传作家，引导您回忆和讲述人生经历。\n请用语音回答问题。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<InterviewBloc>()
                      .add(const StartInterviewSession());
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始采访'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 活跃会话布局
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // 问题显示区域
                  _buildQuestionCard(context, state),

                  const SizedBox(height: 12),

                  // 实时转写内容框（放在AI问题下方，录音模块上方）
                  _buildTranscriptionBox(context, state),

                  const SizedBox(height: 6), // 从12减少到6，高度减半

                  // 录音控制区域
                  _buildRecordingArea(context, state),

                  const SizedBox(height: 8), // 从16减少到8，高度减半

                  // 操作按钮
                  _buildActionButtons(context, state),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, InterviewState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '采访进度',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '${state.answeredCount}/${state.totalQuestions}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 6,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, InterviewState state) {
    if (state.status == InterviewStatus.saving ||
        state.status == InterviewStatus.generating) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在保存并生成下一个问题...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // 从8减少到4，高度减半
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6), // 从8减少到6
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).primaryColor,
                  size: 16, // 从20减少到16
                ),
              ),
              const SizedBox(width: 8), // 从12减少到8
              Text(
                'AI问题',
                style: Theme.of(context).textTheme.labelMedium?.copyWith( // 从labelLarge改为labelMedium
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8), // 从12减少到8
          Text(
            state.currentQuestion ?? '',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  // 从titleLarge改为labelLarge，与"AI问题"标题字号一致
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingArea(BuildContext context, InterviewState state) {
    final recordingState = context.watch<IntegratedRecordingBloc>().state;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // 录音按钮
          GestureDetector(
            onTap: () {
              if (recordingState.canStart) {
                context
                    .read<IntegratedRecordingBloc>()
                    .add(const StartIntegratedRecording());
              } else if (recordingState.canPause) {
                context
                    .read<IntegratedRecordingBloc>()
                    .add(const PauseIntegratedRecording());
              } else if (recordingState.canResume) {
                context
                    .read<IntegratedRecordingBloc>()
                    .add(const ResumeIntegratedRecording());
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final isRecording = recordingState.isRecording;
                return Transform.scale(
                  scale: isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 56, // 从80统一到56，与自主录音一致
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F), // 统一使用红色
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F)
                              .withValues(alpha: 0.3), // 统一阴影透明度
                          blurRadius: isRecording ? 20 : 15, // 统一模糊半径
                          spreadRadius: isRecording ? 3 : 0, // 统一扩散范围
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isRecording ? Icons.pause : Icons.mic,
                        color: Colors.white,
                        size: 20, // 从32统一到20，与自主录音一致
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Text(
            recordingState.isRecording ? '录音中...' : '点击开始录音回答',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // 录音时长
          Text(
            _formatDuration(recordingState.duration),
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建实时转写内容框
  Widget _buildTranscriptionBox(BuildContext context, InterviewState state) {
    final recordingState = context.watch<IntegratedRecordingBloc>().state;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 110,
        maxHeight: 130,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
              if (recordingState.hasRecognizedText) ...[
                const Spacer(),
                Text(
                  recordingState.confidencePercentage,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                recordingState.hasRecognizedText
                    ? recordingState.recognizedText
                    : '开始录音后，这里将实时显示语音识别的文字内容...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: recordingState.hasRecognizedText
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.4),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, InterviewState state) {
    final recordingState = context.watch<IntegratedRecordingBloc>().state;

    return Row(
      children: [
        // 跳过按钮 - 与自主录音按钮保持一致的样式
        Expanded(
          child: OutlinedButton.icon(
            onPressed: recordingState.canStart
                ? () {
                    context.read<InterviewBloc>().add(const SkipQuestion());
                  }
                : null,
            icon: const Icon(Icons.skip_next, size: 18),
            label: const Text('跳过此问题'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10), // 从14减少到10，与自主录音按钮一致
              textStyle: const TextStyle(fontSize: 15),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 完成回答按钮 - 与自主录音保存按钮保持一致的样式
        Expanded(
          child: ElevatedButton.icon(
            onPressed: recordingState.canStop
                ? () {
                    context
                        .read<IntegratedRecordingBloc>()
                        .add(const StopIntegratedRecording());
                  }
                : null,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('完成回答'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10), // 从14减少到10，与自主录音按钮一致
              textStyle: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  void _saveAnswer(IntegratedRecordingState recordingState) {
    final recognizedText = recordingState.recognizedText;
    final filePath = recordingState.filePath;
    final duration = recordingState.duration;

    print('[InterviewWidget] _saveAnswer called:');
    print('  - recognizedText: $recognizedText');
    print('  - filePath: $filePath');
    print('  - duration: $duration ms');
    print('  - confidence: ${recordingState.confidence}');

    final answerText = recognizedText.isNotEmpty ? recognizedText : '（语音回答）';
    print(
        '[InterviewWidget] Sending AnswerQuestion event with text: $answerText');

    // 保存回答到采访会话
    context.read<InterviewBloc>().add(AnswerQuestion(
          answerText: answerText,
          audioFilePath: filePath,
          duration: duration,
        ));

    // 重置录音状态
    context
        .read<IntegratedRecordingBloc>()
        .add(const CancelIntegratedRecording());

    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '回答已保存: ${answerText.length > 20 ? '${answerText.substring(0, 20)}...' : answerText}'),
        duration: const Duration(seconds: 2),
      ),
    );

    print('[InterviewWidget] Answer saved and snackbar shown');
  }

  void _showEndSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束采访'),
        content: const Text('确定要结束本次采访吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InterviewBloc>().add(const EndInterviewSession());
            },
            child: const Text('结束'),
          ),
        ],
      ),
    );
  }
}
