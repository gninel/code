# 手机号注册登录与云同步功能使用指南

## 功能概述

本应用已实现完整的手机号注册登录功能和云端数据同步系统，用户可以通过手机号验证码的方式快速注册登录，并将录音和自传数据自动同步到云端。

## 主要功能

### 1. 手机号注册登录
- ✅ 短信验证码发送（60秒倒计时）
- ✅ 手机号格式验证
- ✅ 注册/登录无缝切换
- ✅ 同时支持手机号登录和邮箱登录

### 2. 云端数据同步
- ✅ 登录后自动启用同步
- ✅ 每30分钟自动同步一次
- ✅ 手动上传/下载数据
- ✅ 数据冲突智能处理

### 3. 自动同步机制
- ✅ 用户登录后自动启用
- ✅ 定时后台同步
- ✅ 数据变更时触发同步
- ✅ 退出登录时禁用同步

## 后端实现

### 数据库模型

**User模型** ([server/app/models/user.py](server/app/models/user.py))
```python
class User(Base):
    id = Column(String(36), primary_key=True)
    email = Column(String(255), unique=True, nullable=True)
    phone = Column(String(20), unique=True, nullable=True)  # 新增
    password_hash = Column(String(255), nullable=True)
    nickname = Column(String(100), nullable=True)
```

### API接口

#### 1. 发送验证码
```
POST /auth/send-code
Content-Type: application/json

{
  "phone": "13800138000"
}
```

#### 2. 手机号注册
```
POST /auth/phone/register
Content-Type: application/json

{
  "phone": "13800138000",
  "code": "123456",
  "password": "可选",
  "nickname": "可选"
}
```

#### 3. 手机号登录
```
POST /auth/phone/login
Content-Type: application/json

{
  "phone": "13800138000",
  "code": "123456"
}
```

### 短信服务

当前使用内存模拟短信发送（开发环境）：
- [server/app/utils/sms_service.py](server/app/utils/sms_service.py)
- 验证码有效期：5分钟
- 发送频率限制：60秒一次
- 验证次数限制：最多3次

**生产环境集成真实短信服务：**
```python
# TODO: 集成阿里云短信/腾讯云短信
# 在 sms_service.py 的 send_code 方法中实现
```

## 前端实现

### 核心组件

#### 1. 手机号登录页面
[lib/presentation/pages/phone_auth_page.dart](lib/presentation/pages/phone_auth_page.dart)

功能：
- 手机号输入与验证
- 验证码输入
- 倒计时功能
- 注册/登录切换
- 昵称输入（注册时）

#### 2. 个人中心页面
[lib/presentation/widgets/profile_widget.dart](lib/presentation/widgets/profile_widget.dart)

功能：
- 显示登录状态
- 登录方式选择（手机号/邮箱）
- 云端数据上传/下载
- 数据统计展示

#### 3. 云同步服务
[lib/data/services/cloud_sync_service.dart](lib/data/services/cloud_sync_service.dart)

方法：
```dart
// 发送验证码
Future<void> sendVerificationCode(String phone)

// 手机号注册
Future<User> registerWithPhone(String phone, String code, ...)

// 手机号登录
Future<User> loginWithPhone(String phone, String code)

// 上传数据
Future<void> uploadData({...})

// 下载数据
Future<({...})> downloadData()
```

#### 4. 自动同步服务
[lib/data/services/auto_sync_service.dart](lib/data/services/auto_sync_service.dart)

特性：
- 登录后自动启用
- 30分钟定时同步
- 后台静默同步
- 退出登录时禁用

### 状态管理

**AuthBloc** 处理所有认证相关事件：
- `SendVerificationCode` - 发送验证码
- `PhoneRegister` - 手机号注册
- `PhoneLogin` - 手机号登录
- `UploadData` - 上传数据
- `DownloadData` - 下载数据

## 使用流程

### 用户注册流程

1. 打开应用，进入个人中心
2. 点击"登录"按钮
3. 选择"手机号登录"
4. 输入手机号
5. 点击"获取验证码"
6. 输入收到的6位验证码
7. （可选）输入昵称
8. 点击"注册"按钮
9. 注册成功，自动登录并启用自动同步

### 用户登录流程

1. 打开应用，进入个人中心
2. 点击"登录"按钮
3. 选择"手机号登录"
4. 输入手机号
5. 点击"获取验证码"
6. 输入收到的6位验证码
7. 点击"登录"按钮
8. 登录成功，自动启用自动同步

### 数据同步流程

**自动同步：**
- 用户登录后，系统每30分钟自动同步一次
- 后台静默执行，不影响用户操作

**手动同步：**
1. 进入个人中心
2. 在"云端同步"卡片中：
   - 点击"上传数据"：将本地数据上传到云端
   - 点击"恢复数据"：从云端下载数据到本地

## 安全性说明

### 数据传输
- 所有API请求使用HTTPS加密
- 使用JWT Token进行身份认证
- Token存储在本地加密存储

### 验证码安全
- 验证码6位随机数字
- 5分钟有效期
- 最多验证3次
- 60秒发送频率限制

### 密码安全
- 使用bcrypt加密存储
- 手机号登录不强制要求密码
- 支持后续绑定密码

## 开发环境配置

### 后端配置

1. 安装依赖：
```bash
cd server
pip install -r requirements.txt
```

2. 配置环境变量：
```bash
cp .env.example .env
# 编辑 .env 文件，配置数据库等
```

3. 运行服务器：
```bash
python -m app.main
```

### 前端配置

1. 修改服务器地址：
编辑 [lib/data/services/cloud_sync_service.dart](lib/data/services/cloud_sync_service.dart)
```dart
static const String _baseUrl = 'http://your-server-ip:8000';
```

2. 运行应用：
```bash
flutter pub get
flutter run
```

## 生产环境部署

### 短信服务集成

**推荐服务商：**
- 阿里云短信服务
- 腾讯云短信服务
- 云片短信

**集成步骤：**
1. 在 `server/app/utils/sms_service.py` 中集成API
2. 配置短信签名和模板
3. 添加API密钥到环境变量
4. 测试发送功能

### 服务器部署

1. 配置数据库（PostgreSQL/MySQL）
2. 配置Nginx反向代理
3. 配置SSL证书（HTTPS）
4. 使用PM2/Supervisor管理进程
5. 配置日志和监控

## 常见问题

**Q: 验证码收不到怎么办？**
A: 开发环境下验证码会打印在后端控制台，生产环境需集成真实短信服务。

**Q: 数据同步失败怎么办？**
A: 检查网络连接和服务器状态，确认已登录。

**Q: 自动同步什么时候触发？**
A: 登录后立即执行一次，之后每30分钟自动同步。

**Q: 可以关闭自动同步吗？**
A: 目前不支持手动关闭，退出登录会自动禁用。

## 技术栈

### 后端
- FastAPI - Web框架
- SQLAlchemy - ORM
- Pydantic - 数据验证
- JWT - 身份认证
- bcrypt - 密码加密

### 前端
- Flutter 3.10+ - 跨平台框架
- BLoC - 状态管理
- Dio - HTTP客户端
- shared_preferences - 本地存储
- Injectable - 依赖注入

## 未来计划

- [ ] 支持微信/QQ第三方登录
- [ ] 实现增量同步机制
- [ ] 添加数据冲突解决策略
- [ ] 支持多设备管理
- [ ] 添加数据加密
- [ ] 实现离线缓存

---

**文档版本：** 1.0.0
**最后更新：** 2025-12-29
**作者：** 语音自传开发团队
