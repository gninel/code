import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// 讯飞语音识别服务
@singleton
class XunfeiAsrService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _resultController;
  StreamSubscription? _subscription;
  
  /// 句子分段存储 (sn -> text)
  final Map<int, String> _sentenceSegments = {};
  
  /// 归档文本 (用于断线重连时保存之前的识别结果)
  String _archivedText = '';

  /// 获取累积的完整文本
  String get accumulatedText {
    String currentSegments = '';
    if (_sentenceSegments.isNotEmpty) {
      final sortedKeys = _sentenceSegments.keys.toList()..sort();
      currentSegments = sortedKeys.map((k) => _sentenceSegments[k]).join();
    }
    return _archivedText + currentSegments;
  }

  /// 是否已连接
  bool get isConnected => _channel != null;

  /// 获取最终的完整转写文本（在关闭连接前调用）
  String getFinalText() {
    return accumulatedText;
  }

  /// 语音识别结果流
  Stream<Map<String, dynamic>> get recognitionResultStream {
    _resultController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _resultController!.stream;
  }
  
  /// 归档当前文本并清除分段 (通常在重连前调用)
  void archiveText() {
    if (_sentenceSegments.isNotEmpty) {
      final sortedKeys = _sentenceSegments.keys.toList()..sort();
      _archivedText += sortedKeys.map((k) => _sentenceSegments[k]).join();
      _sentenceSegments.clear();
    }
  }
  
  /// 清除所有文本 (包括归档)
  void clearAccumulatedText() {
    _sentenceSegments.clear();
    _archivedText = '';
  }

  /// 开始语音识别
  /// [clearHistory] 是否清除之前的识别历史，默认为 true。断线重连时应设为 false。
  Future<void> startRecognition({bool clearHistory = true}) async {
    print('ASR: startRecognition(clearHistory: $clearHistory)');
    try {
      // 关闭之前的连接
      await stopRecognition();
      
      // 根据参数决定是否清除历史
      if (clearHistory) {
        clearAccumulatedText();
      }

      // 获取认证URL
      final authUrl = _generateAuthUrl();
      print('ASR: Connecting to $authUrl');

      // 建立WebSocket连接
      _channel = WebSocketChannel.connect(Uri.parse(authUrl));

      // 初始化结果控制器
      _resultController = StreamController<Map<String, dynamic>>.broadcast();

      // 监听WebSocket消息
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // 发送握手消息
      print('ASR: Sending handshake');
      await _sendHandshakeMessage();
    } catch (e) {
      print('ASR: Connection error: $e');
      throw AsrException.websocketConnectionFailed();
    }
  }

  /// 发送音频数据
  Future<void> sendAudioData(Uint8List audioData, {bool isEnd = false}) async {
    if (_channel == null) {
      throw AsrException.websocketConnectionFailed();
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
      
      _channel!.sink.add(json.encode(message));
    } catch (e) {
      print('ASR: Send data error: $e');
      throw AsrException.recognitionFailed();
    }
  }

  /// 停止语音识别
  /// 注意：调用此方法前应先通过 getFinalText() 获取累积的文本
  Future<void> stopRecognition() async {
    try {
      // 归档当前文本，确保不丢失
      archiveText();
      
      // 发送结束消息
      if (_channel != null) {
        await _sendEndMessage();
      }

      // 关闭连接
      await _subscription?.cancel();
      await _channel?.sink.close();

      _channel = null;
      _subscription = null;
    } catch (e) {
      // 忽略关闭时的错误
    }

    // 关闭结果控制器
    await _resultController?.close();
    _resultController = null;
  }

  /// 生成认证URL
  String _generateAuthUrl() {
    final url = Uri.parse(AppConstants.websocketUrl);
    final host = url.host;
    final path = url.path;

    // 生成时间戳 (HttpDate format required: e.g. Fri, 17 Jul 2020 06:13:30 GMT)
    final date = HttpDate.format(DateTime.now());

    // 生成签名字符串
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';

    // 计算签名
    final hmacSha256 = Hmac(sha256, utf8.encode(AppConstants.xunfeiApiSecret));
    final digest = hmacSha256.convert(utf8.encode(signatureOrigin));
    final signature = base64.encode(digest.bytes);

    // 构建认证参数
    final authorizationOrigin = 'api_key="${AppConstants.xunfeiApiKey}", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';
    final authorization = base64.encode(utf8.encode(authorizationOrigin));

    // 构建完整URL
    final params = {
      'authorization': authorization,
      'date': date,
      'host': host,
    };

    final uri = Uri.parse(AppConstants.websocketUrl);
    return uri.replace(queryParameters: params).toString();
  }

  /// 发送握手消息（首帧）
  Future<void> _sendHandshakeMessage() async {
    // 讯飞 IAT API 首帧格式: common + business + data
    final handshakeMessage = {
      'common': {
        'app_id': AppConstants.xunfeiAppId,
      },
      'business': {
        'language': 'zh_cn',
        'domain': 'iat',
        'accent': 'mandarin',
        'vad_eos': 3000,
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

    _channel!.sink.add(json.encode(handshakeMessage));
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

    _channel!.sink.add(json.encode(endMessage));
  }

  /// 处理WebSocket消息
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      print('ASR: Received message: $data');

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
          
          print('ASR: sn=$sn, pgs=$pgs, rst=$rst, rg=$rg, text=$text');
          
          if (text.isNotEmpty) {
            if (rst == 'rlt') {
              // 最终确认结果：将此句子标记为已确认
              // rlt 类型的结果是对之前 pgs 结果的最终确认
              // 使用 rg 范围来替换临时结果
              if (rg != null && rg.length >= 2) {
                final start = rg[0] as int;
                final end = rg[1] as int;
                // 清除 rg 范围内的临时段落
                for (int i = start; i <= end; i++) {
                  _sentenceSegments.remove(i);
                }
              }
              // 将最终确认的文本存储
              _sentenceSegments[sn] = text;
              print('ASR: Final result confirmed for sn=$sn: $text');
            } else {
              // 临时结果 (pgs)
              if (pgs == 'rpl' && rg != null && rg.length >= 2) {
                // 替换模式：只替换 rg 范围内的临时结果
                final start = rg[0] as int;
                final end = rg[1] as int;
                for (int i = start; i <= end; i++) {
                  _sentenceSegments.remove(i);
                }
                _sentenceSegments[sn] = text;
              } else if (pgs == 'apd') {
                // 追加模式：追加到对应句子
                _sentenceSegments[sn] = (_sentenceSegments[sn] ?? '') + text;
              } else {
                // 无 pgs：替换对应句子
                _sentenceSegments[sn] = text;
              }
            }
            print('ASR: Accumulated text: $accumulatedText');
          }
        }
        
        // 发送包含累积文本的结果
        _resultController?.add({
          ...resultData,
          'accumulatedText': accumulatedText,
        });

        // 检查是否结束
        if (resultData['status'] == 2) {
          // 最终结果，记录日志但不自动关闭连接
          // 让上层代码控制关闭时机，确保能获取到完整的累积文本
          print('ASR: Received final result, accumulated text: $accumulatedText');
        }
      } else {
        // 识别失败
        final errorMessage = data['message'] ?? '语音识别失败';
        print('ASR: API Error: $errorMessage, Code: ${data['code']}');
        _resultController?.addError(AsrException.recognitionFailed());
      }
    } catch (e) {
      print('ASR: Message parse error: $e');
      _resultController?.addError(AsrException.recognitionFailed());
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
    print('ASR: WebSocket Error: $error');
    _resultController?.addError(AsrException.websocketConnectionFailed());
  }

  /// 处理WebSocket关闭
  void _handleDone() {
    print('ASR: WebSocket Closed');
    _resultController?.close();
  }

  /// 解析识别结果
  static String parseRecognitionResult(Map<String, dynamic> result) {
    try {
      // 讯飞返回格式: data.result.ws[].cw[].w
      final resultData = result['result'];
      if (resultData == null) return '';
      
      final ws = resultData['ws'] as List<dynamic>?;
      if (ws == null || ws.isEmpty) {
        return '';
      }

      final sentences = <String>[];

      for (final wsItem in ws) {
        final cw = wsItem['cw'] as List<dynamic>?;
        if (cw != null && cw.isNotEmpty) {
          final word = cw[0]['w'] as String?;
          if (word != null && word.isNotEmpty) {
            sentences.add(word);
          }
        }
      }

      return sentences.join();
    } catch (e) {
      print('ASR: Parse error: $e');
      return '';
    }
  }

  /// 获取识别置信度
  static double getRecognitionConfidence(Map<String, dynamic> result) {
    try {
      final resultData = result['result'];
      if (resultData == null) return 0.0;
      
      final ws = resultData['ws'] as List<dynamic>?;
      if (ws == null || ws.isEmpty) {
        return 0.0;
      }

      double totalConfidence = 0.0;
      int wordCount = 0;

      for (final wsItem in ws) {
        final cw = wsItem['cw'] as List<dynamic>?;
        if (cw != null && cw.isNotEmpty) {
          final sc = cw[0]['sc'] as double?;
          if (sc != null) {
            totalConfidence += sc;
            wordCount++;
          }
        }
      }

      return wordCount > 0 ? totalConfidence / wordCount : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// 检查是否为最终结果
  static bool isFinalResult(Map<String, dynamic> result) {
    return result['status'] == 2;
  }

  /// 检查是否为中间结果
  static bool isIntermediateResult(Map<String, dynamic> result) {
    return result['status'] == 1;
  }
}