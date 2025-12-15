/// 应用常量配置
class AppConstants {
  // 应用基本信息
  static const String appName = '语音自传';
  static const String appVersion = '1.0.0';

  // API配置
  static const String xunfeiAppId = '2e72f06c';
  static const String xunfeiApiKey = '390583124637d47a099fdd5a59860bde';
  static const String xunfeiApiSecret = 'MThmZmE0M2Y1MmUyZWQwYzU4N2ZlMzQ2';

  // 豆包AI配置
  static const String doubaoApiKey = '405fe7f2-f603-4c4c-b04b-bdea5d441319';
  static const String doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
  static const String doubaoChatCompletions = '/chat/completions';
  static const String doubaoModel = 'doubao-seed-1-6-251015';
  static const int doubaoMaxTokens = 65535;

  // WebSocket URL - 讯飞语音识别
  static const String websocketUrl = 'wss://iat-api.xfyun.cn/v2/iat';

  // 录音参数
  static const int sampleRate = 16000;
  static const int bitRate = 128000;
  static const int channels = 1;
  static const String audioFormat = 'mp4';

  // 网络配置
  static const int connectionTimeout = 30000;
  static const int readTimeout = 60000;
  static const int writeTimeout = 60000;
  static const int maxRetryCount = 3;
  static const int retryDelayMs = 1000;

  // 文件存储路径
  static const String audioRecordingsDir = 'audio_recordings';

  // 数据库配置
  static const String databaseName = 'voice_autobiography_database.db';
  static const int databaseVersion = 1;

  // 权限列表
  static const List<String> requiredPermissions = [
    'android.permission.RECORD_AUDIO',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
  ];

  // UI常量
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // 动画时长
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // 录音相关常量
  static const Duration maxRecordingDuration = Duration(hours: 2);
  static const Duration minRecordingDuration = Duration(seconds: 1);

  // 错误消息
  static const String networkErrorMessage = '网络连接失败，请检查网络设置';
  static const String permissionErrorMessage = '请授予录音权限';
  static const String recordingErrorMessage = '录音过程中出现错误，请重试';
  static const String aiErrorMessage = 'AI服务暂时不可用，请稍后重试';

  // 成功消息
  static const String recordingSuccessMessage = '录音完成';
  static const String savingSuccessMessage = '保存成功';
  static const String generationSuccessMessage = '自传生成成功';
}

/// API端点常量
class ApiEndpoints {
  // 豆包AI端点
  static const String chatCompletions = '/chat/completions';

  // 讯飞ASR端点
  static const String asrWebSocket = 'wss://iat-api.xfyun.cn/v2/iat';
}

/// 数据库表名常量
class DatabaseTables {
  static const String voiceRecords = 'voice_records';
  static const String autobiographies = 'autobiographies';
  static const String settings = 'settings';
}

/// SharedPreferences键名常量
class PreferencesKeys {
  static const String isFirstLaunch = 'is_first_launch';
  static const String asrProvider = 'asr_provider';
  static const String aiProvider = 'ai_provider';
  static const String recordingQuality = 'recording_quality';
  static const String autoBackup = 'auto_backup';
  static const String darkMode = 'dark_mode';
  static const String language = 'language';
  static const String lastBackupTime = 'last_backup_time';
}