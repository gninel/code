import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// 数据库服务
@singleton
class DatabaseService {
  static Database? _database;

  /// 测试模式构造函数
  /// 创建使用内存数据库的实例用于测试
  factory DatabaseService.forTesting() {
    return _TestingDatabaseService();
  }

  // 默认构造函数用于依赖注入
  DatabaseService();

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException.insertFailed();
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    try {
      // 创建语音记录表
      await db.execute('''
        CREATE TABLE ${DatabaseTables.voiceRecords} (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT DEFAULT '',
          audio_file_path TEXT,
          duration INTEGER DEFAULT 0,
          timestamp INTEGER NOT NULL,
          is_processed INTEGER DEFAULT 0,
          tags TEXT DEFAULT '[]',
          transcription TEXT,
          confidence REAL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // 创建自传表
      await db.execute('''
        CREATE TABLE ${DatabaseTables.autobiographies} (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          generated_at INTEGER NOT NULL,
          last_modified_at INTEGER NOT NULL,
          version INTEGER DEFAULT 1,
          word_count INTEGER DEFAULT 0,
          voice_record_ids TEXT DEFAULT '[]',
          summary TEXT,
          tags TEXT DEFAULT '[]',
          status TEXT DEFAULT 'draft',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // 创建设置表
      await db.execute('''
        CREATE TABLE ${DatabaseTables.settings} (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // 创建采访会话表
      await db.execute('''
        CREATE TABLE ${DatabaseTables.interviewSessions} (
          id TEXT PRIMARY KEY,
          current_question_index INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');

      // 创建采访问题表
      await db.execute('''
        CREATE TABLE ${DatabaseTables.interviewQuestions} (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          question TEXT NOT NULL,
          answer TEXT,
          order_index INTEGER NOT NULL,
          is_answered INTEGER DEFAULT 0,
          is_skipped INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES ${DatabaseTables.interviewSessions}(id) ON DELETE CASCADE
        )
      ''');

      // 创建自传版本表
      await db.execute('''
        CREATE TABLE ${DatabaseTables.autobiographyVersions} (
          id TEXT PRIMARY KEY,
          autobiography_id TEXT NOT NULL,
          version_name TEXT NOT NULL,
          content TEXT NOT NULL,
          chapters TEXT NOT NULL,
          word_count INTEGER DEFAULT 0,
          summary TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (autobiography_id) REFERENCES ${DatabaseTables.autobiographies}(id) ON DELETE CASCADE
        )
      ''');

      // 创建索引
      await db.execute('''
        CREATE INDEX idx_voice_records_timestamp
        ON ${DatabaseTables.voiceRecords} (timestamp)
      ''');

      await db.execute('''
        CREATE INDEX idx_autobiographies_status
        ON ${DatabaseTables.autobiographies} (status)
      ''');

      await db.execute('''
        CREATE INDEX idx_autobiographies_generated_at
        ON ${DatabaseTables.autobiographies} (generated_at)
      ''');

      await db.execute('''
        CREATE INDEX idx_autobiography_versions_autobiography_id
        ON ${DatabaseTables.autobiographyVersions} (autobiography_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_autobiography_versions_created_at
        ON ${DatabaseTables.autobiographyVersions} (created_at)
      ''');

      await db.execute('''
        CREATE INDEX idx_interview_sessions_created_at
        ON ${DatabaseTables.interviewSessions} (created_at)
      ''');

      await db.execute('''
        CREATE INDEX idx_interview_questions_session_id
        ON ${DatabaseTables.interviewQuestions} (session_id)
      ''');

    } catch (e) {
      throw DatabaseException.insertFailed();
    }
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // 根据版本进行数据库升级
      if (oldVersion < 2) {
        // 版本1到版本2的升级：添加采访功能相关的表
        await db.execute('''
          CREATE TABLE ${DatabaseTables.interviewSessions} (
            id TEXT PRIMARY KEY,
            current_question_index INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE ${DatabaseTables.interviewQuestions} (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT,
            order_index INTEGER NOT NULL,
            is_answered INTEGER DEFAULT 0,
            is_skipped INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES ${DatabaseTables.interviewSessions}(id) ON DELETE CASCADE
          )
        ''');

        // 创建索引
        await db.execute('''
          CREATE INDEX idx_interview_sessions_created_at
          ON ${DatabaseTables.interviewSessions} (created_at)
        ''');

        await db.execute('''
          CREATE INDEX idx_interview_questions_session_id
          ON ${DatabaseTables.interviewQuestions} (session_id)
        ''');
      }

      if (oldVersion < 3) {
        // 版本2到版本3的升级：添加自传版本管理表
        await db.execute('''
          CREATE TABLE ${DatabaseTables.autobiographyVersions} (
            id TEXT PRIMARY KEY,
            autobiography_id TEXT NOT NULL,
            version_name TEXT NOT NULL,
            content TEXT NOT NULL,
            chapters TEXT NOT NULL,
            word_count INTEGER DEFAULT 0,
            summary TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (autobiography_id) REFERENCES ${DatabaseTables.autobiographies}(id) ON DELETE CASCADE
          )
        ''');

        // 创建索引
        await db.execute('''
          CREATE INDEX idx_autobiography_versions_autobiography_id
          ON ${DatabaseTables.autobiographyVersions} (autobiography_id)
        ''');

        await db.execute('''
          CREATE INDEX idx_autobiography_versions_created_at
          ON ${DatabaseTables.autobiographyVersions} (created_at)
        ''');
      }
    } catch (e) {
      throw DatabaseException.updateFailed();
    }
  }

  /// 插入数据
  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      data['created_at'] = DateTime.now().millisecondsSinceEpoch;
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      return await db.insert(table, data);
    } catch (e) {
      throw DatabaseException.insertFailed();
    }
  }

  /// 查询数据
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseException.queryFailed();
    }
  }

  /// 查询单条数据
  Future<Map<String, dynamic>?> querySingle(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
  }) async {
    try {
      final results = await query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException.queryFailed();
    }
  }

  /// 更新数据
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      values['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw DatabaseException.updateFailed();
    }
  }

  /// 删除数据
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw DatabaseException.deleteFailed();
    }
  }

  /// 执行原始SQL语句
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw DatabaseException.queryFailed();
    }
  }

  /// 执行原始SQL语句（返回影响的行数）
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawUpdate(sql, arguments);
    } catch (e) {
      throw DatabaseException.updateFailed();
    }
  }

  /// 开始事务
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      final db = await database;
      return await db.transaction(action);
    } catch (e) {
      throw DatabaseException.queryFailed();
    }
  }

  /// 获取表的记录数
  Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    try {
      final result = await query(
        table,
        columns: ['COUNT(*) as count'],
        where: where,
        whereArgs: whereArgs,
      );
      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseException.queryFailed();
    }
  }

  /// 清空表
  Future<void> clearTable(String table) async {
    try {
      final db = await database;
      await db.delete(table);
    } catch (e) {
      throw DatabaseException.deleteFailed();
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 删除数据库文件
  Future<void> deleteDatabase() async {
    try {
      await close();
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);
      await databaseFactory.deleteDatabase(path);
    } catch (e) {
      throw DatabaseException.deleteFailed();
    }
  }
}

/// 测试专用数据库服务
/// 使用内存数据库，不依赖文件系统
class _TestingDatabaseService extends DatabaseService {
  Database? _testDatabase;

  _TestingDatabaseService() : super();

  @override
  Future<Database> get database async {
    _testDatabase ??= await _initTestDatabase();
    return _testDatabase!;
  }

  Future<Database> _initTestDatabase() async {
    // 使用内存数据库进行测试
    return await openDatabase(
      inMemoryDatabasePath,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @override
  Future<void> close() async {
    if (_testDatabase != null) {
      await _testDatabase!.close();
      _testDatabase = null;
    }
  }
}