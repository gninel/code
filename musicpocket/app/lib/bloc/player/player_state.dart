import 'package:equatable/equatable.dart';
import '../../models/audio_task.dart';

class PlayerState extends Equatable {
  final AudioTask? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  PlayerState copyWith({
    AudioTask? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [currentTrack?.taskId, isPlaying, position, duration];
}
