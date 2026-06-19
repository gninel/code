import asyncio
from pathlib import Path
from fastapi import APIRouter, BackgroundTasks, HTTPException
from fastapi.responses import FileResponse
from ..schemas.task import ConvertRequest, ConvertResponse, TaskStatusResponse
from ..services.link_service import LinkService
from ..services.task_service import get_task_manager

router = APIRouter(prefix="/api/v1", tags=["convert"])
link_service = LinkService()


@router.post("/convert", response_model=ConvertResponse)
async def create_convert_task(req: ConvertRequest, bg: BackgroundTasks):
    """
    创建转换任务。

    客户端粘贴链接后调用此接口，服务端异步处理：
    1. 识别平台和提取链接
    2. 后台启动 解析→下载→转码 流程
    3. 返回 task_id，客户端轮询状态
    """
    detection = link_service.detect(req.url)

    if not detection.get("supported"):
        raise HTTPException(status_code=400, detail=detection.get("error", "不支持的链接"))

    manager = get_task_manager()
    task_id = manager.create_task(
        url=detection["url"],
        platform=detection["platform"],
        audio_format=req.audio_format,
        bitrate=req.audio_bitrate,
    )

    bg.add_task(manager.process_task, task_id)

    return ConvertResponse(
        task_id=task_id,
        status="pending",
        message=f"已识别为 {detection['platform']} 链接，开始处理",
    )


@router.get("/tasks/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    """查询任务状态和进度（客户端轮询）"""
    manager = get_task_manager()
    task = manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")

    return TaskStatusResponse(
        task_id=task["task_id"],
        status=task["status"],
        progress=task["progress"],
        title=task.get("title"),
        author=task.get("author"),
        cover_url=task.get("cover_url"),
        duration_seconds=task.get("duration_seconds"),
        audio_format=task.get("audio_format"),
        download_url=task.get("download_url"),
        file_size=task.get("file_size"),
        error_message=task.get("error_message"),
        expires_at=task.get("expires_at"),
    )


@router.get("/tasks/{task_id}/download")
async def download_audio(task_id: str):
    """
    下载转换完成的音频文件。

    文件在服务器仅保留数小时，过期自动清理。
    客户端应在转换完成后立即下载到本地。
    """
    manager = get_task_manager()
    task = manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")
    if task["status"] != "completed":
        raise HTTPException(status_code=400, detail=f"任务未完成，当前状态: {task['status']}")

    file_path = Path(task.get("_output_path", ""))
    if not file_path.exists():
        raise HTTPException(status_code=410, detail="文件已过期或已被清理")

    filename = f"{task.get('title', task_id)}.{task.get('audio_format', 'mp3')}"
    return FileResponse(
        path=file_path,
        filename=filename,
        media_type="application/octet-stream",
    )


@router.post("/detect")
async def detect_link(req: ConvertRequest):
    """仅检测链接是否支持，不创建任务（用于客户端实时预览）"""
    return link_service.detect(req.url)
