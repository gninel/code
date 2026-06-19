import 'package:equatable/equatable.dart';
import '../../models/audio_task.dart';

abstract class LibraryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<AudioTask> audios;
  LibraryLoaded(this.audios);

  @override
  List<Object?> get props => [audios.length];
}

class LibraryError extends LibraryState {
  final String message;
  LibraryError(this.message);

  @override
  List<Object?> get props => [message];
}
