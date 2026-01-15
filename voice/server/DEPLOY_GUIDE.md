# 阿里云部署指南

本指南帮助您将语音自传后端服务部署到阿里云。

## 第一步：购买阿里云资源

### 1. ECS 云服务器

1. 登录 [阿里云控制台](https://ecs.console.aliyun.com/)
2. 点击「创建实例」
3. 选择配置：
   - **地域**: 选择离您最近的地域（如华东1-杭州）
   - **实例规格**: 选择 `ecs.t6-c1m2.large`（2核4G）
   - **镜像**: Ubuntu 22.04 或 CentOS 8
   - **系统盘**: 40GB SSD
   - **带宽**: 1-5 Mbps（按量付费）
4. 设置登录密码
5. 完成购买

### 2. RDS MySQL 数据库

1. 访问 [RDS控制台](https://rdsnext.console.aliyun.com/)
2. 点击「创建实例」
3. 选择配置：
   - **数据库引擎**: MySQL 8.0
   - **系列**: 基础版
   - **规格**: 1核1G
   - **存储空间**: 20GB
4. 设置数据库账号和密码
5. 完成购买

### 3. 配置安全组

在ECS控制台配置安全组，开放端口：
- **8000** (后端API)
- **22** (SSH)

在RDS控制台添加ECS的内网IP到白名单。

---

## 第二步：连接服务器

```bash
# 使用SSH连接（替换为您的ECS公网IP）
ssh root@your-ecs-ip
```

---

## 第三步：安装环境

```bash
# 更新系统
apt update && apt upgrade -y

# 安装Python 3.10+
apt install python3 python3-pip python3-venv -y

# 安装Git
apt install git -y
```

---

## 第四步：部署代码

```bash
# 创建目录
mkdir -p /opt/voice-autobiography
cd /opt/voice-autobiography

# 上传代码（使用scp或从Git克隆）
# 方法1: 使用scp上传
# scp -r server/* root@your-ecs-ip:/opt/voice-autobiography/

# 方法2: 直接在服务器上创建文件
# 将 server/ 目录下的所有文件复制到服务器
```

---

## 第五步：配置环境变量

```bash
# 复制配置文件
cp .env.example .env

# 编辑配置
nano .env
```

填入以下配置：
```
DB_HOST=rm-xxx.mysql.rds.aliyuncs.com   # RDS内网地址
DB_PORT=3306
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=voice_autobiography

JWT_SECRET_KEY=生成一个随机字符串
JWT_EXPIRE_HOURS=168

# OSS配置（如需上传音频文件）
OSS_ACCESS_KEY_ID=your_key
OSS_ACCESS_KEY_SECRET=your_secret
OSS_ENDPOINT=oss-cn-hangzhou-internal.aliyuncs.com
OSS_BUCKET_NAME=your-bucket
```

---

## 第六步：创建数据库

登录RDS控制台，使用DMS或命令行创建数据库：

```sql
CREATE DATABASE voice_autobiography CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

## 第七步：启动服务

```bash
# 赋予执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

---

## 第八步：设置开机自启（可选）

创建systemd服务：

```bash
cat > /etc/systemd/system/voice-api.service << 'EOF'
[Unit]
Description=Voice Autobiography API
After=network.target

[Service]
User=root
WorkingDirectory=/opt/voice-autobiography
ExecStart=/opt/voice-autobiography/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
systemctl enable voice-api
systemctl start voice-api

# 查看状态
systemctl status voice-api
```

---

## 第九步：配置Flutter应用

修改 `lib/data/services/cloud_sync_service.dart` 中的服务器地址：

```dart
static const String _baseUrl = 'http://您的ECS公网IP:8000';
```

---

## 验证部署

访问以下地址验证服务是否正常：

- **健康检查**: http://您的IP:8000/health
- **API文档**: http://您的IP:8000/docs

---

## 费用估算

| 服务 | 规格 | 月费用 |
|------|------|--------|
| ECS | 2核4G | ¥50-80 |
| RDS | 1核1G | ¥40-60 |
| OSS | 10GB | ¥1-2 |
| 带宽 | 1Mbps | ¥20 |
| **合计** | | **¥110-160** |

---

## 常见问题

### Q: 连接数据库失败？
A: 检查RDS白名单是否添加了ECS的内网IP

### Q: 服务启动失败？
A: 检查 `.env` 配置是否正确，运行 `cat /var/log/syslog` 查看错误日志

### Q: Flutter连接失败？
A: 检查ECS安全组是否开放了8000端口
