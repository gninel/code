import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// 生成 CURL 命令的脚本
/// 用于用户自行验证 API 是否可用，排除代码实现问题

const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String BASE_URL = 'https://office-api-ist-dx.iflyaisol.com';

void main() async {
  const testFile = '/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a';
  final file = File(testFile);

  if (!file.existsSync()) {
    print('文件不存在: $testFile');
    return;
  }

  final fileSize = await file.length();
  final fileName = testFile.split('/').last;

  final now = DateTime.now();
  final dateTime =
      '${now.year}-${_pad(now.month)}-${_pad(now.day)}T${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}+0800';
  final signatureRandom = const Uuid().v4();

  // 参数
  final params = <String, String>{
    'accessKeyId': API_KEY,
    'dateTime': dateTime,
    'duration': '189481',
    'fileName': fileName, // 编码前的原始文件名
    'fileSize': fileSize.toString(),
    'language': 'zh_cn', // 尝试 zh_cn
    'signatureRandom': signatureRandom,
  };

  // 1. 计算签名
  final signature = javaStyleSignature(API_SECRET, params);

  // 2. 构建 URL (值需要编码)
  final urlParams =
      params.entries.map((e) => '${e.key}=${javaUrlEncode(e.value)}').join('&');
  final url = '$BASE_URL/v2/upload?$urlParams';

  // 3. 生成 CURL
  final curl = StringBuffer();
  curl.write("curl -X POST '$url' \\\n");
  curl.write("  -H 'Content-Type: application/octet-stream' \\\n");
  curl.write("  -H 'Content-Length: $fileSize' \\\n");
  curl.write("  -H 'signature: $signature' \\\n");
  curl.write("  --data-binary '@$testFile'");

  print('\n=== 请复制以下 CURL 命令在终端运行 ===\n');
  print(curl.toString());
  print('\n=====================================\n');
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
