import 'package:equatable/equatable.dart';
import '../../models/audio_task.dart';

abstract class PlayerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlayTrack extends PlayerEvent {
  final AudioTask task;
  PlayTrack(this.task);

  @override
  List<Object?> get props => [task.taskId];
}

class TogglePlayPause extends PlayerEvent {}
class NextTrack extends PlayerEvent {}
class PreviousTrack extends PlayerEvent {}

class SeekTo extends PlayerEvent {
  final Duration position;
  SeekTo(this.position);

  @override
  List<Object?> get props => [position];
}

class SetPlaylist extends PlayerEvent {
  final List<AudioTask> tasks;
  final int startIndex;
  SetPlaylist({required this.tasks, this.startIndex = 0});

  @override
  List<Object?> get props => [tasks.length, startIndex];
}
