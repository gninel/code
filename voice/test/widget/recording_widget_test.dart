import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:voice_autobiography_flutter/domain/entities/recording_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_state.dart';
import 'package:voice_autobiography_flutter/presentation/widgets/recording_widget.dart';

class MockRecordingBloc extends Mock implements RecordingBloc {}

void main() {
  group('RecordingWidget Tests', () {
    late MockRecordingBloc mockRecordingBloc;

    setUp(() {
      mockRecordingBloc = MockRecordingBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<RecordingBloc>.value(
          value: mockRecordingBloc,
          child: const Scaffold(
            body: RecordingWidget(),
          ),
        ),
      );
    }

    testWidgets('初始状态显示麦克风图标', (WidgetTester tester) async {
      // 设置初始状态
      whenListen(
        mockRecordingBloc,
        Stream.value(const RecordingState()),
        initialState: const RecordingState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // 验证麦克风图标存在
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('准备录音'), findsOneWidget);
    });

    testWidgets('录音状态显示录音图标和时长', (WidgetTester tester) async {
      // 设置录音状态
      const recordingState = RecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
      );

      whenListen(
        mockRecordingBloc,
        Stream.value(recordingState),
        initialState: recordingState,
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // 验证录音状态显示
      expect(find.text('正在录音'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('显示错误消息', (WidgetTester tester) async {
      // 设置错误状态
      const errorState = RecordingState(
        status: RecordingStatus.error,
        errorMessage: '录音失败',
      );

      whenListen(
        mockRecordingBloc,
        Stream.value(errorState),
        initialState: errorState,
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // 验证错误消息显示
      expect(find.text('录音失败'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('点击开始录音按钮', (WidgetTester tester) async {
      // 设置初始状态
      whenListen(
        mockRecordingBloc,
        Stream.value(const RecordingState()),
        initialState: const RecordingState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // 查找并点击开始录音按钮
      final startButton = find.byIcon(Icons.mic);
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pump();

      // 验证事件被触发
      verify(mockRecordingBloc.add(const StartRecording())).called(1);
    });

    testWidgets('显示录音时长格式正确', (WidgetTester tester) async {
      // 测试不同的时长格式
      const recordingStates = [
        RecordingState(
            status: RecordingStatus.recording, duration: 500), // 0.5秒
        RecordingState(status: RecordingStatus.recording, duration: 5000), // 5秒
        RecordingState(
            status: RecordingStatus.recording, duration: 65000), // 1分5秒
        RecordingState(
            status: RecordingStatus.recording, duration: 3665000), // 1小时1分5秒
      ];

      whenListen(
        mockRecordingBloc,
        Stream.fromIterable(recordingStates),
        initialState: recordingStates.first,
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // 验证时长格式
      await tester.pump();
      expect(find.text('0'), findsOneWidget); // 0.5秒显示为0

      await tester.pump();
      expect(find.text('5'), findsOneWidget); // 5秒

      await tester.pump();
      expect(find.text('1:05'), findsOneWidget); // 1分5秒

      await tester.pump();
      expect(find.text('1:01:05'), findsOneWidget); // 1小时1分5秒
    });

    testWidgets('录音状态改变时按钮状态改变', (WidgetTester tester) async {
      // 状态序列：idle -> recording -> stopped
      final states = [
        const RecordingState(status: RecordingStatus.idle),
        const RecordingState(status: RecordingStatus.recording),
        const RecordingState(status: RecordingStatus.completed),
      ];

      whenListen(
        mockRecordingBloc,
        Stream.fromIterable(states),
        initialState: states.first,
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // 初始状态显示开始录音按钮
      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.pump();
      // 录音状态显示暂停和停止按钮
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.pump();
      // 完成状态不显示控制按钮（或显示特定按钮）
    });
  });
}
