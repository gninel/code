from abc import ABC, abstractmethod
from typing import Optional
import re
import httpx
import structlog
from ..schemas.task import ParsedVideoInfo

logger = structlog.get_logger()


class BaseParser(ABC):
    """
    平台解析器基类。
    每个平台实现一个子类，注册到 ParserRegistry。
    当平台接口变化时，只需修改对应解析器，无需更新客户端。
    """

    @property
    @abstractmethod
    def platform_name(self) -> str:
        """平台标识，如 'douyin', 'tiktok'"""
        ...

    @property
    @abstractmethod
    def url_patterns(self) -> list[re.Pattern]:
        """匹配该平台的 URL 正则列表"""
        ...

    def matches(self, url: str) -> bool:
        return any(p.search(url) for p in self.url_patterns)

    async def resolve_short_url(self, url: str) -> str:
        """跟随短链接重定向，获取最终 URL"""
        async with httpx.AsyncClient(follow_redirects=True, timeout=15) as client:
            resp = await client.head(url, headers=self._common_headers())
            return str(resp.url)

    @abstractmethod
    async def parse(self, url: str) -> ParsedVideoInfo:
        """解析视频页面，返回媒体信息和下载地址"""
        ...

    @abstractmethod
    def extract_video_id(self, url: str) -> Optional[str]:
        """从 URL 中提取视频/作品 ID"""
        ...

    def _common_headers(self) -> dict:
        return {
            "User-Agent": (
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                "AppleWebKit/605.1.15 (KHTML, like Gecko) "
                "Version/17.0 Mobile/15E148 Safari/604.1"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        }
