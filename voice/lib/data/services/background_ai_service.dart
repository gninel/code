import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:injectable/injectable.dart';

/// 后台AI生成任务处理器
/// 这个回调选择器在主Isolate之外运行
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AiGenerationTaskHandler());
}

/// AI生成任务处理器
class AiGenerationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('BackgroundAiService: Task started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 不需要重复事件，AI生成是一次性任务
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('BackgroundAiService: Task destroyed');
  }

  @override
  void onReceiveData(Object data) {
    print('BackgroundAiService: Received data: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('BackgroundAiService: Notification button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    print('BackgroundAiService: Notification pressed');
  }
}

/// 后台AI服务管理器
@lazySingleton
class BackgroundAiService {
  static final BackgroundAiService _instance = BackgroundAiService._internal();
  factory BackgroundAiService() => _instance;
  BackgroundAiService._internal();

  bool _isInitialized = false;
  bool _isRunning = false;

  /// 检查服务是否正在运行
  bool get isRunning => _isRunning;

  /// 初始化前台任务服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ai_generation_channel',
        channelName: 'AI生成服务',
        channelDescription: '后台运行AI自传生成任务',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
    print('BackgroundAiService: Initialized');
  }

  /// 启动后台AI生成任务
  Future<bool> startBackgroundTask({String? taskDescription}) async {
    // macOS 和其他桌面平台不支持前台服务，直接返回 true
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      print('BackgroundAiService: Desktop platform detected, skipping foreground service');
      _isRunning = true;
      return true;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 检查权限
      final notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        final result =
            await FlutterForegroundTask.requestNotificationPermission();
        if (result != NotificationPermission.granted) {
          print('BackgroundAiService: Notification permission denied');
          // 即使没有通知权限，仍然尝试启动（某些设备可能仍然可以工作）
        }
      }

      // 启动前台服务
      final result = await FlutterForegroundTask.startService(
        notificationTitle: '正在生成自传...',
        notificationText: taskDescription ?? 'AI正在处理您的语音内容',
        callback: startCallback,
      );

      // ServiceRequestResult 是 sealed class，使用类型检查
      _isRunning = result is ServiceRequestSuccess;
      print('BackgroundAiService: Start service result: $result');
      return _isRunning;
    } catch (e) {
      print('BackgroundAiService: Error starting foreground service: $e');
      // 在不支持的平台上，仍然允许继续（在主线程中运行）
      _isRunning = true;
      return true;
    }
  }

  /// 更新通知内容
  Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    // 桌面平台不支持通知更新，直接返回
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return;
    }

    if (_isRunning) {
      try {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      } catch (e) {
        print('BackgroundAiService: Error updating notification: $e');
      }
    }
  }

  /// 停止后台任务
  Future<void> stopBackgroundTask() async {
    if (_isRunning) {
      // 桌面平台不需要停止前台服务
      if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
        try {
          await FlutterForegroundTask.stopService();
        } catch (e) {
          print('BackgroundAiService: Error stopping service: $e');
        }
      }
      _isRunning = false;
      print('BackgroundAiService: Service stopped');
    }
  }

  /// 检查服务是否正在运行
  Future<bool> isServiceRunning() async {
    // 桌面平台返回内部状态标志
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return _isRunning;
    }

    try {
      return await FlutterForegroundTask.isRunningService;
    } catch (e) {
      print('BackgroundAiService: Error checking service status: $e');
      return _isRunning;
    }
  }
}
