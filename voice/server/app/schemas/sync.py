from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel


class VoiceRecordSync(BaseModel):
    """语音记录同步模型"""
    id: str
    title: str
    content: str
    transcription: Optional[str]
    duration: int
    audio_url: Optional[str]
    is_processed: bool
    confidence: Optional[float]
    note: Optional[str]
    is_included_in_bio: bool
    tags: List[str]
    timestamp: datetime


class AutobiographySync(BaseModel):
    """自传同步模型"""
    id: str
    title: str
    content: str
    summary: Optional[str]
    word_count: int
    version: int
    status: str
    style: Optional[str]
    voice_record_ids: List[str]
    tags: List[str]
    chapters: List[dict]
    generated_at: datetime
    last_modified_at: datetime


class SyncUploadRequest(BaseModel):
    """上传同步请求"""
    voice_records: List[VoiceRecordSync]
    autobiographies: List[AutobiographySync]


class SyncDownloadResponse(BaseModel):
    """下载同步响应"""
    voice_records: List[VoiceRecordSync]
    autobiographies: List[AutobiographySync]
    synced_at: datetime


class SyncStatusResponse(BaseModel):
    """同步状态响应"""
    success: bool
    message: str
    voice_records_count: int
    autobiographies_count: int
    synced_at: datetime
