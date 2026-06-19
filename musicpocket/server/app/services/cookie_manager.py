import json
import time
from typing import Optional
import structlog

logger = structlog.get_logger()


class CookieManager:
    """
    平台 Cookie 池管理。

    部分平台（抖音、小红书）的接口需要有效 Cookie 才能访问。
    本服务管理多组 Cookie，轮换使用，自动标记失效。

    Cookie 获取方式：
    1. 手动登录后导出（开发阶段）
    2. Playwright 自动化登录获取（生产阶段）
    3. 第三方 Cookie 服务
    """

    def __init__(self):
        # platform -> [CookieEntry]
        self._pools: dict[str, list[dict]] = {}

    def add_cookies(self, platform: str, cookies: str, label: str = ""):
        """添加一组 Cookie 到池中"""
        entry = {
            "cookies": cookies,
            "label": label,
            "added_at": time.time(),
            "last_used": 0,
            "fail_count": 0,
            "is_valid": True,
        }
        if platform not in self._pools:
            self._pools[platform] = []
        self._pools[platform].append(entry)
        logger.info("cookie_added", platform=platform, label=label)

    def get_cookie(self, platform: str) -> Optional[str]:
        """获取一个可用 Cookie（最久未使用的优先）"""
        pool = self._pools.get(platform, [])
        valid = [e for e in pool if e["is_valid"]]
        if not valid:
            return None

        valid.sort(key=lambda e: e["last_used"])
        entry = valid[0]
        entry["last_used"] = time.time()
        return entry["cookies"]

    def report_failure(self, platform: str, cookies: str):
        """标记 Cookie 失效"""
        pool = self._pools.get(platform, [])
        for entry in pool:
            if entry["cookies"] == cookies:
                entry["fail_count"] += 1
                if entry["fail_count"] >= 3:
                    entry["is_valid"] = False
                    logger.warning("cookie_invalidated", platform=platform, label=entry["label"])
                break

    def get_stats(self) -> dict:
        """返回各平台 Cookie 池统计"""
        stats = {}
        for platform, pool in self._pools.items():
            valid = sum(1 for e in pool if e["is_valid"])
            stats[platform] = {"total": len(pool), "valid": valid}
        return stats

    def load_from_file(self, path: str):
        """从 JSON 文件批量加载 Cookie"""
        with open(path) as f:
            data = json.load(f)
        for platform, entries in data.items():
            for entry in entries:
                self.add_cookies(platform, entry["cookies"], entry.get("label", ""))
