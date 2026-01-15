import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 深度调试脚本
/// 目的：找出为何服务器提示 "signature is empty"

const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 深度调试 signature is empty 问题 ===\n');

  // 1. 基准测试: 不带 signature 参数
  // 预期: 应该返回 "signature is empty"
  await runTest('1. 不带 signature', (params) {
    params.remove('signature');
    return params;
  });

  // 2. 正常测试: 带 signature (再次确认)
  await runTest('2. 带 signature (URL Encoded)', (params) {
    // 保持原样
    return params;
  });

  // 3. 匹配 Content-Length
  await runTest('3. 匹配 Content-Length', (params) {
    return params;
  }, matchContentLength: true);

  // 4. 尝试放在 Header 中
  await runTest('4. Signature 放在 Header', (params) {
    final sig = params['signature'];
    params.remove('signature');
    return params;
  }, headerSignature: true);
}

Future<void> runTest(
  String name,
  Map<String, String> Function(Map<String, String>) modifyParams, {
  bool matchContentLength = false,
  bool headerSignature = false,
}) async {
  print('\n--- $name ---');

  final now = DateTime.now();
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';
  final signatureRandom = const Uuid().v4();
  final dummyData = utf8.encode('1234567890'); // 10 bytes
  final fileSize = dummyData.length;

  final params = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '1000',
    'fileName': 'test.txt',
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,
  };

  // 生成签名
  final signature = javaStyleSignature(API_SECRET, params);
  params['signature'] = signature;

  // 修改参数
  final finalParams = modifyParams(Map.from(params));
  String? headerSig;
  if (headerSignature) {
    headerSig = signature;
  }

  // 构建 URL
  final urlParams = finalParams.entries
      .map((e) => '${e.key}=${javaUrlEncode(e.value)}')
      .join('&');
  final url = '$BASE_URL/v2/upload?$urlParams';
  print('URL: $url');

  final dio = Dio();
  try {
    final headers = <String, dynamic>{
      'Content-Type': 'application/octet-stream',
    };

    if (matchContentLength) {
      headers['Content-Length'] = fileSize;
    }

    if (headerSig != null) {
      headers['signature'] = headerSig;
      headers['Signature'] = headerSig; // Try capital
    }

    final response = await dio.post(
      url,
      data: Stream.fromIterable([dummyData]),
      options: Options(
        headers: headers,
        validateStatus: (status) => true,
      ),
    );

    print('Status: ${response.statusCode}');
    print('Response: ${response.data}');
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
