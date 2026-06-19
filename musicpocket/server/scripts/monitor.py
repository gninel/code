"""
解析器健康监控脚本。

定期用各平台的测试链接验证解析器是否正常工作。
解析失败时发送告警（stdout，生产环境接入钉钉/飞书/Slack webhook）。

用法：
    python scripts/monitor.py            # 单次检查
    python scripts/monitor.py --loop 300  # 每5分钟检查
"""
import asyncio
import sys
import time
import argparse

sys.path.insert(0, ".")

from app.parsers.registry import get_registry
from app.parsers.douyin import DouyinParser
from app.parsers.tiktok import TikTokParser
from app.parsers.bilibili import BilibiliParser
from app.parsers.xiaohongshu import XiaohongshuParser


# 各平台测试 URL（应定期更新为仍然有效的公开视频）
TEST_URLS = {
    "douyin": "https://www.douyin.com/video/7000000000000000000",
    "bilibili": "https://www.bilibili.com/video/BV1xx411c7mD",
    "tiktok": "https://www.tiktok.com/@tiktok/video/7000000000000000000",
    "xiaohongshu": "https://www.xiaohongshu.com/explore/6567890abcdef",
}


async def check_parser(parser, url: str) -> dict:
    """测试单个解析器"""
    start = time.time()
    try:
        result = await asyncio.wait_for(parser.parse(url), timeout=30)
        elapsed = time.time() - start
        return {
            "platform": parser.platform_name,
            "status": "ok",
            "title": result.title[:50] if result.title else "",
            "elapsed_seconds": round(elapsed, 2),
        }
    except asyncio.TimeoutError:
        return {
            "platform": parser.platform_name,
            "status": "timeout",
            "error": "超时（30秒）",
            "elapsed_seconds": 30,
        }
    except Exception as e:
        elapsed = time.time() - start
        return {
            "platform": parser.platform_name,
            "status": "error",
            "error": str(e)[:200],
            "elapsed_seconds": round(elapsed, 2),
        }


async def run_checks():
    registry = get_registry()
    registry.register(DouyinParser())
    registry.register(TikTokParser())
    registry.register(BilibiliParser())
    registry.register(XiaohongshuParser())

    print(f"\n{'='*60}")
    print(f"MusicPocket 解析器健康检查  {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*60}")

    results = []
    for platform, url in TEST_URLS.items():
        parser = registry.find_parser(url)
        if parser:
            result = await check_parser(parser, url)
            results.append(result)
            status_icon = "✓" if result["status"] == "ok" else "✗"
            print(f"  {status_icon} {platform:15s} {result['status']:8s} {result['elapsed_seconds']:.1f}s")
            if result.get("error"):
                print(f"    └─ {result['error'][:100]}")

    failed = [r for r in results if r["status"] != "ok"]
    print(f"\n总计: {len(results)} 个平台, {len(results) - len(failed)} 正常, {len(failed)} 异常")

    if failed:
        # 生产环境在此接入告警
        print("\n⚠ 以下平台解析异常，需要检查：")
        for r in failed:
            print(f"  - {r['platform']}: {r.get('error', r['status'])}")

    return len(failed) == 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--loop", type=int, default=0, help="循环检查间隔（秒），0 = 单次")
    args = parser.parse_args()

    if args.loop > 0:
        async def loop():
            while True:
                await run_checks()
                await asyncio.sleep(args.loop)
        asyncio.run(loop())
    else:
        ok = asyncio.run(run_checks())
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
