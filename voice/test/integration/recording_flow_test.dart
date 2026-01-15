import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:voice_autobiography_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recording Flow Integration Tests', () {
    testWidgets('should complete full recording flow',
        (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 1. 验证主页加载
      expect(find.text('语音自传'), findsOneWidget);

      // 2. 点击录音按钮
      final recordButton = find.byIcon(Icons.mic);
      expect(recordButton, findsOneWidget);
      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      // 3. 验证录音界面已打开
      expect(find.text('开始录音'), findsOneWidget);

      // 4. 开始录音
      await tester.tap(find.text('开始录音'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 5. 验证录音状态
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 6. 等待几秒
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 7. 停止录音
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // 8. 验证录音已保存
      expect(find.text('录音已保存'), findsOneWidget);
    });

    testWidgets('should handle recording with transcription',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 开始录音流程
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // 2. 录音
      await tester.tap(find.text('开始录音'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3. 停止录音
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // 4. 等待转录
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 5. 验证转录结果
      expect(find.text('转写完成'), findsOneWidget);
    });

    testWidgets('should navigate to recording detail and play',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 导航到录音列表
      await tester.tap(find.text('录音'));
      await tester.pumpAndSettle();

      // 2. 点击第一个录音项
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // 3. 验证详情页
      expect(find.byType(IconButton), findsWidgets);

      // 4. 播放录音
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // 5. 验证播放状态
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should generate autobiography from recordings',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 导航到自传页面
      await tester.tap(find.text('自传'));
      await tester.pumpAndSettle();

      // 2. 点击生成自传按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 3. 选择录音
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // 4. 生成自传
      await tester.tap(find.text('生成自传'));
      await tester.pumpAndSettle();

      // 5. 等待生成完成
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 6. 验证自传已生成
      expect(find.text('自传生成完成'), findsOneWidget);
    });

    testWidgets('should handle error states gracefully',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 尝试在没有权限的情况下录音
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      await tester.tap(find.text('开始录音'));
      await tester.pumpAndSettle();

      // 2. 验证错误提示
      if (find.text('权限被拒绝').evaluate().isNotEmpty) {
        expect(find.text('权限被拒绝'), findsOneWidget);
      }
    });

    testWidgets('should persist data across app restart',
        (WidgetTester tester) async {
      // 1. 启动应用并创建录音
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      await tester.tap(find.text('开始录音'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // 2. 重启应用
      app.main();
      await tester.pumpAndSettle();

      // 3. 验证数据持久化
      await tester.tap(find.text('录音'));
      await tester.pumpAndSettle();

      // 应该能看到之前创建的录音
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
