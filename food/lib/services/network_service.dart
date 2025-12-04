import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 网络缓存服务
class NetworkService {
  static NetworkService? _instance;
  late final Dio _dio;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, Timer?> _cacheTimers = {};

  // 缓存配置
  static const Duration _defaultCacheTimeout = Duration(hours: 1);
  static const Duration _shortCacheTimeout = Duration(minutes: 15);
  static const Duration _longCacheTimeout = Duration(days: 1);
  static const int _maxMemoryCacheSize = 100; // 内存缓存最大条目数

  NetworkService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    // 添加拦截器
    _dio.interceptors.add(NetworkCacheInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => print('Network: $obj'),
    ));
  }

  factory NetworkService() {
    _instance ??= NetworkService._internal();
    return _instance!;
  }

  /// 获取GET请求
  Future<T?> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Duration? cacheTimeout,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateCacheKey(url, queryParameters);
    final timeout = cacheTimeout ?? _defaultCacheTimeout;

    // 检查内存缓存
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final cachedData = _memoryCache[cacheKey];
      if (cachedData['expiry'] != null &&
          DateTime.now().isBefore(cachedData['expiry'])) {
        return cachedData['data'] as T?;
      } else {
        _memoryCache.remove(cacheKey);
      }
    }

    try {
      final response = await _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: Options(
          extra: {
            'cacheKey': cacheKey,
            'cacheTimeout': timeout,
          },
        ),
      );

      // 缓存响应数据
      if (response.data != null) {
        _cacheInMemory(cacheKey, response.data as T, timeout);
      }

      return response.data;
    } on DioException catch (e) {
      print('GET request failed: ${e.message}');
      // 尝试返回过期的缓存数据
      if (_memoryCache.containsKey(cacheKey)) {
        return _memoryCache[cacheKey]['data'] as T?;
      }
      rethrow;
    }
  }

  /// POST请求
  Future<T?> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? cacheTimeout,
  }) async {
    try {
      final response = await _dio.post<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          extra: {
            'cacheKey': _generateCacheKey(url, queryParameters, data: data),
            'cacheTimeout': cacheTimeout ?? _shortCacheTimeout,
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      print('POST request failed: ${e.message}');
      rethrow;
    }
  }

  /// 下载文件
  Future<String> downloadFile(
    String url, {
    String? savePath,
    ProgressCallback? onReceiveProgress,
    Duration? cacheTimeout,
  }) async {
    try {
      final fileName = savePath ?? path.basename(url);
      final directory = Directory.systemTemp;
      final filePath = path.join(directory.path, fileName);

      final response = await _dio.download(
        url,
        filePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          extra: {
            'cacheKey': _generateCacheKey(url),
            'cacheTimeout': cacheTimeout ?? _longCacheTimeout,
          },
        ),
      );

      return filePath;
    } on DioException catch (e) {
      print('Download failed: ${e.message}');
      rethrow;
    }
  }

  /// 上传文件
  Future<T?> uploadFile<T>(
    String url,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final file = File(filePath);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        ...?data,
      });

      final response = await _dio.post<T>(
        url,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return response.data;
    } on DioException catch (e) {
      print('Upload failed: ${e.message}');
      rethrow;
    }
  }

  /// 生成缓存键
  String _generateCacheKey(
    String url, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) {
    final buffer = StringBuffer();
    buffer.write(url);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      buffer.write('?${json.encode(sortedParams)}');
    }

    if (data != null) {
      buffer.write('|${json.encode(data)}');
    }

    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  /// 内存缓存
  void _cacheInMemory<T>(String key, T data, Duration timeout) {
    // 检查缓存大小限制
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _evictOldestCache();
    }

    final expiry = DateTime.now().add(timeout);
    _memoryCache[key] = {
      'data': data,
      'expiry': expiry,
      'cachedAt': DateTime.now(),
    };

    // 设置过期清理定时器
    _scheduleCacheEviction(key, timeout);
  }

  /// 清理最旧的缓存
  void _evictOldestCache() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      final cachedAt = entry.value['cachedAt'] as DateTime?;
      if (cachedAt != null &&
          (oldestTime == null || cachedAt.isBefore(oldestTime!))) {
        oldestKey = entry.key;
        oldestTime = cachedAt;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      _cacheTimers[oldestKey]?.cancel();
      _cacheTimers.remove(oldestKey);
    }
  }

  /// 安排缓存清理
  void _scheduleCacheEviction(String key, Duration timeout) {
    _cacheTimers[key]?.cancel();
    _cacheTimers[key] = Timer(timeout, () {
      _memoryCache.remove(key);
      _cacheTimers.remove(key);
    });
  }

  /// 清除指定缓存
  void clearCache(String key) {
    _memoryCache.remove(key);
    _cacheTimers[key]?.cancel();
    _cacheTimers.remove(key);
  }

  /// 清除所有缓存
  void clearAllCache() {
    for (final timer in _cacheTimers.values) {
      timer?.cancel();
    }
    _memoryCache.clear();
    _cacheTimers.clear();
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    int expiredCount = 0;
    final now = DateTime.now();

    for (final entry in _memoryCache.values) {
      final expiry = entry['expiry'] as DateTime?;
      if (expiry != null && now.isAfter(expiry)) {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _memoryCache.length,
      'expiredEntries': expiredCount,
      'validEntries': _memoryCache.length - expiredCount,
      'maxSize': _maxMemoryCacheSize,
    };
  }

  /// 清理过期缓存
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _memoryCache.entries) {
      final expiry = entry.value['expiry'] as DateTime?;
      if (expiry != null && now.isAfter(expiry)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      clearCache(key);
    }
  }

  /// 检查网络连接
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 带重试的请求
  Future<T?> requestWithRetry<T>(
    Future<T?> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }

        // 指数退避
        final waitTime = delay * (1 << (attempts - 1));
        await Future.delayed(waitTime);
      }
    }

    return null;
  }

  /// 批量请求
  Future<List<T?>> batchRequest<T>(
    List<Future<T?> Function()> requests, {
    bool parallel = true,
  }) async {
    if (parallel) {
      return await Future.wait(requests);
    } else {
      final results = <T?>[];
      for (final request in requests) {
        try {
          final result = await request();
          results.add(result);
        } catch (e) {
          results.add(null);
        }
      }
      return results;
    }
  }

  /// 预加载资源
  Future<void> preloadResources(List<String> urls) async {
    final futures = urls.map((url) => get(url)).toList();
    await Future.wait(futures);
  }

  /// 取消所有请求
  void cancelRequests() {
    _dio.close(force: true);
  }

  /// 释放资源
  void dispose() {
    cancelRequests();
    clearAllCache();
  }
}

/// 网络缓存拦截器
class NetworkCacheInterceptor extends InterceptorsWrapper {
  static final Map<String, dynamic> _persistentCache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final cacheKey = options.extra['cacheKey'] as String?;
    final cacheTimeout = options.extra['cacheTimeout'] as Duration?;

    if (cacheKey != null && options.method == 'GET') {
      // 检查持久化缓存
      if (_persistentCache.containsKey(cacheKey)) {
        final cachedData = _persistentCache[cacheKey];
        if (cachedData['expiry'] != null &&
            DateTime.now().isBefore(cachedData['expiry'])) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: cachedData['data'],
              statusCode: 200,
            ),
          );
          return;
        } else {
          _persistentCache.remove(cacheKey);
        }
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final cacheKey = response.requestOptions.extra['cacheKey'] as String?;
    final cacheTimeout = response.requestOptions.extra['cacheTimeout'] as Duration?;

    if (cacheKey != null &&
        response.requestOptions.method == 'GET' &&
        response.statusCode == 200 &&
        response.data != null) {
      // 缓存响应数据
      _persistentCache[cacheKey] = {
        'data': response.data,
        'expiry': DateTime.now().add(cacheTimeout ?? const Duration(hours: 1)),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final cacheKey = err.requestOptions.extra['cacheKey'] as String?;

    // 如果网络请求失败，尝试返回缓存数据
    if (cacheKey != null && _persistentCache.containsKey(cacheKey)) {
      final cachedData = _persistentCache[cacheKey];
      handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: cachedData['data'],
          statusCode: 200,
        ),
      );
      return;
    }

    super.onError(err, handler);
  }

  /// 清除持久化缓存
  static void clearPersistentCache() {
    _persistentCache.clear();
  }

  /// 获取持久化缓存统计
  static Map<String, dynamic> getPersistentCacheStats() {
    int expiredCount = 0;
    final now = DateTime.now();

    for (final entry in _persistentCache.values) {
      final expiry = entry['expiry'] as DateTime?;
      if (expiry != null && now.isAfter(expiry)) {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _persistentCache.length,
      'expiredEntries': expiredCount,
      'validEntries': _persistentCache.length - expiredCount,
    };
  }
}