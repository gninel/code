import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/repositories/autobiography_repository.dart';
import '../../../domain/repositories/voice_record_repository.dart';
import '../../../domain/usecases/recording_usecases.dart';

import 'autobiography_event.dart';
import 'autobiography_state.dart';

@injectable
class AutobiographyBloc extends Bloc<AutobiographyEvent, AutobiographyState> {
  final AutobiographyRepository _repository;
  final VoiceRecordRepository _voiceRecordRepository;
  final RecordingUseCases _recordingUseCases;

  AutobiographyBloc(
    this._repository,
    this._voiceRecordRepository,
    this._recordingUseCases,
  ) : super(const AutobiographyState()) {
    on<LoadAutobiographies>(_onLoadAutobiographies);
    on<AddAutobiography>(_onAddAutobiography);
    on<UpdateAutobiography>(_onUpdateAutobiography);
    on<DeleteAutobiography>(_onDeleteAutobiography);
    on<GenerateAutobiography>(_onGenerateAutobiography);
    on<SearchAutobiographies>(_onSearchAutobiographies);
    on<RefreshAutobiographies>(_onRefreshAutobiographies);
  }

  Future<void> _onLoadAutobiographies(
    LoadAutobiographies event,
    Emitter<AutobiographyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await _repository.getAllAutobiographies();
      result.fold(
        (failure) => emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        )),
        (autobiographies) => emit(state.copyWith(
          isLoading: false,
          autobiographies: autobiographies,
          filteredAutobiographies: autobiographies,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddAutobiography(
    AddAutobiography event,
    Emitter<AutobiographyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _repository.insertAutobiography(event.autobiography);

      // 重新加载记录
      add(const LoadAutobiographies());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '保存自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateAutobiography(
    UpdateAutobiography event,
    Emitter<AutobiographyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _repository.updateAutobiography(event.autobiography);

      // 重新加载记录
      add(const LoadAutobiographies());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '更新自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteAutobiography(
    DeleteAutobiography event,
    Emitter<AutobiographyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _repository.deleteAutobiography(event.id);

      // 重新加载记录
      add(const LoadAutobiographies());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '删除自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onGenerateAutobiography(
    GenerateAutobiography event,
    Emitter<AutobiographyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // 使用录制用例生成自传
      final generatedAutobiography = await _recordingUseCases.generateAutobiographyUseCase
          .call(GenerateAutobiographyParams(
        voiceRecords: event.voiceRecords,
        style: event.style ?? 'default',
      ));

      // 保存生成的自传
      await _repository.insertAutobiography(generatedAutobiography);

      // 重新加载记录
      add(const LoadAutobiographies());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '生成自传失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchAutobiographies(
    SearchAutobiographies event,
    Emitter<AutobiographyState> emit,
  ) async {
    final filteredAutobiographies = state.autobiographies.where((autobiography) {
      return autobiography.title.toLowerCase().contains(event.query.toLowerCase()) ||
             autobiography.content.toLowerCase().contains(event.query.toLowerCase());
    }).toList();

    emit(state.copyWith(
      filteredAutobiographies: filteredAutobiographies,
      searchQuery: event.query,
    ));
  }

  Future<void> _onRefreshAutobiographies(
    RefreshAutobiographies event,
    Emitter<AutobiographyState> emit,
  ) async {
    add(const LoadAutobiographies());
  }
}