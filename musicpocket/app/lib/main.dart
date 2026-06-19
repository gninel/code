import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'services/audio_player_service.dart';
import 'services/local_storage_service.dart';
import 'bloc/task/task_bloc.dart';
import 'bloc/library/library_bloc.dart';
import 'bloc/player/player_bloc.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MusicPocketApp());
}

class MusicPocketApp extends StatefulWidget {
  const MusicPocketApp({super.key});

  @override
  State<MusicPocketApp> createState() => _MusicPocketAppState();
}

class _MusicPocketAppState extends State<MusicPocketApp> {
  late final ApiService _apiService;
  late final AudioPlayerService _playerService;
  late final LocalStorageService _storageService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _playerService = AudioPlayerService();
    _storageService = LocalStorageService();
  }

  @override
  void dispose() {
    _playerService.dispose();
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.black,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
