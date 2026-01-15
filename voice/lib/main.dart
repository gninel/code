import 'dart:io' show Platform, Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'generated/app_localizations.dart';
import 'presentation/bloc/language/language_bloc.dart';
import 'presentation/bloc/language/language_event.dart';
import 'presentation/bloc/language/language_state.dart';

import 'core/themes/app_theme.dart';
import 'core/utils/injection.dart';
import 'core/services/prompt_loader_service.dart';
import 'data/services/background_ai_service.dart';
import 'presentation/bloc/recording/recording_bloc.dart';
import 'presentation/bloc/integrated_recording/integrated_recording_bloc.dart';
import 'presentation/bloc/voice_record/voice_record_bloc.dart';
import 'presentation/bloc/autobiography/autobiography_bloc.dart';
import 'presentation/bloc/ai_generation/ai_generation_bloc.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/interview/interview_bloc.dart';
import 'presentation/bloc/autobiography_version/autobiography_version_bloc.dart';
import 'presentation/pages/main_page.dart';
import 'data/repositories/web_mock_repositories.dart';
import 'domain/repositories/autobiography_repository.dart';
import 'domain/repositories/autobiography_version_repository.dart';
import 'domain/repositories/voice_record_repository.dart';
import 'domain/repositories/ai_generation_repository.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅在非 Web 平台执行平台特定操作
  if (!kIsWeb) {
    // 请求存储权限
    await requestStoragePermission();

    // 执行数据迁移
    await migrateData();

    // 初始化后台AI服务（仅Android/iOS）
    if (Platform.isAndroid || Platform.isIOS) {
      await BackgroundAiService().initialize();
    }
  }

  // 初始化依赖注入
  await configureDependencies();

  // Web环境使用Mock仓库 (文件/数据库操作不支持Web)
  if (kIsWeb) {
    getIt.allowReassignment = true;

    getIt.unregister<AutobiographyRepository>();
    getIt.registerSingleton<AutobiographyRepository>(
        MockAutobiographyRepository());

    getIt.unregister<AutobiographyVersionRepository>();
    getIt.registerSingleton<AutobiographyVersionRepository>(
        MockAutobiographyVersionRepository());

    getIt.unregister<VoiceRecordRepository>();
    getIt.registerSingleton<VoiceRecordRepository>(MockVoiceRecordRepository());

    getIt.unregister<AiGenerationRepository>();
    getIt.registerSingleton<AiGenerationRepository>(
        MockAiGenerationRepository());
  }

  // 初始化提示词配置
  await initializePromptLoader();

  runApp(const VoiceAutobiographyApp());
}

/// 初始化提示词加载服务
Future<void> initializePromptLoader() async {
  try {
    final promptLoader = getIt<PromptLoaderService>();
    await promptLoader.init();
    print('[Main] 提示词配置加载成功');
  } catch (e) {
    print('[Main] 提示词配置加载失败: $e');
    // 非关键错误，允许应用继续运行
  }
}

Future<void> requestStoragePermission() async {
  // permission_handler doesn't support desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return;
  }

  // Android 11+ (API 30+) 需要 MANAGE_EXTERNAL_STORAGE
  if (await Permission.manageExternalStorage.status.isDenied) {
    await Permission.manageExternalStorage.request();
  }

  // 旧版本 Android 需要 STORAGE
  if (await Permission.storage.status.isDenied) {
    await Permission.storage.request();
  }
}

Future<void> migrateData() async {
  if (!Platform.isAndroid) return;

  try {
    // 旧目录 (App-specific external storage)
    final oldDir = await getExternalStorageDirectory();
    if (oldDir == null) return;
    final oldAppDir = Directory('${oldDir.path}/VoiceAutobiography');

    // 新目录 (Public Download directory)
    final newDir = Directory('/storage/emulated/0/Download/VoiceAutobiography');

    // 如果旧目录存在且新目录不存在(或为空)，则迁移
    if (await oldAppDir.exists()) {
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      final files = oldAppDir.listSync();
      for (final file in files) {
        if (file is File) {
          final filename = file.path.split('/').last;
          final newFile = File('${newDir.path}/$filename');
          if (!await newFile.exists()) {
            await file.copy(newFile.path);
            print('Data Migration: Copied $filename to public storage');
          }
        }
      }
    }
  } catch (e) {
    print('Data Migration Failed: $e');
  }
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
        BlocProvider(
          create: (context) => getIt<AiGenerationBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<InterviewBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<AutobiographyVersionBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<LanguageBloc>()..add(const LoadLanguage()),
        ),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return MaterialApp(
            title: 'Voice Autobiography',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: languageState.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('zh'),
            ],
            home: const MainPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
