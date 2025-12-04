import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 性能优化工具类
class PerformanceOptimizer {
  static PerformanceOptimizer? _instance;
  final Map<String, Stopwatch> _timers = {};
  final Map<String, int> _counters = {};
  bool _isMonitoring = false;

  // 常量定义
  static const String operation_success = 'success';
  static const String operation_error = 'error';
  static const String operation_batch_processed = 'batch_processed';

  PerformanceOptimizer._internal();

  factory PerformanceOptimizer() {
    _instance ??= PerformanceOptimizer._internal();
    return _instance!;
  }

  /// 开始性能监控
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    if (kDebugMode) {
      developer.log('Performance monitoring started');
    }
  }

  /// 停止性能监控
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    if (kDebugMode) {
      developer.log('Performance monitoring stopped');
      _printPerformanceReport();
    }

    _clearMetrics();
  }

  /// 开始计时
  void startTimer(String operation) {
    if (!_isMonitoring) return;

    _timers[operation] = Stopwatch()..start();
  }

  /// 结束计时
  void endTimer(String operation) {
    if (!_isMonitoring) return;

    final timer = _timers[operation];
    if (timer != null && timer.isRunning) {
      timer.stop();
      _logTiming(operation, timer.elapsedMicroseconds);
    }
  }

  /// 增加计数器
  void incrementCounter(String event, [int value = 1]) {
    if (!_isMonitoring) return;

    _counters[event] = (_counters[event] ?? 0) + value;
    _logCounter(event, _counters[event]!);
  }

  /// 记录内存使用情况
  void logMemoryUsage(String context) {
    if (!_isMonitoring) return;

    // 在实际应用中，这里可以使用 memory_info 等插件获取更详细的内存信息
    if (kDebugMode) {
      developer.log('Memory usage at $context: ${DateTime.now()}');
    }
  }

  /// 执行性能优化的异步操作
  Future<T> performOptimizedAsync<T>(
    String operation,
    Future<T> Function() operationFunction, {
    Duration? timeout,
    int maxRetries = 3,
  }) async {
    if (!_isMonitoring) {
      return await operationFunction();
    }

    startTimer(operation);
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final result = await operationFunction()
            .timeout(timeout ?? const Duration(seconds: 30));
        endTimer(operation);
        incrementCounter('$operation_success');
        return result;
      } catch (e) {
        attempts++;
        incrementCounter('$operation_error');

        if (attempts >= maxRetries) {
          endTimer(operation);
          rethrow;
        }

        // 指数退避重试
        await Future.delayed(Duration(milliseconds: 100 * (1 << attempts)));
      }
    }

    endTimer(operation);
    throw Exception('Operation failed after $maxRetries attempts');
  }

  /// 批量处理操作
  Future<List<T>> processBatch<T>(
    String operation,
    List<T> items,
    Future<void> Function(T, int) processFunction, {
    int batchSize = 10,
    Duration delayBetweenBatches = const Duration(milliseconds: 100),
  }) async {
    if (!_isMonitoring) {
      // 不监控时直接处理
      for (int i = 0; i < items.length; i++) {
        await processFunction(items[i], i);
      }
      return items;
    }

    startTimer(operation);

    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      await Future.wait(
        batch.map((item) => processFunction(item, i + batch.indexOf(item))),
      );

      incrementCounter('$operation_batch_processed', batch.length);

      // 在批次之间添加延迟，避免UI阻塞
      if (i + batchSize < items.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }

    endTimer(operation);
    return items;
  }

  /// 优化图片加载
  Future<void> optimizeImageLoading(List<String> imageUrls) async {
    if (!_isMonitoring || imageUrls.isEmpty) return;

    startTimer('image_loading_batch');

    // 预加载图片，限制并发数量
    const maxConcurrent = 3;
    for (int i = 0; i < imageUrls.length; i += maxConcurrent) {
      final end = (i + maxConcurrent < imageUrls.length)
          ? i + maxConcurrent
          : imageUrls.length;

      final batch = imageUrls.sublist(i, end);

      await Future.wait(
        batch.map((url) => _preloadImage(url)),
      );

      incrementCounter('images_loaded', batch.length);
    }

    endTimer('image_loading_batch');
  }

  /// 预加载单张图片
  Future<void> _preloadImage(String imageUrl) async {
    try {
      // 在实际应用中，这里应该使用 pre_cache_image 等插件
      await Future.delayed(const Duration(milliseconds: 50)); // 模拟加载时间
      incrementCounter('image_preload_success');
    } catch (e) {
      incrementCounter('image_preload_error');
    }
  }

  /// 清理资源
  void cleanup() {
    _clearMetrics();
    _isMonitoring = false;
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    return {
      'timers': _timers.map((key, timer) => MapEntry(
        key,
        {
          'elapsedMicroseconds': timer.elapsedMicroseconds,
          'elapsedMilliseconds': timer.elapsedMilliseconds,
        }
      )),
      'counters': Map.from(_counters),
      'isMonitoring': _isMonitoring,
    };
  }

  // 私有方法

  void _logTiming(String operation, int microseconds) {
    if (kDebugMode) {
      final milliseconds = (microseconds / 1000).toStringAsFixed(2);
      developer.log('⏱️ $operation: ${milliseconds}ms');
    }
  }

  void _logCounter(String event, int count) {
    if (kDebugMode) {
      developer.log('📊 $event: $count');
    }
  }

  void _clearMetrics() {
    _timers.clear();
    _counters.clear();
  }

  void _printPerformanceReport() {
    if (kDebugMode) {
      developer.log('\n📈 Performance Report:');
      developer.log('==================');

      if (_timers.isNotEmpty) {
        developer.log('\n⏱️ Operation Timings:');
        _timers.forEach((operation, timer) {
          final ms = timer.elapsedMilliseconds;
          developer.log('  $operation: ${ms}ms');
        });
      }

      if (_counters.isNotEmpty) {
        developer.log('\n📊 Event Counters:');
        _counters.forEach((event, count) {
          developer.log('  $event: $count');
        });
      }

      developer.log('==================\n');
    }
  }
}

/// 性能监控装饰器
class PerformanceMonitor {
  final String operation;
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();

  PerformanceMonitor(this.operation);

  /// 监控同步操作
  T monitor<T>(T Function() operationFunction) {
    _optimizer.startTimer(operation);
    try {
      final result = operationFunction();
      _optimizer.endTimer(operation);
      _optimizer.incrementCounter('${operation}_success');
      return result;
    } catch (e) {
      _optimizer.endTimer(operation);
      _optimizer.incrementCounter('${operation}_error');
      rethrow;
    }
  }

  /// 监控异步操作
  Future<T> monitorAsync<T>(Future<T> Function() operationFunction) async {
    return await _optimizer.performOptimizedAsync(operation, operationFunction);
  }
}

/// 内存缓存管理器
class MemoryCacheManager {
  final Map<String, CacheEntry> _cache = {};
  final int _maxSize;
  int _currentSize = 0;

  MemoryCacheManager({int maxSize = 100 * 1024 * 1024}) // 100MB
      : _maxSize = maxSize;

  /// 存储缓存项
  void put<T>(String key, T value, {Duration? ttl}) {
    final size = _calculateSize(value);

    // 检查是否需要清理缓存
    if (_currentSize + size > _maxSize) {
      _evictLeastRecentlyUsed(size);
    }

    final entry = CacheEntry(
      value: value,
      size: size,
      createdAt: DateTime.now(),
      ttl: ttl,
      lastAccessedAt: DateTime.now(),
    );

    _cache[key] = entry;
    _currentSize += size;
  }

  /// 获取缓存项
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // 检查是否过期
    if (entry.isExpired) {
      _cache.remove(key);
      _currentSize -= entry.size;
      return null;
    }

    // 更新访问时间
    entry.lastAccessedAt = DateTime.now();
    return entry.value as T?;
  }

  /// 删除缓存项
  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSize -= entry.size;
    }
  }

  /// 清空所有缓存
  void clear() {
    _cache.clear();
    _currentSize = 0;
  }

  /// 获取缓存统计
  Map<String, dynamic> getStats() {
    return {
      'itemCount': _cache.length,
      'currentSize': _currentSize,
      'maxSize': _maxSize,
      'utilization': (_currentSize / _maxSize * 100).toStringAsFixed(2) + '%',
    };
  }

  /// 计算对象大小（简化版本）
  int _calculateSize<T>(T value) {
    if (value is String) {
      return value.length * 2; // 假设每个字符2字节
    } else if (value is List) {
      return value.length * 8; // 假设每个列表项8字节
    } else {
      return 64; // 默认大小
    }
  }

  /// LRU淘汰策略
  void _evictLeastRecentlyUsed(int requiredSize) {
    if (_cache.isEmpty) return;

    // 按最后访问时间排序
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    int freedSize = 0;
    for (final entry in sortedEntries) {
      _cache.remove(entry.key);
      freedSize += entry.value.size;
      _currentSize -= entry.value.size;

      if (freedSize >= requiredSize) break;
    }
  }
}

/// 缓存项
class CacheEntry<T> {
  final T value;
  final int size;
  final DateTime createdAt;
  final Duration? ttl;
  DateTime lastAccessedAt;

  CacheEntry({
    required this.value,
    required this.size,
    required this.createdAt,
    this.ttl,
    required this.lastAccessedAt,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }
}