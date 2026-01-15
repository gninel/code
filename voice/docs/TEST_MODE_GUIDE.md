# 测试模式使用指南

## 概述

本应用提供了测试模式功能,方便开发和测试阶段快速验证手机登录/注册功能,无需真实发送短信验证码。

## 配置文件

测试模式的配置在 `lib/core/constants/test_config.dart` 文件中:

```dart
class TestConfig {
  /// 是否为测试模式
  static const bool isTestMode = true;  // 测试阶段

  /// 测试验证码
  static const String testVerificationCode = '1111';

  /// 验证码长度
  static const int verificationCodeLength = 4;

  /// 验证码倒计时时长(秒)
  static const int verificationCodeTimeout = 60;
}
```

## 测试模式 vs 生产模式

### 测试模式 (isTestMode = true)

**特点:**
- ✅ 不发送真实短信
- ✅ 所有手机号使用固定验证码 `1111`
- ✅ 模拟网络延迟(500-800ms)
- ✅ 创建本地测试用户
- ✅ UI显示测试提示信息

**适用场景:**
- 开发阶段调试
- 功能测试
- UI测试
- 演示Demo

### 生产模式 (isTestMode = false)

**特点:**
- ✅ 调用真实短信API
- ✅ 发送真实验证码
- ✅ 连接后端服务器
- ✅ 真实用户数据

**适用场景:**
- 正式上线
- 生产环境部署

## 如何使用测试模式

### 1. 启用测试模式

打开 `lib/core/constants/test_config.dart`,确保:

```dart
static const bool isTestMode = true;
```

### 2. 测试登录/注册流程

1. 打开应用,进入登录页面
2. 输入任意符合格式的手机号(如: 13800138000)
3. 点击"获取验证码"
4. 看到提示: "验证码已发送(测试: 1111)"
5. 输入验证码 `1111`
6. 点击"登录"或"注册"
7. ✅ 成功进入应用

### 3. UI提示信息

测试模式下,登录页面会显示醒目的橙色提示框:

```
⚠️ 测试模式:验证码统一为 1111
```

### 4. 控制台日志

测试模式下会输出调试信息:

```
测试模式: 验证码为 1111
```

## 切换到生产模式

### 步骤

1. 打开 `lib/core/constants/test_config.dart`
2. 修改配置:
   ```dart
   static const bool isTestMode = false;
   ```
3. 确保后端服务器已配置
4. 配置真实的短信API密钥
5. 重新编译应用

### 注意事项

⚠️ **重要提醒:**
- 生产环境部署前**必须**关闭测试模式
- 关闭测试模式后,UI将不再显示测试提示
- 需要配置真实的服务器地址和短信服务

## 自定义测试验证码

如果需要修改测试验证码,在 `TestConfig` 中修改:

```dart
static const String testVerificationCode = '6666';  // 改为你想要的验证码
static const int verificationCodeLength = 4;        // 对应修改长度
```

然后同步修改UI页面的验证码长度验证:
- `lib/presentation/pages/phone_auth_page.dart`

## 代码实现位置

### 核心文件

1. **配置文件**
   - `lib/core/constants/test_config.dart` - 测试模式配置

2. **服务层**
   - `lib/data/services/cloud_sync_service.dart` - 实现测试模式逻辑

3. **UI层**
   - `lib/presentation/pages/phone_auth_page.dart` - 登录/注册页面
   - 显示测试模式提示
   - 验证码长度为4位

### 关键方法

1. **发送验证码**
   ```dart
   Future<void> sendVerificationCode(String phone) async {
     if (TestConfig.isTestMode) {
       // 测试模式逻辑
     } else {
       // 生产模式逻辑
     }
   }
   ```

2. **手机号注册**
   ```dart
   Future<User> registerWithPhone(String phone, String code, ...) async {
     if (TestConfig.isTestMode) {
       if (code != TestConfig.testVerificationCode) {
         throw Exception('验证码错误');
       }
       // 创建测试用户
     } else {
       // 调用真实API
     }
   }
   ```

3. **手机号登录**
   ```dart
   Future<User> loginWithPhone(String phone, String code) async {
     if (TestConfig.isTestMode) {
       // 验证测试验证码
     } else {
       // 调用真实API
     }
   }
   ```

## 测试用例

### 成功场景

✅ 手机号: 13800138000, 验证码: 1111 → 登录成功
✅ 手机号: 13900139000, 验证码: 1111 → 注册成功

### 失败场景

❌ 手机号: 13800138000, 验证码: 1234 → 验证码错误
❌ 手机号: abc, 验证码: 1111 → 手机号格式不正确
❌ 验证码: 123 → 验证码为4位数字

## 常见问题

### Q1: 为什么输入正确的验证码还是提示错误?

A: 检查是否输入了完整的4位验证码 `1111`,不要有空格。

### Q2: 如何知道当前是测试模式还是生产模式?

A: 测试模式下登录页面会显示橙色提示框,并且验证码发送成功提示会包含"(测试: 1111)"。

### Q3: 测试模式下创建的用户数据会保存吗?

A: 会保存在本地SharedPreferences中,但仅用于测试,切换到生产模式后需要重新登录。

### Q4: 可以同时支持测试账号和真实账号吗?

A: 当前设计是全局开关,建议分别在测试环境和生产环境使用不同的配置。

## 安全建议

1. ✅ 测试验证码不要使用过于简单的数字(如: 0000, 1234)
2. ✅ 生产环境部署前务必关闭测试模式
3. ✅ 不要将测试模式配置提交到生产分支
4. ✅ 建议使用环境变量或配置文件管理不同环境的设置

---

**最后更新:** 2025-12-29
**版本:** 1.0.0
