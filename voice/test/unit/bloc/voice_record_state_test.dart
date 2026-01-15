// VoiceRecord Bloc 状态测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_state.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';

void main() {
  group('VoiceRecordState', () {
    test('初始状态应该是空的', () {
      const state = VoiceRecordState();
      expect(state.records, isEmpty);
      expect(state.filteredRecords, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.sortType, SortType.dateDesc);
    });

    test('copyWith 应该正确复制并修改属性', () {
      final now = DateTime.now();
      final records = [
        VoiceRecord(id: '1', title: '录音1', timestamp: now),
        VoiceRecord(id: '2', title: '录音2', timestamp: now),
      ];

      const state = VoiceRecordState();
      final updated = state.copyWith(
        records: records,
        isLoading: true,
      );

      expect(updated.records.length, 2);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clearSelectedTag 应该清除标签', () {
      const state = VoiceRecordState(selectedTag: '标签1');
      final updated = state.copyWith(clearSelectedTag: true);
      expect(updated.selectedTag, isNull);
    });

    test('copyWith clearError 应该清除错误', () {
      const state = VoiceRecordState(error: '错误信息');
      final updated = state.copyWith(clearError: true);
      expect(updated.error, isNull);
    });

    test('allTags 应该返回所有唯一标签并排序', () {
      final now = DateTime.now();
      final records = [
        VoiceRecord(id: '1', title: '录音1', timestamp: now, tags: const ['工作', '童年']),
        VoiceRecord(id: '2', title: '录音2', timestamp: now, tags: const ['童年', '家庭']),
      ];

      final state = VoiceRecordState(records: records);
      final tags = state.allTags;

      expect(tags.length, 3);
      expect(tags[0], '家庭');
      expect(tags[1], '工作');
      expect(tags[2], '童年');
    });
  });

  group('SortType', () {
    test('所有排序类型应该存在', () {
      expect(SortType.values.length, 4);
      expect(SortType.values, contains(SortType.dateDesc));
      expect(SortType.values, contains(SortType.dateAsc));
      expect(SortType.values, contains(SortType.durationDesc));
      expect(SortType.values, contains(SortType.durationAsc));
    });
  });
}
