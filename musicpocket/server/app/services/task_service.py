import uuid
import asyncio
from datetime import datetime, timedelta
import structlog
from ..config import get_settings
from ..parsers.registry import get_registry
from ..schemas.task import ParsedVideoInfo
from .download_service import DownloadService
from .transcode_service import TranscodeService

logger = structlog.get_logger()


class TaskManager:
    """
    任务管理器：协调解析、下载、转码的完整流程。

    生产环境应替换为 Celery + Redis 异步任务队列。
    当前实现使用 asyncio 用于 MVP 演示。
    """

    def __init__(self):
        self.settings = get_settings()
        self.registry = get_registry()
        self.downloader = DownloadService()
        self.transcoder = TranscodeService()
        # 内存任务存储（生产环境用数据库 + Redis）
        self._tasks: dict[str, dict] = {}

    def create_task(self, url: str, platform: str, audio_format: str, bitrate: str) -> str:
        task_id = str(uuid.uuid4())
        self._tasks[task_id] = {
            "task_id": task_id,
            "url": url,
            "platform": platform,
            "audio_format": audio_format,
            "audio_bitrate": bitrate,
            "status": "pending",
            "progress": 0,
            "title": None,
            "author": None,
            "cover_url": None,
            "duration_seconds": None,
            "download_url": None,
            "file_size": None,
            "error_message": None,
            "created_at": datetime.utcnow(),
            "expires_at": None,
        }
        return task_id

    def get_task(self, task_id: str) -> dict | None:
        return self._tasks.get(task_id)

    async def process_task(self, task_id: str):
        """
        完整处理流程：解析 → 下载 → 转码。
        每一步更新任务状态，客户端通过轮询获取进度。
        """
        task = self._tasks.get(task_id)
        if not task:
            return

        try:
            # 1. 解析
            task["status"] = "parsing"
            task["progress"] = 10

            parser = self.registry.find_parser(task["url"])
            if not parser:
                raise ValueError("不支持的平台")

            info: ParsedVideoInfo = await parser.parse(task["url"])
            task["title"] = info.title
            task["author"] = info.author
            task["cover_url"] = info.cover_url
            task["duration_seconds"] = info.duration_seconds
            task["progress"] = 30

            # 2. 下载
            task["status"] = "downloading"

            async def on_download_progress(pct):
                task["progress"] = 30 + int(pct * 0.4)  # 30-70

            raw_path = await self.downloader.download(
                url=info.media_url,
                task_id=task_id,
                headers=info.headers,
                on_progress=on_download_progress,
            )
            task["progress"] = 70

            # 3. 转码
            task["status"] = "transcoding"

            if info.is_audio_only and task["audio_format"] in ("m4a", "aac"):
                # 音频流且目标格式兼容，可能跳过转码
                output_path = raw_path
                task["progress"] = 90
            else:
                output_path = await self.transcoder.transcode(
                    input_path=raw_path,
                    task_id=task_id,
                    audio_format=task["audio_format"],
                    bitrate=task["audio_bitrate"],
                )
                task["progress"] = 90

            # 获取精确时长
            if not task["duration_seconds"]:
                task["duration_seconds"] = await self.transcoder.get_duration(output_path)

            # 4. 完成
            task["status"] = "completed"
            task["progress"] = 100
            task["file_size"] = output_path.stat().st_size
            task["download_url"] = f"/api/v1/tasks/{task_id}/download"
            task["expires_at"] = datetime.utcnow() + timedelta(seconds=self.settings.temp_file_ttl)
            task["_output_path"] = str(output_path)

            logger.info("task_completed", task_id=task_id, title=info.title)

            # 清理原始下载文件（保留转码后的）
            self.downloader.cleanup(task_id)

        except Exception as e:
            task["status"] = "failed"
            task["error_message"] = str(e)
            logger.error("task_failed", task_id=task_id, error=str(e))
            self.downloader.cleanup(task_id)


_task_manager: TaskManager | None = None


def get_task_manager() -> TaskManager:
    global _task_manager
    if _task_manager is None:
        _task_manager = TaskManager()
    return _task_manager
