import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 讯飞实时语音转写测试 - 使用真实音频文件
/// 文档: https://www.xfyun.cn/doc/asr/voicedictation/API.html

// API配置
const String APP_ID = '2e72f06c';
const String API_KEY = '390583124637d47a099fdd5a59860bde';
const String API_SECRET = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

// WebSocket URL
const String WS_URL = 'wss://iat-api.xfyun.cn/v2/iat';

class RealAudioAsrTest {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final StringBuffer _recognizedText = StringBuffer();

  /// 开始语音识别测试
  Future<void> startTestWithAudioFile(String audioFilePath) async {
    print('🎤 开始讯飞实时语音转写测试');
    print('=' * 50);
    print('📁 音频文件: $audioFilePath');

    final audioFile = File(audioFilePath);
    if (!audioFile.existsSync()) {
      print('❌ 音频文件不存在');
      return;
    }

    try {
      // 1. 建立WebSocket连接
      await _connectWebSocket();

      // 2. 发送握手消息
      await _sendHandshakeMessage();

      // 3. 读取并发送音频文件
      await _sendAudioFile(audioFile);

      // 4. 发送结束消息
      await _sendEndMessage();

      // 5. 等待最终结果
      await Future.delayed(const Duration(seconds: 3));

    } catch (e) {
      print('❌ 测试失败: $e');
    } finally {
      await stopRecognition();
    }
  }

  /// 建立WebSocket连接
  Future<void> _connectWebSocket() async {
    print('🔗 正在建立WebSocket连接...');

    final authUrl = _generateAuthUrl();
    print('🔗 连接URL: ${authUrl.length > 100 ? '${authUrl.substring(0, 100)}...' : authUrl}');

    _channel = WebSocketChannel.connect(Uri.parse(authUrl));
    await _channel!.ready;

    // 监听响应
    _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
    );

    _isConnected = true;
    print('✅ WebSocket连接成功');
  }

  /// 生成认证URL
  String _generateAuthUrl() {
    final url = Uri.parse(WS_URL);
    final host = url.host;
    final path = url.path;

    // 生成时间戳 (RFC 1123 format required)
    final date = _formatHttpDate(DateTime.now());

    // 生成签名字符串
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';

    // 计算签名 (HMAC-SHA256)
    final hmacSha256 = Hmac(sha256, utf8.encode(API_SECRET));
    final digest = hmacSha256.convert(utf8.encode(signatureOrigin));
    final signature = base64.encode(digest.bytes);

    // 构建认证参数
    final authorizationOrigin =
        'api_key="$API_KEY", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';
    final authorization = base64.encode(utf8.encode(authorizationOrigin));

    // 构建完整URL
    final params = {
      'authorization': authorization,
      'date': date,
      'host': host,
    };

    final uri = Uri.parse(WS_URL);
    return uri.replace(queryParameters: params).toString();
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

  /// 发送握手消息（首帧）
  Future<void> _sendHandshakeMessage() async {
    print('🤝 发送握手消息...');

    final handshakeMessage = {
      'common': {
        'app_id': APP_ID,
      },
      'business': {
        'language': 'zh_cn',
        'domain': 'iat',
        'accent': 'mandarin',
        'vad_eos': 10000, // 静音检测超时 10 秒
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
    _channel!.sink.add(message);
  }

  /// 发送音频文件
  Future<void> _sendAudioFile(File audioFile) async {
    print('📤 开始发送音频文件...');

    final fileBytes = await audioFile.readAsBytes();
    final fileSize = fileBytes.length;
    print('📏 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

    // 如果不是PCM格式，需要转换。这里假设已经是16kHz 16bit PCM格式
    // 如果是其他格式，需要先转换为PCM

    const frameSize = 1280; // 每帧字节数 (16-bit, 16kHz, 80ms)
    int offset = 0;
    int frameCount = 0;

    while (offset < fileBytes.length) {
      final remainingBytes = fileBytes.length - offset;
      final currentFrameSize = min(frameSize, remainingBytes);

      final frameData = Uint8List.fromList(
        fileBytes.sublist(offset, offset + currentFrameSize)
      );

      await _sendAudioData(frameData, isEnd: false);

      offset += currentFrameSize;
      frameCount++;

      // 每80ms发送一帧
      await Future.delayed(const Duration(milliseconds: 80));

      // 进度显示
      if (frameCount % 100 == 0) {
        final progress = (offset / fileSize * 100).toStringAsFixed(1);
        print('📊 发送进度: $progress%');
      }
    }

    print('✅ 音频文件发送完成，共 $frameCount 帧');
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
    } catch (e) {
      print('❌ 发送音频数据失败: $e');
    }
  }

  /// 发送结束消息
  Future<void> _sendEndMessage() async {
    print('🏁 发送结束消息...');

    final endMessage = {
      'data': {
        'status': 2, // 2: 结束帧
        'format': 'audio/L16;rate=16000',
        'encoding': 'raw',
        'audio': '',
      }
    };

    final message = json.encode(endMessage);
    _channel!.sink.add(message);
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
          final text = _parseWsToText(result['ws']);

          print('🎯 识别结果: sn=$sn, pgs=$pgs, rst=$rst, text=$text');

          if (text.isNotEmpty) {
            if (rst == 'rlt') {
              print('✅ 最终结果: $text');
              _recognizedText.write(text);
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

    // 显示最终识别结果
    if (_recognizedText.isNotEmpty) {
      print('\n📄 最终识别结果:');
      print('=' * 40);
      print(_recognizedText.toString());
      print('=' * 40);
    }
  }

  /// 停止语音识别
  Future<void> stopRecognition() async {
    print('🛑 停止语音识别');

    _isConnected = false;

    try {
      await _channel?.sink.close();
    } catch (e) {
      print('⚠️  关闭连接时出错: $e');
    }

    _channel = null;
  }
}

void main(List<String> args) async {
  String audioFile;

  if (args.isNotEmpty) {
    audioFile = args[0];
  } else {
    // 默认查找测试音频文件
    final candidates = [
      '/Users/zhb/Documents/code/voice/test_audio/test_1.wav',
      '/Users/zhb/Documents/code/voice/test_audio.mp3',
    ];

    audioFile = '';
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        audioFile = candidate;
        break;
      }
    }

    if (audioFile.isEmpty) {
      print('❌ 未找到测试音频文件');
      print('请指定音频文件路径: dart test/real_audio_asr_test.dart <音频文件路径>');
      return;
    }
  }

  final test = RealAudioAsrTest();
  await test.startTestWithAudioFile(audioFile);
  print('\n🎉 测试完成');
}