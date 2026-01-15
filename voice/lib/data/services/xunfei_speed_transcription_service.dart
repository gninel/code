import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';
import 'package:voice_autobiography_flutter/core/errors/exceptions.dart';

/// 讯飞录音转写大模型服务
/// 文档: https://www.xfyun.cn/doc/spark/asr_llm/Ifasr_llm.html
class XunfeiSpeedTranscriptionService {
  static final XunfeiSpeedTranscriptionService _instance =
      XunfeiSpeedTranscriptionService._internal();

  factory XunfeiSpeedTranscriptionService() => _instance;

  late final Dio _dio;

  // 录音转写大模型 API Endpoints
  static const String _baseUrl = 'https://office-api-ist-dx.iflyaisol.com';
  static const String _uploadPath = '/v2/upload';
  static const String _getResultPath = '/v2/getResult';

  XunfeiSpeedTranscriptionService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 60000),
      receiveTimeout: const Duration(milliseconds: 60000),
      sendTimeout: const Duration(milliseconds: 60000),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('SpeedTranscription: $obj'),
    ));
  }

  /// 识别录音文件
  Future<String> transcribeFile(String filePath,
      {void Function(String)? onProgress}) async {
    try {
      print('Service: Starting transcription for $filePath...');
      onProgress?.call('正在上传文件...');

      // 1. 上传文件并获取 orderId
      final orderId = await _uploadFile(filePath);
      if (orderId == null) {
        throw const AsrException('文件上传失败');
      }
      print('Service: File uploaded, orderId: $orderId');
      onProgress?.call('上传成功，正在转写...');

      // 2. 轮询结果
      return await _pollResult(orderId, onProgress);
    } catch (e) {
      print('Service: Exception in transcribeFile: $e');
      if (e is AppException) rethrow;
      throw AsrException('转写失败: $e');
    }
  }

  /// 上传文件并直接获取 orderId
  Future<String?> _uploadFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw AsrException('文件不存在: $filePath');
    }

    final fileSize = await file.length();
    final fileName = filePath.split('/').last;
    final duration = await _getAudioDuration(filePath);

    // 构建请求参数 (用于签名)
    final dateTime = _getDateTimeString();
    final signatureRandom = const Uuid().v4();

    // 构建请求参数 (参与签名计算)
    // 注意：必须包含 appId 参数，language 使用 autodialect
    final params = <String, String>{
      'appId': AppConstants.xunfeiAppId,
      'accessKeyId': AppConstants.xunfeiLlmApiKey,
      'dateTime': dateTime,
      'duration': duration.toString(),
      'fileName': fileName,
      'fileSize': fileSize.toString(),
      'language': 'autodialect', // 自动识别方言
      'signatureRandom': signatureRandom,
    };

    // 生成签名 (HMAC-SHA1) - 使用与 Java 兼容的编码方式
    final signature =
        _generateSignature(params, AppConstants.xunfeiLlmApiSecret);

    // 注意：签名不放在 URL 参数中，而是放在 Header 'signature' 中
    // params['signature'] = signature;

    // 构建 URL (不包含 signature) - 按照 Python 示例对 key 和 value 都编码
    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final url = '$_baseUrl$_uploadPath?$queryString';

    print('SpeedTranscription: Upload URL: $url');
    print('SpeedTranscription: File size: $fileSize, duration: $duration');

    try {
      // 发送文件数据
      final fileBytes = await file.readAsBytes();
      final response = await _dio.post(
        url,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': fileSize,
            'signature': signature, // 签名放在 Header 中
          },
        ),
      );

      print('SpeedTranscription: Upload response: ${response.data}');

      final data = response.data;
      final code = data['code']?.toString();

      if (code == '000000' || code == '0') {
        // 成功，返回 orderId
        return data['content']?['orderId'];
      } else {
        print('SpeedTranscription: Upload error: ${data['descInfo']}');
        throw AsrException('上传失败: ${data['descInfo']} (Code: $code)',
            code: 'UPLOAD_ERROR_$code');
      }
    } on DioException catch (e) {
      print('SpeedTranscription: Upload exception: ${e.response?.data}');
      throw AsrException('上传网络错误: ${e.message}');
    }
  }

  /// 轮询查询结果
  Future<String> _pollResult(String orderId,
      [void Function(String)? onProgress]) async {
    int retryCount = 0;
    const maxRetries = 120; // 4分钟超时

    while (retryCount < maxRetries) {
      retryCount++;
      await Future.delayed(const Duration(seconds: 2));

      // 构建请求参数
      final dateTime = _getDateTimeString();
      final signatureRandom = const Uuid().v4();

      final params = <String, String>{
        'appId': AppConstants.xunfeiAppId,
        'accessKeyId': AppConstants.xunfeiLlmApiKey,
        'dateTime': dateTime,
        'orderId': orderId,
        'signatureRandom': signatureRandom,
      };

      // 生成签名
      final signature =
          _generateSignature(params, AppConstants.xunfeiLlmApiSecret);

      // 构建 URL (不含 signature) - 按照 Python 示例对 key 和 value 都编码
      final queryString = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = '$_baseUrl$_getResultPath?$queryString';

      try {
        final response = await _dio.post(
          url,
          data: '{}',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'signature': signature, // 签名放在 Header 中
            },
          ),
        );

        final data = response.data;

        final code = data['code']?.toString();

        if (code == '000000') {
          final content = data['content'];
          final orderInfo = content?['orderInfo'];
          final status = orderInfo?['status'];

          // status: 1=创建成功 2=请求转码 3=转写中 4=转写完成 -1=失败
          if (status == 4) {
            // 转写完成
            final orderResult = content['orderResult'];
            return _parseResult(orderResult);
          } else if (status == -1) {
            throw const AsrException('转写任务失败');
          }

          // 继续轮询
          if (retryCount % 5 == 0) {
            onProgress?.call('转写中...(${retryCount * 2}秒)');
          }
        } else {
          print('SpeedTranscription: Query error: ${data['descInfo']}');
        }
      } catch (e) {
        if (e is AsrException) rethrow;
        print('SpeedTranscription: Poll exception: $e');
        // 网络错误可以重试
      }
    }
    throw const AsrException('转写超时');
  }

  /// 解析结果
  String _parseResult(String? orderResult) {
    if (orderResult == null || orderResult.isEmpty) {
      return '';
    }

    try {
      final jsonResult = jsonDecode(orderResult);
      final lattice = jsonResult['lattice'];
      if (lattice == null) return orderResult;

      final sb = StringBuffer();
      for (final item in lattice) {
        final json1best = item['json_1best'];
        if (json1best != null) {
          final parsed = jsonDecode(json1best);
          final st = parsed['st'];
          final rt = st?['rt'];
          if (rt != null) {
            for (final rtItem in rt) {
              final ws = rtItem['ws'];
              if (ws != null) {
                for (final wsItem in ws) {
                  final cw = wsItem['cw'];
                  if (cw != null) {
                    for (final cwItem in cw) {
                      sb.write(cwItem['w'] ?? '');
                    }
                  }
                }
              }
            }
          }
        }
      }
      return sb.toString();
    } catch (e) {
      print('SpeedTranscription: Parse error: $e');
      return orderResult;
    }
  }

  /// 生成签名 (HMAC-SHA1)
  String _generateSignature(
      Map<String, String> params, String accessKeySecret) {
    // 1. 排序参数（按 key 自然排序）
    final sortedKeys = params.keys.toList()..sort();

    // 2. 构建 baseString (按照 Python 示例：对 key 和 value 都编码)
    final pairs = <String>[];
    for (final key in sortedKeys) {
      if (key != 'signature' && params[key]?.isNotEmpty == true) {
        final encodedKey = Uri.encodeComponent(key);
        final encodedValue = Uri.encodeComponent(params[key]!);
        pairs.add('$encodedKey=$encodedValue');
      }
    }
    final baseString = pairs.join('&');
    print('SpeedTranscription: baseString: $baseString');

    // 3. HMAC-SHA1 签名
    final hmac = Hmac(sha1, utf8.encode(accessKeySecret));
    final digest = hmac.convert(utf8.encode(baseString));

    return base64.encode(digest.bytes);
  }

  /// Java URLEncoder 兼容的 URL 编码
  /// Java URLEncoder 会将空格编码为 +，而 Dart Uri.encodeComponent 编码为 %20
  String _javaUrlEncode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('%20', '+'); // Java URLEncoder 将空格编码为 +
  }

  /// 获取日期时间字符串 (yyyy-MM-dd'T'HH:mm:ss+HHmm 格式)
  String _getDateTimeString() {
    final now = DateTime.now();
    final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final dateStr = formatter.format(now);

    // 添加时区偏移
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    return '$dateStr$sign$hours$minutes';
  }

  /// 获取音频时长（毫秒）
  Future<int> _getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      final duration = await player.setFilePath(filePath);
      await player.dispose();
      return duration?.inMilliseconds ?? 0;
    } catch (e) {
      print('SpeedTranscription: Get duration error: $e');
      // 如果获取失败，返回估算值（基于文件大小）
      final file = File(filePath);
      final size = await file.length();
      // 假设 128kbps 比特率
      return (size * 8 / 128).round();
    }
  }
}
