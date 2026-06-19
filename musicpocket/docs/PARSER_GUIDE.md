# 平台解析器开发指南

本文档面向需要维护或新增平台解析器的开发者。

---

## 解析器架构

```
ParserRegistry（注册中心）
  ├── DouyinParser      → 抖音解析
  ├── TikTokParser      → TikTok 解析
  ├── BilibiliParser    → B站解析
  ├── XiaohongshuParser → 小红书解析
  └── [新增平台...]
         │
         ↓ 失败时回退
  BrowserParser（Playwright 兜底）
```

每个解析器独立实现，互不影响。注册中心根据 URL 自动路由到对应解析器。

---

## 解析器接口定义

每个解析器必须实现 `BaseParser` 的三个抽象方法：

```python
class BaseParser(ABC):
    @property
    @abstractmethod
    def platform_name(self) -> str:
        """平台标识，如 'douyin'"""

    @property
    @abstractmethod
    def url_patterns(self) -> list[re.Pattern]:
        """匹配该平台的 URL 正则列表"""

    @abstractmethod
    async def parse(self, url: str) -> ParsedVideoInfo:
        """解析视频页面，返回媒体地址"""

    @abstractmethod
    def extract_video_id(self, url: str) -> Optional[str]:
        """从 URL 提取视频 ID"""
```

`parse()` 返回的 `ParsedVideoInfo`：
```python
class ParsedVideoInfo(BaseModel):
    platform: str          # 平台标识
    video_id: str          # 视频 ID
    title: str             # 标题
    author: str            # 作者
    cover_url: str | None  # 封面图
    duration_seconds: int | None  # 时长
    media_url: str         # 下载地址（核心）
    is_audio_only: bool    # 是否纯音频流
    headers: dict          # 下载时需要的请求头
```

---

## 各平台解析要点

### 抖音（DouyinParser）

**URL 格式**：
- 短链接：`https://v.douyin.com/iRNBho5e/`
- 完整链接：`https://www.douyin.com/video/7234567890123456789`
- 图文笔记：`https://www.douyin.com/note/7234567890123456789`

**解析流程**：
1. 短链接 → `HEAD` 跟随重定向 → 完整 URL
2. 从 URL 提取 `aweme_id`
3. 调用 `/aweme/v1/web/aweme/detail/` 接口
4. 优先取 `music.play_url`（纯音频），回退到 `video.play_addr`

**难点**：
- `X-Bogus` 签名参数：需要 JS 逆向生成
- Cookie 过期快，需要定期刷新
- 部分视频需要登录态
- 风控严格，高频请求会触发验证码

**维护频率**：约 1-2 个月更新一次签名算法

### TikTok（TikTokParser）

**URL 格式**：
- 短链接：`https://vm.tiktok.com/ZMrUxyz/`、`https://vt.tiktok.com/ZSrABC/`
- 完整链接：`https://www.tiktok.com/@user/video/7234567890123456789`

**解析流程**：
1. 短链接 → 重定向 → 完整 URL
2. 提取 `video_id`
3. 调用 `/api/item/detail/` 接口
4. 取 `music.playUrl` 或 `video.downloadAddr`

**难点**：
- 地区限制：部分内容需要特定地区 IP（美国、东南亚）
- `msToken` 和 `X-Bogus` 签名
- 下载链接有效期很短（几分钟）

### B站（BilibiliParser）

**URL 格式**：
- BV号：`https://www.bilibili.com/video/BV1xx411c7mD`
- AV号：`https://www.bilibili.com/video/av12345678`
- 短链接：`https://b23.tv/BV1xx411c7mD`

**解析流程**：
1. 短链接 → 重定向
2. 提取 BV 号或 AV 号
3. `/x/web-interface/view` → 获取 `cid` 和基本信息
4. `/x/player/playurl?fnval=16` → 获取 DASH 格式音频流
5. 从 `dash.audio[]` 中选择最高音质

**关键优势**：B站 DASH 格式音视频分离，可以**直接下载音频流**，无需下载完整视频再转码。

**难点**：
- `wbi` 签名（较稳定，变化不频繁）
- 高音质（192kbps+）需要登录
- 大会员独占内容无法获取
- 分P视频需要处理 `cid` 列表

### 小红书（XiaohongshuParser）

**URL 格式**：
- 短链接：`https://xhslink.com/abc123`
- 完整链接：`https://www.xiaohongshu.com/explore/6567890abcdef`

**解析流程**：
1. 短链接 → 重定向
2. 提取笔记 ID
3. 调用 `/api/sns/web/v1/feed` 接口
4. 检查 `type == "video"`（图文笔记无音频）
5. 从 `video.media.stream` 中获取视频流

**难点（技术难度最高）**：
- `X-s` / `X-t` 签名：加密算法复杂，需要 JS 逆向
- 强制设备指纹校验
- 几乎必须有登录态 Cookie
- 规则变化最频繁（可能每月更新）
- 建议：小红书优先使用 Playwright 兜底方案

---

## Playwright 兜底方案

当常规解析失败时，自动降级到浏览器方案：

```python
from app.parsers.browser.playwright_parser import BrowserParser

browser = BrowserParser(headless=True)
result = await browser.parse("https://v.douyin.com/xxx/")
# result["media_urls"] → 捕获到的媒体地址列表
# result["title"] / result["author"] → 页面元数据

best = browser.select_best_media(result["media_urls"])
# 优先纯音频 → 其次最大视频文件
```

**工作原理**：
1. 启动无头 Chromium，模拟移动端 User-Agent
2. 监听所有网络响应，匹配音视频 Content-Type
3. 同时从 DOM 中查找 `<video>` / `<audio>` 元素
4. 从 `<meta>` 标签提取标题、作者、封面

---

## 新增平台检查清单

- [ ] 实现 `BaseParser` 的全部抽象方法
- [ ] URL 正则覆盖短链接和完整链接
- [ ] `parse()` 优先返回纯音频流
- [ ] `headers` 包含必要的 Referer 和 User-Agent
- [ ] 添加 URL 匹配测试（`tests/test_parsers.py`）
- [ ] 在 `main.py` 注册到 `ParserRegistry`
- [ ] 客户端 `clipboard_service.dart` 添加 URL 模式
- [ ] 客户端 `platform_icon.dart` 添加平台图标
- [ ] `scripts/monitor.py` 添加测试 URL
- [ ] 更新 `docs/` 中的相关文档
