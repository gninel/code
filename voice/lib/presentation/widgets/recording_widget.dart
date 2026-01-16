import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_event.dart';
import 'package:voice_autobiography_flutter/domain/entities/recording_state.dart';

class RecordingWidget extends StatefulWidget {
  const RecordingWidget({super.key});

  @override
  State<RecordingWidget> createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget>
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
      end: 1.2,
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
      final currentDuration = context.read<RecordingBloc>().state.duration + 100;
      context
          .read<RecordingBloc>()
          .add(UpdateRecordingDuration(currentDuration));
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _startPulseAnimation() {
    _pulseController.repeat();
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingBloc, RecordingState>(
      listener: (context, state) {
        if (state.isRecording) {
          _startTimer();
          _startPulseAnimation();
        } else {
          _stopTimer();
          _stopPulseAnimation();
        }

        // 显示错误消息
        if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<RecordingBloc, RecordingState>(
        builder: (context, state) {
          return Column(
            children: [
              const SizedBox(height: 32),
              // 录音状态指示器
              _buildRecordingIndicator(state),
              const SizedBox(height: 48),
              // 录音时长显示
              _buildDurationDisplay(state),
              const SizedBox(height: 48),
              // 录音控制按钮
              _buildRecordingControls(state),
              const SizedBox(height: 32),
              // 提示信息
              _buildRecordingTip(state),
              // 错误消息
              if (state.hasError)
                _buildErrorMessage(
                  context,
                  state.errorMessage!,
                  () {
                    context.read<RecordingBloc>().add(const CancelRecording());
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingIndicator(RecordingState state) {
    final color = _getStatusColor(state.status);
    final description = state.status.displayName;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: state.isRecording ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(state.status),
                  size: 60,
                  color: color,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDisplay(RecordingState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '录音时长',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.formattedDuration,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls(RecordingState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 开始/恢复录音按钮
        if (state.canStart)
          FloatingActionButton(
            heroTag: "start_recording",
            onPressed: () {
              context.read<RecordingBloc>().add(const StartRecording());
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.mic),
          ),

        // 暂停录音按钮
        if (state.canPause)
          FloatingActionButton(
            heroTag: "pause_recording",
            onPressed: () {
              context.read<RecordingBloc>().add(const PauseRecording());
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.pause),
          ),

        // 停止录音按钮
        if (state.canStop)
          FloatingActionButton(
            heroTag: "stop_recording",
            onPressed: () {
              context.read<RecordingBloc>().add(const StopRecording());
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop),
          ),

        // 取消录音按钮
        if (state.canCancel && !state.isCompleted)
          FloatingActionButton(
            heroTag: "cancel_recording",
            onPressed: () {
              context.read<RecordingBloc>().add(const CancelRecording());
            },
            backgroundColor: Colors.grey,
            child: const Icon(Icons.close),
          ),
      ],
    );
  }

  Widget _buildRecordingTip(RecordingState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.status.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(
    BuildContext context,
    String message,
    VoidCallback onDismiss,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.idle:
        return Colors.grey;
      case RecordingStatus.recording:
        return Colors.red;
      case RecordingStatus.paused:
        return Colors.orange;
      case RecordingStatus.processing:
        return Colors.blue;
      case RecordingStatus.completed:
        return Colors.green;
      case RecordingStatus.error:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.idle:
      case RecordingStatus.paused:
        return Icons.mic;
      case RecordingStatus.recording:
        return Icons.mic;
      case RecordingStatus.processing:
        return Icons.hourglass_empty;
      case RecordingStatus.completed:
        return Icons.check_circle;
      case RecordingStatus.error:
        return Icons.error;
    }
  }
}