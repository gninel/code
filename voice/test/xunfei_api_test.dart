import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// 这里替换为你的真实配置，或者从 AppConstants 读取（如果能跑在 Flutter 环境下）
// 为了独立运行，最好硬编码或从环境变量读
const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';
const String UPLOAD_PATH = '/v2/upload';

void main() async {
  // 测试用例 1: 使用一个简单的虚拟文件进行上传测试
  print('\n=== Test Case 1: Upload a small dummy file ===');
  await testUpload('test_audio.mp3', List.filled(1024, 0)); // 1KB dummy data

  // 如果你有真实文件路径，可以取消注释并测试
  // print('\n=== Test Case 2: Upload real file ===');
  // await testUpload('/path/to/real/file.m4a');
}

Future<void> testUpload(String fileName, [List<int>? content]) async {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));

  final fileSize = content?.length ?? 1024;
  final estimatedDuration = (fileSize / 16).round();

  // 生成时间戳
  final now = DateTime.now().toUtc();
  final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss"); // 去掉 Z，手动拼接时区
  final dateTime = '${formatter.format(now)}+0000';

  final signatureRandom = const Uuid().v4();

  final params = <String, String>{
    'accessKeyId': API_KEY, // 对应 APIKey
    'dateTime': dateTime,
    'duration': estimatedDuration.toString(),
    'fileName': fileName,
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,

    // 尝试添加 appId，看看是否解决问题
    'appId': APP_ID,
  };

  // 生成签名
  final signature = _generateSignature(params, API_SECRET);

  // 准备最终参数
  final queryParams = Map<String, dynamic>.from(params);
  queryParams['signature'] = signature;

  print('Params: $queryParams');

  // 手动构建一下 URL 看看长什么样
  final queryString = queryParams.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  final fullUrl = '$BASE_URL$UPLOAD_PATH?$queryString';
  print('Full URL Preview: $fullUrl');
  print('CURL Command:');
  print(
      'curl -v -X POST "$fullUrl" --data-binary @test_audio.mp3 -H "Content-Type: application/octet-stream"');

  try {
    final response = await dio.post(
      '$BASE_URL$UPLOAD_PATH',
      data: Stream.fromIterable([content ?? []]), // 模拟文件流
      queryParameters: queryParams,
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': fileSize,
          // 尝试把所有鉴权参数放在 Header 里
          'signature': signature,
          'accessKeyId': API_KEY,
          'appId': APP_ID,
          'dateTime': dateTime,
          'signatureRandom': signatureRandom,
        },
      ),
    );
    print('Response: ${response.data}');
  } catch (e) {
    if (e is DioException) {
      print('Error: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
    } else {
      print('Error: $e');
    }
  }
}

String _generateSignature(Map<String, String> params, String secret) {
  final sortedKeys = params.keys.toList()..sort();
  final pairs = <String>[];
  for (final key in sortedKeys) {
    if (key != 'signature' && params[key]?.isNotEmpty == true) {
      final value = _encodeParam(params[key]!);
      pairs.add('$key=$value');
    }
  }
  final baseString = pairs.join('&');
  print('BaseString: $baseString');

  // 尝试把 secret 当做 Base64 string
  List<int> secretBytes = base64.decode(secret);
  print('Secret Bytes Len: ${secretBytes.length}');

  final hmac = Hmac(sha256, secretBytes);
  // final hmac = Hmac(sha256, utf8.encode(secret)); // 原来的方式

  final digest = hmac.convert(utf8.encode(baseString));
  return base64.encode(digest.bytes);
}

// String _encodeParam(String value) { ... }

String _encodeParam(String value) {
  return Uri.encodeComponent(value)
      .replaceAll('%20', '+')
      .replaceAll('*', '%2A')
      .replaceAll('~', '%7E');
}
