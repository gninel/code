import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/usecases/autobiography_version_usecases.dart';
import 'autobiography_version_event.dart';
import 'autobiography_version_state.dart';

/// 自传版本BLoC
@injectable
class AutobiographyVersionBloc
    extends Bloc<AutobiographyVersionEvent, AutobiographyVersionState> {
  final AutobiographyVersionUseCases _versionUseCases;

  AutobiographyVersionBloc(this._versionUseCases)
      : super(const AutobiographyVersionState()) {
    on<SaveCurrentVersion>(_onSaveCurrentVersion);
    on<LoadVersions>(_onLoadVersions);
    on<DeleteVersion>(_onDeleteVersion);
    on<SelectVersionForRestore>(_onSelectVersionForRestore);
    on<ResetVersionState>(_onResetVersionState);
  }

  Future<void> _onSaveCurrentVersion(
    SaveCurrentVersion event,
    Emitter<AutobiographyVersionState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));

    final result = await _versionUseCases.saveCurrentAsVersion(
      autobiography: event.autobiography,
      customName: event.customName,
    );

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: '保存版本失败: ${failure.message}',
        ));
      },
      (version) async {
        // 保存成功后重新加载版本列表
        final versionsResult = await _versionUseCases.getVersionsForAutobiography(
          autobiographyId: event.autobiography.id,
        );

        // 确保在异步操作完成后检查emit状态
        if (!emit.isDone) {
          versionsResult.fold(
            (failure) {
              emit(state.copyWith(
                isSaving: false,
                successMessage: '版本已保存',
              ));
            },
            (versions) {
              emit(state.copyWith(
                isSaving: false,
                versions: versions,
                versionCount: versions.length,
                successMessage: '版本已保存',
              ));
            },
          );
        }
      },
    );
  }

  Future<void> _onLoadVersions(
    LoadVersions event,
    Emitter<AutobiographyVersionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _versionUseCases.getVersionsForAutobiography(
      autobiographyId: event.autobiographyId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: '加载版本列表失败: ${failure.message}',
        ));
      },
      (versions) {
        emit(state.copyWith(
          isLoading: false,
          versions: versions,
          versionCount: versions.length,
        ));
      },
    );
  }

  Future<void> _onDeleteVersion(
    DeleteVersion event,
    Emitter<AutobiographyVersionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _versionUseCases.deleteVersion(
      versionId: event.versionId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: '删除版本失败: ${failure.message}',
        ));
      },
      (_) {
        // 删除成功后更新列表
        final updatedVersions = state.versions
            .where((version) => version.id != event.versionId)
            .toList();

        emit(state.copyWith(
          isLoading: false,
          versions: updatedVersions,
          versionCount: updatedVersions.length,
          successMessage: '版本已删除',
        ));
      },
    );
  }

  Future<void> _onSelectVersionForRestore(
    SelectVersionForRestore event,
    Emitter<AutobiographyVersionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _versionUseCases.getVersionDetail(
      versionId: event.versionId,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: '获取版本详情失败: ${failure.message}',
        ));
      },
      (version) {
        emit(state.copyWith(
          isLoading: false,
          selectedVersion: version,
        ));
      },
    );
  }

  Future<void> _onResetVersionState(
    ResetVersionState event,
    Emitter<AutobiographyVersionState> emit,
  ) async {
    emit(const AutobiographyVersionState());
  }
}
