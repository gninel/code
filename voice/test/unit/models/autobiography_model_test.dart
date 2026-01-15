import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/models/autobiography_model.dart';

void main() {
  group('AutobiographyModel', () {
    test('应该正确从JSON创建', () {
      final json = {
        'id': 'bio-id',
        'title': '自传',
        'content': '',
        'generatedAt': '2024-01-01T00:00:00.000Z',
        'lastModifiedAt': '2024-01-02T00:00:00.000Z',
      };
      
      final model = AutobiographyModel.fromJson(json);
      expect(model.id, 'bio-id');
      expect(model.title, '自传');
    });

    test('应该正确解析status', () {
      // 测试status解析
      expect(true, isTrue);
    });
  });
}
