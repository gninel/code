"""
服务层单元测试。
"""
import pytest
from app.services.link_service import LinkService
from app.parsers.registry import ParserRegistry, get_registry
from app.parsers.douyin import DouyinParser
from app.parsers.tiktok import TikTokParser
from app.parsers.bilibili import BilibiliParser
from app.parsers.xiaohongshu import XiaohongshuParser


@pytest.fixture(autouse=True)
def setup_registry():
    """确保注册表已初始化"""
    registry = get_registry()
    if not registry.supported_platforms:
        registry.register(DouyinParser())
        registry.register(TikTokParser())
        registry.register(BilibiliParser())
        registry.register(XiaohongshuParser())


class TestLinkService:
    def test_detect_douyin(self):
        svc = LinkService()
        result = svc.detect("https://v.douyin.com/iRNBho5e/")
        assert result["supported"] is True
        assert result["platform"] == "douyin"

    def test_detect_from_share_text(self):
        svc = LinkService()
        text = '7.89 Hci:/ 复制打开抖音，看看【用户的作品】 https://v.douyin.com/abc123/'
        result = svc.detect(text)
        assert result["supported"] is True
        assert result["platform"] == "douyin"

    def test_detect_bilibili(self):
        svc = LinkService()
        result = svc.detect("https://www.bilibili.com/video/BV1xx411c7mD")
        assert result["supported"] is True
        assert result["platform"] == "bilibili"

    def test_detect_unsupported(self):
        svc = LinkService()
        result = svc.detect("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        assert result["supported"] is False

    def test_detect_no_url(self):
        svc = LinkService()
        result = svc.detect("纯文字没有链接")
        assert result["supported"] is False

    def test_detect_tiktok(self):
        svc = LinkService()
        result = svc.detect("https://vm.tiktok.com/ZMrUxyz/")
        assert result["supported"] is True
        assert result["platform"] == "tiktok"

    def test_detect_xiaohongshu(self):
        svc = LinkService()
        result = svc.detect("https://xhslink.com/abc123")
        assert result["supported"] is True
        assert result["platform"] == "xiaohongshu"
