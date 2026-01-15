import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

const String UPLOAD_URL = 'https://upload-ost-api.xfyun.cn/file/upload';
const String CREATE_BASE_URL = 'https://ost-api.xfyun.cn';

void main() async {
  print('=== OST API task_type 值测试 ===\n');

  // 使用已上传的文件 URL（节省时间）
  const fileUrl =
      'https://xfyun-seve-dx/IBAUEX+ollA5b/18xtFQFR+TYlU1dp7UqPcyprLi+OlCfJ7RFENIMSx3LBGi0fhEngRNMv80xS4LY2aJ6JesMJ2HuCSWnUJJPbOYPHA953Lv3gVzPScuDPgtnAhtko9ijQZ3tatAD9yUUuGq9khDnSJ9d1I6sO/91d+sMu6F2bVWU0XhB4kEvqBEP4vY7UN2vkmGIXxLDcN1nsOk+V2k+ED5RGnNmXQOyAIgFF3sCT1ueFhqQlJ+cQEOmYo+axExcC2QwRqZ+0rlBYFB8QZux0xdSi1SpU2023DlTgKWk+gojp6lq4nMWUd8dO46Mn0/l/f26JVMo/MrL0HcdkgwzwvFqlhOpHP+IiYGUKYxoBRdJvlLotqO1IG1uNEZ9WbDvW8+yMfQLdmR+dklYDBnzw==';

  // 测试各种 task_type 值
  final taskTypeValues = [
    'asr',
    'ASR',
    'transcribe',
    'transfer',
    'trans',
    'audio',
    'voice',
    'speech',
    'ost',
    'OST',
    'file',
    'record',
    'meeting',
    'default',
    'standard',
    '2',
    '3',
    '4',
    '5',
    '10',
    '16',
    'sms16k',
    'iat',
    'lfasr',
    'fast',
    'normal',
  ];

  for (int i = 0; i < taskTypeValues.length; i++) {
    final taskType = taskTypeValues[i];
    print('--- Test ${i + 1}: task_type = "$taskType" ---');
    await testCreateTask(fileUrl, taskType);
    print('');
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

Future<void> testCreateTask(String fileUrl, String taskType) async {
  final dio = Dio();
  const url = '$CREATE_BASE_URL/v2/ost/create';
  final requestId = const Uuid().v4().replaceAll('-', '');

  final body = {
    'common': {'app_id': APP_ID},
    'business': {
      'request_id': requestId,
      'language': 'zh_cn',
      'task_type': taskType,
    },
    'data': {
      'audio_url': fileUrl,
      'audio_src': 'http',
      'format': 'audio/m4a',
      'encoding': 'aac',
    },
  };

  final bodyJson = jsonEncode(body);

  // 计算 Digest
  final digestBytes = sha256.convert(utf8.encode(bodyJson)).bytes;
  final digest = 'SHA-256=${base64.encode(digestBytes)}';

  // 生成鉴权头
  const requestLine = 'POST /v2/ost/create HTTP/1.1';
  final authHeaders = generateAuthHeaders(url, requestLine, digest: digest);
  authHeaders['Content-Type'] = 'application/json';

  try {
    final response = await dio.post(
      url,
      data: bodyJson,
      options: Options(
        headers: authHeaders,
        validateStatus: (status) => true,
      ),
    );

    final code = response.data['code'];
    final message = response.data['message'];

    if (code == 0 || code == '0') {
      print('✓✓✓ 成功! orderId: ${response.data['data']?['orderId']}');
    } else if (message?.toString().contains('not exists') == true) {
      print('✗ 值无效: $message');
    } else {
      print('Response: ${response.data}');
    }
  } catch (e) {
    print('✗ 异常: $e');
  }
}

Map<String, String> generateAuthHeaders(String urlStr, String requestLine,
    {String? digest}) {
  final uri = Uri.parse(urlStr);
  final date =
      '${DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').format(DateTime.now().toUtc())} GMT';
  final host = uri.host;

  String signatureOrigin = 'host: $host\ndate: $date\n$requestLine';
  if (digest != null) {
    signatureOrigin += '\ndigest: $digest';
  }

  final hmac = Hmac(sha256, utf8.encode(API_SECRET));
  final signature =
      base64.encode(hmac.convert(utf8.encode(signatureOrigin)).bytes);

  String headers = 'host date request-line';
  if (digest != null) {
    headers += ' digest';
  }

  final authorization =
      'api_key="$API_KEY", algorithm="hmac-sha256", headers="$headers", signature="$signature"';

  return {
    'Host': host,
    'Date': date,
    'Authorization': authorization,
    if (digest != null) 'Digest': digest,
  };
}
