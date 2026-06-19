"""
平台解析器单元测试。
测试 URL 匹配、视频 ID 提取、短链接解析等不依赖外部服务的逻辑。
"""
import pytest
from app.parsers.registry import ParserRegistry
from app.parsers.douyin import DouyinParser
from app.parsers.tiktok import TikTokParser
from app.parsers.bilibili import BilibiliParser
from app.parsers.xiaohongshu import XiaohongshuParser


@pytest.fixture
def registry():
    r = ParserRegistry()
    r.register(DouyinParser())
    r.register(TikTokParser())
    r.register(BilibiliParser())
    r.register(XiaohongshuParser())
    return r


class TestURLExtraction:
    def test_extract_url_from_plain(self, registry):
        assert registry.extract_url("https://v.douyin.com/abc123/") == "https://v.douyin.com/abc123/"

    def test_extract_url_from_share_text(self, registry):
        text = '3.28 复制打开抖音，看看【某某的作品】 https://v.douyin.com/iRNBho5e/ 复制此链接'
        url = registry.extract_url(text)
        assert url == "https://v.douyin.com/iRNBho5e/"

    def test_extract_url_from_bilibili(self, registry):
        text = "【标题】 https://b23.tv/BV1xx411c7mD 来看看"
        url = registry.extract_url(text)
        assert url is not None
        assert "b23.tv" in url

    def test_no_url(self, registry):
        assert registry.extract_url("没有链接的普通文字") is None


class TestDouyinParser:
    def test_match_short_url(self):
        p = DouyinParser()
        assert p.matches("https://v.douyin.com/iRNBho5e/")

    def test_match_full_url(self):
        p = DouyinParser()
        assert p.matches("https://www.douyin.com/video/7234567890123456789")

    def test_match_note_url(self):
        p = DouyinParser()
        assert p.matches("https://www.douyin.com/note/7234567890123456789")

    def test_extract_video_id(self):
        p = DouyinParser()
        assert p.extract_video_id("https://www.douyin.com/video/7234567890123456789") == "7234567890123456789"

    def test_extract_note_id(self):
        p = DouyinParser()
        assert p.extract_video_id("https://www.douyin.com/note/7234567890123456789") == "7234567890123456789"

    def test_no_match(self):
        p = DouyinParser()
        assert not p.matches("https://www.youtube.com/watch?v=xxx")


class TestTikTokParser:
    def test_match_vm(self):
        p = TikTokParser()
        assert p.matches("https://vm.tiktok.com/ZMrUxyz/")

    def test_match_full(self):
        p = TikTokParser()
        assert p.matches("https://www.tiktok.com/@user/video/7234567890123456789")

    def test_match_vt(self):
        p = TikTokParser()
        assert p.matches("https://vt.tiktok.com/ZSrABC/")

    def test_extract_id(self):
        p = TikTokParser()
        vid = p.extract_video_id("https://www.tiktok.com/@user/video/7234567890123456789")
        assert vid == "7234567890123456789"


class TestBilibiliParser:
    def test_match_bv(self):
        p = BilibiliParser()
        assert p.matches("https://www.bilibili.com/video/BV1xx411c7mD")

    def test_match_av(self):
        p = BilibiliParser()
        assert p.matches("https://www.bilibili.com/video/av12345678")

    def test_match_short(self):
        p = BilibiliParser()
        assert p.matches("https://b23.tv/BV1xx411c7mD")

    def test_extract_bvid(self):
        p = BilibiliParser()
        assert p.extract_video_id("https://www.bilibili.com/video/BV1xx411c7mD") == "BV1xx411c7mD"

    def test_extract_avid(self):
        p = BilibiliParser()
        assert p.extract_video_id("https://www.bilibili.com/video/av12345678") == "av12345678"


class TestXiaohongshuParser:
    def test_match_explore(self):
        p = XiaohongshuParser()
        assert p.matches("https://www.xiaohongshu.com/explore/6567890abcdef")

    def test_match_short(self):
        p = XiaohongshuParser()
        assert p.matches("https://xhslink.com/abc123")

    def test_extract_id(self):
        p = XiaohongshuParser()
        assert p.extract_video_id("https://www.xiaohongshu.com/explore/6567890abcdef") == "6567890abcdef"

    def test_no_match_other(self):
        p = XiaohongshuParser()
        assert not p.matches("https://weibo.com/12345")


class TestRegistryRouting:
    def test_routes_to_correct_parser(self, registry):
        assert registry.find_parser("https://v.douyin.com/abc/").platform_name == "douyin"
        assert registry.find_parser("https://vm.tiktok.com/abc/").platform_name == "tiktok"
        assert registry.find_parser("https://www.bilibili.com/video/BV1xx411c7mD").platform_name == "bilibili"
        assert registry.find_parser("https://xhslink.com/abc").platform_name == "xiaohongshu"

    def test_unsupported_url(self, registry):
        assert registry.find_parser("https://www.youtube.com/watch?v=xxx") is None

    def test_supported_platforms(self, registry):
        platforms = registry.supported_platforms
        assert "douyin" in platforms
        assert "tiktok" in platforms
        assert "bilibili" in platforms
        assert "xiaohongshu" in platforms
