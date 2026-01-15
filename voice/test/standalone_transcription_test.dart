import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// 讯飞录音文件转写大模型 WebAPI 独立测试
/// 不依赖Flutter框架，可直接运行
/// 文档: https://www.xfyun.cn/doc/spark/asr_llm/Ifasr_llm.html

// API配置
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

// API端点
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';
const String UPLOAD_PATH = '/v2/upload';
const String GET_RESULT_PATH = '/v2/getResult';

class SimpleTranscriptionService {
  late final Dio _dio;

  SimpleTranscriptionService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 60000),
      receiveTimeout: const Duration(milliseconds: 60000),
      sendTimeout: const Duration(milliseconds: 60000),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[HTTP] $obj'),
    ));
  }

  /// 转写音频文件
  Future<String> transcribeFile(String filePath, {void Function(String)? onProgress}) async {
    try {
      print('开始转写文件: $filePath');
      onProgress?.call('正在上传文件...');

      // 1. 上传文件并获取 orderId
      final orderId = await _uploadFile(filePath);
      if (orderId == null) {
        throw Exception('文件上传失败');
      }
      print('文件上传成功，订单ID: $orderId');
      onProgress?.call('上传成功，正在转写...');

      // 2. 轮询结果
      return await _pollResult(orderId, onProgress);
    } catch (e) {
      print('转写失败: $e');
      rethrow;
    }
  }

  /// 上传文件
  Future<String?> _uploadFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final fileSize = await file.length();
    final fileName = filePath.split('/').last;
    final duration = await _getAudioDuration(filePath);

    // 构建请求参数
    final dateTime = _getDateTimeString();
    final signatureRandom = const Uuid().v4();

    final params = <String, String>{
      'accessKeyId': API_KEY,
      'dateTime': dateTime,
      'duration': duration.toString(),
      'fileName': fileName,
      'fileSize': fileSize.toString(),
      'language': 'zh_cn',
      'signatureRandom': signatureRandom,
    };

    // 生成签名
    final signature = _generateSignature(params, API_SECRET);

    // 构建 URL (不含 signature)
    final queryString = params.entries
        .map((e) => '${e.key}=${_javaUrlEncode(e.value)}')
        .join('&');
    final url = '$BASE_URL$UPLOAD_PATH?$queryString';

    print('上传URL: $url');
    print('文件大小: $fileSize, 时长: $duration');

    try {
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

      print('上传响应: ${response.data}');

      final data = response.data;
      final code = data['code']?.toString();

      if (code == '000000' || code == '0') {
        return data['content']?['orderId'];
      } else {
        throw Exception('上传失败: ${data['descInfo']} (Code: $code)');
      }
    } on DioException catch (e) {
      throw Exception('上传网络错误: ${e.message}');
    }
  }

  /// 轮询查询结果
  Future<String> _pollResult(String orderId, [void Function(String)? onProgress]) async {
    int retryCount = 0;
    const maxRetries = 60; // 2分钟超时

    while (retryCount < maxRetries) {
      retryCount++;
      await Future.delayed(const Duration(seconds: 2));

      // 构建请求参数
      final dateTime = _getDateTimeString();
      final signatureRandom = const Uuid().v4();

      final params = <String, String>{
        'accessKeyId': API_KEY,
        'dateTime': dateTime,
        'orderId': orderId,
        'signatureRandom': signatureRandom,
      };

      // 生成签名
      final signature = _generateSignature(params, API_SECRET);

      // 构建 URL (不含 signature)
      final queryString = params.entries
          .map((e) => '${e.key}=${_javaUrlEncode(e.value)}')
          .join('&');
      final url = '$BASE_URL$GET_RESULT_PATH?$queryString';

      try {
        final response = await _dio.post(
          url,
          data: '{}',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'signature': signature,
            },
          ),
        );

        final data = response.data;
        final code = data['code']?.toString();

        if (code == '000000') {
          final content = data['content'];
          final orderInfo = content?['orderInfo'];
          final status = orderInfo?['status'];

          if (status == 4) {
            // 转写完成
            final orderResult = content['orderResult'];
            return _parseResult(orderResult);
          } else if (status == -1) {
            throw Exception('转写任务失败');
          }

          // 继续轮询
          if (retryCount % 5 == 0) {
            onProgress?.call('转写中...(${retryCount * 2}秒)');
          }
        } else {
          print('查询错误: ${data['descInfo']}');
        }
      } catch (e) {
        print('查询异常: $e');
      }
    }
    throw Exception('转写超时');
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
      print('解析错误: $e');
      return orderResult;
    }
  }

  /// 生成签名 (HMAC-SHA1)
  String _generateSignature(Map<String, String> params, String accessKeySecret) {
    // 1. 排序参数
    final sortedKeys = params.keys.toList()..sort();

    // 2. 构建 baseString
    final pairs = <String>[];
    for (final key in sortedKeys) {
      if (key != 'signature' && params[key]?.isNotEmpty == true) {
        final value = _javaUrlEncode(params[key]!);
        pairs.add('$key=$value');
      }
    }
    final baseString = pairs.join('&');
    print('签名字符串: $baseString');

    // 3. HMAC-SHA1 签名
    final hmac = Hmac(sha1, utf8.encode(accessKeySecret));
    final digest = hmac.convert(utf8.encode(baseString));

    return base64.encode(digest.bytes);
  }

  /// Java URLEncoder 兼容的 URL 编码
  String _javaUrlEncode(String value) {
    return Uri.encodeComponent(value).replaceAll('%20', '+');
  }

  /// 获取日期时间字符串
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
    // 简单估算：假设 128kbps 比特率
    final file = File(filePath);
    final size = await file.length();
    return (size * 8 / 128).round();
  }
}

void main(List<String> args) async {
  print('🎤 讯飞录音文件转写大模型独立测试');
  print('=' * 50);

  // 确定测试文件
  String testFile;

  if (args.isNotEmpty) {
    testFile = args[0];
    if (!File(testFile).existsSync()) {
      print('❌ 指定的文件不存在: $testFile');
      return;
    }
  } else {
    // 自动查找测试文件
    final candidates = [
      'test_audio.mp3',
      '/Users/zhb/Documents/code/voice/test_audio.mp3',
      '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a',
      '/Users/zhb/Documents/code/voice/小鹿录音与成诗先生的相遇.m4a',
      '/Users/zhb/Documents/code/voice/转折：小鹿飞向新世界的起点.m4a',
    ];

    testFile = '';
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        testFile = candidate;
        break;
      }
    }

    if (testFile.isEmpty) {
      print('❌ 未找到测试音频文件');
      return;
    }
  }

  final fileName = testFile.split('/').last;
  final fileSize = await File(testFile).length();

  print('📁 测试文件: $fileName');
  print('📏 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
  print('🔑 API Key: ${API_KEY.substring(0, 8)}...');
  print('');

  try {
    final service = SimpleTranscriptionService();
    print('🚀 开始转写...');
    final startTime = DateTime.now();

    String result = await service.transcribeFile(
      testFile,
      onProgress: (progress) {
        print('⏳ $progress');
      },
    );

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // 显示结果
    print('');
    print('✅ 转写成功！');
    print('⏱️  总耗时: ${duration.inMinutes}分${duration.inSeconds % 60}秒');
    print('📝 转写文本长度: ${result.length} 字符');

    // 预览结果
    print('');
    print('📄 转写结果:');
    print('-' * 40);
    print(result);
    print('-' * 40);

    // 保存结果
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = 'transcription_${timestamp}_$fileName.txt';
    await File(outputFile).writeAsString(result);
    print('💾 结果已保存到: $outputFile');

  } catch (e) {
    print('');
    print('❌ 转写失败: $e');
  }

  print('');
  print('🏁 测试结束');
}