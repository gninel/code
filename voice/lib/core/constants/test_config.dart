/// 测试配置
///
/// 用于控制测试模式的开关和测试参数
///
/// 使用说明:
/// - 开发/测试阶段: 将 isTestMode 设置为 true
/// - 生产环境: 将 isTestMode 设置为 false
class TestConfig {
  /// 是否为测试模式
  ///
  /// true: 测试模式 - 使用固定验证码,不发送真实短信
  /// false: 生产模式 - 调用真实API发送短信
  static const bool isTestMode = true;

  /// 测试验证码
  ///
  /// 在测试模式下,所有手机号都使用这个验证码进行验证
  static const String testVerificationCode = '1111';

  /// 验证码长度
  static const int verificationCodeLength = 4;

  /// 验证码倒计时时长(秒)
  static const int verificationCodeTimeout = 60;

  TestConfig._(); // 私有构造函数,防止实例化
}
