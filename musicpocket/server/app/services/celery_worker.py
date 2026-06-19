"""
Celery 异步任务配置。

生产环境中用 Celery + Redis 替代 asyncio 后台任务：
- 支持任务重试和死信队列
- 水平扩展 worker 数量
- 任务超时和并发控制
- 结果持久化

启动 worker：
    celery -A app.services.celery_worker worker --loglevel=info --concurrency=4

启动调度器（定时清理）：
    celery -A app.services.celery_worker beat --loglevel=info
"""
from celery import Celery
from celery.schedules import crontab
from ..config import get_settings

settings = get_settings()

celery_app = Celery(
    "musicpocket",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Shanghai",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=settings.task_timeout,
    task_soft_time_limit=settings.task_timeout - 30,
    worker_max_tasks_per_child=100,
    worker_prefetch_multiplier=1,
    task_acks_late=True,
    task_reject_on_worker_lost=True,
)

# 定时任务
celery_app.conf.beat_schedule = {
    "cleanup-expired-files": {
        "task": "app.services.celery_worker.cleanup_expired_files",
        "schedule": crontab(minute="*/30"),
    },
}


@celery_app.task(
    bind=True,
    max_retries=2,
    default_retry_delay=30,
    acks_late=True,
)
def process_convert_task(self, task_id: str, url: str, platform: str, audio_format: str, bitrate: str):
    """
    Celery 版转换任务。
    在独立 worker 进程中执行：解析 → 下载 → 转码。
    """
    import asyncio
    from ..parsers.registry import get_registry
    from ..parsers.douyin import DouyinParser
    from ..parsers.tiktok import TikTokParser
    from ..parsers.bilibili import BilibiliParser
    from ..parsers.xiaohongshu import XiaohongshuParser
    from .download_service import DownloadService
    from .transcode_service import TranscodeService

    registry = get_registry()
    if not registry.supported_platforms:
        registry.register(DouyinParser())
        registry.register(TikTokParser())
        registry.register(BilibiliParser())
        registry.register(XiaohongshuParser())

    async def _run():
        parser = registry.find_parser(url)
        if not parser:
            raise ValueError("不支持的平台")

        self.update_state(state="PARSING", meta={"progress": 10})
        info = await parser.parse(url)

        self.update_state(state="DOWNLOADING", meta={"progress": 30, "title": info.title, "author": info.author})
        downloader = DownloadService()
        raw_path = await downloader.download(url=info.media_url, task_id=task_id, headers=info.headers)

        self.update_state(state="TRANSCODING", meta={"progress": 70})
        transcoder = TranscodeService()
        output_path = await transcoder.transcode(
            input_path=raw_path,
            task_id=task_id,
            audio_format=audio_format,
            bitrate=bitrate,
        )

        duration = await transcoder.get_duration(output_path)
        file_size = output_path.stat().st_size
        downloader.cleanup(task_id)

        return {
            "task_id": task_id,
            "status": "completed",
            "title": info.title,
            "author": info.author,
            "cover_url": info.cover_url,
            "duration_seconds": info.duration_seconds or duration,
            "file_size": file_size,
            "output_path": str(output_path),
        }

    try:
        return asyncio.run(_run())
    except Exception as exc:
        raise self.retry(exc=exc)


@celery_app.task
def cleanup_expired_files():
    """定时清理过期临时文件"""
    import asyncio
    from .cleanup_service import CleanupService
    asyncio.run(CleanupService()._cleanup_round())
