import random
from typing import Optional
import httpx
import structlog
from ..config import get_settings

logger = structlog.get_logger()


class ProxyPool:
    """
    代理 IP 池管理。

    生产环境中，各平台会对高频请求 IP 进行封禁。
    需要代理池轮换 IP 来保证解析服务稳定性。

    支持两种模式：
    1. 外部代理池 API（推荐）：调用第三方代理服务获取可用IP
    2. 静态代理列表：配置文件中写死（仅用于开发测试）
    """

    def __init__(self):
        self.settings = get_settings()
        self._static_proxies: list[str] = []
        self._failed_proxies: set[str] = set()

    async def get_proxy(self, platform: str = "") -> Optional[str]:
        """获取一个可用代理"""
        if self.settings.proxy_pool_url:
            return await self._fetch_from_api(platform)

        if self._static_proxies:
            available = [p for p in self._static_proxies if p not in self._failed_proxies]
            return random.choice(available) if available else None

        return None

    async def _fetch_from_api(self, platform: str) -> Optional[str]:
        """从代理池 API 获取代理"""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                resp = await client.get(
                    self.settings.proxy_pool_url,
                    params={"platform": platform},
                )
                data = resp.json()
                proxy = data.get("proxy") or data.get("ip")
                if proxy:
                    if not proxy.startswith("http"):
                        proxy = f"http://{proxy}"
                    return proxy
        except Exception as e:
            logger.warning("proxy_pool_fetch_failed", error=str(e))
        return None

    def report_failure(self, proxy: str):
        """标记代理失败"""
        self._failed_proxies.add(proxy)
        logger.info("proxy_marked_failed", proxy=proxy)

    def add_static_proxies(self, proxies: list[str]):
        self._static_proxies.extend(proxies)
