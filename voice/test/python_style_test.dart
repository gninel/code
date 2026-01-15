import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// 严格按照 Python 示例实现的测试脚本
/// 关键差异点：
/// 1. 包含 appId 参数
/// 2. language 使用 autodialect
/// 3. 对 key 和 value 都进行 URL 编码

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 严格按照 Python 示例测试 ===\n');

  const testFile = '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a';
  final file = File(testFile);

  if (!file.existsSync()) {
    print('文件不存在: $testFile');
    return;
  }

  final fileSize = await file.length();
  final fileName = testFile.split('/').last;
  final fileBytes = await file.readAsBytes();

  // 使用估算时长（毫秒）
  const duration = 189481;

  print('文件名: $fileName');
  print('文件大小: $fileSize 字节');
  print('音频时长: $duration 毫秒\n');

  // 测试用例
  final testCases = [
    {
      'desc': 'Python示例: appId + autodialect',
      'useAppId': true,
      'language': 'autodialect'
    },
    {'desc': 'appId + cn', 'useAppId': true, 'language': 'cn'},
    {
      'desc': '无appId + autodialect',
      'useAppId': false,
      'language': 'autodialect'
    },
  ];

  for (int i = 0; i < testCases.length; i++) {
    final test = testCases[i];
    print('\n--- Test ${i + 1}: ${test['desc']} ---');

    await runTest(
      fileSize: fileSize,
      fileName: fileName,
      duration: duration,
      useAppId: test['useAppId'] as bool,
      language: test['language'] as String,
      fileBytes: fileBytes,
    );

    await Future.delayed(const Duration(seconds: 2));
  }
}

Future<void> runTest({
  required int fileSize,
  required String fileName,
  required int duration,
  required bool useAppId,
  required String language,
  required List<int> fileBytes,
}) async {
  // 生成时间戳
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}$sign$hours$minutes';

  final signatureRandom = generateRandomStr(16);

  // 构建参数
  final params = <String, String>{};
  if (useAppId) {
    params['appId'] = APP_ID;
  }
  params['accessKeyId'] = API_KEY;
  params['dateTime'] = dateTime;
  params['signatureRandom'] = signatureRandom;
  params['fileSize'] = fileSize.toString();
  params['fileName'] = fileName;
  params['language'] = language;
  params['duration'] = duration.toString();

  // 生成签名
  final signature = generateSignature(params, API_SECRET);

  // 构建 URL
  final queryString = params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  final url = '$BASE_URL/v2/upload?$queryString';

  print('Signature: $signature');

  try {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;

    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/octet-stream');
    request.headers.set('signature', signature);
    request.add(fileBytes);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('Response: $responseBody');

    final data = jsonDecode(responseBody);
    if (data['code'] == '000000') {
      print('✓✓✓ 成功! orderId: ${data['content']?['orderId']}');
    } else {
      print('✗ 失败: ${data['descInfo']} (code: ${data['code']})');
    }

    client.close();
  } catch (e) {
    print('异常: $e');
  }
}

String generateSignature(Map<String, String> params, String secret) {
  final sortedKeys = params.keys.toList()..sort();

  final parts = <String>[];
  for (final key in sortedKeys) {
    if (key == 'signature') continue;
    final value = params[key];
    if (value != null && value.isNotEmpty) {
      parts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
    }
  }

  final baseString = parts.join('&');
  print('baseString: $baseString');

  final hmac = Hmac(sha1, utf8.encode(secret));
  return base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
}

String generateRandomStr(int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = DateTime.now().millisecondsSinceEpoch;
  return List.generate(length, (i) => chars[(random + i * 7) % chars.length])
      .join();
}

String _pad(int n) => n.toString().padLeft(2, '0');
