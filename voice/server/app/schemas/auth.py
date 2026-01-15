from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
import re


class UserCreate(BaseModel):
    """用户注册请求（邮箱）"""
    email: EmailStr
    password: str
    nickname: Optional[str] = None


class PhoneRegister(BaseModel):
    """手机号注册请求"""
    phone: str = Field(..., description="手机号")
    code: str = Field(..., description="验证码")
    password: Optional[str] = Field(None, description="密码（可选）")
    nickname: Optional[str] = None

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """验证手机号格式"""
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('手机号格式不正确')
        return v


class UserLogin(BaseModel):
    """用户登录请求（邮箱）"""
    email: EmailStr
    password: str


class PhoneLogin(BaseModel):
    """手机号登录请求"""
    phone: str = Field(..., description="手机号")
    code: str = Field(..., description="验证码")

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """验证手机号格式"""
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('手机号格式不正确')
        return v


class SendCodeRequest(BaseModel):
    """发送验证码请求"""
    phone: str = Field(..., description="手机号")

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v: str) -> str:
        """验证手机号格式"""
        if not re.match(r'^1[3-9]\d{9}$', v):
            raise ValueError('手机号格式不正确')
        return v


class UserResponse(BaseModel):
    """用户响应"""
    id: str
    email: Optional[str] = None
    phone: Optional[str] = None
    nickname: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    """令牌响应"""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
