import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_autobiography_flutter/presentation/widgets/recording_widget.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/recording/recording_state.dart';

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
          child: const RecordingWidget(),
        ),
      );
    }

    testWidgets('should display recording widget with initial state',
        (WidgetTester tester) async {
      // Arrange
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(const RecordingState()));
      when(mockRecordingBloc.state).thenReturn(const RecordingState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('录音'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('should show recording button when idle',
        (WidgetTester tester) async {
      // Arrange
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(const RecordingState()));
      when(mockRecordingBloc.state).thenReturn(const RecordingState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should show recording indicator when recording',
        (WidgetTester tester) async {
      // Arrange
      const recordingState = RecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
      );
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(recordingState));
      when(mockRecordingBloc.state).thenReturn(recordingState);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display duration when recording',
        (WidgetTester tester) async {
      // Arrange
      const recordingState = RecordingState(
        status: RecordingStatus.recording,
        duration: 65000, // 1分5秒
      );
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(recordingState));
      when(mockRecordingBloc.state).thenReturn(recordingState);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('1:05'), findsOneWidget);
    });

    testWidgets('should add StartRecording event when button pressed',
        (WidgetTester tester) async {
      // Arrange
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(const RecordingState()));
      when(mockRecordingBloc.state).thenReturn(const RecordingState());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Assert
      verify(mockRecordingBloc.add(const StartRecording())).called(1);
    });

    testWidgets('should show error message when recording fails',
        (WidgetTester tester) async {
      // Arrange
      const errorState = RecordingState(
        status: RecordingStatus.error,
        errorMessage: '录音失败',
      );
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(errorState));
      when(mockRecordingBloc.state).thenReturn(errorState);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('录音失败'), findsOneWidget);
    });

    testWidgets('should show audio level indicator when recording',
        (WidgetTester tester) async {
      // Arrange
      const recordingState = RecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
        audioLevel: 0.7,
      );
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(recordingState));
      when(mockRecordingBloc.state).thenReturn(recordingState);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display stop button when recording',
        (WidgetTester tester) async {
      // Arrange
      const recordingState = RecordingState(
        status: RecordingStatus.recording,
        duration: 5000,
      );
      when(mockRecordingBloc.stream).thenAnswer(
          (_) => Stream.value(recordingState));
      when(mockRecordingBloc.state).thenReturn(recordingState);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    group('User Interactions', () {
      testWidgets('should pause recording when pause button pressed',
          (WidgetTester tester) async {
        // Arrange
        const recordingState = RecordingState(
          status: RecordingStatus.recording,
          duration: 5000,
        );
        when(mockRecordingBloc.stream).thenAnswer(
            (_) => Stream.value(recordingState));
        when(mockRecordingBloc.state).thenReturn(recordingState);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();

        // Assert
        verify(mockRecordingBloc.add(const PauseRecording())).called(1);
      });

      testWidgets('should cancel recording when cancel button pressed',
          (WidgetTester tester) async {
        // Arrange
        const recordingState = RecordingState(
          status: RecordingStatus.recording,
          duration: 5000,
        );
        when(mockRecordingBloc.stream).thenAnswer(
            (_) => Stream.value(recordingState));
        when(mockRecordingBloc.state).thenReturn(recordingState);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        // Assert
        verify(mockRecordingBloc.add(const CancelRecording())).called(1);
      });
    });
  });
}
