import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 录音转写大模型 API - 真实文件上传测试
/// 测试发送真实文件数据

const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 录音转写大模型 API - 真实文件上传测试 ===\n');

  const testFile = '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a';
  final file = File(testFile);

  if (!file.existsSync()) {
    print('文件不存在: $testFile');
    return;
  }

  final fileBytes = await file.readAsBytes();
  final fileSize = fileBytes.length;
  final fileName = testFile.split('/').last;

  print('文件: $fileName');
  print('大小: $fileSize bytes');
  print('');

  // 生成请求参数
  final now = DateTime.now();
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';
  final signatureRandom = const Uuid().v4();

  final params = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '189481', // 大约 3 分钟
    'fileName': fileName,
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,
  };

  // 生成 baseString (值需要 URL 编码)
  final sortedKeys = params.keys.toList()..sort();
  final pairs = <String>[];
  for (final key in sortedKeys) {
    final value = _javaUrlEncode(params[key]!);
    pairs.add('$key=$value');
  }
  final baseString = pairs.join('&');
  print('baseString: $baseString');

  // HMAC-SHA1 签名
  final hmac = Hmac(sha1, utf8.encode(API_SECRET));
  final signature = base64.encode(hmac.convert(utf8.encode(baseString)).bytes);
  print('signature: $signature');

  // 添加签名 (签名本身也需要 URL 编码)
  params['signature'] = signature;

  // 构建 URL
  final urlPairs =
      params.entries.map((e) => '${e.key}=${_javaUrlEncode(e.value)}');
  final url = '$BASE_URL/v2/upload?${urlPairs.join('&')}';
  print('URL: $url');
  print('');

  // 发送请求 - 这次发送真实文件数据
  final dio = Dio();
  dio.options.validateStatus = (status) => true;

  print('正在上传文件...');

  try {
    final response = await dio.post(
      url,
      data: Stream.fromIterable(fileBytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': fileSize,
        },
      ),
    );

    print('');
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.data}');

    final code = response.data['code']?.toString();
    if (code == '000000') {
      print('');
      print('✓✓✓ 上传成功！');
      print('orderId: ${response.data['content']?['orderId']}');
    } else {
      print('');
      print('✗ 上传失败');
      print('错误码: $code');
      print('描述: ${response.data['descInfo']}');
    }
  } catch (e) {
    print('异常: $e');
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _javaUrlEncode(String value) {
  return Uri.encodeComponent(value).replaceAll('%20', '+');
}
