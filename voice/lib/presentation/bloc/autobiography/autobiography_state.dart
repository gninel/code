import 'package:equatable/equatable.dart';
import '../../../domain/entities/autobiography.dart';

class AutobiographyState extends Equatable {
  final List<Autobiography> autobiographies;
  final List<Autobiography> filteredAutobiographies;
  final String? searchQuery;
  final bool isLoading;
  final String? error;

  const AutobiographyState({
    this.autobiographies = const [],
    this.filteredAutobiographies = const [],
    this.searchQuery,
    this.isLoading = false,
    this.error,
  });

  AutobiographyState copyWith({
    List<Autobiography>? autobiographies,
    List<Autobiography>? filteredAutobiographies,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return AutobiographyState(
      autobiographies: autobiographies ?? this.autobiographies,
      filteredAutobiographies: filteredAutobiographies ?? this.filteredAutobiographies,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        autobiographies,
        filteredAutobiographies,
        searchQuery,
        isLoading,
        error,
      ];
}