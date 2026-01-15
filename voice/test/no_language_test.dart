import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// 测试不包含language参数
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

void main() async {
  print('🔍 测试不包含language参数');
  print('=' * 40);

  const testFile = '/Users/zhb/Documents/code/voice/test_audio/test_1.wav';
  final file = File(testFile);

  if (!file.existsSync()) {
    print('❌ 测试文件不存在');
    return;
  }

  final fileSize = await file.length();
  final fileName = file.path.split('/').last;

  try {
    final success = await testWithoutLanguage(file);
    if (success) {
      print('✅ 不包含language参数成功！');
    } else {
      print('❌ 不包含language参数失败');
    }
  } catch (e) {
    print('❌ 测试时出错: $e');
  }
}

Future<bool> testWithoutLanguage(File file) async {
  final fileSize = await file.length();
  final fileName = file.path.split('/').last;

  // 构建请求参数（不包含language）
  final dateTime = _getDateTimeString();
  final signatureRandom = const Uuid().v4();

  final params = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '8522',
    'fileName': fileName,
    'fileSize': fileSize.toString(),
    // 'language': 'zh_cn', // 不包含language参数
    'signatureRandom': signatureRandom,
  };

  // 生成签名
  final signature = _generateSignature(params, API_SECRET);

  // 构建 URL
  final queryString = params.entries
      .map((e) => '${e.key}=${_javaUrlEncode(e.value)}')
      .join('&');
  final url = 'https://office-api-ist-dx.iflyaisol.com/v2/upload?$queryString';

  print('请求URL: $url');

  try {
    final dio = Dio();
    final response = await dio.post(
      url,
      data: file.readAsBytesSync(),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': fileSize,
          'signature': signature,
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final data = response.data;
    final code = data['code']?.toString();

    if (code == '000000' || code == '0') {
      print('✓ 上传成功，orderId: ${data['content']?['orderId']}');
      return true;
    } else {
      print('✗ 上传失败: ${data['descInfo']} (Code: $code)');
      return false;
    }
  } catch (e) {
    print('✗ 网络错误: $e');
    return false;
  }
}

String _generateSignature(Map<String, String> params, String accessKeySecret) {
  final sortedKeys = params.keys.toList()..sort();

  final pairs = <String>[];
  for (final key in sortedKeys) {
    if (key != 'signature' && params[key]?.isNotEmpty == true) {
      final value = _javaUrlEncode(params[key]!);
      pairs.add('$key=$value');
    }
  }
  final baseString = pairs.join('&');

  final hmac = Hmac(sha1, utf8.encode(accessKeySecret));
  final digest = hmac.convert(utf8.encode(baseString));

  return base64.encode(digest.bytes);
}

String _javaUrlEncode(String value) {
  return Uri.encodeComponent(value).replaceAll('%20', '+');
}

String _getDateTimeString() {
  final now = DateTime.now();
  final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  final dateStr = formatter.format(now);

  final offset = now.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

  return '$dateStr$sign$hours$minutes';
}