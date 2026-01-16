import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';

void main() {
  group('Failure基类', () {
    test('应该正确创建基础Failure', () {
      final failure = NetworkFailure('测试失败', code: 'TEST_CODE');

      expect(failure.message, '测试失败');
      expect(failure.code, 'TEST_CODE');
      expect(failure.details, isNull);
    });

    test('应该支持details参数', () {
      final failure = NetworkFailure(
        '测试失败',
        code: 'TEST_CODE',
        details: const {'key': 'value'},
      );

      expect(failure.details, {'key': 'value'});
    });

    test('toString应该包含message和code', () {
      final failure = NetworkFailure('测试失败', code: 'TEST_CODE');
      final str = failure.toString();

      expect(str, contains('测试失败'));
      expect(str, contains('TEST_CODE'));
    });

    test('toString在没有code时不显示code', () {
      final failure = NetworkFailure('测试失败');
      final str = failure.toString();

      expect(str, contains('测试失败'));
      expect(str, isNot(contains('(Code:')));
    });

    test('Equatable应该正确比较', () {
      final failure1 = NetworkFailure('测试', code: 'CODE');
      final failure2 = NetworkFailure('测试', code: 'CODE');
      final failure3 = NetworkFailure('不同', code: 'CODE');

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });
  });

  group('NetworkFailure', () {
    test('timeout工厂方法应该创建正确的失败', () {
      final failure = NetworkFailure.timeout();

      expect(failure.message, '请求超时，请检查网络连接');
      expect(failure.code, 'TIMEOUT');
    });

    test('noConnection工厂方法应该创建正确的失败', () {
      final failure = NetworkFailure.noConnection();

      expect(failure.message, '无网络连接，请检查网络设置');
      expect(failure.code, 'NO_CONNECTION');
    });

    test('serverError工厂方法应该包含statusCode', () {
      final failure = NetworkFailure.serverError(statusCode: 500);

      expect(failure.message, contains('500'));
      expect(failure.code, 'SERVER_ERROR');
      expect(failure.details, 500);
    });

    test('serverError可以不传statusCode', () {
      final failure = NetworkFailure.serverError();

      expect(failure.message, '服务器错误');
      expect(failure.details, isNull);
    });

    test('unauthorized工厂方法应该创建正确的失败', () {
      final failure = NetworkFailure.unauthorized();

      expect(failure.message, '未授权访问，请检查API密钥');
      expect(failure.code, 'UNAUTHORIZED');
    });
  });

  group('PermissionFailure', () {
    test('microphoneDenied应该创建正确的失败', () {
      final failure = PermissionFailure.microphoneDenied();

      expect(failure.message, '麦克风权限被拒绝');
      expect(failure.code, 'MICROPHONE_DENIED');
    });

    test('storageDenied应该创建正确的失败', () {
      final failure = PermissionFailure.storageDenied();

      expect(failure.message, '存储权限被拒绝');
      expect(failure.code, 'STORAGE_DENIED');
    });

    test('microphonePermanentlyDenied应该创建正确的失败', () {
      final failure = PermissionFailure.microphonePermanentlyDenied();

      expect(failure.message, '麦克风权限被永久拒绝，请在设置中手动开启');
      expect(failure.code, 'MICROPHONE_PERMANENTLY_DENIED');
    });
  });

  group('RecordingFailure', () {
    test('recordingFailed应该创建正确的失败', () {
      final failure = RecordingFailure.recordingFailed();

      expect(failure.message, '录音失败');
      expect(failure.code, 'RECORDING_FAILED');
    });

    test('audioFileNotFound应该创建正确的失败', () {
      final failure = RecordingFailure.audioFileNotFound();

      expect(failure.message, '音频文件未找到');
      expect(failure.code, 'AUDIO_FILE_NOT_FOUND');
    });

    test('durationTooShort应该创建正确的失败', () {
      final failure = RecordingFailure.durationTooShort();

      expect(failure.message, '录音时长过短，请至少录制1秒');
      expect(failure.code, 'DURATION_TOO_SHORT');
    });

    test('durationTooLong应该创建正确的失败', () {
      final failure = RecordingFailure.durationTooLong();

      expect(failure.message, '录音时长过长，最长支持2小时');
      expect(failure.code, 'DURATION_TOO_LONG');
    });
  });

  group('AsrFailure', () {
    test('recognitionFailed应该创建正确的失败', () {
      final failure = AsrFailure.recognitionFailed();

      expect(failure.message, '语音识别失败');
      expect(failure.code, 'RECOGNITION_FAILED');
    });

    test('websocketConnectionFailed应该创建正确的失败', () {
      final failure = AsrFailure.websocketConnectionFailed();

      expect(failure.message, 'WebSocket连接失败');
      expect(failure.code, 'WEBSOCKET_CONNECTION_FAILED');
    });

    test('authenticationFailed应该创建正确的失败', () {
      final failure = AsrFailure.authenticationFailed();

      expect(failure.message, 'ASR服务认证失败');
      expect(failure.code, 'AUTHENTICATION_FAILED');
    });

    test('noSpeechDetected应该创建正确的失败', () {
      final failure = AsrFailure.noSpeechDetected();

      expect(failure.message, '未检测到语音输入');
      expect(failure.code, 'NO_SPEECH_DETECTED');
    });
  });

  group('AiGenerationFailure', () {
    test('serviceUnavailable应该创建正确的失败', () {
      final failure = AiGenerationFailure.serviceUnavailable();

      expect(failure.message, 'AI服务暂时不可用');
      expect(failure.code, 'SERVICE_UNAVAILABLE');
    });

    test('contentGenerationFailed应该支持自定义消息', () {
      final failure = AiGenerationFailure.contentGenerationFailed(
        message: '自定义错误消息',
      );

      expect(failure.message, '自定义错误消息');
      expect(failure.code, 'CONTENT_GENERATION_FAILED');
    });

    test('contentGenerationFailed应该使用默认消息', () {
      final failure = AiGenerationFailure.contentGenerationFailed();

      expect(failure.message, '内容生成失败');
    });

    test('invalidApiKey应该创建正确的失败', () {
      final failure = AiGenerationFailure.invalidApiKey();

      expect(failure.message, '无效的API密钥');
      expect(failure.code, 'INVALID_API_KEY');
    });

    test('quotaExceeded应该创建正确的失败', () {
      final failure = AiGenerationFailure.quotaExceeded();

      expect(failure.message, 'API调用次数已超限');
      expect(failure.code, 'QUOTA_EXCEEDED');
    });
  });

  group('DatabaseFailure', () {
    test('tableNotFound应该包含表名', () {
      final failure = DatabaseFailure.tableNotFound('test_table');

      expect(failure.message, contains('test_table'));
      expect(failure.code, 'TABLE_NOT_FOUND');
      expect(failure.details, 'test_table');
    });

    test('insertFailed应该创建正确的失败', () {
      final failure = DatabaseFailure.insertFailed();

      expect(failure.message, '数据插入失败');
      expect(failure.code, 'INSERT_FAILED');
    });

    test('updateFailed应该创建正确的失败', () {
      final failure = DatabaseFailure.updateFailed();

      expect(failure.message, '数据更新失败');
      expect(failure.code, 'UPDATE_FAILED');
    });

    test('deleteFailed应该创建正确的失败', () {
      final failure = DatabaseFailure.deleteFailed();

      expect(failure.message, '数据删除失败');
      expect(failure.code, 'DELETE_FAILED');
    });

    test('queryFailed应该创建正确的失败', () {
      final failure = DatabaseFailure.queryFailed();

      expect(failure.message, '数据查询失败');
      expect(failure.code, 'QUERY_FAILED');
    });
  });

  group('FileSystemFailure', () {
    test('fileNotFound应该包含文件路径', () {
      final failure = FileSystemFailure.fileNotFound('/path/to/file.txt');

      expect(failure.message, contains('/path/to/file.txt'));
      expect(failure.code, 'FILE_NOT_FOUND');
      expect(failure.details, '/path/to/file.txt');
    });

    test('directoryNotFound应该包含目录路径', () {
      final failure = FileSystemFailure.directoryNotFound('/path/to/dir');

      expect(failure.message, contains('/path/to/dir'));
      expect(failure.code, 'DIRECTORY_NOT_FOUND');
      expect(failure.details, '/path/to/dir');
    });

    test('permissionDenied应该包含路径', () {
      final failure = FileSystemFailure.permissionDenied('/protected/path');

      expect(failure.message, contains('/protected/path'));
      expect(failure.code, 'PERMISSION_DENIED');
      expect(failure.details, '/protected/path');
    });

    test('diskSpaceInsufficient应该创建正确的失败', () {
      final failure = FileSystemFailure.diskSpaceInsufficient();

      expect(failure.message, '磁盘空间不足');
      expect(failure.code, 'DISK_SPACE_INSUFFICIENT');
    });
  });

  group('ConfigurationFailure', () {
    test('missingApiKey应该包含服务名', () {
      final failure = ConfigurationFailure.missingApiKey('OpenAI');

      expect(failure.message, contains('OpenAI'));
      expect(failure.code, 'MISSING_API_KEY');
      expect(failure.details, 'OpenAI');
    });

    test('invalidConfiguration应该包含字段名', () {
      final failure = ConfigurationFailure.invalidConfiguration('api_endpoint');

      expect(failure.message, contains('api_endpoint'));
      expect(failure.code, 'INVALID_CONFIGURATION');
      expect(failure.details, 'api_endpoint');
    });
  });

  group('UnknownFailure', () {
    test('unexpected应该包含错误信息', () {
      final error = Exception('Unexpected error');
      final failure = UnknownFailure.unexpected(error: error);

      expect(failure.message, contains('Unexpected error'));
      expect(failure.code, 'UNEXPECTED');
      expect(failure.details, error);
    });

    test('unexpected应该处理字符串错误', () {
      final failure = UnknownFailure.unexpected(error: 'Some error');

      expect(failure.message, contains('Some error'));
    });

    test('unexpected应该处理null错误', () {
      final failure = UnknownFailure.unexpected();

      expect(failure.code, 'UNEXPECTED');
      expect(failure.message, contains('null'));
    });
  });

  group('CacheFailure', () {
    test('cacheMiss应该创建正确的失败', () {
      final failure = CacheFailure.cacheMiss();

      expect(failure.message, '缓存未命中');
      expect(failure.code, 'CACHE_MISS');
    });
  });

  group('PlatformFailure', () {
    test('notSupported应该创建正确的失败', () {
      final failure = PlatformFailure.notSupported();

      expect(failure.message, '平台不支持此功能');
      expect(failure.code, 'NOT_SUPPORTED');
    });
  });

  group('Failure类型比较', () {
    test('不同类型的Failure不应该相等', () {
      final networkFailure = NetworkFailure.timeout();
      final permissionFailure = PermissionFailure.microphoneDenied();

      expect(networkFailure, isNot(equals(permissionFailure)));
    });

    test('相同类型相同参数的Failure应该相等', () {
      final failure1 = NetworkFailure.timeout();
      final failure2 = NetworkFailure.timeout();

      expect(failure1, equals(failure2));
    });

    test('相同类型不同参数的Failure不应该相等', () {
      final failure1 = DatabaseFailure.tableNotFound('table1');
      final failure2 = DatabaseFailure.tableNotFound('table2');

      expect(failure1, isNot(equals(failure2)));
    });
  });

  group('Failure的props', () {
    test('所有Failure类型都应该有正确的props', () {
      final failures = [
        NetworkFailure.timeout(),
        PermissionFailure.microphoneDenied(),
        RecordingFailure.recordingFailed(),
        AsrFailure.recognitionFailed(),
        AiGenerationFailure.serviceUnavailable(),
        DatabaseFailure.insertFailed(),
        FileSystemFailure.fileNotFound('/path'),
        ConfigurationFailure.missingApiKey('service'),
        UnknownFailure.unexpected(),
        CacheFailure.cacheMiss(),
        PlatformFailure.notSupported(),
      ];

      for (final failure in failures) {
        expect(failure.props, isList);
        expect(failure.props, isNotEmpty);
      }
    });
  });
}
