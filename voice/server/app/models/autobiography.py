from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, Integer, ForeignKey
from sqlalchemy.orm import relationship

from ..database import Base


class Autobiography(Base):
    """自传模型"""
    __tablename__ = "autobiographies"

    id = Column(String(36), primary_key=True, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    summary = Column(Text, nullable=True)
    word_count = Column(Integer, default=0)
    version = Column(Integer, default=1)
    status = Column(String(50), default="draft")
    style = Column(String(50), nullable=True)
    voice_record_ids = Column(Text, default="[]")  # JSON字符串
    tags = Column(Text, default="[]")  # JSON字符串
    chapters = Column(Text, default="[]")  # JSON字符串
    generated_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 关系
    user = relationship("User", back_populates="autobiographies")
