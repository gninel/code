import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 录音转写大模型 API 签名测试脚本
/// 目的：彻底验证签名生成逻辑是否与官方 Java 代码一致

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 录音转写大模型 API 签名验证测试 ===\n');

  // 测试1: 使用简单参数验证签名逻辑
  await testSimpleSignature();

  // 测试2: 使用真实文件测试上传（小文件）
  await testUpload();
}

/// 测试1: 简单签名验证
Future<void> testSimpleSignature() async {
  print('--- Test 1: 签名生成验证 ---');

  // 固定参数用于调试
  final params = {
    'accessKeyId': API_KEY,
    'dateTime': '2025-12-21T21:00:00+0800',
    'duration': '1000',
    'fileName': 'test.mp3',
    'fileSize': '1024',
    'language': 'cn',
    'signatureRandom': 'test-uuid-1234',
  };

  // 方法1: 当前实现 (Uri.encodeComponent)
  final sig1 = generateSignature_DartUri(params, API_SECRET);
  print('签名方法1 (Uri.encodeComponent): $sig1');

  // 方法2: Java URLEncoder 模拟 (空格 -> +)
  final sig2 = generateSignature_JavaStyle(params, API_SECRET);
  print('签名方法2 (Java URLEncoder 模拟): $sig2');

  // 方法3: 不对值编码
  final sig3 = generateSignature_NoEncode(params, API_SECRET);
  print('签名方法3 (无编码): $sig3');

  print('');
}

/// 测试2: 真实上传测试
Future<void> testUpload() async {
  print('--- Test 2: 真实上传测试 ---');

  // 使用小音频文件测试
  const testFile = '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a';
  final file = File(testFile);

  if (!file.existsSync()) {
    print('文件不存在: $testFile');
    return;
  }

  final fileSize = file.lengthSync();
  final fileName = testFile.split('/').last;

  // 测试多种签名方法
  final signatureMethods = [
    {'name': '方法1: 值编码 + 签名编码', 'encode': true, 'sigEncode': true},
    {'name': '方法2: 值编码 + 签名不编码', 'encode': true, 'sigEncode': false},
    {'name': '方法3: 值不编码 + 签名不编码', 'encode': false, 'sigEncode': false},
  ];

  for (final method in signatureMethods) {
    print('\n=== ${method['name']} ===');
    await testUploadWithMethod(
      fileName: fileName,
      fileSize: fileSize,
      duration: 189481,
      encodeValues: method['encode'] as bool,
      encodeSignature: method['sigEncode'] as bool,
    );
    await Future.delayed(const Duration(seconds: 1));
  }
}

Future<void> testUploadWithMethod({
  required String fileName,
  required int fileSize,
  required int duration,
  required bool encodeValues,
  required bool encodeSignature,
}) async {
  final dio = Dio();
  final now = DateTime.now();

  // 格式化日期时间: yyyy-MM-dd'T'HH:mm:ss+HHmm
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';

  final signatureRandom = const Uuid().v4();

  final params = {
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': duration.toString(),
    'fileName': fileName,
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,
  };

  // 生成签名 baseString
  final sortedKeys = params.keys.toList()..sort();
  final pairs = <String>[];
  for (final key in sortedKeys) {
    final value = encodeValues ? _javaUrlEncode(params[key]!) : params[key]!;
    pairs.add('$key=$value');
  }
  final baseString = pairs.join('&');
  print('baseString: $baseString');

  // HMAC-SHA1 签名
  final hmac = Hmac(sha1, utf8.encode(API_SECRET));
  final signature = base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
  print('signature (raw): $signature');

  // 添加签名到参数
  params['signature'] = signature;

  // 构建 URL (签名是否编码)
  final urlPairs = <String>[];
  for (final key in params.keys) {
    final value = params[key]!;
    if (key == 'signature') {
      urlPairs.add('$key=${encodeSignature ? _javaUrlEncode(value) : value}');
    } else {
      urlPairs.add('$key=${_javaUrlEncode(value)}');
    }
  }
  final url = '$BASE_URL/v2/upload?${urlPairs.join('&')}';
  print('URL: $url');

  try {
    // 发送请求 (不传文件，只测试签名)
    final response = await dio.post(
      url,
      data: '{}', // 空数据测试签名
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => true,
      ),
    );

    print('Status: ${response.statusCode}');
    print('Response: ${response.data}');

    final code = response.data['code']?.toString();
    if (code == '000000') {
      print('✓✓✓ 签名验证成功！orderId: ${response.data['content']?['orderId']}');
    } else if (code == '100003' &&
        response.data['descInfo']?.toString().contains('signature') == true) {
      print('✗ 签名错误: ${response.data['descInfo']}');
    } else {
      print('结果: ${response.data}');
    }
  } catch (e) {
    print('异常: $e');
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _javaUrlEncode(String value) {
  return Uri.encodeComponent(value).replaceAll('%20', '+');
}

// 签名方法1: 使用 Uri.encodeComponent
String generateSignature_DartUri(Map<String, String> params, String secret) {
  final sortedKeys = params.keys.toList()..sort();
  final pairs = <String>[];
  for (final key in sortedKeys) {
    if (params[key]?.isNotEmpty == true) {
      pairs.add('$key=${Uri.encodeComponent(params[key]!)}');
    }
  }
  final baseString = pairs.join('&');
  final hmac = Hmac(sha1, utf8.encode(secret));
  return base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
}

// 签名方法2: Java URLEncoder 模拟 (空格 -> +)
String generateSignature_JavaStyle(Map<String, String> params, String secret) {
  final sortedKeys = params.keys.toList()..sort();
  final pairs = <String>[];
  for (final key in sortedKeys) {
    if (params[key]?.isNotEmpty == true) {
      final value = Uri.encodeComponent(params[key]!).replaceAll('%20', '+');
      pairs.add('$key=$value');
    }
  }
  final baseString = pairs.join('&');
  final hmac = Hmac(sha1, utf8.encode(secret));
  return base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
}

// 签名方法3: 不对值编码
String generateSignature_NoEncode(Map<String, String> params, String secret) {
  final sortedKeys = params.keys.toList()..sort();
  final pairs = <String>[];
  for (final key in sortedKeys) {
    if (params[key]?.isNotEmpty == true) {
      pairs.add('$key=${params[key]}');
    }
  }
  final baseString = pairs.join('&');
  final hmac = Hmac(sha1, utf8.encode(secret));
  return base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
}
