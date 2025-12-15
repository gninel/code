from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, Integer, Boolean, Float, ForeignKey
from sqlalchemy.orm import relationship

from ..database import Base


class VoiceRecord(Base):
    """语音记录模型"""
    __tablename__ = "voice_records"

    id = Column(String(36), primary_key=True, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, default="")
    transcription = Column(Text, nullable=True)
    duration = Column(Integer, default=0)  # 时长(毫秒)
    audio_url = Column(String(500), nullable=True)  # OSS音频URL
    is_processed = Column(Boolean, default=False)
    confidence = Column(Float, nullable=True)
    note = Column(Text, nullable=True)
    is_included_in_bio = Column(Boolean, default=False)
    tags = Column(Text, default="[]")  # JSON字符串
    timestamp = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    user = relationship("User", back_populates="voice_records")
