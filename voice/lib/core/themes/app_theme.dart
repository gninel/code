import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用主题配置
class AppTheme {
  AppTheme._();

  /// 这里的颜色是为了适配“纸张/复古”风格
  /// 背景色：仿旧纸张颜色
  static const Color vintageBackground = Color(0xFFF7F3E8); // 暖白色/米色
  /// 主色调：深棕色（用于文字、图标、按钮等）
  static const Color vintagePrimary = Color(0xFF5D4037); // Brown
  /// 次要颜色：浅棕色/卡其色（用于分割线、次要背景等）
  static const Color vintageSecondary = Color(0xFFA1887F);

  /// 强调色：深红/铁锈红（用于录音按钮等强调元素）
  static const Color vintageAccent = Color(0xFF8D6E63);

  /// 录音相关颜色
  static const Color recordingColor = Color(0xFFD32F2F); // Deep Red
  static const Color recordingBackgroundColor = Color(0xFFFFEBEE); // Light Red
  static const Color pausedColor = Color(0xFFFFB74D); // Orange/Amber
  static const Color processingColor = Color(0xFF8D6E63); // Brown
  static const Color completedColor = Color(0xFF388E3C); // Green

  /// 通用复古主题（不分深浅，统一使用复古风）
  static ThemeData get vintageTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // 整体是亮色调
      primaryColor: vintagePrimary,
      scaffoldBackgroundColor: vintageBackground,
      colorScheme: const ColorScheme.light(
        primary: vintagePrimary,
        secondary: vintageAccent,
        surface: vintageBackground,
        onSurface: vintagePrimary,
        error: recordingColor,
      ),

      // AppBar主题
      appBarTheme: const AppBarTheme(
        backgroundColor: vintageBackground,
        foregroundColor: vintagePrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: vintagePrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif', // 尝试使用衬线体增强复古感
        ),
        iconTheme: IconThemeData(color: vintagePrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card主题
      cardTheme: CardThemeData(
        color: const Color(0xFFFBF8F1), // 比背景稍亮一点的纸张色
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: vintagePrimary.withOpacity(0.1), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // FloatingActionButton主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: vintagePrimary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vintageSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: vintageSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vintagePrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: TextStyle(color: vintagePrimary.withOpacity(0.5)),
        labelStyle: const TextStyle(color: vintagePrimary),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vintagePrimary,
          foregroundColor: const Color(0xFFF7F3E8), // 文字颜色为纸张色
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: vintagePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vintagePrimary,
          side: const BorderSide(color: vintagePrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),

      // 文本主题 - 统一使用深棕色
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: vintagePrimary,
          fontFamily: 'Serif',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: vintagePrimary,
          fontFamily: 'Serif',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: vintagePrimary,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: vintagePrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: vintagePrimary,
          height: 1.6, // 增加行高，提升阅读体验
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: vintagePrimary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: vintagePrimary,
        ),
      ),

      // 图标主题
      iconTheme: const IconThemeData(
        color: vintagePrimary,
        size: 24,
      ),

      // 分割线主题
      dividerTheme: DividerThemeData(
        color: vintagePrimary.withOpacity(0.2),
        thickness: 1,
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: vintageBackground, // 与页面背景一致
        selectedItemColor: vintagePrimary,
        unselectedItemColor: vintageSecondary, // 浅棕色
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // 进度指示器主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: vintagePrimary,
        linearTrackColor: Color(0xFFE0D8C8),
      ),

      // 对话框主题
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFBF8F1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: vintagePrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: vintagePrimary,
        ),
      ),

      // SnackBar主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: vintagePrimary,
        contentTextStyle: const TextStyle(color: Color(0xFFF7F3E8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 浅色主题 (映射到 vintageTheme)
  static ThemeData get lightTheme => vintageTheme;

  /// 深色主题 (也映射到 vintageTheme，强制统一风格)
  static ThemeData get darkTheme => vintageTheme;
}
