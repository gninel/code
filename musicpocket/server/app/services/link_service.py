import structlog
from ..parsers.registry import get_registry

logger = structlog.get_logger()


class LinkService:
    """从用户输入中识别平台和提取链接"""

    def __init__(self):
        self.registry = get_registry()

    def detect(self, text: str) -> dict:
        """
        解析用户粘贴的文本，识别平台和链接。

        用户可能粘贴的格式：
        - 纯 URL
        - "3.28 复制打开抖音，看看【某某的作品】 https://v.douyin.com/xxxx/"
        - 含 emoji 和中文的分享文本
        """
        url = self.registry.extract_url(text)
        if not url:
            return {"supported": False, "error": "未找到有效链接"}

        parser = self.registry.find_parser(url)
        if not parser:
            return {
                "supported": False,
                "url": url,
                "error": f"不支持的平台，当前支持: {', '.join(self.registry.supported_platforms)}",
            }

        return {
            "supported": True,
            "url": url,
            "platform": parser.platform_name,
            "video_id": parser.extract_video_id(url),
        }
