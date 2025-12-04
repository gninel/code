import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

/// 备份服务
class BackupService {
  static BackupService? _instance;
  late final DatabaseService _databaseService;

  // 备份配置
  static const String _backupDirName = 'backups';
  static const String _backupFilePrefix = 'food_calorie_backup';
  static const int _maxBackupFiles = 10;
  static const List<String> _supportedFormats = ['json', 'csv'];

  BackupService._internal() {
    _databaseService = DatabaseService();
  }

  factory BackupService() {
    _instance ??= BackupService._internal();
    return _instance!;
  }

  /// 创建完整备份
  Future<BackupResult> createFullBackup({String? customName}) async {
    try {
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customName != null
          ? '$customName.json'
          : '$_backupFilePrefix_$timestamp.json';
      final backupFile = File('${backupDir.path}/$fileName');

      // 收集数据
      final backupData = await _collectBackupData();

      // 写入备份文件
      await backupFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      // 清理旧备份
      await _cleanupOldBackups(backupDir);

      return BackupResult.success(
        file: backupFile,
        size: await backupFile.length(),
        itemCount: backupData['foodItems']?.length ?? 0,
      );
    } catch (e) {
      return BackupResult.failure('创建备份失败: $e');
    }
  }

  /// 增量备份
  Future<BackupResult> createIncrementalBackup(DateTime lastBackupTime) async {
    try {
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_backupFilePrefix}_incremental_$timestamp.json';
      final backupFile = File('${backupDir.path}/$fileName');

      // 收集增量数据
      final foodItems = await _databaseService.getAllFoodItems();
      final incrementalItems = foodItems.where((item) =>
        item.createdAt.isAfter(lastBackupTime)
      ).toList();

      final backupData = {
        'type': 'incremental',
        'lastBackupTime': lastBackupTime.toIso8601String(),
        'backupTime': DateTime.now().toIso8601String(),
        'foodItems': incrementalItems.map((item) => item.toMap()).toList(),
      };

      await backupFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      return BackupResult.success(
        file: backupFile,
        size: await backupFile.length(),
        itemCount: incrementalItems.length,
      );
    } catch (e) {
      return BackupResult.failure('创建增量备份失败: $e');
    }
  }

  /// 恢复备份
  Future<RestoreResult> restoreBackup(String filePath) async {
    try {
      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        return RestoreResult.failure('备份文件不存在');
      }

      final content = await backupFile.readAsString();
      final backupData = Map<String, dynamic>.from(json.decode(content));

      // 验证备份格式
      final validationResult = _validateBackupData(backupData);
      if (!validationResult.isValid) {
        return RestoreResult.failure('备份格式无效: ${validationResult.error}');
      }

      // 检查备份类型
      final isIncremental = backupData['type'] == 'incremental';

      // 开始恢复
      int restoredCount = 0;
      final foodItemsData = backupData['foodItems'] as List<dynamic>? ?? [];

      for (final itemData in foodItemsData) {
        try {
          final foodItem = FoodItem.fromMap(itemData);
          await _databaseService.insertFoodItem(foodItem);
          restoredCount++;
        } catch (e) {
          print('恢复食物项失败: $e');
        }
      }

      return RestoreResult.success(
        restoredCount: restoredCount,
        isIncremental: isIncremental,
        backupTime: DateTime.parse(backupData['backupTime']),
      );
    } catch (e) {
      return RestoreResult.failure('恢复备份失败: $e');
    }
  }

  /// 获取备份列表
  Future<List<BackupInfo>> getBackupList() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = await backupDir.list().toList();

      final backupFiles = <BackupInfo>[];

      for (final file in files) {
        if (file is File && _isBackupFile(file)) {
          try {
            final content = await file.readAsString();
            final backupData = Map<String, dynamic>.from(json.decode(content));

            final backupInfo = BackupInfo(
              file: file,
              name: file.path.split('/').last,
              size: await file.length(),
              createdAt: await file.modified(),
              backupTime: DateTime.parse(backupData['backupTime']),
              itemCount: backupData['foodItems']?.length ?? 0,
              type: backupData['type'] ?? 'full',
            );

            backupFiles.add(backupInfo);
          } catch (e) {
            print('解析备份文件失败 ${file.path}: $e');
          }
        }
      }

      // 按创建时间排序（最新的在前）
      backupFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backupFiles;
    } catch (e) {
      print('获取备份列表失败: $e');
      return [];
    }
  }

  /// 删除备份
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除备份失败: $e');
      return false;
    }
  }

  /// 导出CSV格式
  Future<BackupResult> exportToCSV() async {
    try {
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_backupFilePrefix}_$timestamp.csv';
      final csvFile = File('${backupDir.path}/$fileName');

      final foodItems = await _databaseService.getAllFoodItems();

      // 构建CSV内容
      final csvContent = _buildCSVContent(foodItems);

      await csvFile.writeAsString(csvContent);

      return BackupResult.success(
        file: csvFile,
        size: await csvFile.length(),
        itemCount: foodItems.length,
      );
    } catch (e) {
      return BackupResult.failure('导出CSV失败: $e');
    }
  }

  /// 自动备份设置
  Future<void> scheduleAutoBackup() async {
    // 这里可以实现定时自动备份逻辑
    // 比如使用 WorkManager 或者 Timer
    print('自动备份已计划');
  }

  /// 验证备份文件
  BackupValidationResult validateBackupFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return BackupValidationResult(false, '文件不存在');
      }

      final content = file.readAsStringSync();
      final backupData = Map<String, dynamic>.from(json.decode(content));

      return _validateBackupData(backupData);
    } catch (e) {
      return BackupValidationResult(false, '验证失败: $e');
    }
  }

  // 私有方法

  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$_backupDirName');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  Future<Map<String, dynamic>> _collectBackupData() async {
    final foodItems = await _databaseService.getAllFoodItems();

    return {
      'version': '1.0.0',
      'type': 'full',
      'backupTime': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0', // 从配置获取
      'foodItems': foodItems.map((item) => item.toMap()).toList(),
      'statistics': {
        'totalItems': foodItems.length,
        'totalCalories': foodItems.fold<int>(0, (sum, item) => sum + item.calories),
        'dateRange': foodItems.isNotEmpty
            ? {
                'start': foodItems.last.createdAt.toIso8601String(),
                'end': foodItems.first.createdAt.toIso8601String(),
              }
            : null,
      },
    };
  }

  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();
      final backupFiles = files.whereType<File>()
          .where((file) => _isBackupFile(file))
          .toList();

      // 按修改时间排序
      // The original line `backupFiles.sort((a, b) => b.lastModified().compareTo(a.lastModified()));`
      // was replaced based on the instruction to use `lastModified()`.
      // Since `lastModified()` is async, we need to get the DateTime objects first.
      final List<({File file, DateTime lastModified})> filesWithModifiedTime = await Future.wait(
        backupFiles.map((file) async => (file: file, lastModified: await file.lastModified()))
      );

      filesWithModifiedTime.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      final now = DateTime.now();
      // Filter out backups older than 7 days
      final recentBackups = filesWithModifiedTime.where((entry) => now.difference(entry.lastModified).inDays <= 7).toList();

      // Delete backups that are older than 7 days or exceed the max count
      for (final entry in filesWithModifiedTime) {
        if (now.difference(entry.lastModified).inDays > 7) {
          await entry.file.delete();
        }
      }

      // If there are still too many recent backups, delete the oldest ones
      if (recentBackups.length > _maxBackupFiles) {
        // Sort recent backups by lastModified (oldest first) to delete
        recentBackups.sort((a, b) => a.lastModified.compareTo(b.lastModified));
        for (int i = 0; i < recentBackups.length - _maxBackupFiles; i++) {
          await recentBackups[i].file.delete();
        }
      }
    } catch (e) {
      print('清理旧备份失败: $e');
    }
  }

  bool _isBackupFile(File file) {
    final fileName = file.path.split('/').last;
    return fileName.startsWith(_backupFilePrefix) &&
           (fileName.endsWith('.json') || fileName.endsWith('.csv'));
  }

  String _buildCSVContent(List<FoodItem> foodItems) {
    final buffer = StringBuffer();

    // CSV 头部
    buffer.writeln('ID,食物名称,成分,热量,图片路径,创建时间,餐次类型');

    // CSV 数据行
    for (final item in foodItems) {
      buffer.writeln(
        '${item.id},'
        '"${item.foodName}",'
        '"${item.ingredients.join(',')}",'
        '${item.calories},'
        '"${item.imagePath}",'
        '"${item.createdAt.toIso8601String()}",'
        '"${item.mealType}"'
      );
    }

    return buffer.toString();
  }

  BackupValidationResult _validateBackupData(Map<String, dynamic> data) {
    // 检查必要字段
    final requiredFields = ['backupTime', 'foodItems'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        return BackupValidationResult(false, '缺少必要字段: $field');
      }
    }

    // 验证时间格式
    try {
      DateTime.parse(data['backupTime']);
    } catch (e) {
      return BackupValidationResult(false, '无效的备份时间格式');
    }

    // 验证食物项数据
    final foodItemsData = data['foodItems'] as List<dynamic>?;
    if (foodItemsData == null) {
      return BackupValidationResult(false, 'foodItems 不是有效的数组');
    }

    for (int i = 0; i < foodItemsData.length; i++) {
      final itemData = foodItemsData[i];
      if (itemData is! Map<String, dynamic>) {
        return BackupValidationResult(false, '食物项 $i 格式无效');
      }

      final foodItem = FoodItem.fromMap(itemData);
      if (foodItem.foodName.isEmpty) {
        return BackupValidationResult(false, '食物项 $i 缺少名称');
      }
    }

    return BackupValidationResult(true, null);
  }
}

/// 备份结果类
class BackupResult {
  final bool success;
  final String? error;
  final File? file;
  final int? size;
  final int? itemCount;

  BackupResult.success({
    required this.file,
    required this.size,
    required this.itemCount,
  }) : success = true, error = null;

  BackupResult.failure(this.error)
      : success = false,
        file = null,
        size = null,
        itemCount = null;

  @override
  String toString() {
    return 'BackupResult{success: $success, error: $error, file: $file, size: $size, itemCount: $itemCount}';
  }
}

/// 恢复结果类
class RestoreResult {
  final bool success;
  final String? error;
  final int? restoredCount;
  final bool? isIncremental;
  final DateTime? backupTime;

  RestoreResult.success({
    required this.restoredCount,
    this.isIncremental = false,
    this.backupTime,
  }) : success = true, error = null;

  RestoreResult.failure(this.error)
      : success = false,
        restoredCount = null,
        isIncremental = null,
        backupTime = null;

  @override
  String toString() {
    return 'RestoreResult{success: $success, error: $error, restoredCount: $restoredCount}';
  }
}

/// 备份信息类
class BackupInfo {
  final File file;
  final String name;
  final int size;
  final DateTime createdAt;
  final DateTime backupTime;
  final int itemCount;
  final String type;

  BackupInfo({
    required this.file,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.backupTime,
    required this.itemCount,
    required this.type,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedBackupTime {
    return '${backupTime.year}-${backupTime.month.toString().padLeft(2, '0')}-${backupTime.day.toString().padLeft(2, '0')} ${backupTime.hour.toString().padLeft(2, '0')}:${backupTime.minute.toString().padLeft(2, '0')}';
  }

  String get typeDisplayName {
    switch (type) {
      case 'incremental':
        return '增量备份';
      case 'full':
      default:
        return '完整备份';
    }
  }
}

/// 备份验证结果类
class BackupValidationResult {
  final bool isValid;
  final String? error;

  BackupValidationResult(this.isValid, this.error);

  @override
  String toString() {
    return 'BackupValidationResult{isValid: $isValid, error: $error}';
  }
}