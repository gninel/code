import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 严格按照官方 Java 代码实现的签名测试
///
/// Java 代码逻辑：
/// 1. TreeMap 按 key 排序
/// 2. 移除 signature
/// 3. 只对 VALUE 进行 URLEncoder.encode（KEY 不编码！）
/// 4. 格式：key=encodedValue&key2=encodedValue2
/// 5. HMAC-SHA1 + Base64

const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  print('=== 严格按照 Java 代码实现的签名测试 ===\n');

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
  print('大小: $fileSize bytes\n');

  // 构建参数（与 Java TreeMap 相同的排序）
  final now = DateTime.now();
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';
  final signatureRandom = const Uuid().v4();

  // 参数 Map（会被排序）
  final queryParam = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '189481',
    'fileName': fileName,
    'fileSize': fileSize.toString(),
    'language': 'cn',
    'signatureRandom': signatureRandom,
  };

  print('原始参数:');
  queryParam.forEach((k, v) => print('  $k: $v'));
  print('');

  // 严格按照 Java 代码生成签名
  final signature = javaStyleSignature(API_SECRET, queryParam);
  print('生成的签名: $signature\n');

  // 添加签名到参数
  queryParam['signature'] = signature;

  // 构建 URL（这一步需要对所有值进行 URL 编码）
  final urlParams = queryParam.entries
      .map((e) => '${e.key}=${javaUrlEncode(e.value)}')
      .join('&');
  final url = '$BASE_URL/v2/upload?$urlParams';

  print('完整 URL:');
  print(url);
  print('');

  // 发送请求
  print('正在上传文件...');
  final dio = Dio();

  try {
    final response = await dio.post(
      url,
      data: Stream.fromIterable(fileBytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': fileSize,
        },
        validateStatus: (status) => true,
      ),
    );

    print('');
    print('Status: ${response.statusCode}');
    print('Response: ${response.data}');

    final code = response.data['code']?.toString();
    if (code == '000000') {
      print('\n✓✓✓ 上传成功！!');
      print('orderId: ${response.data['content']?['orderId']}');
    } else {
      print('\n✗ 上传失败');
      print('错误码: $code');
      print('描述: ${response.data['descInfo']}');
    }
  } catch (e) {
    print('异常: $e');
  }
}

/// 严格按照 Java 代码实现的签名方法
String javaStyleSignature(
    String accessKeySecret, Map<String, String> queryParam) {
  // 1. TreeMap - 按 key 自然排序
  final sortedKeys = queryParam.keys.toList()..sort();

  // 2. 移除 signature（如果存在）并构建 baseString
  final builder = StringBuffer();
  for (final key in sortedKeys) {
    if (key == 'signature') continue;

    final value = queryParam[key];
    if (value != null && value.isNotEmpty) {
      // 3. 只对 VALUE 进行 URLEncoder.encode
      final encodedValue = javaUrlEncode(value);
      builder.write('$key=$encodedValue&');
    }
  }

  // 4. 删除最后一个 &
  String baseString = builder.toString();
  if (baseString.endsWith('&')) {
    baseString = baseString.substring(0, baseString.length - 1);
  }

  print('baseString: $baseString');

  // 5. HMAC-SHA1 签名
  final hmac = Hmac(sha1, utf8.encode(accessKeySecret));
  final signBytes = hmac.convert(utf8.encode(baseString)).bytes;

  // 6. Base64 编码
  return base64.encode(signBytes);
}

/// Java URLEncoder.encode 兼容实现
/// Java URLEncoder 特点：
/// - 空格 -> +
/// - 其他特殊字符 -> %XX
String javaUrlEncode(String value) {
  // Dart Uri.encodeComponent 将空格编码为 %20
  // Java URLEncoder.encode 将空格编码为 +
  return Uri.encodeComponent(value).replaceAll('%20', '+');
}

String _pad(int n) => n.toString().padLeft(2, '0');
