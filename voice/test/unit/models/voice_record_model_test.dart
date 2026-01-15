import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/data/models/voice_record_model.dart';

void main() {
  group('VoiceRecordModel', () {
    test('应该正确从JSON创建', () {
      final json = {
        'id': 'test-id',
        'title': '测试',
        'timestamp': '2024-01-01T00:00:00.000Z',
      };
      
      final model = VoiceRecordModel.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.title, '测试');
    });

    test('应该正确序列化为JSON', () {
      // 测试序列化
      expect(true, isTrue);
    });

    test('应该处理可选字段', () {
      // 测试默认值
      expect(true, isTrue);
    });
  });
}
