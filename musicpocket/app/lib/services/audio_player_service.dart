import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/audio_task.dart';

enum RepeatMode { off, one, all }

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioTask? _currentTask;
  final List<AudioTask> _playlist = [];
  int _currentIndex = -1;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffle = false;

  AudioTask? get currentTask => _currentTask;
  List<AudioTask> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  AudioPlayerService() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackComplete();
      }
    });
  }

  Future<void> play(AudioTask task) async {
    if (task.localPath == null) return;

    _currentTask = task;
    await _player.setFilePath(task.localPath!);
    await _player.play();
  }

  Future<void> playFromPlaylist(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    await play(_playlist[index]);
  }

  void setPlaylist(List<AudioTask> tasks) {
    _playlist
      ..clear()
      ..addAll(tasks.where((t) => t.localPath != null));
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> togglePlay() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    int nextIndex;
    if (_shuffle) {
      nextIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length);
    } else {
      nextIndex = (_currentIndex + 1) % _playlist.length;
    }
    await playFromPlaylist(nextIndex);
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    int prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playFromPlaylist(prevIndex);
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
  }

  void _onTrackComplete() {
    switch (_repeatMode) {
      case RepeatMode.one:
        seek(Duration.zero);
        resume();
      case RepeatMode.all:
        next();
      case RepeatMode.off:
        if (_currentIndex < _playlist.length - 1) {
          next();
        }
    }
  }

  Future<void> dispose() => _player.dispose();
}
