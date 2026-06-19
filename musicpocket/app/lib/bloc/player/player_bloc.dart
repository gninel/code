import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_player_service.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayerService playerService;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playingSub;

  PlayerBloc({required this.playerService}) : super(const PlayerState()) {
    on<PlayTrack>(_onPlay);
    on<TogglePlayPause>(_onToggle);
    on<NextTrack>(_onNext);
    on<PreviousTrack>(_onPrevious);
    on<SeekTo>(_onSeek);
    on<SetPlaylist>(_onSetPlaylist);

    _positionSub = playerService.positionStream.listen((pos) {
      if (!isClosed) {
        emit(state.copyWith(position: pos));
      }
    });
    _durationSub = playerService.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        emit(state.copyWith(duration: dur));
      }
    });
    _playingSub = playerService.playingStream.listen((playing) {
      if (!isClosed) {
        emit(state.copyWith(
          isPlaying: playing,
          currentTrack: playerService.currentTask,
        ));
      }
    });
  }

  Future<void> _onPlay(PlayTrack event, Emitter<PlayerState> emit) async {
    await playerService.play(event.task);
    emit(state.copyWith(currentTrack: event.task, isPlaying: true));
  }

  Future<void> _onToggle(TogglePlayPause event, Emitter<PlayerState> emit) async {
    await playerService.togglePlay();
  }

  Future<void> _onNext(NextTrack event, Emitter<PlayerState> emit) async {
    await playerService.next();
  }

  Future<void> _onPrevious(PreviousTrack event, Emitter<PlayerState> emit) async {
    await playerService.previous();
  }

  Future<void> _onSeek(SeekTo event, Emitter<PlayerState> emit) async {
    await playerService.seek(event.position);
  }

  Future<void> _onSetPlaylist(SetPlaylist event, Emitter<PlayerState> emit) async {
    playerService.setPlaylist(event.tasks);
    if (event.tasks.isNotEmpty) {
      await playerService.playFromPlaylist(event.startIndex);
    }
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    return super.close();
  }
}
