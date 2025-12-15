import json
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..models.user import User
from ..models.voice_record import VoiceRecord
from ..models.autobiography import Autobiography
from ..schemas.sync import (
    SyncUploadRequest, 
    SyncDownloadResponse, 
    SyncStatusResponse,
    VoiceRecordSync,
    AutobiographySync
)
from .auth import get_current_user

router = APIRouter(prefix="/sync", tags=["数据同步"])


@router.post("/upload", response_model=SyncStatusResponse)
def upload_data(
    data: SyncUploadRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """上传数据到云端"""
    try:
        # 处理语音记录
        for record_data in data.voice_records:
            existing = db.query(VoiceRecord).filter(
                VoiceRecord.id == record_data.id,
                VoiceRecord.user_id == current_user.id
            ).first()
            
            if existing:
                # 更新现有记录
                existing.title = record_data.title
                existing.content = record_data.content
                existing.transcription = record_data.transcription
                existing.duration = record_data.duration
                existing.audio_url = record_data.audio_url
                existing.is_processed = record_data.is_processed
                existing.confidence = record_data.confidence
                existing.note = record_data.note
                existing.is_included_in_bio = record_data.is_included_in_bio
                existing.tags = json.dumps(record_data.tags)
                existing.timestamp = record_data.timestamp
            else:
                # 创建新记录
                new_record = VoiceRecord(
                    id=record_data.id,
                    user_id=current_user.id,
                    title=record_data.title,
                    content=record_data.content,
                    transcription=record_data.transcription,
                    duration=record_data.duration,
                    audio_url=record_data.audio_url,
                    is_processed=record_data.is_processed,
                    confidence=record_data.confidence,
                    note=record_data.note,
                    is_included_in_bio=record_data.is_included_in_bio,
                    tags=json.dumps(record_data.tags),
                    timestamp=record_data.timestamp
                )
                db.add(new_record)
        
        # 处理自传
        for auto_data in data.autobiographies:
            existing = db.query(Autobiography).filter(
                Autobiography.id == auto_data.id,
                Autobiography.user_id == current_user.id
            ).first()
            
            if existing:
                # 更新现有自传
                existing.title = auto_data.title
                existing.content = auto_data.content
                existing.summary = auto_data.summary
                existing.word_count = auto_data.word_count
                existing.version = auto_data.version
                existing.status = auto_data.status
                existing.style = auto_data.style
                existing.voice_record_ids = json.dumps(auto_data.voice_record_ids)
                existing.tags = json.dumps(auto_data.tags)
                existing.chapters = json.dumps(auto_data.chapters)
                existing.generated_at = auto_data.generated_at
            else:
                # 创建新自传
                new_auto = Autobiography(
                    id=auto_data.id,
                    user_id=current_user.id,
                    title=auto_data.title,
                    content=auto_data.content,
                    summary=auto_data.summary,
                    word_count=auto_data.word_count,
                    version=auto_data.version,
                    status=auto_data.status,
                    style=auto_data.style,
                    voice_record_ids=json.dumps(auto_data.voice_record_ids),
                    tags=json.dumps(auto_data.tags),
                    chapters=json.dumps(auto_data.chapters),
                    generated_at=auto_data.generated_at
                )
                db.add(new_auto)
        
        db.commit()
        
        return SyncStatusResponse(
            success=True,
            message="数据上传成功",
            voice_records_count=len(data.voice_records),
            autobiographies_count=len(data.autobiographies),
            synced_at=datetime.utcnow()
        )
    
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"上传失败: {str(e)}"
        )


@router.get("/download", response_model=SyncDownloadResponse)
def download_data(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """从云端下载数据"""
    try:
        # 获取语音记录
        voice_records = db.query(VoiceRecord).filter(
            VoiceRecord.user_id == current_user.id
        ).all()
        
        voice_records_data = [
            VoiceRecordSync(
                id=r.id,
                title=r.title,
                content=r.content or "",
                transcription=r.transcription,
                duration=r.duration,
                audio_url=r.audio_url,
                is_processed=r.is_processed,
                confidence=r.confidence,
                note=r.note,
                is_included_in_bio=r.is_included_in_bio,
                tags=json.loads(r.tags) if r.tags else [],
                timestamp=r.timestamp
            )
            for r in voice_records
        ]
        
        # 获取自传
        autobiographies = db.query(Autobiography).filter(
            Autobiography.user_id == current_user.id
        ).all()
        
        autobiographies_data = [
            AutobiographySync(
                id=a.id,
                title=a.title,
                content=a.content,
                summary=a.summary,
                word_count=a.word_count,
                version=a.version,
                status=a.status,
                style=a.style,
                voice_record_ids=json.loads(a.voice_record_ids) if a.voice_record_ids else [],
                tags=json.loads(a.tags) if a.tags else [],
                chapters=json.loads(a.chapters) if a.chapters else [],
                generated_at=a.generated_at,
                last_modified_at=a.updated_at
            )
            for a in autobiographies
        ]
        
        return SyncDownloadResponse(
            voice_records=voice_records_data,
            autobiographies=autobiographies_data,
            synced_at=datetime.utcnow()
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"下载失败: {str(e)}"
        )
