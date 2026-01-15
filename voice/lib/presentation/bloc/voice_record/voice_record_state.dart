import 'package:equatable/equatable.dart';
import '../../../domain/entities/voice_record.dart';

enum SortType {
  dateDesc,
  dateAsc,
  durationDesc,
  durationAsc,
}

class VoiceRecordState extends Equatable {
  final List<VoiceRecord> records;
  final List<VoiceRecord> filteredRecords;
  final String? searchQuery;
  final String? selectedTag;
  final SortType sortType;
  final bool isLoading;
  final String? error;

  const VoiceRecordState({
    this.records = const [],
    this.filteredRecords = const [],
    this.searchQuery,
    this.selectedTag,
    this.sortType = SortType.dateDesc,
    this.isLoading = false,
    this.error,
  });

  VoiceRecordState copyWith({
    List<VoiceRecord>? records,
    List<VoiceRecord>? filteredRecords,
    String? searchQuery,
    String? selectedTag,
    bool clearSelectedTag = false, // Add flag to clear selectedTag
    bool clearError = false, // Add flag to clear error
    SortType? sortType,
    bool? isLoading,
    String? error,
  }) {
    return VoiceRecordState(
      records: records ?? this.records,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      sortType: sortType ?? this.sortType,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        records,
        filteredRecords,
        searchQuery,
        selectedTag,
        sortType,
        isLoading,
        error,
      ];
  
  // Helper to get all unique tags from records
  List<String> get allTags {
    final tags = <String>{};
    for (var record in records) {
      tags.addAll(record.tags);
    }
    return tags.toList()..sort();
  }
}