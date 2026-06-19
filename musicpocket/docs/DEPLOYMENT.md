# MusicPocket 部署指南

## 环境要求

- Python 3.12+
- FFmpeg 6.0+
- PostgreSQL 16+
- Redis 7+
- Docker & Docker Compose（推荐）

---

## 一、本地开发

### 后端

```bash
cd musicpocket/server

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 安装 Playwright 浏览器（兜底解析用）
playwright install chromium

# 启动依赖服务
docker compose up -d db redis

# 启动 API 服务（开发模式）
MP_DEBUG=true uvicorn app.main:app --reload --port 8000
```

API 文档：http://localhost:8000/docs

### 客户端

```bash
cd musicpocket/app

# 获取依赖
flutter pub get

# 运行（iOS/Android/Web）
flutter run

# 修改服务器地址（默认 localhost:8000）
# 在 App 设置页面修改，或编辑 lib/services/api_service.dart
```

### 运行测试

```bash
cd musicpocket/server

# 安装测试依赖
pip install pytest pytest-asyncio

# 运行全部测试
pytest

# 运行特定测试
pytest tests/test_parsers.py -v
pytest tests/test_api.py -v
```

---

## 二、Docker 部署（开发/测试）

```bash
cd musicpocket/server

# 一键启动（API + PostgreSQL + Redis）
docker compose up -d

# 查看日志
docker compose logs -f api
```

服务地址：http://localhost:8000

---

## 三、生产部署

### 准备配置

```bash
cd musicpocket/server/deploy

# 复制环境变量模板
cp .env.example .env

# 编辑配置（必须修改）
vim .env
```

**必须修改的配置**：
- `POSTGRES_PASSWORD`：数据库密码
- `JWT_SECRET`：JWT 签名密钥

**可选配置**：
- `S3_*`：对象存储（临时文件中转）
- `MP_PROXY_POOL_URL`：代理池 API 地址

### SSL 证书

```bash
# 将证书放到 deploy/certs/ 目录
mkdir -p certs
cp your-cert.crt certs/musicpocket.crt
cp your-key.key certs/musicpocket.key
```

### 启动生产服务

```bash
cd musicpocket/server/deploy

# 启动全部服务（API x2 + Worker x2 + Beat + DB + Redis + Nginx）
docker compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f celery-worker
```

### 生产架构

```
客户端 → Nginx (443) → FastAPI API (x2) → Redis → Celery Worker (x2)
                                           ↓
                                       PostgreSQL
```

- **Nginx**：SSL 终止、负载均衡、静态资源
- **API x2**：无状态，水平扩展
- **Celery Worker x2**：解析+下载+转码，CPU 密集
- **Celery Beat x1**：定时清理过期文件
- **Redis**：任务队列 + 缓存
- **PostgreSQL**：用户、任务、配额持久化

### 扩容

```bash
# 增加 API 实例
docker compose -f docker-compose.prod.yml up -d --scale api=4

# 增加 Worker 实例
docker compose -f docker-compose.prod.yml up -d --scale celery-worker=4
```

---

## 四、监控

### 解析器健康检查

```bash
cd musicpocket/server

# 单次检查
python scripts/monitor.py

# 持续监控（每 5 分钟）
python scripts/monitor.py --loop 300
```

输出示例：
```
============================================================
MusicPocket 解析器健康检查  2024-12-01 10:00:00
============================================================
  ✓ douyin          ok       1.2s
  ✓ tiktok          ok       2.1s
  ✗ bilibili        error    0.5s
    └─ B站 API 错误: 请求被拦截
  ✓ xiaohongshu     ok       3.4s

总计: 4 个平台, 3 正常, 1 异常
```

### 建议接入的监控指标

- 各平台解析成功率（按小时统计）
- API 响应时间（P50/P95/P99）
- 任务完成率和平均耗时
- 服务器 CPU / 内存 / 磁盘使用率
- Redis 队列积压长度
- 临时文件目录占用空间

---

## 五、Cookie 管理

部分平台需要有效 Cookie 才能解析。

### 手动添加

创建 `cookies.json`：
```json
{
  "douyin": [
    {"cookies": "sessionid=xxx; ttwid=xxx", "label": "account-1"}
  ],
  "xiaohongshu": [
    {"cookies": "web_session=xxx", "label": "xhs-1"}
  ]
}
```

程序启动时加载：
```python
cookie_manager.load_from_file("cookies.json")
```

### Cookie 池状态

通过 `CookieManager.get_stats()` 查看各平台 Cookie 可用数量。
连续失败 3 次的 Cookie 会自动标记失效。

---

## 六、常见问题

### 解析突然全部失败

1. 检查服务器出口 IP 是否被封
2. 检查 Cookie 是否全部失效
3. 运行 `python scripts/monitor.py` 定位具体平台
4. 查看平台是否更新了签名算法

### 转码失败

1. 确认 FFmpeg 已安装：`ffmpeg -version`
2. 检查临时目录磁盘空间
3. 查看错误日志中的 FFmpeg 输出

### 文件下载 410 Gone

临时文件已过期（默认 6 小时）。用户需要重新转换。
可调整 `MP_TEMP_FILE_TTL` 环境变量延长保留时间。
