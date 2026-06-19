# MusicPocket 技术方案

## 系统架构

```
┌─────────────────────────────────────────────────────┐
│                  Flutter App (客户端)                 │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ 链接粘贴  │  │ 转换状态  │  │ 离线音频库 + 播放器 │  │
│  │ & 检测   │  │ & 进度   │  │ (just_audio)      │  │
│  └────┬─────┘  └────┬─────┘  └───────┬───────────┘  │
│       │              │               │              │
│  ┌────┴──────────────┴───────────────┴──────────┐   │
│  │              BLoC 状态管理                      │   │
│  │  TaskBloc / LibraryBloc / PlayerBloc          │   │
│  └────┬──────────────────────────────────────────┘   │
│       │                              │              │
│  ┌────┴──────┐              ┌────────┴──────┐       │
│  │ ApiService│              │ LocalStorage  │       │
│  │ (Dio)     │              │ (SQLite)      │       │
│  └────┬──────┘              └───────────────┘       │
└───────┼─────────────────────────────────────────────┘
        │ HTTPS
┌───────┴─────────────────────────────────────────────┐
│                FastAPI 后端服务                       │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │               API Gateway                     │   │
│  │  POST /api/v1/convert    (提交转换任务)         │   │
│  │  GET  /api/v1/tasks/:id  (查询进度)            │   │
│  │  GET  /api/v1/tasks/:id/download (下载音频)     │   │
│  │  POST /api/v1/detect     (链接预检测)           │   │
│  └──────────┬───────────────────────────────────┘   │
│             │                                       │
│  ┌──────────┴───────────────────────────────────┐   │
│  │          插件式解析器注册中心                     │   │
│  │  ParserRegistry                               │   │
│  │    ├── DouyinParser     (抖音)                 │   │
│  │    ├── TikTokParser     (TikTok)              │   │
│  │    ├── BilibiliParser   (B站)                  │   │
│  │    └── XiaohongshuParser(小红书)               │   │
│  └──────────┬───────────────────────────────────┘   │
│             │                                       │
│  ┌──────────┴──────┐  ┌────────────────────────┐   │
│  │ DownloadService │  │  TranscodeService      │   │
│  │ (httpx 流式下载) │  │  (FFmpeg 音频转码)      │   │
│  └─────────────────┘  └────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │ TaskManager (任务编排)                        │    │
│  │ 解析 → 下载 → 转码 → 临时存储 → 通知客户端下载  │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

## 核心设计决策

### 1. 解析器插件化

每个平台一个独立解析器，继承 `BaseParser`，注册到 `ParserRegistry`。

好处：
- 平台规则变化时只改对应解析器，不影响其他平台
- 新增平台只需实现一个类并注册
- 解析逻辑在服务端，更新不需要客户端升级

### 2. 解析逻辑放后端

核心原因：平台反爬策略频繁变化，后端更新即时生效，不依赖用户升级 App。

### 3. 临时文件策略

- 后端只做中转，转码完成后立即让客户端下载
- 服务器文件 6 小时后自动清理
- 降低存储成本和版权风险

### 4. B站 DASH 音频直取

B站采用 DASH 格式，音视频分离存储。直接获取音频流，避免下载完整视频再抽取，节省带宽和时间。

### 5. 客户端 BLoC 架构

- `TaskBloc`：管理转换任务的提交、轮询、完成
- `LibraryBloc`：本地音频库的增删查改
- `PlayerBloc`：音频播放状态（播放/暂停/进度/播放列表）

## 各平台解析难点

| 平台 | 难度 | 关键问题 |
|------|------|---------|
| TikTok | 中 | 地区限制、签名参数(msToken/X-Bogus)、临时链接 |
| 抖音 | 中高 | Cookie风控、X-Bogus签名、频繁更新、验证码 |
| B站 | 中高 | wbi签名、高音质需登录/大会员、DASH格式 |
| 小红书 | 高 | X-s/X-t签名、设备指纹、登录态、反爬最强 |

## 生产环境补充项

当前代码是 MVP 框架，生产部署还需要：

1. **签名模块**：各平台的请求签名算法（JS逆向 / RPC调用）
2. **Cookie池**：管理多账号Cookie，应对登录校验
3. **代理IP池**：轮换IP应对频率限制
4. **Playwright兜底**：网页接口失效时用无头浏览器
5. **Celery任务队列**：替换当前的asyncio，支持高并发
6. **对象存储**：接入S3/OSS存储临时文件
7. **监控告警**：各平台解析成功率监控，失败时自动告警

## 文件结构

```
musicpocket/
├── ARCHITECTURE.md
├── server/                      # Python 后端
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── requirements.txt
│   └── app/
│       ├── main.py              # FastAPI 入口
│       ├── config.py            # 配置管理
│       ├── models/              # 数据库模型
│       │   ├── task.py          # 转换任务
│       │   └── user.py          # 用户
│       ├── schemas/             # Pydantic 请求/响应模型
│       │   └── task.py
│       ├── routers/             # API 路由
│       │   └── convert.py       # 转换相关接口
│       ├── parsers/             # 平台解析器（核心）
│       │   ├── base.py          # 解析器基类
│       │   ├── registry.py      # 注册中心
│       │   ├── douyin.py        # 抖音
│       │   ├── tiktok.py        # TikTok
│       │   ├── bilibili.py      # B站
│       │   └── xiaohongshu.py   # 小红书
│       ├── services/            # 业务服务
│       │   ├── link_service.py  # 链接识别
│       │   ├── download_service.py   # 下载
│       │   ├── transcode_service.py  # FFmpeg转码
│       │   └── task_service.py       # 任务编排
│       └── utils/
└── app/                         # Flutter 客户端
    ├── pubspec.yaml
    └── lib/
        ├── main.dart            # 入口
        ├── models/
        │   └── audio_task.dart  # 音频任务模型
        ├── services/
        │   ├── api_service.dart          # API 通信
        │   ├── audio_player_service.dart # 音频播放
        │   └── local_storage_service.dart# 本地存储
        ├── bloc/
        │   ├── task/            # 转换任务状态
        │   ├── library/         # 音频库状态
        │   └── player/          # 播放器状态
        └── screens/
            ├── home_screen.dart     # 主页（粘贴+转换）
            ├── library_screen.dart  # 音频库列表
            └── player_screen.dart   # 播放器界面
```
