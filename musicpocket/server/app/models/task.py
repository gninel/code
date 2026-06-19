import enum
from datetime import datetime
from sqlalchemy import String, Integer, Enum, DateTime, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from . import Base


class TaskStatus(str, enum.Enum):
    PENDING = "pending"
    PARSING = "parsing"
    DOWNLOADING = "downloading"
    TRANSCODING = "transcoding"
    COMPLETED = "completed"
    FAILED = "failed"


class Platform(str, enum.Enum):
    TIKTOK = "tiktok"
    DOUYIN = "douyin"
    BILIBILI = "bilibili"
    XIAOHONGSHU = "xiaohongshu"


class ConvertTask(Base):
    __tablename__ = "convert_tasks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    task_id: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True, nullable=True)

    original_url: Mapped[str] = mapped_column(Text)
    resolved_url: Mapped[str] = mapped_column(Text, nullable=True)
    platform: Mapped[Platform] = mapped_column(Enum(Platform))
    video_id: Mapped[str] = mapped_column(String(128), nullable=True)

    title: Mapped[str] = mapped_column(String(512), nullable=True)
    author: Mapped[str] = mapped_column(String(256), nullable=True)
    cover_url: Mapped[str] = mapped_column(Text, nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, nullable=True)

    status: Mapped[TaskStatus] = mapped_column(Enum(TaskStatus), default=TaskStatus.PENDING)
    error_message: Mapped[str] = mapped_column(Text, nullable=True)
    progress: Mapped[int] = mapped_column(Integer, default=0)

    audio_format: Mapped[str] = mapped_column(String(16), default="mp3")
    audio_bitrate: Mapped[str] = mapped_column(String(16), default="192k")
    audio_file_url: Mapped[str] = mapped_column(Text, nullable=True)
    audio_file_size: Mapped[int] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=True)
