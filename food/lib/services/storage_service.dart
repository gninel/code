import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/daily_record.dart';
import '../models/api_response.dart';

/// 本地存储和缓存服务
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;
  Directory? _appDir;
  Directory? _cacheDir;

  // 缓存键
  static const String _keyUserSettings = 'user_settings';
  static const String _keyFoodCache = 'food_cache';
  static const String _keyApiCache = 'api_cache';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyAppVersion = 'app_version';

  // 缓存时间限制（秒）
  static const int _cacheDuration = 24 * 60 * 60; // 24小时
  static const int _imageCacheDuration = 7 * 24 * 60 * 60; // 7天

  StorageService._internal();

  factory StorageService() {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  /// 初始化存储服务
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _appDir = await getApplicationDocumentsDirectory();
      _cacheDir = await getTemporaryDirectory();

      debugPrint('StorageService initialized');
      debugPrint('App directory: ${_appDir?.path}');
      debugPrint('Cache directory: ${_cacheDir?.path}');
    } catch (e) {
      debugPrint('Failed to initialize StorageService: $e');
      rethrow;
    }
  }

  /// 用户设置相关
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final settingsJson = _prefs?.getString(_keyUserSettings);
      if (settingsJson != null) {
        return Map<String, dynamic>.from(json.decode(settingsJson));
      }
      return _getDefaultUserSettings();
    } catch (e) {
      debugPrint('Failed to get user settings: $e');
      return _getDefaultUserSettings();
    }
  }

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      final settingsJson = json.encode(settings);
      await _prefs?.setString(_keyUserSettings, settingsJson);
      debugPrint('User settings saved');
    } catch (e) {
      debugPrint('Failed to save user settings: $e');
    }
  }

  Map<String, dynamic> _getDefaultUserSettings() {
    return {
      'dailyCalorieGoal': 2000,
      'enableNotifications': true,
      'darkMode': false,
      'autoBackup': false,
      'language': 'zh_CN',
      'unitSystem': 'metric',
      'reminders': {
        'breakfast': '08:00',
        'lunch': '12:00',
        'dinner': '18:00',
      },
    };
  }

  /// API响应缓存
  Future<FoodAnalysis?> getCachedFoodAnalysis(String imageHash) async {
    try {
      final cacheJson = _prefs?.getString('$_keyApiCache:$imageHash');
      if (cacheJson == null) return null;

      final cacheData = Map<String, dynamic>.from(json.decode(cacheJson));
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 检查缓存是否过期
      if (now - timestamp > _cacheDuration) {
        await _prefs?.remove('$_keyApiCache:$imageHash');
        return null;
      }

      final analysisData = cacheData['data'] as Map<String, dynamic>;
      return FoodAnalysis.fromMap(analysisData);
    } catch (e) {
      debugPrint('Failed to get cached food analysis: $e');
      return null;
    }
  }

  Future<void> cacheFoodAnalysis(String imageHash, FoodAnalysis analysis) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': analysis.toMap(),
      };

      final cacheJson = json.encode(cacheData);
      await _prefs?.setString('$_keyApiCache:$imageHash', cacheJson);
      debugPrint('Food analysis cached for hash: $imageHash');
    } catch (e) {
      debugPrint('Failed to cache food analysis: $e');
    }
  }

  /// 图片缓存
  Future<String?> getCachedImage(String url) async {
    try {
      final fileName = _generateFileName(url);
      final cachedFile = File('${_cacheDir?.path}/$fileName');

      if (await cachedFile.exists()) {
        final stat = await cachedFile.stat();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // 检查图片缓存是否过期
        if (now - stat.modified.millisecondsSinceEpoch ~/ 1000 > _imageCacheDuration) {
          await cachedFile.delete();
          return null;
        }

        return cachedFile.path;
      }
    } catch (e) {
      debugPrint('Failed to get cached image: $e');
    }
    return null;
  }

  Future<String?> downloadAndCacheImage(String url) async {
    try {
      // 先检查缓存
      final cachedPath = await getCachedImage(url);
      if (cachedPath != null) return cachedPath;

      // 下载图片
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fileName = _generateFileName(url);
        final cachedFile = File('${_cacheDir?.path}/$fileName');

        await cachedFile.writeAsBytes(response.bodyBytes);
        debugPrint('Image downloaded and cached: $fileName');
        return cachedFile.path;
      }
    } catch (e) {
      debugPrint('Failed to download and cache image: $e');
    }
    return null;
  }

  String _generateFileName(String url) {
    final bytes = url.codeUnits;
    var hash = 0;
    for (var byte in bytes) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & 0xFFFFFFFF;
    }
    return 'cache_${hash.abs()}.jpg';
  }

  /// 食物数据缓存
  Future<List<FoodItem>?> getCachedFoodItems() async {
    try {
      final cacheJson = _prefs?.getString(_keyFoodCache);
      if (cacheJson == null) return null;

      final cacheData = Map<String, dynamic>.from(json.decode(cacheJson));
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 检查缓存是否过期
      if (now - timestamp > _cacheDuration) {
        await _prefs?.remove(_keyFoodCache);
        return null;
      }

      final itemsData = cacheData['items'] as List<dynamic>;
      return itemsData.map((item) => FoodItem.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Failed to get cached food items: $e');
      return null;
    }
  }

  Future<void> cacheFoodItems(List<FoodItem> items) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'items': items.map((item) => item.toMap()).toList(),
      };

      final cacheJson = json.encode(cacheData);
      await _prefs?.setString(_keyFoodCache, cacheJson);
      debugPrint('Food items cached: ${items.length} items');
    } catch (e) {
      debugPrint('Failed to cache food items: $e');
    }
  }

  /// 数据导出
  Future<String?> exportData() async {
    try {
      final exportData = {
        'version': '1.0.0',
        'exportTime': DateTime.now().toIso8601String(),
        'userSettings': await getUserSettings(),
        'foodItems': [], // 这里需要从数据库获取
        'statistics': {},
      };

      final exportJson = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = 'food_calorie_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final exportFile = File('${_appDir?.path}/$fileName');

      await exportFile.writeAsString(exportJson);
      debugPrint('Data exported to: $fileName');
      return exportFile.path;
    } catch (e) {
      debugPrint('Failed to export data: $e');
      return null;
    }
  }

  /// 数据导入
  Future<bool> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Import file does not exist: $filePath');
        return false;
      }

      final content = await file.readAsString();
      final importData = Map<String, dynamic>.from(json.decode(content));

      // 验证导入数据格式
      if (!_validateImportData(importData)) {
        debugPrint('Invalid import data format');
        return false;
      }

      // 导入用户设置
      if (importData.containsKey('userSettings')) {
        await saveUserSettings(importData['userSettings']);
      }

      // 这里可以添加更多数据的导入逻辑

      debugPrint('Data imported successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to import data: $e');
      return false;
    }
  }

  bool _validateImportData(Map<String, dynamic> data) {
    // 基本格式验证
    return data.containsKey('version') &&
           data.containsKey('exportTime') &&
           data['version'] is String &&
           data['exportTime'] is String;
  }

  /// 缓存管理
  Future<void> clearCache() async {
    try {
      // 清除API缓存
      final keys = _prefs?.getKeys() ?? <String>{};
      for (final key in keys) {
        if (key.startsWith('$_keyApiCache:')) {
          await _prefs?.remove(key);
        }
      }

      // 清除食物缓存
      await _prefs?.remove(_keyFoodCache);

      // 清除图片缓存
      await _clearImageCache();

      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  Future<void> _clearImageCache() async {
    try {
      if (_cacheDir != null) {
        final files = await _cacheDir!.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains('cache_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to clear image cache: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;

      // 计算SharedPreferences缓存大小
      final keys = _prefs?.getKeys() ?? <String>{};
      for (final key in keys) {
        if (key.startsWith(_keyApiCache) || key.startsWith(_keyFoodCache)) {
          final value = _prefs?.get(key);
          if (value is String) {
            totalSize += value.length;
          }
        }
      }

      // 计算图片缓存大小
      if (_cacheDir != null) {
        final files = await _cacheDir!.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains('cache_')) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Failed to get cache size: $e');
      return 0;
    }
  }

  /// 缓存统计
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheSize = await getCacheSize();
      final cacheSizeMB = cacheSize / (1024 * 1024);

      int apiCacheCount = 0;
      int imageCacheCount = 0;

      final keys = _prefs?.getKeys() ?? <String>{};
      for (final key in keys) {
        if (key.startsWith('$_keyApiCache:')) {
          apiCacheCount++;
        }
      }

      if (_cacheDir != null) {
        final files = await _cacheDir!.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains('cache_')) {
            imageCacheCount++;
          }
        }
      }

      return {
        'totalSize': cacheSize,
        'totalSizeMB': cacheSizeMB.toStringAsFixed(2),
        'apiCacheCount': apiCacheCount,
        'imageCacheCount': imageCacheCount,
        'lastSyncTime': _prefs?.getString(_keyLastSyncTime),
      };
    } catch (e) {
      debugPrint('Failed to get cache stats: $e');
      return {};
    }
  }

  /// 应用程序信息
  Future<void> setLastSyncTime() async {
    try {
      await _prefs?.setString(
        _keyLastSyncTime,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Failed to set last sync time: $e');
    }
  }

  Future<String?> getLastSyncTime() async {
    return _prefs?.getString(_keyLastSyncTime);
  }

  /// 备份相关
  Future<String?> createBackup() async {
    try {
      final backupData = {
        'version': '1.0.0',
        'backupTime': DateTime.now().toIso8601String(),
        'userSettings': await getUserSettings(),
        'appVersion': _prefs?.getString(_keyAppVersion) ?? '1.0.0',
      };

      final backupJson = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final backupFile = File('${_appDir?.path}/$fileName');

      await backupFile.writeAsString(backupJson);
      await setLastSyncTime();

      debugPrint('Backup created: $fileName');
      return backupFile.path;
    } catch (e) {
      debugPrint('Failed to create backup: $e');
      return null;
    }
  }

  Future<bool> restoreBackup(String filePath) async {
    return await importData(filePath);
  }

  /// 清理过期缓存
  Future<void> cleanupExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 清理过期的API缓存
      final keys = _prefs?.getKeys() ?? <String>{};
      for (final key in keys) {
        if (key.startsWith('$_keyApiCache:')) {
          final cacheJson = _prefs?.getString(key);
          if (cacheJson != null) {
            final cacheData = Map<String, dynamic>.from(json.decode(cacheJson));
            final timestamp = cacheData['timestamp'] as int;

            if (now - timestamp > _cacheDuration) {
              await _prefs?.remove(key);
            }
          }
        }
      }

      // 清理过期的图片缓存
      if (_cacheDir != null) {
        final files = await _cacheDir!.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains('cache_')) {
            final stat = await file.stat();
            final fileTime = stat.modified.millisecondsSinceEpoch ~/ 1000;

            if (now - fileTime > _imageCacheDuration) {
              await file.delete();
            }
          }
        }
      }

      debugPrint('Expired cache cleaned up');
    } catch (e) {
      debugPrint('Failed to cleanup expired cache: $e');
    }
  }
}