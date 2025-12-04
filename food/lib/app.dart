import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation.dart';
import 'screens/result_screen.dart';
import 'screens/camera_screen.dart';
import 'providers/food_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/user_provider.dart';
import 'l10n/app_localizations.dart';

/// 主应用组件
class FoodCalorieApp extends StatelessWidget {
  const FoodCalorieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    return MaterialApp(
      title: '食物热量识别',
      debugShowCheckedModeBanner: false,
      
      // 国际化配置
      locale: userProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''),
        Locale('en', ''),
      ],
      
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF26a69a),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
        ).copyWith(
          secondary: const Color(0xFF00897b),
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF26a69a),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF26a69a),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF26a69a),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF26a69a),
          foregroundColor: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        primaryColor: const Color(0xFFFF6B35),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A2A),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
      routes: {
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}

/// 路由管理
class AppRoutes {
  static const String home = '/home';
  static const String result = '/result';
  static const String statistics = '/statistics';
  static const String camera = '/camera';

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  static void navigateToResult(BuildContext context, Map<String, dynamic> arguments) {
    Navigator.pushNamed(context, result, arguments: arguments);
  }

  static void navigateToStatistics(BuildContext context) {
    Navigator.pushNamed(context, statistics);
  }

  static void navigateToCamera(BuildContext context, Function(String) onPictureTaken) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(onPictureTaken: onPictureTaken),
      ),
    );
  }
}

/// 应用初始化
class AppInitializer {
  static Future<void> initialize(BuildContext context) async {
    try {
      // 设置系统UI样式
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      // 设置横竖屏方向
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 初始化数据
      debugPrint('AppInitializer: 开始初始化数据...');
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);

      await Future.wait([
        foodProvider.initialize(),
        statisticsProvider.initialize(),
      ]);
      debugPrint('AppInitializer: 数据初始化完成');

    } catch (e) {
      debugPrint('应用初始化失败: $e');
    }
  }
}

/// 应用工具类
class AppUtils {
  /// 显示加载对话框
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 隐藏加载对话框
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 显示错误提示
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '确定',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 显示成功提示
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示确认对话框
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 格式化热量显示
  /// 格式化热量显示
  static String formatCalories(BuildContext context, int calories) {
    final l10n = AppLocalizations.of(context)!;
    if (calories >= 1000) {
      return '${(calories / 1000).toStringAsFixed(1)}k ${l10n.get('kcal')}';
    }
    return '$calories ${l10n.get('kcal')}';
  }

  /// 格式化日期
  /// 格式化日期
  static String formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = targetDate.difference(today).inDays;

    switch (difference) {
      case 0:
        return l10n.get('today');
      case 1:
        return l10n.get('tomorrow');
      case -1:
        return l10n.get('yesterday');
      default:
        return '${date.month}/${date.day}';
    }
  }

  /// 获取热量颜色
  static Color getCalorieColor(int calories) {
    if (calories < 50) {
      return Colors.green;
    } else if (calories < 150) {
      return Colors.orange;
    } else if (calories < 300) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  /// 获取餐次图标
  static IconData getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_cloudy;
      case 'dinner':
        return Icons.nights_stay;
      default:
        return Icons.restaurant;
    }
  }

  /// 获取餐次名称
  /// 获取餐次名称
  static String getMealName(BuildContext context, String mealType) {
    final l10n = AppLocalizations.of(context)!;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return l10n.get('breakfast');
      case 'lunch':
        return l10n.get('lunch');
      case 'dinner':
        return l10n.get('dinner');
      default:
        return l10n.get('other');
      }
  }

  /// 获取热量等级
  /// 获取热量等级
  static String getCalorieLevel(BuildContext context, int calories) {
    final l10n = AppLocalizations.of(context)!;
    if (calories < 100) {
      return l10n.get('low_calorie');
    } else if (calories < 300) {
      return l10n.get('medium_calorie');
    } else {
      return l10n.get('high_calorie');
    }
  }
}