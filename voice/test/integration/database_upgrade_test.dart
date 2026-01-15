import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voice_autobiography_flutter/data/services/database_service.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';

/// 数据库升级回归测试
/// 验证从版本1升级到版本2的数据完整性
void main() {
  // 初始化 FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('数据库升级回归测试 (V1 -> V2)', () {
    late Database database;
    late String dbPath;

    setUp(() async {
      // 创建内存数据库用于测试
      database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbPath = inMemoryDatabasePath;
    });

    tearDown(() async {
      await database.close();
    });

    group('版本1初始化', () {
      test('应该创建版本1的表结构', () async {
        // 模拟版本1的表创建
        await database.execute('''
          CREATE TABLE voice_records (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT DEFAULT '',
            audio_file_path TEXT,
            duration INTEGER DEFAULT 0,
            timestamp INTEGER NOT NULL,
            is_processed INTEGER DEFAULT 0,
            transcription TEXT,
            confidence REAL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('''
          CREATE TABLE autobiographies (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            voice_record_ids TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        // 设置数据库版本为1
        await database.execute('PRAGMA user_version = 1');

        final version = await database.getVersion();
        expect(version, equals(1));

        // 验证表存在
        final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        );

        final tableNames = tables.map((row) => row['name'] as String).toList();
        expect(tableNames, contains('voice_records'));
        expect(tableNames, contains('autobiographies'));
        expect(tableNames, isNot(contains('interview_sessions')));
        expect(tableNames, isNot(contains('interview_questions')));
      });

      test('版本1应该支持插入和查询语音记录', () async {
        // 创建版本1表
        await database.execute('''
          CREATE TABLE voice_records (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT DEFAULT '',
            audio_file_path TEXT,
            duration INTEGER DEFAULT 0,
            timestamp INTEGER NOT NULL,
            is_processed INTEGER DEFAULT 0,
            transcription TEXT,
            confidence REAL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('PRAGMA user_version = 1');

        // 插入测试数据
        await database.insert('voice_records', {
          'id': 'record-1',
          'title': '测试录音',
          'content': '测试内容',
          'audio_file_path': '/path/to/audio.m4a',
          'duration': 5000,
          'timestamp': 1704096000000,
          'is_processed': 0,
          'transcription': '转写文本',
          'confidence': 0.95,
          'created_at': 1704096000000,
        });

        // 查询验证
        final result = await database.query('voice_records');
        expect(result, hasLength(1));
        expect(result.first['title'], equals('测试录音'));
        expect(result.first['content'], equals('测试内容'));
      });
    });

    group('升级到版本2', () {
      test('应该创建新表并保留旧数据', () async {
        // 步骤1: 创建版本1表并插入数据
        await database.execute('''
          CREATE TABLE voice_records (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT DEFAULT '',
            audio_file_path TEXT,
            duration INTEGER DEFAULT 0,
            timestamp INTEGER NOT NULL,
            is_processed INTEGER DEFAULT 0,
            transcription TEXT,
            confidence REAL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('''
          CREATE TABLE autobiographies (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            voice_record_ids TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        // 插入测试数据
        await database.insert('voice_records', {
          'id': 'record-1',
          'title': '录音1',
          'content': '内容1',
          'audio_file_path': '/path/1.m4a',
          'duration': 3000,
          'timestamp': 1704096000000,
          'is_processed': 0,
          'created_at': 1704096000000,
        });

        await database.insert('voice_records', {
          'id': 'record-2',
          'title': '录音2',
          'content': '内容2',
          'audio_file_path': '/path/2.m4a',
          'duration': 7000,
          'timestamp': 1704097000000,
          'is_processed': 1,
          'created_at': 1704097000000,
        });

        await database.insert('autobiographies', {
          'id': 'auto-1',
          'title': '自传1',
          'content': '自传内容',
          'voice_record_ids': 'record-1,record-2',
          'created_at': 1704096000000,
        });

        await database.execute('PRAGMA user_version = 1');

        // 步骤2: 执行升级
        await database.execute('''
          CREATE TABLE interview_sessions (
            id TEXT PRIMARY KEY,
            current_question_index INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('''
          CREATE TABLE interview_questions (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT,
            order_index INTEGER NOT NULL DEFAULT 0,
            is_answered INTEGER NOT NULL DEFAULT 0,
            is_skipped INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            audio_file_path TEXT,
            duration INTEGER DEFAULT 0,
            FOREIGN KEY (session_id) REFERENCES interview_sessions (id) ON DELETE CASCADE
          )
        ''');

        // 创建索引
        await database.execute('''
          CREATE INDEX idx_interview_questions_session_id
          ON interview_questions(session_id)
        ''');

        await database.execute('''
          CREATE INDEX idx_interview_sessions_active
          ON interview_sessions(is_active)
        ''');

        await database.execute('PRAGMA user_version = 2');

        // 步骤3: 验证数据完整性
        final version = await database.getVersion();
        expect(version, equals(2));

        // 验证所有表都存在
        final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        );
        final tableNames = tables.map((row) => row['name'] as String).toList();

        expect(tableNames, contains('voice_records'));
        expect(tableNames, contains('autobiographies'));
        expect(tableNames, contains('interview_sessions'));
        expect(tableNames, contains('interview_questions'));

        // 验证旧数据完整保留
        final voiceRecords = await database.query('voice_records');
        expect(voiceRecords, hasLength(2));
        expect(voiceRecords[0]['title'], equals('录音1'));
        expect(voiceRecords[1]['title'], equals('录音2'));

        final autobiographies = await database.query('autobiographies');
        expect(autobiographies, hasLength(1));
        expect(autobiographies.first['title'], equals('自传1'));

        // 验证新表可以正常使用
        await database.insert('interview_sessions', {
          'id': 'session-1',
          'current_question_index': 0,
          'is_active': 1,
          'created_at': 1704096000000,
        });

        await database.insert('interview_questions', {
          'id': 'q1',
          'session_id': 'session-1',
          'question': '测试问题',
          'order_index': 0,
          'created_at': 1704096000000,
        });

        final sessions = await database.query('interview_sessions');
        expect(sessions, hasLength(1));

        final questions = await database.query('interview_questions');
        expect(questions, hasLength(1));
        expect(questions.first['question'], equals('测试问题'));
      });
    });

    group('版本2功能测试', () {
      setUp(() async {
        // 创建完整的版本2数据库
        await database.execute('''
          CREATE TABLE voice_records (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT DEFAULT '',
            audio_file_path TEXT,
            duration INTEGER DEFAULT 0,
            timestamp INTEGER NOT NULL,
            is_processed INTEGER DEFAULT 0,
            transcription TEXT,
            confidence REAL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('''
          CREATE TABLE autobiographies (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            voice_record_ids TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('''
          CREATE TABLE interview_sessions (
            id TEXT PRIMARY KEY,
            current_question_index INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await database.execute('''
          CREATE TABLE interview_questions (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT,
            order_index INTEGER NOT NULL DEFAULT 0,
            is_answered INTEGER NOT NULL DEFAULT 0,
            is_skipped INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            audio_file_path TEXT,
            duration INTEGER DEFAULT 0,
            FOREIGN KEY (session_id) REFERENCES interview_sessions (id) ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE INDEX idx_interview_questions_session_id
          ON interview_questions(session_id)
        ''');

        await database.execute('''
          CREATE INDEX idx_interview_sessions_active
          ON interview_sessions(is_active)
        ''');

        await database.execute('PRAGMA user_version = 2');
      });

      test('应该支持完整的采访会话CRUD操作', () async {
        // 创建采访会话
        const sessionId = 'session-test-1';
        await database.insert('interview_sessions', {
          'id': sessionId,
          'current_question_index': 0,
          'is_active': 1,
          'created_at': 1704096000000,
          'updated_at': 1704096000000,
        });

        // 添加多个问题
        await database.insert('interview_questions', {
          'id': 'q1',
          'session_id': sessionId,
          'question': '第一个问题',
          'order_index': 0,
          'is_answered': 0,
          'is_skipped': 0,
          'created_at': 1704096000000,
        });

        await database.insert('interview_questions', {
          'id': 'q2',
          'session_id': sessionId,
          'question': '第二个问题',
          'order_index': 1,
          'is_answered': 0,
          'is_skipped': 0,
          'created_at': 1704096000000,
        });

        // 查询会话及其问题
        final sessions = await database.query(
          'interview_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        expect(sessions, hasLength(1));

        final questions = await database.query(
          'interview_questions',
          where: 'session_id = ?',
          whereArgs: [sessionId],
          orderBy: 'order_index',
        );
        expect(questions, hasLength(2));

        // 更新问题回答
        await database.update(
          'interview_questions',
          {
            'answer': '我的回答',
            'is_answered': 1,
          },
          where: 'id = ?',
          whereArgs: ['q1'],
        );

        // 更新会话进度
        await database.update(
          'interview_sessions',
          {
            'current_question_index': 1,
            'updated_at': 1704097000000,
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );

        // 验证更新
        final updatedQuestions = await database.query(
          'interview_questions',
          where: 'id = ?',
          whereArgs: ['q1'],
        );
        expect(updatedQuestions.first['answer'], equals('我的回答'));
        expect(updatedQuestions.first['is_answered'], equals(1));
      });

      test('应该支持级联删除', () async {
        // 创建会话和问题
        const sessionId = 'session-cascade';
        await database.insert('interview_sessions', {
          'id': sessionId,
          'current_question_index': 0,
          'is_active': 1,
          'created_at': 1704096000000,
        });

        await database.insert('interview_questions', {
          'id': 'q-cascade',
          'session_id': sessionId,
          'question': '问题',
          'order_index': 0,
          'created_at': 1704096000000,
        });

        // 删除会话
        await database.delete(
          'interview_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
        );

        // 验证问题也被删除（通过外键约束）
        final questions = await database.query(
          'interview_questions',
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
        expect(questions, isEmpty);
      });

      test('索引应该正常工作', () async {
        // 插入多个会话
        for (var i = 0; i < 10; i++) {
          await database.insert('interview_sessions', {
            'id': 'session-$i',
            'current_question_index': 0,
            'is_active': i % 2 == 0 ? 1 : 0, // 一半活跃，一半不活跃
            'created_at': 1704096000000 + i * 1000,
          });
        }

        // 使用索引查询活跃会话
        final activeSessions = await database.query(
          'interview_sessions',
          where: 'is_active = ?',
          whereArgs: [1],
        );
        expect(activeSessions, hasLength(5));

        // 使用索引查询特定会话的问题
        const sessionId = 'session-0';
        for (var i = 0; i < 5; i++) {
          await database.insert('interview_questions', {
            'id': 'q-$i',
            'session_id': sessionId,
            'question': '问题$i',
            'order_index': i,
            'created_at': 1704096000000,
          });
        }

        final questions = await database.query(
          'interview_questions',
          where: 'session_id = ?',
          whereArgs: [sessionId],
          orderBy: 'order_index',
        );
        expect(questions, hasLength(5));
      });
    });
  });

  group('DatabaseService集成测试', () {
    late DatabaseService dbService;

    setUp(() async {
      // 使用临时数据库路径
      dbService = DatabaseService.forTesting();
      await dbService.database;
    });

    tearDown(() async {
      await dbService.close();
    });

    test('新安装应该创建版本2数据库', () async {
      final db = await dbService.database;
      final version = await db.getVersion();

      expect(version, equals(AppConstants.databaseVersion));

      // 验证所有表存在
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tables.map((row) => row['name'] as String).toList();

      for (final tableName in DatabaseTables.tables) {
        expect(tableNames, contains(tableName));
      }
    });

    test('应该支持语音记录和采访数据的协同操作', () async {
      final db = await dbService.database;

      // 插入语音记录
      await db.insert('voice_records', {
        'id': 'record-integration',
        'title': '集成测试录音',
        'content': '内容',
        'audio_file_path': '/path.m4a',
        'duration': 5000,
        'timestamp': 1704096000000,
        'is_processed': 0,
        'created_at': 1704096000000,
      });

      // 创建采访会话
      const sessionId = 'session-integration';
      await db.insert('interview_sessions', {
        'id': sessionId,
        'current_question_index': 0,
        'is_active': 1,
        'created_at': 1704096000000,
      });

      // 添加关联问题
      await db.insert('interview_questions', {
        'id': 'q-integration',
        'session_id': sessionId,
        'question': '请讲述您的人生经历',
        'answer': '这是我的回答',
        'order_index': 0,
        'is_answered': 1,
        'audio_file_path': '/path.m4a',
        'duration': 5000,
        'created_at': 1704096000000,
      });

      // 验证数据关联
      final records = await db.query('voice_records');
      expect(records, hasLength(1));

      final sessions = await db.query('interview_sessions');
      expect(sessions, hasLength(1));

      final questions = await db.query('interview_questions');
      expect(questions, hasLength(1));
    });
  });
}
