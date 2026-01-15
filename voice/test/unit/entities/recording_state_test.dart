// Recording State 测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/domain/entities/recording_state.dart';

void main() {
  group('RecordingState', () {
    test('初始状态应该是 idle', () {
      const state = RecordingState();
      expect(state.status, RecordingStatus.idle);
      expect(state.duration, 0);
      expect(state.filePath, isNull);
      expect(state.errorMessage, isNull);
    });

    test('copyWith 应该正确复制并修改属性', () {
      const state = RecordingState();
      final updated = state.copyWith(
        status: RecordingStatus.recording,
        filePath: '/path/to/file.mp3',
        duration: 5000,
      );

      expect(updated.status, RecordingStatus.recording);
      expect(updated.filePath, '/path/to/file.mp3');
      expect(updated.duration, 5000);
    });

    test('isRecording 应该正确判断录音状态', () {
      const idle = RecordingState();
      expect(idle.isRecording, isFalse);

      const recording = RecordingState(status: RecordingStatus.recording);
      expect(recording.isRecording, isTrue);
    });

    test('isPaused 应该正确判断暂停状态', () {
      const paused = RecordingState(status: RecordingStatus.paused);
      expect(paused.isPaused, isTrue);
    });

    test('isProcessing 应该正确判断处理状态', () {
      const processing = RecordingState(status: RecordingStatus.processing);
      expect(processing.isProcessing, isTrue);
    });

    test('isCompleted 应该正确判断完成状态', () {
      const completed = RecordingState(status: RecordingStatus.completed);
      expect(completed.isCompleted, isTrue);
    });

    test('hasError 应该正确判断错误状态', () {
      const error = RecordingState(status: RecordingStatus.error);
      expect(error.hasError, isTrue);
    });

    test('canStart 应该正确判断可开始状态', () {
      const idle = RecordingState();
      expect(idle.canStart, isTrue);

      const error = RecordingState(status: RecordingStatus.error);
      expect(error.canStart, isTrue);

      const recording = RecordingState(status: RecordingStatus.recording);
      expect(recording.canStart, isFalse);
    });

    test('canStop 应该正确判断可停止状态', () {
      const recording = RecordingState(status: RecordingStatus.recording);
      expect(recording.canStop, isTrue);

      const paused = RecordingState(status: RecordingStatus.paused);
      expect(paused.canStop, isTrue);

      const idle = RecordingState();
      expect(idle.canStop, isFalse);
    });

    test('canPause 应该正确判断可暂停状态', () {
      const shortRecording =
          RecordingState(status: RecordingStatus.recording, duration: 500);
      expect(shortRecording.canPause, isFalse); // 时长不足1秒

      const longRecording =
          RecordingState(status: RecordingStatus.recording, duration: 1000);
      expect(longRecording.canPause, isTrue);
    });

    test('canResume 应该正确判断可恢复状态', () {
      const paused = RecordingState(status: RecordingStatus.paused);
      expect(paused.canResume, isTrue);

      const recording = RecordingState(status: RecordingStatus.recording);
      expect(recording.canResume, isFalse);
    });

    test('canCancel 应该正确判断可取消状态', () {
      const recording = RecordingState(status: RecordingStatus.recording);
      expect(recording.canCancel, isTrue);

      const paused = RecordingState(status: RecordingStatus.paused);
      expect(paused.canCancel, isTrue);

      const processing = RecordingState(status: RecordingStatus.processing);
      expect(processing.canCancel, isTrue);

      const idle = RecordingState();
      expect(idle.canCancel, isFalse);
    });

    test('formattedDuration 应该正确格式化时长', () {
      // 30秒
      const short = RecordingState(duration: 30000);
      expect(short.formattedDuration, '30');

      // 2分5秒
      const medium = RecordingState(duration: 125000);
      expect(medium.formattedDuration, '2:05');

      // 1小时2分5秒
      const long = RecordingState(duration: 3725000);
      expect(long.formattedDuration, '1:02:05');
    });
  });

  group('RecordingStatus', () {
    test('displayName 应该返回正确的中文名称', () {
      expect(RecordingStatus.idle.displayName, '空闲');
      expect(RecordingStatus.processing.displayName, '处理中');
      expect(RecordingStatus.recording.displayName, '录音中');
      expect(RecordingStatus.paused.displayName, '已暂停');
      expect(RecordingStatus.completed.displayName, '已完成');
      expect(RecordingStatus.error.displayName, '错误');
    });

    test('description 应该返回正确的描述', () {
      expect(RecordingStatus.idle.description, '准备录音');
      expect(RecordingStatus.recording.description, '正在录音');
      expect(RecordingStatus.completed.description, '录音完成');
    });

    test('colorValue 应该返回正确的颜色值', () {
      expect(RecordingStatus.idle.colorValue, 0xFF9E9E9E);
      expect(RecordingStatus.recording.colorValue, 0xFF4CAF50);
      expect(RecordingStatus.error.colorValue, 0xFFF44336);
    });

    test('iconName 应该返回正确的图标名', () {
      expect(RecordingStatus.idle.iconName, 'mic_none');
      expect(RecordingStatus.recording.iconName, 'mic');
      expect(RecordingStatus.paused.iconName, 'pause');
      expect(RecordingStatus.error.iconName, 'error');
    });
  });
}
