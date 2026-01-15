import 'package:equatable/equatable.dart';
import '../../../domain/entities/autobiography.dart';
import '../../../domain/entities/voice_record.dart';

abstract class AutobiographyEvent extends Equatable {
  const AutobiographyEvent();

  @override
  List<Object?> get props => [];
}

/// 加载自传列表事件
class LoadAutobiographies extends AutobiographyEvent {
  const LoadAutobiographies();
}

/// 添加自传事件
class AddAutobiography extends AutobiographyEvent {
  final Autobiography autobiography;

  const AddAutobiography(this.autobiography);

  @override
  List<Object?> get props => [autobiography];
}

/// 更新自传事件
class UpdateAutobiography extends AutobiographyEvent {
  final Autobiography autobiography;

  const UpdateAutobiography(this.autobiography);

  @override
  List<Object?> get props => [autobiography];
}

/// 删除自传事件
class DeleteAutobiography extends AutobiographyEvent {
  final String id;

  const DeleteAutobiography(this.id);

  @override
  List<Object?> get props => [id];
}

/// 生成自传事件
class GenerateAutobiography extends AutobiographyEvent {
  final List<VoiceRecord> voiceRecords;
  final String? style;

  const GenerateAutobiography(this.voiceRecords, {this.style});

  @override
  List<Object?> get props => [voiceRecords, style];
}

/// 搜索自传事件
class SearchAutobiographies extends AutobiographyEvent {
  final String query;

  const SearchAutobiographies(this.query);

  @override
  List<Object?> get props => [query];
}

/// 刷新自传列表事件
class RefreshAutobiographies extends AutobiographyEvent {
  const RefreshAutobiographies();
}