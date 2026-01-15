import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/voice_record.dart';
import '../../../domain/repositories/voice_record_repository.dart';
import '../../../domain/usecases/recording_usecases.dart';
import '../../../data/services/auto_tagger_service.dart';

import 'voice_record_event.dart';
import 'voice_record_state.dart';

@injectable
class VoiceRecordBloc extends Bloc<VoiceRecordEvent, VoiceRecordState> {
  final VoiceRecordRepository _repository;
  final RecordingUseCases _recordingUseCases;
  final AutoTaggerService _autoTaggerService;

  VoiceRecordBloc(
    this._repository,
    this._recordingUseCases,
    this._autoTaggerService,
  ) : super(const VoiceRecordState()) {
    on<LoadVoiceRecords>(_onLoadVoiceRecords);
    on<AddVoiceRecord>(_onAddVoiceRecord);
    on<UpdateVoiceRecord>(_onUpdateVoiceRecord);
    on<DeleteVoiceRecord>(_onDeleteVoiceRecord);
    on<SearchVoiceRecords>(_onSearchVoiceRecords);
    on<FilterVoiceRecordsByTag>(_onFilterVoiceRecordsByTag);
    on<SortVoiceRecords>(_onSortVoiceRecords);
  }

  Future<void> _onLoadVoiceRecords(
    LoadVoiceRecords event,
    Emitter<VoiceRecordState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await _repository.getAllVoiceRecords();
      result.fold(
        (failure) => emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        )),
        (records) {
          final newState = state.copyWith(
            isLoading: false,
            records: records,
          );
          emit(newState.copyWith(
            filteredRecords: _applyFiltersAndSort(newState),
          ));
          
          // 后台执行自动打标签
          _autoTagRecords(records, emit);
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载语音记录失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddVoiceRecord(
    AddVoiceRecord event,
    Emitter<VoiceRecordState> emit,
  ) async {
    print('VoiceRecordBloc: _onAddVoiceRecord called for ${event.record.id}');
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await _repository.insertVoiceRecord(event.record);
      result.fold(
        (failure) {
          print('VoiceRecordBloc: Insert failed: ${failure.message}');
          emit(state.copyWith(
            isLoading: false,
            error: failure.message,
          ));
        },
        (_) {
          print('VoiceRecordBloc: Insert succeeded, loading records');
          add(const LoadVoiceRecords());
        },
      );
    } catch (e) {
      print('VoiceRecordBloc: Exception: $e');
      emit(state.copyWith(
        isLoading: false,
        error: '保存语音记录失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateVoiceRecord(
    UpdateVoiceRecord event,
    Emitter<VoiceRecordState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await _repository.updateVoiceRecord(event.record);
      result.fold(
        (failure) => emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        )),
        (_) => add(const LoadVoiceRecords()),
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '更新语音记录失败: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteVoiceRecord(
    DeleteVoiceRecord event,
    Emitter<VoiceRecordState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await _repository.deleteVoiceRecord(event.id);
      result.fold(
        (failure) => emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        )),
        (_) => add(const LoadVoiceRecords()),
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '删除语音记录失败: ${e.toString()}',
      ));
    }
  }

  void _onSearchVoiceRecords(
    SearchVoiceRecords event,
    Emitter<VoiceRecordState> emit,
  ) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(
      filteredRecords: _applyFiltersAndSort(newState),
    ));
  }

  void _onFilterVoiceRecordsByTag(
    FilterVoiceRecordsByTag event,
    Emitter<VoiceRecordState> emit,
  ) {
    final newState = state.copyWith(
      selectedTag: event.tag,
      clearSelectedTag: event.tag == null,
    );
    
    emit(newState.copyWith(
      filteredRecords: _applyFiltersAndSort(newState),
    ));
  }
  
  // Wait, I can't write the implementation of _onFilterVoiceRecordsByTag correctly if copyWith is broken.
  // I should probably fix copyWith first.
  // But I am already in this tool call.
  // I will write the logic to use a custom copyWith-like construction if needed, or just ignore the null issue for a moment and fix it immediately after.
  // Actually, looking at my previous `VoiceRecordState` code:
  // `selectedTag: selectedTag ?? this.selectedTag`
  // Yes, it prevents clearing.
  
  // I will implement the method structure now and fix the nullability issue in the next step.
  
  void _onSortVoiceRecords(
    SortVoiceRecords event,
    Emitter<VoiceRecordState> emit,
  ) {
    final newState = state.copyWith(sortType: event.sortType);
    emit(newState.copyWith(
      filteredRecords: _applyFiltersAndSort(newState),
    ));
  }

  Future<void> _onRefreshVoiceRecords(
    RefreshVoiceRecords event,
    Emitter<VoiceRecordState> emit,
  ) async {
    add(const LoadVoiceRecords());
  }

  List<VoiceRecord> _applyFiltersAndSort(VoiceRecordState currentState) {
    var filtered = List<VoiceRecord>.from(currentState.records);

    // 1. Apply Search
    if (currentState.searchQuery != null && currentState.searchQuery!.isNotEmpty) {
      final query = currentState.searchQuery!.toLowerCase();
      filtered = filtered.where((record) {
        return record.title.toLowerCase().contains(query) ||
               (record.transcription?.toLowerCase().contains(query) ?? false) ||
               record.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // 2. Apply Tag Filter
    if (currentState.selectedTag != null) {
      filtered = filtered.where((record) {
        return record.tags.contains(currentState.selectedTag);
      }).toList();
    }

    // 3. Apply Sort
    switch (currentState.sortType) {
      case SortType.dateDesc:
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortType.dateAsc:
        filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortType.durationDesc:
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case SortType.durationAsc:
        filtered.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }

    return filtered;
  }

  Future<void> _autoTagRecords(
    List<VoiceRecord> records,
    Emitter<VoiceRecordState> emit,
  ) async {
    bool hasUpdates = false;
    final updatedRecords = List<VoiceRecord>.from(records);
    
    for (int i = 0; i < updatedRecords.length; i++) {
        final record = updatedRecords[i];
        // 如果没有标签且有转写内容，则尝试自动生成标签
        if (record.tags.isEmpty && record.transcription != null && record.transcription!.isNotEmpty && record.transcription!.length > 10) {
             try {
               final tags = await _autoTaggerService.generateTags(record.transcription!);
               if (tags.isNotEmpty) {
                   final updatedRecord = record.copyWith(tags: tags);
                   // 更新数据库
                   await _repository.updateVoiceRecord(updatedRecord);
                   // 更新本地列表
                   updatedRecords[i] = updatedRecord;
                   hasUpdates = true;
                   print('AutoTagger: Tagged record ${record.id} with $tags');
               }
             } catch (e) {
               print('AutoTagger: Failed to tag record ${record.id}: $e');
             }
        }
    }
    
    if (hasUpdates) {
        // 更新状态以显示新标签
        if (!emit.isDone) {
           final postTagState = state.copyWith(records: updatedRecords);
           emit(postTagState.copyWith(
             filteredRecords: _applyFiltersAndSort(postTagState),
           ));
        }
    }
  }
}