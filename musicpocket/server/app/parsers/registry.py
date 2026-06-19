import re
from typing import Optional
import structlog
from .base import BaseParser

logger = structlog.get_logger()


class ParserRegistry:
    """
    解析器注册中心。
    插件式架构：启动时自动注册所有平台解析器，运行时根据 URL 匹配。
    """

    def __init__(self):
        self._parsers: list[BaseParser] = []

    def register(self, parser: BaseParser):
        self._parsers.append(parser)
        logger.info("parser_registered", platform=parser.platform_name)

    def find_parser(self, url: str) -> Optional[BaseParser]:
        """根据 URL 找到对应的平台解析器"""
        for parser in self._parsers:
            if parser.matches(url):
                return parser
        return None

    def extract_url(self, text: str) -> Optional[str]:
        """从用户粘贴的文本中提取 URL"""
        pattern = re.compile(
            r'https?://[^\s<>"\')\]]+',
            re.IGNORECASE
        )
        match = pattern.search(text)
        return match.group(0).rstrip(".,;:!?") if match else None

    @property
    def supported_platforms(self) -> list[str]:
        return [p.platform_name for p in self._parsers]


_registry = ParserRegistry()


def get_registry() -> ParserRegistry:
    return _registry
