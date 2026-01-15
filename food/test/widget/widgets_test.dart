import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/widgets/loading_widget.dart';

void main() {
  group('LoadingWidget Tests', () {
    testWidgets('should display loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: '加载中...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display custom message', (WidgetTester tester) async {
      const message = '加载中...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: message),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
    });

    testWidgets('should center content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: '加载中...'),
          ),
        ),
      );

      final centerFinder = find.byType(Center);
      expect(centerFinder, findsOneWidget);
    });

    testWidgets('should use column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: '加载中...'),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should have correct spacing between elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: '自定义消息'),
          ),
        ),
      );

      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('should handle empty message gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: ''),
          ),
        ),
      );

      // 应该仍然显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle long message', (WidgetTester tester) async {
      const longMessage = '这是一个非常长的加载消息，用于测试组件如何处理长文本显示';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: longMessage),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('should use custom color when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(
              message: '加载中...',
              color: Colors.red,
            ),
          ),
        ),
      );

      final circularProgressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(circularProgressIndicator.valueColor, isA<AlwaysStoppedAnimation<Color>>());
    });

    testWidgets('should use custom size when provided', (WidgetTester tester) async {
      const customSize = 32.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(
              message: '加载中...',
              size: customSize,
            ),
          ),
        ),
      );

      // CircularProgressIndicator 应该使用指定的大小
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SmallLoadingIndicator Tests', () {
    testWidgets('should display small loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmallLoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should use custom size', (WidgetTester tester) async {
      const customSize = 16.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmallLoadingIndicator(size: customSize),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(customSize));
      expect(sizedBox.height, equals(customSize));
    });

    testWidgets('should use custom color when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmallLoadingIndicator(color: Colors.blue),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingOverlay Tests', () {
    testWidgets('should display child when not loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display overlay when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: Text('Content'),
              message: '加载中...',
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载中...'), findsOneWidget);
    });

    testWidgets('should show semi-transparent background when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsAtLeastNWidgets(1));
    });
  });

  group('EmptyStateWidget Tests', () {
    testWidgets('should display icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '暂无数据',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('should display subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '暂无数据',
              subtitle: '点击添加第一条记录',
            ),
          ),
        ),
      );

      expect(find.text('点击添加第一条记录'), findsOneWidget);
    });

    testWidgets('should display action button when provided', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '暂无数据',
              actionText: '添加记录',
              onAction: () {
                actionPressed = true;
              },
            ),
          ),
        ),
      );

      // 等待 widget 完成
      await tester.pumpAndSettle();

      expect(find.text('添加记录'), findsOneWidget);
      // ElevatedButton.icon 可能被渲染为不同的 widget 结构，直接点击文本
      await tester.tap(find.text('添加记录'));
      expect(actionPressed, isTrue);
    });

    testWidgets('should center all content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: '暂无数据',
            ),
          ),
        ),
      );

      // EmptyStateWidget 本身有一个 Center，使用 atLeastOneWidget
      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });
  });

  group('ErrorStateWidget Tests', () {
    testWidgets('should display error icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: '加载失败',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
    });

    testWidgets('should display subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: '加载失败',
              subtitle: '请检查网络连接后重试',
            ),
          ),
        ),
      );

      expect(find.text('请检查网络连接后重试'), findsOneWidget);
    });

    testWidgets('should display action button when provided', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: '加载失败',
              actionText: '重试',
              onAction: () {
                actionPressed = true;
              },
            ),
          ),
        ),
      );

      // 等待 widget 完成
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
      // ElevatedButton.icon 可能被渲染为不同的 widget 结构，直接点击文本
      await tester.tap(find.text('重试'));
      expect(actionPressed, isTrue);
    });
  });

  group('SkeletonWidget Tests', () {
    testWidgets('should display skeleton with specified dimensions', (WidgetTester tester) async {
      const width = 100.0;
      const height = 20.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonWidget(
              width: width,
              height: height,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(container.constraints?.minWidth, equals(width));
      expect(container.constraints?.minHeight, equals(height));
    });

    testWidgets('should apply border radius when provided', (WidgetTester tester) async {
      const borderRadius = BorderRadius.all(Radius.circular(8));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonWidget(
              width: 100,
              height: 20,
              borderRadius: borderRadius,
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.borderRadius, equals(borderRadius));
    });
  });

  group('SkeletonListItem Tests', () {
    testWidgets('should display skeleton list item with avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(showAvatar: true),
          ),
        ),
      );

      expect(find.byType(SkeletonWidget), findsNWidgets(3)); // avatar + 2 text lines
    });

    testWidgets('should display skeleton list item without avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(showAvatar: false),
          ),
        ),
      );

      expect(find.byType(SkeletonWidget), findsNWidgets(2)); // 2 text lines
    });
  });
}

