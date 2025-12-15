import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/themes/app_theme.dart';
import 'core/utils/injection.dart';
import 'presentation/bloc/recording/recording_bloc.dart';
import 'presentation/bloc/integrated_recording/integrated_recording_bloc.dart';
import 'presentation/bloc/voice_record/voice_record_bloc.dart';
import 'presentation/bloc/autobiography/autobiography_bloc.dart';
import 'presentation/pages/main_page.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化依赖注入
  await configureDependencies();

  runApp(const VoiceAutobiographyApp());
}

class VoiceAutobiographyApp extends StatelessWidget {
  const VoiceAutobiographyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<RecordingBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<IntegratedRecordingBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<VoiceRecordBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<AutobiographyBloc>(),
        ),
      ],
      child: MaterialApp(
        title: '语音自传',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // 跟随系统主题
        home: const MainPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}