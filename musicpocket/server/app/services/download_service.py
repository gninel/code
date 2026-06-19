import os
import tempfile
from pathlib import Path
import httpx
import structlog
from ..config import get_settings

logger = structlog.get_logger()


class DownloadService:
    """下载媒体文件到临时目录"""

    def __init__(self):
        self.settings = get_settings()
        self.temp_dir = Path(tempfile.gettempdir()) / "musicpocket"
        self.temp_dir.mkdir(exist_ok=True)

    async def download(
        self,
        url: str,
        task_id: str,
        headers: dict | None = None,
        on_progress: callable = None,
    ) -> Path:
        """
        流式下载媒体文件，支持进度回调。
        返回临时文件路径。
        """
        output_path = self.temp_dir / f"{task_id}_raw"

        async with httpx.AsyncClient(
            timeout=httpx.Timeout(connect=15, read=120, write=30, pool=15),
            follow_redirects=True,
        ) as client:
            async with client.stream("GET", url, headers=headers or {}) as resp:
                resp.raise_for_status()

                total = int(resp.headers.get("content-length", 0))
                max_size = self.settings.max_file_size_mb * 1024 * 1024
                if total > max_size:
                    raise ValueError(f"文件过大: {total // 1024 // 1024}MB，上限 {self.settings.max_file_size_mb}MB")

                downloaded = 0
                with open(output_path, "wb") as f:
                    async for chunk in resp.aiter_bytes(chunk_size=65536):
                        f.write(chunk)
                        downloaded += len(chunk)
                        if on_progress and total:
                            progress = int(downloaded / total * 100)
                            await on_progress(progress)

        file_size = output_path.stat().st_size
        logger.info("download_complete", task_id=task_id, size_mb=round(file_size / 1024 / 1024, 2))
        return output_path

    def cleanup(self, task_id: str):
        """清理任务的临时文件"""
        for f in self.temp_dir.glob(f"{task_id}_*"):
            try:
                f.unlink()
            except OSError:
                pass
