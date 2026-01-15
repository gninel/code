from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text
from sqlalchemy.orm import relationship

from ..database import Base


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=True)  # 改为可选
    phone = Column(String(20), unique=True, index=True, nullable=True)  # 新增手机号字段
    password_hash = Column(String(255), nullable=True)  # 改为可选（手机号登录可能不需要密码）
    nickname = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    voice_records = relationship("VoiceRecord", back_populates="user")
    autobiographies = relationship("Autobiography", back_populates="user")
