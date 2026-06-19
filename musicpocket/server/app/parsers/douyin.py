import re
import json
from typing import Optional
import httpx
import structlog
from .base import BaseParser
from ..schemas.task import ParsedVideoInfo

logger = structlog.get_logger()


class DouyinParser(BaseParser):
    """
    抖音解析器。

    难点：
    - 短链接需要跟随重定向
    - 接口有签名校验（X-Bogus / a_bogus），需要动态生成
    - Cookie 和设备指纹校验
    - 频繁更新反爬策略

    当前采用网页解析方案，后续可切换到 Playwright 模拟方案。
    """

    @property
    def platform_name(self) -> str:
        return "douyin"

    @property
    def url_patterns(self) -> list[re.Pattern]:
        return [
            re.compile(r'v\.douyin\.com/\w+', re.IGNORECASE),
            re.compile(r'www\.douyin\.com/video/(\d+)', re.IGNORECASE),
            re.compile(r'www\.douyin\.com/note/(\d+)', re.IGNORECASE),
        ]

    def extract_video_id(self, url: str) -> Optional[str]:
        match = re.search(r'/video/(\d+)', url)
        if match:
            return match.group(1)
        match = re.search(r'/note/(\d+)', url)
        if match:
            return match.group(1)
        return None

    async def parse(self, url: str) -> ParsedVideoInfo:
        resolved = await self.resolve_short_url(url) if "v.douyin.com" in url else url
        video_id = self.extract_video_id(resolved)
        if not video_id:
            raise ValueError(f"无法从 URL 提取抖音视频 ID: {resolved}")

        logger.info("douyin_parsing", video_id=video_id, url=resolved)

        detail = await self._fetch_video_detail(video_id)

        video_info = detail.get("aweme_detail", {})
        desc = video_info.get("desc", "未知标题")
        author = video_info.get("author", {}).get("nickname", "未知作者")
        cover = video_info.get("video", {}).get("cover", {}).get("url_list", [None])[0]
        duration_ms = video_info.get("video", {}).get("duration", 0)

        # 优先获取音频流（抖音部分视频有独立音频）
        music = video_info.get("music", {})
        play_url = music.get("play_url", {}).get("uri", "")
        is_audio_only = bool(play_url)

        if not play_url:
            # 回退到视频流
            play_addr = video_info.get("video", {}).get("play_addr", {})
            url_list = play_addr.get("url_list", [])
            play_url = url_list[0] if url_list else ""

        if not play_url:
            raise ValueError("无法获取抖音媒体地址")

        return ParsedVideoInfo(
            platform=self.platform_name,
            video_id=video_id,
            title=desc,
            author=author,
            cover_url=cover,
            duration_seconds=duration_ms // 1000 if duration_ms else None,
            media_url=play_url,
            is_audio_only=is_audio_only,
            headers=self._download_headers(),
        )

    async def _fetch_video_detail(self, video_id: str) -> dict:
        """
        通过抖音网页接口获取视频详情。

        注意：此接口需要有效的签名参数，实际部署时需要：
        1. 维护签名算法（JS逆向或 RPC 调用）
        2. 管理 Cookie 池
        3. 处理验证码
        """
        api_url = f"https://www.douyin.com/aweme/v1/web/aweme/detail/"
        params = {
            "aweme_id": video_id,
            "aid": "6383",
            "cookie_enabled": "true",
        }
        # TODO: 生产环境需要添加 X-Bogus 签名
        headers = {
            **self._common_headers(),
            "Referer": f"https://www.douyin.com/video/{video_id}",
        }
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(api_url, params=params, headers=headers)
            resp.raise_for_status()
            return resp.json()

    def _download_headers(self) -> dict:
        return {
            **self._common_headers(),
            "Referer": "https://www.douyin.com/",
        }
