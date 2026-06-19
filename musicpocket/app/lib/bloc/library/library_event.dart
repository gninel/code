import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class LoadFavorites extends LibraryEvent {}

class ToggleFavorite extends LibraryEvent {
  final String taskId;
  ToggleFavorite(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class DeleteAudio extends LibraryEvent {
  final String taskId;
  DeleteAudio(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class SearchLibrary extends LibraryEvent {
  final String query;
  SearchLibrary(this.query);

  @override
  List<Object?> get props => [query];
}
