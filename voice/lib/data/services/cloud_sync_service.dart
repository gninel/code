import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/voice_record.dart';
import '../../domain/entities/autobiography.dart';

/// 云同步服务
@lazySingleton
class CloudSyncService {
  // TODO: 部署后替换为实际的服务器地址
  static const String _baseUrl = 'http://your-server-ip:8000';
  
  final Dio _dio;
  String? _accessToken;
  User? _currentUser;

  CloudSyncService() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  /// 是否已登录
  bool get isLoggedIn => _accessToken != null && _currentUser != null;

  /// 当前用户
  User? get currentUser => _currentUser;

  /// 初始化（恢复登录状态）
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    final userJson = prefs.getString('current_user');
    if (userJson != null && _accessToken != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
        _updateAuthHeader();
      } catch (e) {
        await logout();
      }
    }
  }

  /// 更新认证头
  void _updateAuthHeader() {
    if (_accessToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// 用户注册
  Future<User> register(String email, String password, {String? nickname}) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'nickname': nickname,
      });

      _accessToken = response.data['access_token'];
      _currentUser = User.fromJson(response.data['user']);
      _updateAuthHeader();
      await _saveLoginState();

      return _currentUser!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 用户登录
  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      _accessToken = response.data['access_token'];
      _currentUser = User.fromJson(response.data['user']);
      _updateAuthHeader();
      await _saveLoginState();

      return _currentUser!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 退出登录
  Future<void> logout() async {
    _accessToken = null;
    _currentUser = null;
    _updateAuthHeader();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('current_user');
  }

  /// 保存登录状态
  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_currentUser != null) {
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
    }
  }

  /// 上传数据到云端
  Future<void> uploadData({
    required List<VoiceRecord> voiceRecords,
    required List<Autobiography> autobiographies,
  }) async {
    if (!isLoggedIn) {
      throw Exception('请先登录');
    }

    try {
      final response = await _dio.post('/sync/upload', data: {
        'voice_records': voiceRecords.map((r) => _voiceRecordToJson(r)).toList(),
        'autobiographies': autobiographies.map((a) => _autobiographyToJson(a)).toList(),
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? '上传失败');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 从云端下载数据
  Future<({List<VoiceRecord> voiceRecords, List<Autobiography> autobiographies})> downloadData() async {
    if (!isLoggedIn) {
      throw Exception('请先登录');
    }

    try {
      final response = await _dio.get('/sync/download');

      final voiceRecords = (response.data['voice_records'] as List)
          .map((json) => _voiceRecordFromJson(json))
          .toList();

      final autobiographies = (response.data['autobiographies'] as List)
          .map((json) => _autobiographyFromJson(json))
          .toList();

      return (voiceRecords: voiceRecords, autobiographies: autobiographies);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// VoiceRecord 转 JSON
  Map<String, dynamic> _voiceRecordToJson(VoiceRecord record) {
    return {
      'id': record.id,
      'title': record.title,
      'content': record.content,
      'transcription': record.transcription,
      'duration': record.duration,
      'audio_url': record.audioFilePath,
      'is_processed': record.isProcessed,
      'confidence': record.confidence,
      'note': record.note,
      'is_included_in_bio': record.isIncludedInBio,
      'tags': record.tags,
      'timestamp': record.timestamp.toIso8601String(),
    };
  }

  /// JSON 转 VoiceRecord
  VoiceRecord _voiceRecordFromJson(Map<String, dynamic> json) {
    return VoiceRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      transcription: json['transcription'] as String?,
      duration: json['duration'] as int? ?? 0,
      audioFilePath: json['audio_url'] as String?,
      isProcessed: json['is_processed'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble(),
      note: json['note'] as String?,
      isIncludedInBio: json['is_included_in_bio'] as bool? ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Autobiography 转 JSON
  Map<String, dynamic> _autobiographyToJson(Autobiography auto) {
    return {
      'id': auto.id,
      'title': auto.title,
      'content': auto.content,
      'summary': auto.summary,
      'word_count': auto.wordCount,
      'version': auto.version,
      'status': auto.status.name,
      'style': auto.style?.name,
      'voice_record_ids': auto.voiceRecordIds,
      'tags': auto.tags,
      'chapters': auto.chapters.map((c) => {
        'id': c.id,
        'title': c.title,
        'content': c.content,
        'order': c.order,
      }).toList(),
      'generated_at': auto.generatedAt.toIso8601String(),
      'last_modified_at': auto.lastModifiedAt.toIso8601String(),
    };
  }

  /// JSON 转 Autobiography
  Autobiography _autobiographyFromJson(Map<String, dynamic> json) {
    return Autobiography(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      wordCount: json['word_count'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      status: _parseStatus(json['status'] as String?),
      style: _parseStyle(json['style'] as String?),
      voiceRecordIds: (json['voice_record_ids'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      generatedAt: DateTime.parse(json['generated_at'] as String),
      lastModifiedAt: DateTime.parse(json['last_modified_at'] as String),
    );
  }

  AutobiographyStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft': return AutobiographyStatus.draft;
      case 'published': return AutobiographyStatus.published;
      case 'archived': return AutobiographyStatus.archived;
      default: return AutobiographyStatus.draft;
    }
  }

  AutobiographyStyle? _parseStyle(String? style) {
    switch (style) {
      case 'narrative': return AutobiographyStyle.narrative;
      case 'emotional': return AutobiographyStyle.emotional;
      case 'achievement': return AutobiographyStyle.achievement;
      case 'chronological': return AutobiographyStyle.chronological;
      case 'reflection': return AutobiographyStyle.reflection;
      default: return null;
    }
  }

  /// 处理错误
  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'];
      }
      return '请求失败: ${e.response!.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return '连接超时，请检查网络';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接到服务器';
    }
    return '网络错误: ${e.message}';
  }
}
