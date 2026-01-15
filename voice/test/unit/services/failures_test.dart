// 错误处理 Failures 测试
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_autobiography_flutter/core/errors/failures.dart';

void main() {
  group('Failure', () {
    test('toString 应该正确格式化', () {
      const failure = NetworkFailure('测试消息', code: 'TEST_CODE');
      expect(failure.toString(), contains('Failure: 测试消息'));
      expect(failure.toString(), contains('TEST_CODE'));
    });

    test('props 应该正确比较', () {
      const f1 = NetworkFailure('消息1', code: 'CODE1');
      const f2 = NetworkFailure('消息1', code: 'CODE1');
      const f3 = NetworkFailure('消息2', code: 'CODE1');

      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
    });
  });

  group('NetworkFailure', () {
    test('timeout 应该返回正确消息', () {
      final failure = NetworkFailure.timeout();
      expect(failure.message, contains('超时'));
      expect(failure.code, 'TIMEOUT');
    });

    test('noConnection 应该返回正确消息', () {
      final failure = NetworkFailure.noConnection();
      expect(failure.message, contains('无网络'));
      expect(failure.code, 'NO_CONNECTION');
    });

    test('serverError 应该包含状态码', () {
      final failure = NetworkFailure.serverError(statusCode: 500);
      expect(failure.message, contains('500'));
      expect(failure.code, 'SERVER_ERROR');
    });

    test('unauthorized 应该返回正确消息', () {
      final failure = NetworkFailure.unauthorized();
      expect(failure.code, 'UNAUTHORIZED');
    });
  });

  group('PermissionFailure', () {
    test('microphoneDenied 应该返回正确消息', () {
      final failure = PermissionFailure.microphoneDenied();
      expect(failure.message, contains('麦克风'));
      expect(failure.code, 'MICROPHONE_DENIED');
    });

    test('storageDenied 应该返回正确消息', () {
      final failure = PermissionFailure.storageDenied();
      expect(failure.message, contains('存储'));
      expect(failure.code, 'STORAGE_DENIED');
    });

    test('microphonePermanentlyDenied 应该返回正确消息', () {
      final failure = PermissionFailure.microphonePermanentlyDenied();
      expect(failure.message, contains('永久'));
      expect(failure.code, 'MICROPHONE_PERMANENTLY_DENIED');
    });
  });

  group('RecordingFailure', () {
    test('recordingFailed 应该返回正确消息', () {
      final failure = RecordingFailure.recordingFailed();
      expect(failure.message, contains('录音失败'));
      expect(failure.code, 'RECORDING_FAILED');
    });

    test('audioFileNotFound 应该返回正确消息', () {
      final failure = RecordingFailure.audioFileNotFound();
      expect(failure.message, contains('未找到'));
      expect(failure.code, 'AUDIO_FILE_NOT_FOUND');
    });

    test('durationTooShort 应该返回正确消息', () {
      final failure = RecordingFailure.durationTooShort();
      expect(failure.message, contains('过短'));
      expect(failure.code, 'DURATION_TOO_SHORT');
    });

    test('durationTooLong 应该返回正确消息', () {
      final failure = RecordingFailure.durationTooLong();
      expect(failure.message, contains('过长'));
      expect(failure.code, 'DURATION_TOO_LONG');
    });
  });

  group('AsrFailure', () {
    test('recognitionFailed 应该返回正确消息', () {
      final failure = AsrFailure.recognitionFailed();
      expect(failure.message, contains('识别失败'));
      expect(failure.code, 'RECOGNITION_FAILED');
    });

    test('websocketConnectionFailed 应该返回正确消息', () {
      final failure = AsrFailure.websocketConnectionFailed();
      expect(failure.message, contains('WebSocket'));
      expect(failure.code, 'WEBSOCKET_CONNECTION_FAILED');
    });

    test('authenticationFailed 应该返回正确消息', () {
      final failure = AsrFailure.authenticationFailed();
      expect(failure.message, contains('认证'));
      expect(failure.code, 'AUTHENTICATION_FAILED');
    });

    test('noSpeechDetected 应该返回正确消息', () {
      final failure = AsrFailure.noSpeechDetected();
      expect(failure.message, contains('未检测到'));
      expect(failure.code, 'NO_SPEECH_DETECTED');
    });
  });

  group('AiGenerationFailure', () {
    test('serviceUnavailable 应该返回正确消息', () {
      final failure = AiGenerationFailure.serviceUnavailable();
      expect(failure.message, contains('不可用'));
      expect(failure.code, 'SERVICE_UNAVAILABLE');
    });

    test('contentGenerationFailed 应该返回正确消息', () {
      final failure = AiGenerationFailure.contentGenerationFailed();
      expect(failure.message, contains('生成失败'));
      expect(failure.code, 'CONTENT_GENERATION_FAILED');
    });

    test('contentGenerationFailed 应该支持自定义消息', () {
      final failure =
          AiGenerationFailure.contentGenerationFailed(message: '自定义错误');
      expect(failure.message, '自定义错误');
    });

    test('invalidApiKey 应该返回正确消息', () {
      final failure = AiGenerationFailure.invalidApiKey();
      expect(failure.message, contains('API密钥'));
      expect(failure.code, 'INVALID_API_KEY');
    });

    test('quotaExceeded 应该返回正确消息', () {
      final failure = AiGenerationFailure.quotaExceeded();
      expect(failure.message, contains('超限'));
      expect(failure.code, 'QUOTA_EXCEEDED');
    });
  });

  group('DatabaseFailure', () {
    test('tableNotFound 应该包含表名', () {
      final failure = DatabaseFailure.tableNotFound('users');
      expect(failure.message, contains('users'));
      expect(failure.code, 'TABLE_NOT_FOUND');
    });

    test('insertFailed 应该返回正确消息', () {
      final failure = DatabaseFailure.insertFailed();
      expect(failure.code, 'INSERT_FAILED');
    });

    test('updateFailed 应该返回正确消息', () {
      final failure = DatabaseFailure.updateFailed();
      expect(failure.code, 'UPDATE_FAILED');
    });

    test('deleteFailed 应该返回正确消息', () {
      final failure = DatabaseFailure.deleteFailed();
      expect(failure.code, 'DELETE_FAILED');
    });

    test('queryFailed 应该返回正确消息', () {
      final failure = DatabaseFailure.queryFailed();
      expect(failure.code, 'QUERY_FAILED');
    });
  });

  group('FileSystemFailure', () {
    test('fileNotFound 应该包含文件路径', () {
      final failure = FileSystemFailure.fileNotFound('/path/to/file');
      expect(failure.message, contains('/path/to/file'));
      expect(failure.code, 'FILE_NOT_FOUND');
    });

    test('directoryNotFound 应该包含目录路径', () {
      final failure = FileSystemFailure.directoryNotFound('/path/to/dir');
      expect(failure.message, contains('/path/to/dir'));
      expect(failure.code, 'DIRECTORY_NOT_FOUND');
    });

    test('permissionDenied 应该包含路径', () {
      final failure = FileSystemFailure.permissionDenied('/path');
      expect(failure.message, contains('/path'));
      expect(failure.code, 'PERMISSION_DENIED');
    });

    test('diskSpaceInsufficient 应该返回正确消息', () {
      final failure = FileSystemFailure.diskSpaceInsufficient();
      expect(failure.message, contains('空间不足'));
      expect(failure.code, 'DISK_SPACE_INSUFFICIENT');
    });
  });

  group('其他 Failure 类型', () {
    test('ConfigurationFailure.missingApiKey 应该包含服务名', () {
      final failure = ConfigurationFailure.missingApiKey('OpenAI');
      expect(failure.message, contains('OpenAI'));
      expect(failure.code, 'MISSING_API_KEY');
    });

    test('UnknownFailure.unexpected 应该包含错误信息', () {
      final failure = UnknownFailure.unexpected(error: 'test error');
      expect(failure.message, contains('test error'));
      expect(failure.code, 'UNEXPECTED');
    });

    test('CacheFailure.cacheMiss 应该返回正确消息', () {
      final failure = CacheFailure.cacheMiss();
      expect(failure.code, 'CACHE_MISS');
    });

    test('PlatformFailure.notSupported 应该返回正确消息', () {
      final failure = PlatformFailure.notSupported();
      expect(failure.code, 'NOT_SUPPORTED');
    });
  });
}
