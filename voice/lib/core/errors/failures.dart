import 'package:equatable/equatable.dart';

/// 基础失败类
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(
    this.message, {
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() {
    return 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// 网络失败
class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      '请求超时，请检查网络连接',
      code: 'TIMEOUT',
    );
  }

  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      '无网络连接，请检查网络设置',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkFailure.serverError({int? statusCode}) {
    return NetworkFailure(
      '服务器错误${statusCode != null ? ' ($statusCode)' : ''}',
      code: 'SERVER_ERROR',
      details: statusCode,
    );
  }

  factory NetworkFailure.unauthorized() {
    return const NetworkFailure(
      '未授权访问，请检查API密钥',
      code: 'UNAUTHORIZED',
    );
  }
}

/// 权限失败
class PermissionFailure extends Failure {
  const PermissionFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory PermissionFailure.microphoneDenied() {
    return const PermissionFailure(
      '麦克风权限被拒绝',
      code: 'MICROPHONE_DENIED',
    );
  }

  factory PermissionFailure.storageDenied() {
    return const PermissionFailure(
      '存储权限被拒绝',
      code: 'STORAGE_DENIED',
    );
  }

  factory PermissionFailure.microphonePermanentlyDenied() {
    return const PermissionFailure(
      '麦克风权限被永久拒绝，请在设置中手动开启',
      code: 'MICROPHONE_PERMANENTLY_DENIED',
    );
  }
}

/// 录音失败
class RecordingFailure extends Failure {
  const RecordingFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory RecordingFailure.recordingFailed() {
    return const RecordingFailure(
      '录音失败',
      code: 'RECORDING_FAILED',
    );
  }

  factory RecordingFailure.audioFileNotFound() {
    return const RecordingFailure(
      '音频文件未找到',
      code: 'AUDIO_FILE_NOT_FOUND',
    );
  }

  factory RecordingFailure.durationTooShort() {
    return const RecordingFailure(
      '录音时长过短，请至少录制1秒',
      code: 'DURATION_TOO_SHORT',
    );
  }

  factory RecordingFailure.durationTooLong() {
    return const RecordingFailure(
      '录音时长过长，最长支持2小时',
      code: 'DURATION_TOO_LONG',
    );
  }
}

/// ASR（语音识别）失败
class AsrFailure extends Failure {
  const AsrFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory AsrFailure.recognitionFailed() {
    return const AsrFailure(
      '语音识别失败',
      code: 'RECOGNITION_FAILED',
    );
  }

  factory AsrFailure.websocketConnectionFailed() {
    return const AsrFailure(
      'WebSocket连接失败',
      code: 'WEBSOCKET_CONNECTION_FAILED',
    );
  }

  factory AsrFailure.authenticationFailed() {
    return const AsrFailure(
      'ASR服务认证失败',
      code: 'AUTHENTICATION_FAILED',
    );
  }

  factory AsrFailure.noSpeechDetected() {
    return const AsrFailure(
      '未检测到语音输入',
      code: 'NO_SPEECH_DETECTED',
    );
  }
}

/// AI生成失败
class AiGenerationFailure extends Failure {
  const AiGenerationFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory AiGenerationFailure.serviceUnavailable() {
    return const AiGenerationFailure(
      'AI服务暂时不可用',
      code: 'SERVICE_UNAVAILABLE',
    );
  }

  factory AiGenerationFailure.contentGenerationFailed({String? message}) {
    return AiGenerationFailure(
      message ?? '内容生成失败',
      code: 'CONTENT_GENERATION_FAILED',
    );
  }

  factory AiGenerationFailure.invalidApiKey() {
    return const AiGenerationFailure(
      '无效的API密钥',
      code: 'INVALID_API_KEY',
    );
  }

  factory AiGenerationFailure.quotaExceeded() {
    return const AiGenerationFailure(
      'API调用次数已超限',
      code: 'QUOTA_EXCEEDED',
    );
  }
}

/// 数据库失败
class DatabaseFailure extends Failure {
  const DatabaseFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory DatabaseFailure.tableNotFound(String tableName) {
    return DatabaseFailure(
      '数据表 $tableName 未找到',
      code: 'TABLE_NOT_FOUND',
      details: tableName,
    );
  }

  factory DatabaseFailure.insertFailed() {
    return const DatabaseFailure(
      '数据插入失败',
      code: 'INSERT_FAILED',
    );
  }

  factory DatabaseFailure.updateFailed() {
    return const DatabaseFailure(
      '数据更新失败',
      code: 'UPDATE_FAILED',
    );
  }

  factory DatabaseFailure.deleteFailed() {
    return const DatabaseFailure(
      '数据删除失败',
      code: 'DELETE_FAILED',
    );
  }

  factory DatabaseFailure.queryFailed() {
    return const DatabaseFailure(
      '数据查询失败',
      code: 'QUERY_FAILED',
    );
  }
}

/// 文件系统失败
class FileSystemFailure extends Failure {
  const FileSystemFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory FileSystemFailure.fileNotFound(String filePath) {
    return FileSystemFailure(
      '文件未找到: $filePath',
      code: 'FILE_NOT_FOUND',
      details: filePath,
    );
  }

  factory FileSystemFailure.directoryNotFound(String dirPath) {
    return FileSystemFailure(
      '目录未找到: $dirPath',
      code: 'DIRECTORY_NOT_FOUND',
      details: dirPath,
    );
  }

  factory FileSystemFailure.permissionDenied(String path) {
    return FileSystemFailure(
      '文件访问权限被拒绝: $path',
      code: 'PERMISSION_DENIED',
      details: path,
    );
  }

  factory FileSystemFailure.diskSpaceInsufficient() {
    return const FileSystemFailure(
      '磁盘空间不足',
      code: 'DISK_SPACE_INSUFFICIENT',
    );
  }
}

/// 配置失败
class ConfigurationFailure extends Failure {
  const ConfigurationFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory ConfigurationFailure.missingApiKey(String service) {
    return ConfigurationFailure(
      '缺少 $service 的API密钥',
      code: 'MISSING_API_KEY',
      details: service,
    );
  }

  factory ConfigurationFailure.invalidConfiguration(String field) {
    return ConfigurationFailure(
      '无效的配置项: $field',
      code: 'INVALID_CONFIGURATION',
      details: field,
    );
  }
}

/// 未知失败
class UnknownFailure extends Failure {
  const UnknownFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory UnknownFailure.unexpected({dynamic error}) {
    return UnknownFailure(
      '未知错误: ${error.toString()}',
      code: 'UNEXPECTED',
      details: error,
    );
  }
}

/// 缓存失败
class CacheFailure extends Failure {
  const CacheFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory CacheFailure.cacheMiss() {
    return const CacheFailure(
      '缓存未命中',
      code: 'CACHE_MISS',
    );
  }
}

/// 平台失败
class PlatformFailure extends Failure {
  const PlatformFailure(
    super.message, {
    super.code,
    super.details,
  });

  factory PlatformFailure.notSupported() {
    return const PlatformFailure(
      '平台不支持此功能',
      code: 'NOT_SUPPORTED',
    );
  }
}