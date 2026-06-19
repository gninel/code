import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'services/audio_player_service.dart';
import 'services/local_storage_service.dart';
import 'services/clipboard_service.dart';
import 'bloc/task/task_bloc.dart';
import 'bloc/library/library_bloc.dart';
import 'bloc/player/player_bloc.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MusicPocketApp());
}

class MusicPocketApp extends StatefulWidget {
  const MusicPocketApp({super.key});

  @override
  State<MusicPocketApp> createState() => _MusicPocketAppState();
}

class _MusicPocketAppState extends State<MusicPocketApp> with WidgetsBindingObserver {
  late final ApiService _apiService;
  late final AudioPlayerService _playerService;
  late final LocalStorageService _storageService;
  late final ClipboardService _clipboardService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apiService = ApiService();
    _playerService = AudioPlayerService();
    _storageService = LocalStorageService();
    _clipboardService = ClipboardService();
    _clipboardService.startWatching();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clipboardService.startWatching();
    } else if (state == AppLifecycleState.paused) {
      _clipboardService.stopWatching();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerService.dispose();
    _clipboardService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TaskBloc(api: _apiService, storage: _storageService),
        ),
        BlocProvider(
          create: (_) => LibraryBloc(storage: _storageService),
        ),
        BlocProvider(
          create: (_) => PlayerBloc(playerService: _playerService),
        ),
      ],
      child: MaterialApp(
        title: 'MusicPocket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: HomeScreen(clipboardService: _clipboardService),
      ),
    );
  }
}
