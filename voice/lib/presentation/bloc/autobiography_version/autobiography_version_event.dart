import 'package:equatable/equatable.dart';

import '../../../domain/entities/autobiography.dart';

/// 自传版本事件基类
abstract class AutobiographyVersionEvent extends Equatable {
  const AutobiographyVersionEvent();

  @override
  List<Object?> get props => [];
}

/// 保存当前版本
class SaveCurrentVersion extends AutobiographyVersionEvent {
  final Autobiography autobiography;
  final String? customName;

  const SaveCurrentVersion({
    required this.autobiography,
    this.customName,
  });

  @override
  List<Object?> get props => [autobiography, customName];
}

/// 加载版本列表
class LoadVersions extends AutobiographyVersionEvent {
  final String autobiographyId;

  const LoadVersions(this.autobiographyId);

  @override
  List<Object?> get props => [autobiographyId];
}

/// 删除版本
class DeleteVersion extends AutobiographyVersionEvent {
  final String versionId;

  const DeleteVersion(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// 选择版本以恢复
class SelectVersionForRestore extends AutobiographyVersionEvent {
  final String versionId;

  const SelectVersionForRestore(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// 重置状态
class ResetVersionState extends AutobiographyVersionEvent {
  const ResetVersionState();
}
