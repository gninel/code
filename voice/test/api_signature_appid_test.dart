import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 测试 AppID 参数对签名的影响
/// 以及使用 ASCII 文件名排除编码干扰

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 录音转写大模型 API - AppID 参数测试 ===\n');

  // 使用不存在的简单文件进行测试 (我们只关心签名验证)
  // 或者创建一个临时文件
  final tempFile = File('test_audio.txt');
  await tempFile.writeAsString('dummy audio content');

  try {
    // 测试 1: 无 AppID (基准)
    await testUpload('无 AppID', {});

    // 测试 2: 添加 appId
    await testUpload('有 appId', {'appId': APP_ID});

    // 测试 3: 添加 app_id
    await testUpload('有 app_id', {'app_id': APP_ID});
  } finally {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}

Future<void> testUpload(
    String testName, Map<String, String> extraParams) async {
  print('\n--- 测试: $testName ---');

  final now = DateTime.now();
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';
  final signatureRandom = const Uuid().v4();
  const fileName = 'test_audio.m4a';
  const fileSize = 100; // 假大小

  // 基础参数
  final params = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '1000',
    'fileName': fileName,
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,
    ...extraParams,
  };

  print('参数: $params');

  // 生成签名
  final signature = javaStyleSignature(API_SECRET, params);
  params['signature'] = signature;
  print('签名: $signature');

  // 构建 URL
  final urlParams =
      params.entries.map((e) => '${e.key}=${javaUrlEncode(e.value)}').join('&');
  final url = '$BASE_URL/v2/upload?$urlParams';
  print('URL: $url');

  final dio = Dio();
  try {
    final response = await dio.post(
      url,
      data: 'dummy data', // 简单数据
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': 10, // 假长度
        },
        validateStatus: (status) => true,
      ),
    );

    print('Status: ${response.statusCode}');
    print('Response: ${response.data}');

    if (response.statusCode == 200 && response.data['code'] == '000000') {
      print('✓✓✓ 验证成功!!!!!');
    } else {
      print('✗ 验证失败: ${response.data['descInfo']}');
    }
  } catch (e) {
    print('异常: $e');
  }
}

String javaStyleSignature(
    String accessKeySecret, Map<String, String> queryParam) {
  final sortedKeys = queryParam.keys.toList()..sort();
  final builder = StringBuffer();
  for (final key in sortedKeys) {
    if (key == 'signature') continue;
    final value = queryParam[key];
    if (value != null && value.isNotEmpty) {
      builder.write('$key=${javaUrlEncode(value)}&');
    }
  }
  String baseString = builder.toString();
  if (baseString.endsWith('&')) {
    baseString = baseString.substring(0, baseString.length - 1);
  }

  final hmac = Hmac(sha1, utf8.encode(accessKeySecret));
  return base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
}

String javaUrlEncode(String value) {
  return Uri.encodeComponent(value).replaceAll('%20', '+');
}

String _pad(int n) => n.toString().padLeft(2, '0');
