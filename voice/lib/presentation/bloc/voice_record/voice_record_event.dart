import 'package:equatable/equatable.dart';
import '../../../domain/entities/voice_record.dart';
import 'voice_record_state.dart';

abstract class VoiceRecordEvent extends Equatable {
  const VoiceRecordEvent();

  @override
  List<Object?> get props => [];
}

/// 加载语音记录事件
class LoadVoiceRecords extends VoiceRecordEvent {
  const LoadVoiceRecords();
}

/// 添加语音记录事件
class AddVoiceRecord extends VoiceRecordEvent {
  final VoiceRecord record;

  const AddVoiceRecord(this.record);

  @override
  List<Object?> get props => [record];
}

/// 更新语音记录事件
class UpdateVoiceRecord extends VoiceRecordEvent {
  final VoiceRecord record;

  const UpdateVoiceRecord(this.record);

  @override
  List<Object?> get props => [record];
}

/// 删除语音记录事件
class DeleteVoiceRecord extends VoiceRecordEvent {
  final String id;

  const DeleteVoiceRecord(this.id);

  @override
  List<Object?> get props => [id];
}

/// 搜索语音记录事件
class SearchVoiceRecords extends VoiceRecordEvent {
  final String query;

  const SearchVoiceRecords(this.query);

  @override
  List<Object?> get props => [query];
}

/// 刷新语音记录事件
class RefreshVoiceRecords extends VoiceRecordEvent {
  const RefreshVoiceRecords();
}

/// 按标签筛选事件
class FilterVoiceRecordsByTag extends VoiceRecordEvent {
  final String? tag; // null means all tags

  const FilterVoiceRecordsByTag(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// 排序事件
class SortVoiceRecords extends VoiceRecordEvent {
  final SortType sortType;

  const SortVoiceRecords(this.sortType);

  @override
  List<Object?> get props => [sortType];
}