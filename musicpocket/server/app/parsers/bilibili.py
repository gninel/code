import re
import json
from typing import Optional
import httpx
import structlog
from .base import BaseParser
from ..schemas.task import ParsedVideoInfo

logger = structlog.get_logger()


class BilibiliParser(BaseParser):
    """
    B站解析器。

    难点：
    - DASH 格式音视频分离（但对本产品反而有利，可直接取音频流）
    - 高清晰度/高音质需要登录和大会员
    - wbi 签名参数
    - 防盗链 Referer 校验
    """

    @property
    def platform_name(self) -> str:
        return "bilibili"

    @property
    def url_patterns(self) -> list[re.Pattern]:
        return [
            re.compile(r'b23\.tv/\w+', re.IGNORECASE),
            re.compile(r'bilibili\.com/video/(BV\w+)', re.IGNORECASE),
            re.compile(r'bilibili\.com/video/av(\d+)', re.IGNORECASE),
            re.compile(r'b23\.tv/(\w+)', re.IGNORECASE),
        ]

    def extract_video_id(self, url: str) -> Optional[str]:
        match = re.search(r'/(BV\w+)', url)
        if match:
            return match.group(1)
        match = re.search(r'/av(\d+)', url)
        if match:
            return f"av{match.group(1)}"
        return None

    async def parse(self, url: str) -> ParsedVideoInfo:
        if "b23.tv" in url:
            url = await self.resolve_short_url(url)

        video_id = self.extract_video_id(url)
        if not video_id:
            raise ValueError(f"无法从 URL 提取 B站视频 ID: {url}")

        logger.info("bilibili_parsing", video_id=video_id)

        # 获取视频信息
        info = await self._fetch_video_info(video_id)
        data = info.get("data", {})

        title = data.get("title", "未知标题")
        author = data.get("owner", {}).get("name", "未知作者")
        cover = data.get("pic", "")
        duration = data.get("duration", 0)
        cid = data.get("cid", 0) or data.get("pages", [{}])[0].get("cid", 0)

        bvid = video_id if video_id.startswith("BV") else None
        aid = data.get("aid")

        # 获取音频流地址（DASH 格式）
        audio_url = await self._fetch_audio_stream(bvid=bvid, aid=aid, cid=cid)

        return ParsedVideoInfo(
            platform=self.platform_name,
            video_id=video_id,
            title=title,
            author=author,
            cover_url=cover,
            duration_seconds=duration if duration else None,
            media_url=audio_url,
            is_audio_only=True,
            headers=self._download_headers(),
        )

    async def _fetch_video_info(self, video_id: str) -> dict:
        """通过 B站 API 获取视频基础信息"""
        api_url = "https://api.bilibili.com/x/web-interface/view"
        params = {}
        if video_id.startswith("BV"):
            params["bvid"] = video_id
        else:
            params["aid"] = video_id.replace("av", "")

        headers = {
            **self._common_headers(),
            "Referer": "https://www.bilibili.com/",
        }
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(api_url, params=params, headers=headers)
            resp.raise_for_status()
            result = resp.json()
            if result.get("code") != 0:
                raise ValueError(f"B站 API 错误: {result.get('message', '未知错误')}")
            return result

    async def _fetch_audio_stream(
        self,
        bvid: Optional[str] = None,
        aid: Optional[int] = None,
        cid: int = 0,
    ) -> str:
        """
        获取 DASH 音频流地址。
        B站视频采用 DASH 格式，音视频分离存储。
        直接获取音频流避免下载完整视频再转码。
        """
        api_url = "https://api.bilibili.com/x/player/playurl"
        params = {
            "cid": cid,
            "fnval": 16,  # DASH 格式
            "fnver": 0,
            "fourk": 1,
        }
        if bvid:
            params["bvid"] = bvid
        elif aid:
            params["avid"] = aid

        headers = {
            **self._common_headers(),
            "Referer": "https://www.bilibili.com/",
        }
        # TODO: 添加 wbi 签名
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get(api_url, params=params, headers=headers)
            resp.raise_for_status()
            result = resp.json()

        dash = result.get("data", {}).get("dash", {})
        audio_list = dash.get("audio", [])
        if not audio_list:
            raise ValueError("无法获取 B站音频流，可能需要登录或大会员")

        # 按音质排序，取最高音质
        audio_list.sort(key=lambda x: x.get("bandwidth", 0), reverse=True)
        return audio_list[0].get("baseUrl") or audio_list[0].get("base_url", "")

    def _download_headers(self) -> dict:
        return {
            **self._common_headers(),
            "Referer": "https://www.bilibili.com/",
            "Origin": "https://www.bilibili.com",
        }
