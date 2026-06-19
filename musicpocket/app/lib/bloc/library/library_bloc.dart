import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/local_storage_service.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LocalStorageService storage;

  LibraryBloc({required this.storage}) : super(LibraryInitial()) {
    on<LoadLibrary>(_onLoad);
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DeleteAudio>(_onDelete);
    on<SearchLibrary>(_onSearch);
  }

  Future<void> _onLoad(LoadLibrary event, Emitter<LibraryState> emit) async {
    emit(LibraryLoading());
    try {
      final audios = await storage.getAllAudios();
      emit(LibraryLoaded(audios));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> _onLoadFavorites(LoadFavorites event, Emitter<LibraryState> emit) async {
    emit(LibraryLoading());
    try {
      final audios = await storage.getFavorites();
      emit(LibraryLoaded(audios));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(ToggleFavorite event, Emitter<LibraryState> emit) async {
    await storage.toggleFavorite(event.taskId);
    add(LoadLibrary());
  }

  Future<void> _onDelete(DeleteAudio event, Emitter<LibraryState> emit) async {
    await storage.deleteAudio(event.taskId);
    add(LoadLibrary());
  }

  Future<void> _onSearch(SearchLibrary event, Emitter<LibraryState> emit) async {
    emit(LibraryLoading());
    try {
      final audios = await storage.searchAudios(event.query);
      emit(LibraryLoaded(audios));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }
}
