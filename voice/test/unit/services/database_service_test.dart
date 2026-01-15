import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';
import 'package:voice_autobiography_flutter/data/services/database_service.dart';

void main() {
  late DatabaseService service;

  // 初始化 sqflite_ffi
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // 使用测试专用的内存数据库
    service = DatabaseService.forTesting();
  });

  tearDown(() async {
    await service.close();
  });

  group('DatabaseService - 表创建', () {
    test('_onCreate - 创建voice_records表', () async {
      final db = await service.database;

      // 验证表存在
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='voice_records'",
      );
      expect(tables.length, equals(1));
    });

    test('_onCreate - 创建autobiographies表', () async {
      final db = await service.database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='autobiographies'",
      );
      expect(tables.length, equals(1));
    });

    test('_onCreate - 创建settings表', () async {
      final db = await service.database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
      );
      expect(tables.length, equals(1));
    });

    test('_onCreate - 创建interview_sessions表', () async {
      final db = await service.database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='interview_sessions'",
      );
      expect(tables.length, equals(1));
    });

    test('_onCreate - 创建所有索引', () async {
      final db = await service.database;

      // 验证索引存在
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      expect(indexes.length, greaterThan(0));
    });
  });

  group('DatabaseService - CRUD操作', () {
    test('insert - 插入语音记录', () async {
      final id = await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试录音',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      expect(id, greaterThan(0));
    });

    test('query - 查询所有记录', () async {
      // 插入测试数据
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试录音1',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await service.insert('voice_records', {
        'id': 'test_id_2',
        'title': '测试录音2',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final records = await service.query('voice_records');
      expect(records.length, equals(2));
    });

    test('query - 条件查询(where, orderBy, limit)', () async {
      // 插入测试数据
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '录音A',
        'timestamp': 1000,
      });
      await service.insert('voice_records', {
        'id': 'test_id_2',
        'title': '录音B',
        'timestamp': 2000,
      });
      await service.insert('voice_records', {
        'id': 'test_id_3',
        'title': '录音C',
        'timestamp': 3000,
      });

      // 条件查询
      final records = await service.query(
        'voice_records',
        where: 'timestamp > ?',
        whereArgs: [1500],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      expect(records.length, equals(1));
      expect(records.first['id'], equals('test_id_3'));
    });

    test('querySingle - 查询单条记录', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试录音',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      expect(record, isNotNull);
      expect(record!['title'], equals('测试录音'));
    });

    test('update - 更新记录', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '原标题',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final updatedCount = await service.update(
        'voice_records',
        {'title': '新标题'},
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      expect(updatedCount, equals(1));

      final record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );
      expect(record!['title'], equals('新标题'));
    });

    test('delete - 删除记录', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '待删除',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final deletedCount = await service.delete(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      expect(deletedCount, equals(1));

      final record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );
      expect(record, isNull);
    });
  });

  group('DatabaseService - 事务处理', () {
    test('transaction - 批量插入成功提交', () async {
      await service.transaction((txn) async {
        await txn.insert('voice_records', {
          'id': 'test_id_1',
          'title': '录音1',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        await txn.insert('voice_records', {
          'id': 'test_id_2',
          'title': '录音2',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      });

      final records = await service.query('voice_records');
      expect(records.length, equals(2));
    });

    test('transaction - 操作失败时回滚', () async {
      try {
        await service.transaction((txn) async {
          await txn.insert('voice_records', {
            'id': 'test_id_1',
            'title': '录音1',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

          // 插入重复ID，应该失败
          await txn.insert('voice_records', {
            'id': 'test_id_1',
            'title': '录音2',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
        });
        fail('应该抛出异常');
      } catch (e) {
        // 事务回滚，不应该有任何记录
        final records = await service.query('voice_records');
        expect(records.length, equals(0));
      }
    });
  });

  group('DatabaseService - 工具方法', () {
    test('getCount - 获取记录数', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '录音1',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await service.insert('voice_records', {
        'id': 'test_id_2',
        'title': '录音2',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final count = await service.getCount('voice_records');
      expect(count, equals(2));
    });

    test('getCount - 条件计数', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '录音A',
        'timestamp': 1000,
      });
      await service.insert('voice_records', {
        'id': 'test_id_2',
        'title': '录音B',
        'timestamp': 2000,
      });

      final count = await service.getCount(
        'voice_records',
        where: 'timestamp > ?',
        whereArgs: [1500],
      );
      expect(count, equals(1));
    });

    test('clearTable - 清空表', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '录音1',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await service.clearTable('voice_records');

      final count = await service.getCount('voice_records');
      expect(count, equals(0));
    });

    test('rawQuery - 执行原始查询', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final results = await service.rawQuery(
        'SELECT * FROM voice_records WHERE id = ?',
        ['test_id_1'],
      );

      expect(results.length, equals(1));
    });

    test('rawUpdate - 执行原始更新', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '原标题',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final count = await service.rawUpdate(
        'UPDATE voice_records SET title = ? WHERE id = ?',
        ['新标题', 'test_id_1'],
      );

      expect(count, equals(1));
    });
  });

  group('DatabaseService - 时间戳', () {
    test('insert - 自动添加created_at和updated_at', () async {
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      expect(record!['created_at'], isNotNull);
      expect(record['updated_at'], isNotNull);
    });

    test('update - 自动更新updated_at', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试',
        'timestamp': now,
      });

      // 等待一小会儿
      await Future.delayed(const Duration(milliseconds: 10));

      await service.update(
        'voice_records',
        {'title': '更新'},
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      final record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      // updated_at 应该比 created_at 大
      expect(record!['updated_at'], greaterThanOrEqualTo(record['created_at']));
    });
  });

  group('DatabaseService - 完整CRUD流程', () {
    test('真实CRUD流程', () async {
      // 1. 插入
      await service.insert('voice_records', {
        'id': 'test_id_1',
        'title': '测试录音',
        'content': '这是内容',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // 2. 查询
      var record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );
      expect(record, isNotNull);
      expect(record!['title'], equals('测试录音'));

      // 3. 更新
      await service.update(
        'voice_records',
        {'title': '更新后的标题', 'content': '更新后的内容'},
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );
      expect(record!['title'], equals('更新后的标题'));
      expect(record['content'], equals('更新后的内容'));

      // 4. 删除
      await service.delete(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );

      record = await service.querySingle(
        'voice_records',
        where: 'id = ?',
        whereArgs: ['test_id_1'],
      );
      expect(record, isNull);
    });
  });

  group('DatabaseService - 数据完整性', () {
    test('删除记录后不影响其他记录', () async {
      // 插入两条自传记录
      await service.insert('autobiographies', {
        'id': 'auto_1',
        'title': '我的自传',
        'content': '内容',
        'generated_at': DateTime.now().millisecondsSinceEpoch,
        'last_modified_at': DateTime.now().millisecondsSinceEpoch,
      });

      await service.insert('autobiographies', {
        'id': 'auto_2',
        'title': '另一篇自传',
        'content': '内容',
        'generated_at': DateTime.now().millisecondsSinceEpoch,
        'last_modified_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 删除第一条
      await service.delete(
        'autobiographies',
        where: 'id = ?',
        whereArgs: ['auto_1'],
      );

      // 验证第二条仍然存在
      final remaining = await service.query(
        'autobiographies',
        where: 'id = ?',
        whereArgs: ['auto_2'],
      );
      expect(remaining.length, equals(1));
      expect(remaining.first['title'], equals('另一篇自传'));
    });
  });
}
