import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

// OST API Conf
const String UPLOAD_URL = 'https://upload-ost-api.xfyun.cn/file/upload';

void main() async {
  print('\n=== Test Case OST: Upload M4A to OST API ===');
  // 使用用户真实文件
  await testOstUpload('/Users/zhb/Documents/code/voice/北京记忆：从夏令营到大学.m4a');
}

Future<void> testOstUpload(String filePath, [List<int>? content]) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('File not found: $filePath');
    return;
  }
  final fileContent = await file.readAsBytes();

  final dio = Dio();
  dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));

  final requestId = const Uuid().v4().replaceAll('-', '');

  // OST Auth
  final date = '${DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .format(DateTime.now().toUtc())} GMT';
  const host = 'upload-ost-api.xfyun.cn';
  const requestLine = 'POST /file/upload HTTP/1.1';
  const digest =
      'SHA-256=47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU='; // Assuming empty/dummy digest for multipart

  final signatureOrigin =
      'host: $host\ndate: $date\n$requestLine\ndigest: $digest';
  final hmac = Hmac(sha256, utf8.encode(API_SECRET));
  final signature =
      base64.encode(hmac.convert(utf8.encode(signatureOrigin)).bytes);
  final authorization =
      'api_key="$API_KEY", algorithm="hmac-sha256", headers="host date request-line digest", signature="$signature"';

  try {
    // Need to use FormData for multipart
    final formData = FormData.fromMap({
      'data': MultipartFile.fromBytes(fileContent, filename: filePath),
      'app_id': APP_ID,
      'request_id': requestId,
    });

    final response = await dio.post(
      UPLOAD_URL,
      data: formData,
      options: Options(
        headers: {
          'host': host,
          'date': date,
          'authorization': authorization,
          'digest': digest,
        },
      ),
    );
    print('Response: ${response.data}');

    final code = response.data['code'];
    if (response.statusCode == 200 && (code == 0 || code == '0')) {
      final fileUrl = response.data['data']['url'];
      print('Upload Success! URL: $fileUrl');

      // NOW Create Task with M4A params
      await createOstTask(fileUrl, 'm4a');
    }
  } catch (e) {
    if (e is DioException) {
      print('Error: ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}

Future<void> createOstTask(String fileUrl, String format) async {
  const createUrl =
      'https://ost-api.xfyun.cn/v2/ost/create'; // 尝试标准版 create (无 pro_)
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(responseBody: true));

  final date = '${DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US')
          .format(DateTime.now().toUtc())} GMT';
  const host = 'ost-api.xfyun.cn';

  // Construct Body
  // M4A Params
  final dataMap = {
    'audio_url': fileUrl,
    'audio_src': 'http',
    'format': 'audio/m4a', // Try audio/m4a or audio/mp4
    'encoding': 'aac', // Try aac
  };

  final requestMap = {
    'common': {'app_id': APP_ID},
    'business': {
      'request_id': const Uuid().v4().replaceAll('-', ''),
      'language': 'zh_cn',
      // 'domain': 'pro_ost_ed',
      // 尝试去掉 domain 或者换个值
      // 'domain': 'ist_ed_open', // Try removing domain as well if error persists
      // 某些文档说 business 里不需要 domain?
      // 试着加 ent 参数
      'ent': 'phrases',
    },
    'data': dataMap,
  };
  final body = json.encode(requestMap);

  // Auth
  final digestBytes = sha256.convert(utf8.encode(body)).bytes;
  final digest = 'SHA-256=${base64.encode(digestBytes)}';
  const requestLine = 'POST /v2/ost/create HTTP/1.1';
  final signatureOrigin =
      'host: $host\ndate: $date\n$requestLine\ndigest: $digest';
  final hmac = Hmac(sha256, utf8.encode(API_SECRET));
  final signature =
      base64.encode(hmac.convert(utf8.encode(signatureOrigin)).bytes);
  final authorization =
      'api_key="$API_KEY", algorithm="hmac-sha256", headers="host date request-line digest", signature="$signature"';

  try {
    final response = await dio.post(createUrl,
        data: body,
        options: Options(headers: {
          'host': host,
          'date': date,
          'authorization': authorization,
          'digest': digest,
          'Content-Type': 'application/json'
        }));
    print('Create Task Response: ${response.data}');
  } catch (e) {
    if (e is DioException) {
      print('Create Task Error: ${e.response?.data}');
    } else {
      print('Create Task Error: $e');
    }
  }
}
