/// 基础异常类
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.details,
  });

  factory NetworkException.requestTimeout() {
    return const NetworkException(
      '请求超时，请检查网络连接',
      code: 'REQUEST_TIMEOUT',
    );
  }

  factory NetworkException.noConnection() {
    return const NetworkException(
      '无网络连接，请检查网络设置',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkException.serverError({int? statusCode}) {
    return NetworkException(
      '服务器错误${statusCode != null ? ' ($statusCode)' : ''}',
      code: 'SERVER_ERROR',
      details: statusCode,
    );
  }

  factory NetworkException.unauthorized() {
    return const NetworkException(
      '未授权访问，请检查API密钥',
      code: 'UNAUTHORIZED',
    );
  }
}

/// 权限异常
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.details,
  });

  factory PermissionException.microphoneDenied() {
    return const PermissionException(
      '麦克风权限被拒绝',
      code: 'MICROPHONE_DENIED',
    );
  }

  factory PermissionException.storageDenied() {
    return const PermissionException(
      '存储权限被拒绝',
      code: 'STORAGE_DENIED',
    );
  }

  factory PermissionException.microphonePermanentlyDenied() {
    return const PermissionException(
      '麦克风权限被永久拒绝，请在设置中手动开启',
      code: 'MICROPHONE_PERMANENTLY_DENIED',
    );
  }
}

/// 录音异常
class RecordingException extends AppException {
  const RecordingException(
    super.message, {
    super.code,
    super.details,
  });

  factory RecordingException.recordingFailed() {
    return const RecordingException(
      '录音失败',
      code: 'RECORDING_FAILED',
    );
  }

  factory RecordingException.audioFileNotFound() {
    return const RecordingException(
      '音频文件未找到',
      code: 'AUDIO_FILE_NOT_FOUND',
    );
  }

  factory RecordingException.durationTooShort() {
    return const RecordingException(
      '录音时长过短，请至少录制1秒',
      code: 'DURATION_TOO_SHORT',
    );
  }

  factory RecordingException.durationTooLong() {
    return const RecordingException(
      '录音时长过长，最长支持2小时',
      code: 'DURATION_TOO_LONG',
    );
  }
}

/// ASR（语音识别）异常
class AsrException extends AppException {
  const AsrException(
    super.message, {
    super.code,
    super.details,
  });

  factory AsrException.recognitionFailed() {
    return const AsrException(
      '语音识别失败',
      code: 'RECOGNITION_FAILED',
    );
  }

  factory AsrException.websocketConnectionFailed() {
    return const AsrException(
      'WebSocket连接失败',
      code: 'WEBSOCKET_CONNECTION_FAILED',
    );
  }

  factory AsrException.authenticationFailed() {
    return const AsrException(
      'ASR服务认证失败',
      code: 'AUTHENTICATION_FAILED',
    );
  }

  factory AsrException.noSpeechDetected() {
    return const AsrException(
      '未检测到语音输入',
      code: 'NO_SPEECH_DETECTED',
    );
  }
}

/// AI生成异常
class AiGenerationException extends AppException {
  const AiGenerationException(
    super.message, {
    super.code,
    super.details,
  });

  factory AiGenerationException.serviceUnavailable() {
    return const AiGenerationException(
      'AI服务暂时不可用',
      code: 'SERVICE_UNAVAILABLE',
    );
  }

  factory AiGenerationException.contentGenerationFailed() {
    return const AiGenerationException(
      '内容生成失败',
      code: 'CONTENT_GENERATION_FAILED',
    );
  }

  factory AiGenerationException.invalidApiKey() {
    return const AiGenerationException(
      '无效的API密钥',
      code: 'INVALID_API_KEY',
    );
  }

  factory AiGenerationException.quotaExceeded() {
    return const AiGenerationException(
      'API调用次数已超限',
      code: 'QUOTA_EXCEEDED',
    );
  }
}

/// 数据库异常
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.details,
  });

  factory DatabaseException.tableNotFound(String tableName) {
    return DatabaseException(
      '数据表 $tableName 未找到',
      code: 'TABLE_NOT_FOUND',
      details: tableName,
    );
  }

  factory DatabaseException.insertFailed() {
    return const DatabaseException(
      '数据插入失败',
      code: 'INSERT_FAILED',
    );
  }

  factory DatabaseException.updateFailed() {
    return const DatabaseException(
      '数据更新失败',
      code: 'UPDATE_FAILED',
    );
  }

  factory DatabaseException.deleteFailed() {
    return const DatabaseException(
      '数据删除失败',
      code: 'DELETE_FAILED',
    );
  }

  factory DatabaseException.queryFailed() {
    return const DatabaseException(
      '数据查询失败',
      code: 'QUERY_FAILED',
    );
  }
}

/// 文件系统异常
class FileSystemException extends AppException {
  const FileSystemException(
    super.message, {
    super.code,
    super.details,
  });

  factory FileSystemException.fileNotFound(String filePath) {
    return FileSystemException(
      '文件未找到: $filePath',
      code: 'FILE_NOT_FOUND',
      details: filePath,
    );
  }

  factory FileSystemException.directoryNotFound(String dirPath) {
    return FileSystemException(
      '目录未找到: $dirPath',
      code: 'DIRECTORY_NOT_FOUND',
      details: dirPath,
    );
  }

  factory FileSystemException.permissionDenied(String path) {
    return FileSystemException(
      '文件访问权限被拒绝: $path',
      code: 'PERMISSION_DENIED',
      details: path,
    );
  }

  factory FileSystemException.diskSpaceInsufficient() {
    return const FileSystemException(
      '磁盘空间不足',
      code: 'DISK_SPACE_INSUFFICIENT',
    );
  }
}

/// 配置异常
class ConfigurationException extends AppException {
  const ConfigurationException(
    super.message, {
    super.code,
    super.details,
  });

  factory ConfigurationException.missingApiKey(String service) {
    return ConfigurationException(
      '缺少 $service 的API密钥',
      code: 'MISSING_API_KEY',
      details: service,
    );
  }

  factory ConfigurationException.invalidConfiguration(String field) {
    return ConfigurationException(
      '无效的配置项: $field',
      code: 'INVALID_CONFIGURATION',
      details: field,
    );
  }
}

/// 缓存异常
class CacheException extends AppException {
  const CacheException([
    super.message = '缓存操作失败',
    String? code = 'CACHE_ERROR',
    dynamic details,
  ]) : super(code: code, details: details);

  factory CacheException.cacheMiss() {
    return const CacheException(
      '缓存未命中',
      'CACHE_MISS',
    );
  }
}