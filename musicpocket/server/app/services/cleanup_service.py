import asyncio
import os
import time
from pathlib import Path
import tempfile
import structlog
from ..config import get_settings

logger = structlog.get_logger()


class CleanupService:
    """
    定时清理过期的临时音频文件。

    策略：
    - 转码完成的文件保留 temp_file_ttl 秒（默认 6 小时）
    - 清理周期：每 30 分钟扫描一次
    - 只清理 musicpocket 临时目录下的文件
    """

    def __init__(self):
        self.settings = get_settings()
        self.temp_dir = Path(tempfile.gettempdir()) / "musicpocket"

    async def start(self):
        """启动后台清理循环"""
        logger.info("cleanup_service_started", ttl_hours=self.settings.temp_file_ttl / 3600)
        while True:
            try:
                await self._cleanup_round()
            except Exception as e:
                logger.error("cleanup_error", error=str(e))
            await asyncio.sleep(1800)  # 30 分钟

    async def _cleanup_round(self):
        if not self.temp_dir.exists():
            return

        now = time.time()
        ttl = self.settings.temp_file_ttl
        removed = 0
        freed_bytes = 0

        for f in self.temp_dir.iterdir():
            if not f.is_file():
                continue
            age = now - f.stat().st_mtime
            if age > ttl:
                size = f.stat().st_size
                try:
                    f.unlink()
                    removed += 1
                    freed_bytes += size
                except OSError:
                    pass

        if removed > 0:
            logger.info(
                "cleanup_completed",
                removed=removed,
                freed_mb=round(freed_bytes / 1024 / 1024, 2),
            )
