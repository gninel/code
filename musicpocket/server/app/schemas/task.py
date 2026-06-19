from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class ConvertRequest(BaseModel):
    url: str = Field(..., description="视频分享链接或包含链接的文本")
    audio_format: str = Field(default="mp3", pattern="^(mp3|m4a|aac|opus)$")
    audio_bitrate: str = Field(default="192k", pattern="^(128k|192k|320k)$")


class ConvertResponse(BaseModel):
    task_id: str
    status: str
    message: str


class TaskStatusResponse(BaseModel):
    task_id: str
    status: str
    progress: int
    title: Optional[str] = None
    author: Optional[str] = None
    cover_url: Optional[str] = None
    duration_seconds: Optional[int] = None
    audio_format: Optional[str] = None
    download_url: Optional[str] = None
    file_size: Optional[int] = None
    error_message: Optional[str] = None
    expires_at: Optional[datetime] = None


class ParsedVideoInfo(BaseModel):
    platform: str
    video_id: str
    title: str
    author: str
    cover_url: Optional[str] = None
    duration_seconds: Optional[int] = None
    media_url: str
    is_audio_only: bool = False
    headers: dict = Field(default_factory=dict)
