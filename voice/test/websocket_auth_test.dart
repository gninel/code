import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';

/// 验证 WebSocket 语音听写服务权限
///
/// 目的：如果这个连接成功，说明用户的 AppID 开通的是 "语音听写" 服务
/// 而不是 "录音文件转写" 服务。这两个是完全不同的接口。

const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';
const String HOST = 'iat-api.xfyun.cn';
const String PATH = '/v2/iat';

void main() async {
  print('=== 验证 WebSocket 语音听写服务 ===\n');

  final url = _generateAuthUrl();
  print('Connecting to: $url');

  try {
    final channel = IOWebSocketChannel.connect(Uri.parse(url));

    // 监听消息
    channel.stream.listen(
      (message) {
        print('Received: $message');
        final data = jsonDecode(message);
        if (data['code'] == 0) {
          print('✓✓✓ WebSocket 连接和鉴权成功！');
          print('结论：该账号开通了"语音听写"服务。');
          channel.sink.close();
        } else {
          print('✗ WebSocket 错误: ${data['message']} (code: ${data['code']})');
        }
      },
      onError: (error) {
        print('WebSocket Error: $error');
      },
      onDone: () {
        print('WebSocket Closed');
      },
    );

    // 发送握手帧 (模拟开始识别)
    // 只是为了触发鉴权响应
    final handshake = {
      "common": {"app_id": APP_ID},
      "business": {"language": "zh_cn", "domain": "iat", "accent": "mandarin"},
      "data": {"status": 0, "format": "audio/L16;rate=16000", "encoding": "raw"}
    };
    channel.sink.add(jsonEncode(handshake));
    print('Sent handshake...');

    // 等待一会
    await Future.delayed(const Duration(seconds: 5));
  } catch (e) {
    print('这是异常: $e');
  }
}

String _generateAuthUrl() {
  final date = HttpDate.format(DateTime.now());
  final signatureOrigin = 'host: $HOST\ndate: $date\nGET $PATH HTTP/1.1';

  final hmac = Hmac(sha256, utf8.encode(API_SECRET));
  final signature =
      base64.encode(hmac.convert(utf8.encode(signatureOrigin)).bytes);

  final authorization = base64.encode(utf8.encode(
      'api_key="$API_KEY", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"'));

  return 'wss://$HOST$PATH?authorization=$authorization&date=${Uri.encodeComponent(date)}&host=$HOST';
}
