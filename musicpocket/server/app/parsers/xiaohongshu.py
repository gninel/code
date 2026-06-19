import re
import json
from typing import Optional
import httpx
import structlog
from .base import BaseParser
from ..schemas.task import ParsedVideoInfo

logger = structlog.get_logger()


class XiaohongshuParser(BaseParser):
    """
    小红书解析器。

    难点（技术难度最高）：
    - 反爬非常强，频繁更新策略
    - 需要登录态和设备指纹校验
    - X-s / X-t 签名参数
    - 图文笔记无音频（需过滤）
    - 可能需要 Playwright 兜底
    """

    @property
    def platform_name(self) -> str:
        return "xiaohongshu"

    @property
    def url_patterns(self) -> list[re.Pattern]:
        return [
            re.compile(r'xhslink\.com/\w+', re.IGNORECASE),
            re.compile(r'xiaohongshu\.com/explore/(\w+)', re.IGNORECASE),
            re.compile(r'xiaohongshu\.com/discovery/item/(\w+)', re.IGNORECASE),
        ]

    def extract_video_id(self, url: str) -> Optional[str]:
        match = re.search(r'/explore/(\w+)', url)
        if match:
            return match.group(1)
        match = re.search(r'/item/(\w+)', url)
        if match:
            return match.group(1)
        return None

    async def parse(self, url: str) -> ParsedVideoInfo:
        if "xhslink.com" in url:
            url = await self.resolve_short_url(url)

        video_id = self.extract_video_id(url)
        if not video_id:
            raise ValueError(f"无法从 URL 提取小红书笔记 ID: {url}")

        logger.info("xiaohongshu_parsing", video_id=video_id)

        note = await self._fetch_note_detail(video_id)

        note_type = note.get("type", "")
        if note_type != "video":
            raise ValueError("该笔记不是视频类型，无法提取音频")

        title = note.get("title", "") or note.get("desc", "未知标题")
        author = note.get("user", {}).get("nickname", "未知作者")
        cover = note.get("imageList", [{}])[0].get("urlDefault", "")

        video_info = note.get("video", {})
        media = video_info.get("media", {})
        stream = media.get("stream", {})

        # 尝试获取视频流
        video_url = ""
        for quality in ["h265", "h264", "av1"]:
            streams = stream.get(quality, [])
            if streams:
                video_url = streams[0].get("masterUrl", "")
                break

        if not video_url:
            video_url = video_info.get("url", "")

        if not video_url:
            raise ValueError("无法获取小红书视频地址")

        duration_ms = video_info.get("duration", 0)

        return ParsedVideoInfo(
            platform=self.platform_name,
            video_id=video_id,
            title=title,
            author=author,
            cover_url=cover,
            duration_seconds=duration_ms // 1000 if duration_ms else None,
            media_url=video_url,
            is_audio_only=False,
            headers=self._download_headers(),
        )

    async def _fetch_note_detail(self, note_id: str) -> dict:
        """
        通过小红书网页接口获取笔记详情。

        实际部署需要：
        1. 维护 X-s / X-t 签名（JS逆向）
        2. 管理 Cookie 和登录态
        3. 设备指纹生成
        4. 可能需要 Playwright 作为兜底方案
        """
        api_url = "https://edith.xiaohongshu.com/api/sns/web/v1/feed"
        payload = {"source_note_id": note_id}
        headers = {
            **self._common_headers(),
            "Referer": "https://www.xiaohongshu.com/",
            "Origin": "https://www.xiaohongshu.com",
            "Content-Type": "application/json",
            # TODO: 添加 X-s, X-t 签名
        }
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(api_url, json=payload, headers=headers)
            resp.raise_for_status()
            result = resp.json()

        items = result.get("data", {}).get("items", [])
        if not items:
            raise ValueError("无法获取小红书笔记详情")

        return items[0].get("note_card", {})

    def _download_headers(self) -> dict:
        return {
            **self._common_headers(),
            "Referer": "https://www.xiaohongshu.com/",
        }
