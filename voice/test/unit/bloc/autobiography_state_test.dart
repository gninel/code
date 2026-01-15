// Autobiography Bloc 状态测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_state.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';

void main() {
  group('AutobiographyState', () {
    test('初始状态应该是空的', () {
      const state = AutobiographyState();
      expect(state.autobiographies, isEmpty);
      expect(state.filteredAutobiographies, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.searchQuery, isNull);
    });

    test('copyWith 应该正确复制并修改属性', () {
      final now = DateTime.now();
      final autobiographies = [
        Autobiography(
          id: '1',
          title: '自传1',
          content: '内容1',
          generatedAt: now,
          lastModifiedAt: now,
        ),
        Autobiography(
          id: '2',
          title: '自传2',
          content: '内容2',
          generatedAt: now,
          lastModifiedAt: now,
        ),
      ];

      const state = AutobiographyState();
      final updated = state.copyWith(
        autobiographies: autobiographies,
        isLoading: true,
      );

      expect(updated.autobiographies.length, 2);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith 应该保持未修改的属性', () {
      final now = DateTime.now();
      final autobiography = Autobiography(
        id: '1',
        title: '自传',
        content: '内容',
        generatedAt: now,
        lastModifiedAt: now,
      );

      final state = AutobiographyState(
        autobiographies: [autobiography],
        searchQuery: '搜索词',
        isLoading: false,
      );

      final updated = state.copyWith(error: '新错误');

      expect(updated.autobiographies.length, 1);
      expect(updated.searchQuery, '搜索词');
      expect(updated.isLoading, isFalse);
      expect(updated.error, '新错误');
    });

    test('props 应该包含所有字段', () {
      const state1 = AutobiographyState(searchQuery: '查询1');
      const state2 = AutobiographyState(searchQuery: '查询1');
      const state3 = AutobiographyState(searchQuery: '查询2');

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
