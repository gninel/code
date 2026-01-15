import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 验证签名在 Header 中的正确用法
/// 使用真实文件

const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 验证签名在 Header 中的用法 ===\n');

  const testFile = '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a';
  final file = File(testFile);

  if (!file.existsSync()) {
    print('文件不存在: $testFile');
    return;
  }

  final fileBytes = await file.readAsBytes();
  final fileSize = fileBytes.length;
  final fileName = testFile.split('/').last;

  print('文件大小: $fileSize bytes\n');

  // 测试 1: Header Key = 'signature'
  await runTest(
      '1. Header Key = signature', fileBytes, fileSize, fileName, 'signature');

  // 测试 2: Header Key = 'Signature'
  await runTest(
      '2. Header Key = Signature', fileBytes, fileSize, fileName, 'Signature');
}

Future<void> runTest(String name, List<int> fileBytes, int fileSize,
    String fileName, String headerKey) async {
  print('\n--- $name ---');

  final now = DateTime.now();
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';
  final signatureRandom = const Uuid().v4();

  // URL 参数 (签名中包含这些)
  final params = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '189481',
    'fileName': fileName, // 真实文件名
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,
  };

  // 生成签名
  final signature = javaStyleSignature(API_SECRET, params);
  print('签名: $signature');

  // 构建 URL (不含 signature, 不含 appId)
  final urlParams =
      params.entries.map((e) => '${e.key}=${javaUrlEncode(e.value)}').join('&');
  final url = '$BASE_URL/v2/upload?$urlParams';
  print('URL: $url');

  final dio = Dio();
  try {
    final response = await dio.post(
      url,
      data: Stream.fromIterable(fileBytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': fileSize,
          headerKey: signature, // 放在 Header
        },
        validateStatus: (status) => true,
      ),
    );

    print('Response: ${response.data}');

    if (response.data['code'] == '000000') {
      print('✓✓✓ 成功!!!');
      print('orderId: ${response.data['content']?['orderId']}');
    } else {
      print('✗ 失败: ${response.data['descInfo']}');
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
    // 签名本身不参与签名计算
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
