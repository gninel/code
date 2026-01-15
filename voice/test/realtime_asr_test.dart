import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 讯飞实时语音转写测试
/// 文档: https://www.xfyun.cn/doc/asr/voicedictation/API.html

// API配置
const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

// WebSocket URL
const String WS_URL = 'wss://iat-api.xfyun.cn/v2/iat';

class RealtimeAsrTest {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _resultController;
  bool _isConnected = false;

  /// 开始语音识别测试
  Future<void> startTest() async {
    print('🎤 开始讯飞实时语音转写测试');
    print('=' * 50);

    try {
      // 1. 生成认证URL
      final authUrl = _generateAuthUrl();
      print('🔗 连接URL: $authUrl');

      // 2. 建立WebSocket连接
      print('📡 正在建立WebSocket连接...');
      _channel = WebSocketChannel.connect(Uri.parse(authUrl));

      // 3. 设置消息监听
      _resultController = StreamController<Map<String, dynamic>>.broadcast();
      await _channel!.ready;

      print('✅ WebSocket连接成功');

      // 4. 发送握手消息
      print('🤝 发送握手消息...');
      await _sendHandshakeMessage();

      // 5. 监听响应
      print('👂 开始监听识别结果...');
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _isConnected = true;

      // 6. 模拟发送音频数据
      await _simulateAudioData();

      // 7. 等待一段时间接收结果
      await Future.delayed(const Duration(seconds: 10));

      // 8. 发送结束消息
      print('🏁 发送结束消息...');
      await _sendEndMessage();

      // 9. 等待最终结果
      await Future.delayed(const Duration(seconds: 2));

    } catch (e) {
      print('❌ 测试失败: $e');
    } finally {
      await stopRecognition();
    }
  }

  /// 格式化HTTP日期 (RFC 1123)
  String _formatHttpDate(DateTime dateTime) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final utcTime = dateTime.toUtc();
    final weekday = weekdays[utcTime.weekday - 1];
    final day = utcTime.day.toString().padLeft(2, '0');
    final month = months[utcTime.month - 1];
    final year = utcTime.year;
    final hour = utcTime.hour.toString().padLeft(2, '0');
    final minute = utcTime.minute.toString().padLeft(2, '0');
    final second = utcTime.second.toString().padLeft(2, '0');

    return '$weekday, $day $month $year $hour:$minute:$second GMT';
  }

  /// 生成认证URL
  String _generateAuthUrl() {
    final url = Uri.parse(WS_URL);
    final host = url.host;
    final path = url.path;

    // 生成时间戳 (RFC 1123 format required)
    final date = _formatHttpDate(DateTime.now());
    print('📅 时间戳: $date');

    // 生成签名字符串
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';
    print('✍️  签名原文:\n$signatureOrigin');

    // 计算签名 (HMAC-SHA256)
    final hmacSha256 = Hmac(sha256, utf8.encode(API_SECRET));
    final digest = hmacSha256.convert(utf8.encode(signatureOrigin));
    final signature = base64.encode(digest.bytes);
    print('🔐 签名: $signature');

    // 构建认证参数
    final authorizationOrigin =
        'api_key="$API_KEY", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';
    final authorization = base64.encode(utf8.encode(authorizationOrigin));
    print('🎫 认证头: $authorization');

    // 构建完整URL
    final params = {
      'authorization': authorization,
      'date': date,
      'host': host,
    };

    final uri = Uri.parse(WS_URL);
    return uri.replace(queryParameters: params).toString();
  }

  /// 发送握手消息（首帧）
  Future<void> _sendHandshakeMessage() async {
    final handshakeMessage = {
      'common': {
        'app_id': APP_ID,
      },
      'business': {
        'language': 'zh_cn',
        'domain': 'iat',
        'accent': 'mandarin',
        'vad_eos': 5000, // 静音检测超时 5 秒
        'dwa': 'wpgs', // 动态修正
        'ptt': 1, // 添加标点
      },
      'data': {
        'status': 0, // 0: 首帧
        'format': 'audio/L16;rate=16000',
        'encoding': 'raw',
        'audio': '', // 首帧可以不带音频
      }
    };

    final message = json.encode(handshakeMessage);
    print('📤 握手消息: $message');
    _channel!.sink.add(message);
  }

  /// 发送音频数据
  Future<void> _sendAudioData(Uint8List audioData, {bool isEnd = false}) async {
    if (!_isConnected || _channel == null) {
      print('⚠️  连接未建立，无法发送音频数据');
      return;
    }

    try {
      final base64Audio = base64.encode(audioData);
      final message = {
        'data': {
          'status': isEnd ? 2 : 1, // 1: 中间帧, 2: 结束帧
          'format': 'audio/L16;rate=16000',
          'encoding': 'raw',
          'audio': base64Audio,
        }
      };

      final jsonMessage = json.encode(message);
      _channel!.sink.add(jsonMessage);

      if (isEnd) {
        print('📤 发送结束帧');
      } else {
        print('📤 发送音频数据: ${audioData.length} bytes');
      }
    } catch (e) {
      print('❌ 发送音频数据失败: $e');
    }
  }

  /// 发送结束消息
  Future<void> _sendEndMessage() async {
    final endMessage = {
      'data': {
        'status': 2, // 2: 结束帧
        'format': 'audio/L16;rate=16000',
        'encoding': 'raw',
        'audio': '',
      }
    };

    final message = json.encode(endMessage);
    print('📤 结束消息: $message');
    _channel!.sink.add(message);
  }

  /// 模拟音频数据
  Future<void> _simulateAudioData() async {
    print('🎵 开始模拟发送音频数据...');

    // 创建模拟的音频数据 (PCM 16-bit 16kHz)
    const sampleRate = 16000;
    const durationSeconds = 5;
    const samplesPerFrame = 1280; // 每帧样本数 (约80ms)

    for (int i = 0; i < durationSeconds * 1000 ~/ 80; i++) {
      // 生成模拟的PCM数据
      final audioData = Uint8List(samplesPerFrame * 2); // 16-bit samples

      // 填充一些简单的音频数据（正弦波）
      for (int j = 0; j < samplesPerFrame; j++) {
        final sample = (sin(2 * pi * 440 * (i * samplesPerFrame + j) / sampleRate) * 32767).round();
        final bytes = Uint8List(2);
        bytes[0] = sample & 0xFF;
        bytes[1] = (sample >> 8) & 0xFF;
        audioData[j * 2] = bytes[0];
        audioData[j * 2 + 1] = bytes[1];
      }

      await _sendAudioData(audioData);

      // 等待80ms再发送下一帧
      await Future.delayed(const Duration(milliseconds: 80));
    }

    print('🎵 音频数据发送完成');
  }

  /// 处理WebSocket消息
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      print('📥 收到消息: $data');

      if (data['code'] == 0) {
        // 识别成功
        final resultData = data['data'] ?? {};
        final result = resultData['result'];

        if (result != null) {
          // 解析句子编号和文本
          final sn = result['sn'] as int? ?? 0;
          final pgs = result['pgs'] as String?; // rpl: 替换, apd: 追加
          final rst = result['rst'] as String?; // pgs: 临时结果, rlt: 最终确认结果
          final rg = result['rg'] as List<dynamic>?; // 替换范围 [start, end]
          final text = _parseWsToText(result['ws']);

          print('🎯 识别结果: sn=$sn, pgs=$pgs, rst=$rst, text=$text');

          if (text.isNotEmpty) {
            if (rst == 'rlt') {
              print('✅ 最终结果: $text');
            } else {
              print('⏳ 临时结果: $text');
            }
          }
        }

        // 检查是否结束
        if (resultData['status'] == 2) {
          print('🏁 识别完成');
        }
      } else {
        // 识别失败
        final errorMessage = data['message'] ?? '语音识别失败';
        print('❌ API错误: $errorMessage, Code: ${data['code']}');
      }
    } catch (e) {
      print('❌ 消息解析错误: $e');
    }
  }

  /// 解析 ws 数组为文本
  String _parseWsToText(dynamic ws) {
    if (ws == null) return '';
    try {
      final wsList = ws as List<dynamic>;
      final words = <String>[];
      for (final wsItem in wsList) {
        final cw = wsItem['cw'] as List<dynamic>?;
        if (cw != null && cw.isNotEmpty) {
          final word = cw[0]['w'] as String?;
          if (word != null) {
            words.add(word);
          }
        }
      }
      return words.join();
    } catch (e) {
      return '';
    }
  }

  /// 处理WebSocket错误
  void _handleError(dynamic error) {
    print('❌ WebSocket错误: $error');
    _isConnected = false;
  }

  /// 处理WebSocket关闭
  void _handleDone() {
    print('🔌 WebSocket连接关闭');
    _isConnected = false;
  }

  /// 停止语音识别
  Future<void> stopRecognition() async {
    print('🛑 停止语音识别');

    _isConnected = false;

    try {
      await _channel?.sink.close();
      await _resultController?.close();
    } catch (e) {
      print('⚠️  关闭连接时出错: $e');
    }

    _channel = null;
    _resultController = null;
  }
}

void main() async {
  final test = RealtimeAsrTest();
  await test.startTest();
  print('\n🎉 测试完成');
}