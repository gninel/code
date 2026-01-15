import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// OST API - Create Task 参数测试 (v3)
/// 目标：验证 ent 参数绕过 domain 错误

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

const String UPLOAD_URL = 'https://upload-ost-api.xfyun.cn/file/upload';
const String CREATE_URL = 'https://ost-api.xfyun.cn/v2/ost/create';

void main() async {
  print('=== OST API Create Task 参数测试 (v3) ===\n');

  // 第一步：上传文件获取 URL
  final fileUrl =
      await uploadFile('/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a');
  if (fileUrl == null) {
    print('上传失败！');
    return;
  }
  print('文件上传成功: $fileUrl\n');

  // 测试各种 ent 参数组合
  final testCases = [
    {
      'desc': 'ent=trans_ost_fast',
      'params': {'language': 'zh_cn', 'ent': 'trans_ost_fast'}
    },
    {
      'desc': 'ent=sms16k',
      'params': {'language': 'zh_cn', 'ent': 'sms16k'}
    },
    {
      'desc': 'task_type=trans (Retry)',
      'params': {'language': 'zh_cn', 'task_type': 'trans'}
    },
    {
      'desc': 'task_type=trans + ent=trans_ost_fast',
      'params': {
        'language': 'zh_cn',
        'task_type': 'trans',
        'ent': 'trans_ost_fast'
      }
    },
  ];

  for (int i = 0; i < testCases.length; i++) {
    final test = testCases[i];
    print('\n--- Test ${i + 1}: ${test['desc']} ---');
    await testCreateTask(fileUrl, test['params'] as Map<String, String>);
    await Future.delayed(const Duration(seconds: 1));
  }
}

Future<String?> uploadFile(String filePath) async {
  print('正在上传文件...');
  final dio = Dio();
  final file = File(filePath);
  if (!file.existsSync()) {
    print('文件不存在: $filePath');
    return null;
  }

  final requestId = const Uuid().v4().replaceAll('-', '');

  final authHeaders =
      generateAuthHeaders(UPLOAD_URL, 'POST /file/upload HTTP/1.1');

  try {
    final formData = FormData.fromMap({
      'data': await MultipartFile.fromFile(filePath),
      'app_id': APP_ID,
      'request_id': requestId,
    });

    final response = await dio.post(
      UPLOAD_URL,
      data: formData,
      options: Options(headers: authHeaders, validateStatus: (status) => true),
    );

    final data = response.data;
    if (data['code'] == 0 || data['code'] == '0') {
      return data['data']['url'];
    } else {
      print('上传错误: ${data['message']} (Code: ${data['code']})');
      return null;
    }
  } catch (e) {
    print('上传异常: $e');
    return null;
  }
}

Future<void> testCreateTask(
    String fileUrl, Map<String, String> businessParams) async {
  final dio = Dio();
  final requestId = const Uuid().v4().replaceAll('-', '');

  final body = {
    'common': {'app_id': APP_ID},
    'business': {
      'request_id': requestId,
      ...businessParams,
    },
    'data': {
      'audio_url': fileUrl,
      'audio_src': 'http',
      'format': 'audio/m4a',
      'encoding': 'aac',
    },
  };

  final bodyJson = jsonEncode(body);
  final digestBytes = sha256.convert(utf8.encode(bodyJson)).bytes;
  final digest = 'SHA-256=${base64.encode(digestBytes)}';

  final authHeaders = generateAuthHeaders(
      CREATE_URL, 'POST /v2/ost/create HTTP/1.1',
      digest: digest);
  authHeaders['Content-Type'] = 'application/json';

  try {
    final response = await dio.post(
      CREATE_URL,
      data: bodyJson,
      options: Options(headers: authHeaders, validateStatus: (status) => true),
    );

    final data = response.data;
    print('Response: $data');
    if (data['code'] == 0 || data['code'] == '0') {
      print('✓✓✓ 成功! task_id: ${data['data']?['task_id']}');
    } else {
      print('✗ 错误: ${data['code']} - ${data['message']}');
    }
  } catch (e) {
    print('异常: $e');
  }
}

Map<String, String> generateAuthHeaders(String urlStr, String requestLine,
    {String? digest}) {
  final uri = Uri.parse(urlStr);
  final date = '${DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .format(DateTime.now().toUtc())} GMT';
  final host = uri.host;

  String signatureOrigin = 'host: $host\ndate: $date\n$requestLine';
  if (digest != null) signatureOrigin += '\ndigest: $digest';

  final hmac = Hmac(sha256, utf8.encode(API_SECRET));
  final signature =
      base64.encode(hmac.convert(utf8.encode(signatureOrigin)).bytes);

  String headers = 'host date request-line';
  if (digest != null) headers += ' digest';

  final authorization =
      'api_key="$API_KEY", algorithm="hmac-sha256", headers="$headers", signature="$signature"';

  final result = {
    'Host': host,
    'Date': date,
    'Authorization': authorization,
  };
  if (digest != null) result['Digest'] = digest;
  return result;
}
