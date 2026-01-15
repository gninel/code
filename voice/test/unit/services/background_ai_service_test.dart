// BackgroundAiService 基础测试
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:voice_autobiography_flutter/data/services/background_ai_service.dart';

void main() {
  group('BackgroundAiService', () {
    late BackgroundAiService service;

    setUp(() {
      service = BackgroundAiService();
    });

    tearDown(() async {
      // 确保每个测试后清理状态
      await service.stopBackgroundTask();
    });

    test('应该是单例', () {
      final service1 = BackgroundAiService();
      final service2 = BackgroundAiService();

      expect(service1, same(service2));
    });

    test('初始状态 isRunning 应该为 false', () {
      expect(service.isRunning, false);
    });

    test('在桌面平台应该成功启动任务', () async {
      // 在测试环境中，默认行为是桌面平台
      final result = await service.startBackgroundTask(
        taskDescription: '测试任务',
      );

      expect(result, true);
      expect(service.isRunning, true);
    });

    test('停止任务后 isRunning 应该为 false', () async {
      await service.startBackgroundTask();
      expect(service.isRunning, true);

      await service.stopBackgroundTask();
      expect(service.isRunning, false);
    });

    test('检查服务状态应该返回正确值', () async {
      expect(await service.isServiceRunning(), false);

      await service.startBackgroundTask();
      expect(await service.isServiceRunning(), true);

      await service.stopBackgroundTask();
      expect(await service.isServiceRunning(), false);
    });

    test('未启动时停止服务应该安全', () async {
      // 即使服务未启动，停止也应该安全
      await service.stopBackgroundTask();

      expect(service.isRunning, false);
    });

    test('应该支持更新通知', () async {
      await service.startBackgroundTask();

      // 更新通知不应该抛出异常
      await service.updateNotification(
        title: '更新的标题',
        text: '更新的内容',
      );

      expect(service.isRunning, true);
    });

    test('未启动时更新通知应该安全', () async {
      // 确保服务未启动
      await service.stopBackgroundTask();
      
      // 未启动时更新通知应该安全
      await service.updateNotification(
        title: '标题',
        text: '内容',
      );

      expect(service.isRunning, false);
    });
  });

  group('AiGenerationTaskHandler', () {
    late AiGenerationTaskHandler handler;

    setUp(() {
      handler = AiGenerationTaskHandler();
    });

    test('onStart 应该正常执行', () async {
      await handler.onStart(DateTime.now(), TaskStarter.developer);
      // 不应该抛出异常
      expect(true, true);
    });

    test('onDestroy 应该正常执行', () async {
      await handler.onDestroy(DateTime.now());
      // 不应该抛出异常
      expect(true, true);
    });

    test('onRepeatEvent 应该正常执行', () {
      handler.onRepeatEvent(DateTime.now());
      // 不应该抛出异常
      expect(true, true);
    });

    test('onReceiveData 应该正常执行', () {
      handler.onReceiveData({'key': 'value'});
      // 不应该抛出异常
      expect(true, true);
    });

    test('onNotificationButtonPressed 应该正常执行', () {
      handler.onNotificationButtonPressed('button_id');
      // 不应该抛出异常
      expect(true, true);
    });

    test('onNotificationPressed 应该正常执行', () {
      handler.onNotificationPressed();
      // 不应该抛出异常
      expect(true, true);
    });
  });
}
