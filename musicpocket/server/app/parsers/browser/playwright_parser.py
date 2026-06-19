import asyncio
import re
from typing import Optional
import structlog
from ..base import BaseParser
from ...schemas.task import ParsedVideoInfo

logger = structlog.get_logger()


class BrowserParser:
    """
    Playwright 无头浏览器兜底解析器。

    当常规 API 解析失败（签名过期、接口变更）时，
    通过真实浏览器加载页面并监听网络请求，捕获音视频流地址。

    优点：
    - 兼容性最强，平台更新后修复成本低
    - 能绕过大部分签名和指纹校验

    缺点：
    - 资源消耗高（每个任务启动一个浏览器标签页）
    - 速度慢（需等页面完全加载）
    - 容易被检测为自动化访问
    - 并发受限
    """

    MEDIA_PATTERNS = [
        re.compile(r'\.mp4(\?|$)', re.IGNORECASE),
        re.compile(r'\.m4a(\?|$)', re.IGNORECASE),
        re.compile(r'\.mp3(\?|$)', re.IGNORECASE),
        re.compile(r'\.flv(\?|$)', re.IGNORECASE),
        re.compile(r'\.m3u8(\?|$)', re.IGNORECASE),
        re.compile(r'audio.*\.m4s', re.IGNORECASE),
        re.compile(r'/playurl\?', re.IGNORECASE),
        re.compile(r'bilivideo\.com', re.IGNORECASE),
        re.compile(r'douyinvod\.com', re.IGNORECASE),
        re.compile(r'tiktokcdn\.com', re.IGNORECASE),
        re.compile(r'sns-video', re.IGNORECASE),
    ]

    def __init__(self, headless: bool = True, proxy: Optional[str] = None):
        self.headless = headless
        self.proxy = proxy
        self._browser = None
        self._playwright = None

    async def _ensure_browser(self):
        if self._browser is None:
            from playwright.async_api import async_playwright
            self._playwright = await async_playwright().start()
            launch_opts = {"headless": self.headless}
            if self.proxy:
                launch_opts["proxy"] = {"server": self.proxy}
            self._browser = await self._playwright.chromium.launch(**launch_opts)

    async def parse(self, url: str, timeout_ms: int = 30000) -> dict:
        """
        通过浏览器加载页面，监听网络请求，提取媒体地址和页面元数据。

        返回:
        {
            "media_urls": [...],   # 捕获到的媒体地址列表
            "title": "...",
            "author": "...",
            "cover_url": "...",
        }
        """
        await self._ensure_browser()

        context = await self._browser.new_context(
            user_agent=(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                "AppleWebKit/605.1.15 (KHTML, like Gecko) "
                "Version/17.0 Mobile/15E148 Safari/604.1"
            ),
            viewport={"width": 390, "height": 844},
            locale="zh-CN",
        )

        page = await context.new_page()
        captured_urls: list[dict] = []

        async def on_response(response):
            req_url = response.url
            content_type = response.headers.get("content-type", "")
            is_media = (
                any(p.search(req_url) for p in self.MEDIA_PATTERNS)
                or "video/" in content_type
                or "audio/" in content_type
            )
            if is_media:
                is_audio = "audio" in content_type or ".m4a" in req_url or ".mp3" in req_url or "audio" in req_url
                captured_urls.append({
                    "url": req_url,
                    "content_type": content_type,
                    "is_audio": is_audio,
                    "size": int(response.headers.get("content-length", "0")),
                })
                logger.info("browser_media_captured", url=req_url[:120], type=content_type)

        page.on("response", on_response)

        try:
            await page.goto(url, wait_until="networkidle", timeout=timeout_ms)
            # 额外等待一些延迟加载的请求
            await asyncio.sleep(2)

            # 提取页面元数据
            metadata = await page.evaluate("""
                () => {
                    const getMeta = (name) => {
                        const el = document.querySelector(`meta[property="${name}"], meta[name="${name}"]`);
                        return el ? el.getAttribute('content') : null;
                    };
                    return {
                        title: getMeta('og:title') || document.title || '',
                        author: getMeta('og:site_name') || getMeta('author') || '',
                        cover_url: getMeta('og:image') || '',
                        description: getMeta('og:description') || '',
                    };
                }
            """)

            # 如果没有通过网络监听捕获到，尝试查找页面中的 video/audio 元素
            if not captured_urls:
                element_urls = await page.evaluate("""
                    () => {
                        const urls = [];
                        document.querySelectorAll('video source, video, audio source, audio').forEach(el => {
                            const src = el.src || el.getAttribute('src');
                            if (src && src.startsWith('http')) {
                                urls.push({url: src, is_audio: el.tagName === 'AUDIO' || el.closest('audio') !== null});
                            }
                        });
                        return urls;
                    }
                """)
                for item in element_urls:
                    captured_urls.append({
                        "url": item["url"],
                        "content_type": "",
                        "is_audio": item.get("is_audio", False),
                        "size": 0,
                    })

            return {
                "media_urls": captured_urls,
                "title": metadata.get("title", ""),
                "author": metadata.get("author", ""),
                "cover_url": metadata.get("cover_url", ""),
            }

        finally:
            await page.close()
            await context.close()

    async def close(self):
        if self._browser:
            await self._browser.close()
        if self._playwright:
            await self._playwright.stop()

    def select_best_media(self, media_urls: list[dict]) -> Optional[dict]:
        """从捕获的媒体列表中选择最佳音频源"""
        # 优先选纯音频
        audio_only = [m for m in media_urls if m.get("is_audio")]
        if audio_only:
            audio_only.sort(key=lambda x: x.get("size", 0), reverse=True)
            return audio_only[0]

        # 其次选最大的视频文件（通常质量最好）
        if media_urls:
            media_urls.sort(key=lambda x: x.get("size", 0), reverse=True)
            return media_urls[0]

        return None
