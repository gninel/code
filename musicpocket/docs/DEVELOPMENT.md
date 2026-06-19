# MusicPocket 开发指南

## 项目结构

```
musicpocket/
├── docs/                        # 文档
│   ├── FEASIBILITY.md           # 可行性分析
│   ├── ARCHITECTURE.md          # 系统架构
│   ├── API.md                   # API 接口文档
│   ├── DEPLOYMENT.md            # 部署指南
│   ├── DEVELOPMENT.md           # 开发指南（本文件）
│   └── PARSER_GUIDE.md          # 解析器开发指南
├── server/                      # Python 后端
│   ├── app/
│   │   ├── main.py              # FastAPI 入口
│   │   ├── config.py            # 配置
│   │   ├── parsers/             # 平台解析器
│   │   ├── services/            # 业务服务
│   │   ├── routers/             # API 路由
│   │   ├── middleware/          # 中间件
│   │   ├── models/              # 数据库模型
│   │   └── schemas/             # 请求/响应模型
│   ├── tests/                   # 测试
│   ├── scripts/                 # 运维脚本
│   └── deploy/                  # 部署配置
└── app/                         # Flutter 客户端
    └── lib/
        ├── main.dart            # 入口
        ├── bloc/                # 状态管理
        ├── screens/             # 页面
        ├── widgets/             # 组件
        ├── services/            # 服务层
        ├── models/              # 数据模型
        └── theme/               # 主题
```

---

## 后端开发

### 技术栈

| 组件 | 技术 | 用途 |
|------|------|------|
| Web 框架 | FastAPI | 异步 API 服务 |
| HTTP 客户端 | httpx | 异步请求、短链接跟随 |
| 音频转码 | FFmpeg | 视频转音频、格式转换 |
| 任务队列 | Celery + Redis | 异步任务处理（生产） |
| 数据库 | PostgreSQL + SQLAlchemy | 用户、任务、配额 |
| 浏览器模拟 | Playwright | 兜底解析方案 |
| 日志 | structlog | 结构化日志 |

### 解析器开发

每个平台解析器是一个独立类，继承 `BaseParser`：

```python
from app.parsers.base import BaseParser
from app.schemas.task import ParsedVideoInfo

class NewPlatformParser(BaseParser):
    @property
    def platform_name(self) -> str:
        return "newplatform"

    @property
    def url_patterns(self) -> list[re.Pattern]:
        return [
            re.compile(r'newplatform\.com/video/(\w+)'),
        ]

    def extract_video_id(self, url: str) -> Optional[str]:
        match = re.search(r'/video/(\w+)', url)
        return match.group(1) if match else None

    async def parse(self, url: str) -> ParsedVideoInfo:
        # 1. 解析短链接
        # 2. 提取视频 ID
        # 3. 调用平台接口获取媒体地址
        # 4. 返回 ParsedVideoInfo
        ...
```

然后在 `app/main.py` 注册：
```python
registry.register(NewPlatformParser())
```

### 添加测试

在 `tests/test_parsers.py` 中添加：
```python
class TestNewPlatformParser:
    def test_match_url(self):
        p = NewPlatformParser()
        assert p.matches("https://newplatform.com/video/abc123")

    def test_extract_id(self):
        p = NewPlatformParser()
        assert p.extract_video_id("https://newplatform.com/video/abc123") == "abc123"
```

### 代码规范

- 类型注解：所有公共方法必须有类型注解
- 错误处理：解析失败抛出 `ValueError`，附带有意义的错误信息
- 日志：关键步骤用 `structlog` 记录，包含 `task_id` 和 `platform`
- 临时文件：用完立即清理，不在服务器长期保留

---

## 客户端开发

### 技术栈

| 组件 | 技术 | 用途 |
|------|------|------|
| 框架 | Flutter 3.10+ | 跨平台 UI |
| 状态管理 | flutter_bloc | BLoC 模式 |
| 网络 | Dio | HTTP 请求 |
| 本地存储 | sqflite | SQLite 音频库 |
| 音频播放 | just_audio | 离线音频播放 |
| 设置 | shared_preferences | 用户偏好存储 |

### BLoC 架构

三个核心 BLoC：

**TaskBloc**：转换任务生命周期
```
SubmitUrl → TaskDetecting → TaskSubmitted → (轮询) → TaskProcessing → TaskCompleted
                                                                    → TaskFailed
```

**LibraryBloc**：本地音频库
```
LoadLibrary / LoadFavorites / SearchLibrary → LibraryLoaded
ToggleFavorite / DeleteAudio → 重新加载
```

**PlayerBloc**：音频播放
```
PlayTrack / SetPlaylist → 更新 PlayerState
TogglePlayPause / SeekTo / NextTrack / PreviousTrack
```

### 添加新页面

1. 在 `lib/screens/` 创建页面 Widget
2. 如需新状态，在 `lib/bloc/` 创建对应的 Event/State/Bloc
3. 在 `main.dart` 的 `MultiBlocProvider` 注册新 Bloc
4. 通过 `Navigator.push` 或导航栏接入

### 主题系统

所有颜色和样式定义在 `lib/theme/app_theme.dart`：
```dart
AppColors.primary    // 黑色
AppColors.accent     // 红色（MusicPocket 品牌色）
AppColors.surface    // 浅灰背景
AppColors.textPrimary / textSecondary
```

---

## 开发流程

### 新增平台支持

1. `server/app/parsers/` 创建新解析器
2. `server/tests/test_parsers.py` 添加 URL 匹配测试
3. `server/app/main.py` 注册解析器
4. `app/lib/widgets/platform_icon.dart` 添加平台图标
5. `app/lib/services/clipboard_service.dart` 添加 URL 模式
6. 运行测试确认

### 修复解析器

当某个平台解析失败时：

1. 用 `scripts/monitor.py` 确认问题
2. 用浏览器开发者工具抓包分析接口变化
3. 更新对应解析器的请求参数/签名/Headers
4. 运行测试确认修复
5. 部署到服务端即可，无需客户端更新

### 调试技巧

后端：
```bash
# 启用调试日志
MP_DEBUG=true uvicorn app.main:app --reload

# 测试单个链接解析
python -c "
import asyncio
from app.parsers.douyin import DouyinParser
p = DouyinParser()
result = asyncio.run(p.parse('https://www.douyin.com/video/xxx'))
print(result)
"
```

客户端：
```bash
# 热重载开发
flutter run --debug

# 查看网络请求
# 在 ApiService 构造函数中添加 Dio 拦截器打印请求日志
```
