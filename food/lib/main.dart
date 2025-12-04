import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/food_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/user_provider.dart'; // Added import
// The following imports were in the provided "Code Edit" but are not strictly necessary for this file based on the original content.
// Assuming they are intended to be added for future use or are part of a larger context.
// import 'screens/main_navigation.dart';
// import 'screens/camera_screen.dart';
// import 'screens/result_screen.dart';
// import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 强制竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  debugPrint('MAIN: 应用启动...');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()), // Added UserProvider
      ],
      child: const FoodCalorieApp(),
    ),
  );
}