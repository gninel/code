import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audio_task.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://localhost:8000';

  late final Dio _dio;

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// 提交转换任务
  Future<Map<String, dynamic>> submitConvert({
    required String url,
    String format = 'mp3',
    String bitrate = '192k',
  }) async {
    final resp = await _dio.post('/api/v1/convert', data: {
      'url': url,
      'audio_format': format,
      'audio_bitrate': bitrate,
    });
    return resp.data as Map<String, dynamic>;
  }

  /// 查询任务状态
  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    final resp = await _dio.get('/api/v1/tasks/$taskId');
    return resp.data as Map<String, dynamic>;
  }

  /// 检测链接是否支持
  Future<Map<String, dynamic>> detectLink(String url) async {
    final resp = await _dio.post('/api/v1/detect', data: {'url': url});
    return resp.data as Map<String, dynamic>;
  }

  /// 下载音频文件到本地
  Future<String> downloadAudio(AudioTask task) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/MusicPocket');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }

    final ext = task.audioFormat ?? 'mp3';
    final safeName = (task.title ?? task.taskId)
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .substring(0, (task.title ?? task.taskId).length.clamp(0, 80));
    final filePath = '${audioDir.path}/$safeName.$ext';

    await _dio.download(
      '/api/v1/tasks/${task.taskId}/download',
      filePath,
    );

    return filePath;
  }
}
