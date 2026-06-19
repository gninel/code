import re
from typing import Optional
import httpx
import structlog
from .base import BaseParser
from ..schemas.task import ParsedVideoInfo

logger = structlog.get_logger()


class TikTokParser(BaseParser):
    """
    TikTok 国际版解析器。

    难点：
    - 地区限制，部分内容需要特定地区 IP
    - 签名参数（msToken, X-Bogus）
    - 临时下载链接有效期短
    """

    @property
    def platform_name(self) -> str:
        return "tiktok"

    @property
    def url_patterns(self) -> list[re.Pattern]:
        return [
            re.compile(r'vm\.tiktok\.com/\w+', re.IGNORECASE),
            re.compile(r'vt\.tiktok\.com/\w+', re.IGNORECASE),
            re.compile(r'www\.tiktok\.com/@[\w.]+/video/(\d+)', re.IGNORECASE),
            re.compile(r'tiktok\.com/t/\w+', re.IGNORECASE),
        ]

    def extract_video_id(self, url: str) -> Optional[str]:
        match = re.search(r'/video/(\d+)', url)
        return match.group(1) if match else None

    async def parse(self, url: str) -> ParsedVideoInfo:
        # 短链接跟随重定向
        if any(s in url for s in ["vm.tiktok.com", "vt.tiktok.com", "tiktok.com/t/"]):
            url = await self.resolve_short_url(url)

        video_id = self.extract_video_id(url)
        if not video_id:
            raise ValueError(f"无法从 URL 提取 TikTok 视频 ID: {url}")

        logger.info("tiktok_parsing", video_id=video_id)

        detail = await self._fetch_video_detail(video_id)
        item = detail.get("itemInfo", {}).get("itemStruct", {})

        desc = item.get("desc", "未知标题")
        author = item.get("author", {}).get("nickname", "未知作者")
        cover = item.get("video", {}).get("cover", "")
        duration = item.get("video", {}).get("duration", 0)

        # TikTok 音乐信息
        music = item.get("music", {})
        music_url = music.get("playUrl", "")
        is_audio_only = bool(music_url)

        if not music_url:
            download_addr = item.get("video", {}).get("downloadAddr", "")
            play_addr = item.get("video", {}).get("playAddr", "")
            music_url = download_addr or play_addr

        if not music_url:
            raise ValueError("无法获取 TikTok 媒体地址")

        return ParsedVideoInfo(
            platform=self.platform_name,
            video_id=video_id,
            title=desc,
            author=author,
            cover_url=cover,
            duration_seconds=duration if duration else None,
            media_url=music_url,
            is_audio_only=is_audio_only,
            headers=self._download_headers(),
        )

    async def _fetch_video_detail(self, video_id: str) -> dict:
        """
        通过 TikTok 网页接口获取视频详情。
        生产环境需要处理签名和地区代理。
        """
        api_url = f"https://www.tiktok.com/api/item/detail/"
        params = {"itemId": video_id}
        headers = {
            **self._common_headers(),
            "Referer": "https://www.tiktok.com/",
        }
        # TODO: 添加 msToken 和 X-Bogus 签名
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(api_url, params=params, headers=headers)
            resp.raise_for_status()
            return resp.json()

    def _download_headers(self) -> dict:
        return {
            **self._common_headers(),
            "Referer": "https://www.tiktok.com/",
        }
