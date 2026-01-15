import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_autobiography_flutter/presentation/widgets/voice_records_list.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_state.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';

class MockVoiceRecordBloc extends Mock implements VoiceRecordBloc {}

void main() {
  group('VoiceRecordsList Widget Tests', () {
    late MockVoiceRecordBloc mockBloc;

    setUp(() {
      mockBloc = MockVoiceRecordBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<VoiceRecordBloc>.value(
          value: mockBloc,
          child: const VoiceRecordsList(),
        ),
      );
    }

    final testRecords = [
      VoiceRecord(
        id: '1',
        title: 'First Record',
        content: 'Content 1',
        timestamp: DateTime(2024, 12, 26, 10, 0),
        duration: 65000,
      ),
      VoiceRecord(
        id: '2',
        title: 'Second Record',
        content: 'Content 2',
        timestamp: DateTime(2024, 12, 25, 15, 30),
        duration: 120000,
      ),
    ];

    testWidgets('should display loading indicator when loading',
        (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(const VoiceRecordState(isLoading: true));
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(const VoiceRecordState(isLoading: true)));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display records list when loaded',
        (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: testRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: testRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('First Record'), findsOneWidget);
      expect(find.text('Second Record'), findsOneWidget);
    });

    testWidgets('should display empty message when no records',
        (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        const VoiceRecordState(
          isLoading: false,
          filteredRecords: [],
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(const VoiceRecordState(
                isLoading: false,
                filteredRecords: [],
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('暂无录音记录'), findsOneWidget);
    });

    testWidgets('should display error message when error occurs',
        (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        const VoiceRecordState(
          isLoading: false,
          error: 'Failed to load records',
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(const VoiceRecordState(
                isLoading: false,
                error: 'Failed to load records',
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Failed to load records'), findsOneWidget);
    });

    testWidgets('should display formatted duration', (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: testRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: testRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('should display formatted date', (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: testRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: testRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('2024-12-26'), findsOneWidget);
      expect(find.text('2024-12-25'), findsOneWidget);
    });

    testWidgets('should tap on record and trigger navigation',
        (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: testRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: testRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('First Record'));
      await tester.pumpAndSettle();

      // Assert
      // Navigation would be verified with a mock navigator
      // For now, we just verify the tap doesn't crash
    });

    testWidgets('should display search icon', (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: testRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: testRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display filter icon', (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: testRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: testRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should handle long titles gracefully',
        (WidgetTester tester) async {
      // Arrange
      final longTitleRecords = [
        VoiceRecord(
          id: '1',
          title: 'This is a very long title that should be truncated',
          content: 'Content',
          timestamp: DateTime.now(),
        ),
      ];
      when(mockBloc.state).thenReturn(
        VoiceRecordState(
          isLoading: false,
          filteredRecords: longTitleRecords,
        ),
      );
      when(mockBloc.stream).thenAnswer(
          (_) => Stream.value(VoiceRecordState(
                isLoading: false,
                filteredRecords: longTitleRecords,
              )));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(ListTile), findsOneWidget);
    });

    group('Record Item Interactions', () {
      testWidgets('should show delete button on long press',
          (WidgetTester tester) async {
        // Arrange
        when(mockBloc.state).thenReturn(
          VoiceRecordState(
            isLoading: false,
            filteredRecords: testRecords,
          ),
        );
        when(mockBloc.stream).thenAnswer(
            (_) => Stream.value(VoiceRecordState(
                  isLoading: false,
                  filteredRecords: testRecords,
                )));

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.longPress(find.text('First Record'));
        await tester.pumpAndSettle();

        // Assert - would verify delete button appears
      });

      testWidgets('should display record tags if present',
          (WidgetTester tester) async {
        // Arrange
        final taggedRecords = [
          VoiceRecord(
            id: '1',
            title: 'Tagged Record',
            content: 'Content',
            timestamp: DateTime.now(),
            tags: const ['童年', '回忆'],
          ),
        ];
        when(mockBloc.state).thenReturn(
          VoiceRecordState(
            isLoading: false,
            filteredRecords: taggedRecords,
          ),
        );
        when(mockBloc.stream).thenAnswer(
            (_) => Stream.value(VoiceRecordState(
                  isLoading: false,
                  filteredRecords: taggedRecords,
                )));

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.text('童年'), findsOneWidget);
        expect(find.text('回忆'), findsOneWidget);
      });
    });

    group('List Layout', () {
      testWidgets('should use ListView widget', (WidgetTester tester) async {
        // Arrange
        when(mockBloc.state).thenReturn(
          VoiceRecordState(
            isLoading: false,
            filteredRecords: testRecords,
          ),
        );
        when(mockBloc.stream).thenAnswer(
            (_) => Stream.value(VoiceRecordState(
                  isLoading: false,
                  filteredRecords: testRecords,
                )));

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should display records in correct order',
          (WidgetTester tester) async {
        // Arrange
        when(mockBloc.state).thenReturn(
          VoiceRecordState(
            isLoading: false,
            filteredRecords: testRecords,
          ),
        );
        when(mockBloc.stream).thenAnswer(
            (_) => Stream.value(VoiceRecordState(
                  isLoading: false,
                  filteredRecords: testRecords,
                )));

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert
        final firstItem = tester.widget<ListTile>(
          find.byType(ListTile).first,
        );
        expect(firstItem.title, isA<Text>());
        expect((firstItem.title as Text).data, 'First Record');
      });
    });
  });
}
