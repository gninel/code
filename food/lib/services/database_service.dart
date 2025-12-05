import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/daily_record.dart';

/// 数据库服务类
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  // 单例模式
  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    try {
      print('DatabaseService: 开始初始化数据库...');
      final databasePath = await getDatabasesPath();
      print('DatabaseService: 数据库目录: $databasePath');
      final path = join(databasePath, 'food_calorie.db');
      print('DatabaseService: 数据库完整路径: $path');
      
      return await openDatabase(
        path,
        version: 3, // 升级版本号
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );
    } catch (e) {
      print('DatabaseService: 初始化失败: $e');
      rethrow;
    }
  }

  /// 创建数据表
  Future<void> _createTables(Database db, int version) async {
    // 创建食物记录表
    await db.execute('''
      CREATE TABLE food_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_name TEXT NOT NULL,
        food_name_en TEXT,
        ingredients TEXT,
        ingredients_en TEXT,
        calories INTEGER NOT NULL,
        image_path TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        meal_type TEXT DEFAULT 'other',
        weight REAL DEFAULT 100.0,
        tags TEXT,
        tags_en TEXT
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_food_records_created_at ON food_records(created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_food_records_meal_type ON food_records(meal_type)
    ''');
  }

  /// 升级数据表
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print('DatabaseService: 升级数据库到版本 2，添加 weight 列');
      await db.execute('ALTER TABLE food_records ADD COLUMN weight REAL DEFAULT 100.0');
    }
    if (oldVersion < 3) {
      print('DatabaseService: 升级数据库到版本 3，添加双语字段和标签');
      await db.execute('ALTER TABLE food_records ADD COLUMN food_name_en TEXT');
      await db.execute('ALTER TABLE food_records ADD COLUMN ingredients_en TEXT');
      await db.execute('ALTER TABLE food_records ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE food_records ADD COLUMN tags_en TEXT');
    }
  }

  /// 插入食物记录
  Future<int> insertFoodItem(FoodItem foodItem) async {
    final db = await database;
    final map = foodItem.toMap();
    print('DatabaseService: 准备插入数据: $map');
    final id = await db.insert('food_records', map);
    print('DatabaseService: 插入成功，返回 ID: $id');
    return id;
  }

  /// 获取所有食物记录
  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    print('DatabaseService: 查询所有食物记录...');
    final List<Map<String, dynamic>> maps = await db.query(
      'food_records',
      orderBy: 'created_at DESC',
    );
    print('DatabaseService: 查询到 ${maps.length} 条记录');
    if (maps.isNotEmpty) {
      print('DatabaseService: 第一条记录: ${maps[0]}');
    }

    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  /// 根据日期获取食物记录
  Future<List<FoodItem>> getFoodItemsByDate(DateTime date) async {
    final db = await database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'food_records',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  /// 获取日期范围内的食物记录
  Future<List<FoodItem>> getFoodItemsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      'food_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => FoodItem.fromMap(maps[i]));
  }

  /// 获取每日记录列表
  Future<List<DailyRecord>> getDailyRecords({int days = 30}) async {
    final db = await database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM food_records
      WHERE created_at >= ? AND created_at <= ?
      ORDER BY created_at DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    // 按日期分组
    Map<String, List<FoodItem>> groupedByDate = {};
    for (var map in maps) {
      final foodItem = FoodItem.fromMap(map);
      final dateKey = foodItem.createdAt.toIso8601String().substring(0, 10);

      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(foodItem);
    }

    // 转换为DailyRecord列表
    List<DailyRecord> dailyRecords = [];
    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final dateKey = date.toIso8601String().substring(0, 10);
      final foodItems = groupedByDate[dateKey] ?? [];

      final breakfastItems = foodItems.where((item) => item.mealType == 'breakfast').toList();
      final lunchItems = foodItems.where((item) => item.mealType == 'lunch').toList();
      final dinnerItems = foodItems.where((item) => item.mealType == 'dinner').toList();
      final otherItems = foodItems.where((item) => !['breakfast', 'lunch', 'dinner'].contains(item.mealType)).toList();

      dailyRecords.add(DailyRecord(
        date: date,
        breakfastItems: breakfastItems,
        lunchItems: lunchItems,
        dinnerItems: dinnerItems,
        otherItems: otherItems,
      ));
    }

    return dailyRecords;
  }

  /// 更新食物记录
  Future<int> updateFoodItem(FoodItem foodItem) async {
    final db = await database;
    return await db.update(
      'food_records',
      foodItem.toMap(),
      where: 'id = ?',
      whereArgs: [foodItem.id],
    );
  }

  /// 删除食物记录
  Future<int> deleteFoodItem(int id) async {
    final db = await database;
    return await db.delete(
      'food_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取食物记录总数
  Future<int> getFoodItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM food_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取总热量
  Future<int> getTotalCalories({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String query = 'SELECT SUM(calories) as total FROM food_records';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      query += ' WHERE created_at >= ? AND created_at <= ?';
      args = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取平均每日热量
  Future<double> getAverageDailyCalories({int days = 30}) async {
    final totalCalories = await getTotalCalories(
      startDate: DateTime.now().subtract(Duration(days: days - 1)),
      endDate: DateTime.now(),
    );
    return totalCalories / days;
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('food_records');
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}