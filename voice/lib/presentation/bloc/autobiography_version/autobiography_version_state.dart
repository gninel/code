import 'package:equatable/equatable.dart';

import '../../../domain/entities/autobiography_version.dart';

/// 自传版本状态
class AutobiographyVersionState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<AutobiographyVersion> versions;
  final AutobiographyVersion? selectedVersion;
  final String? errorMessage;
  final String? successMessage;
  final int versionCount;

  const AutobiographyVersionState({
    this.isLoading = false,
    this.isSaving = false,
    this.versions = const [],
    this.selectedVersion,
    this.errorMessage,
    this.successMessage,
    this.versionCount = 0,
  });

  bool get hasVersions => versions.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;

  AutobiographyVersionState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<AutobiographyVersion>? versions,
    AutobiographyVersion? selectedVersion,
    String? errorMessage,
    String? successMessage,
    int? versionCount,
  }) {
    return AutobiographyVersionState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      versions: versions ?? this.versions,
      selectedVersion: selectedVersion ?? this.selectedVersion,
      errorMessage: errorMessage,
      successMessage: successMessage,
      versionCount: versionCount ?? this.versionCount,
    );
  }

  AutobiographyVersionState clearMessages() {
    return copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        versions,
        selectedVersion,
        errorMessage,
        successMessage,
        versionCount,
      ];
}
