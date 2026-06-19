from datetime import datetime, timedelta
from jose import jwt, JWTError
from fastapi import HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import uuid
from ..config import get_settings

security = HTTPBearer(auto_error=False)


def create_device_token(device_id: str) -> str:
    """
    基于设备 ID 生成 JWT。
    MusicPocket 采用匿名设备认证，不需要用户注册。
    首次使用自动生成设备 ID 和 token。
    """
    settings = get_settings()
    payload = {
        "sub": device_id,
        "type": "device",
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(minutes=settings.jwt_expire_minutes),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def verify_token(token: str) -> dict:
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="无效的认证令牌")


async def get_current_device(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    """
    提取当前设备 ID。
    如果没有 token，返回匿名标识（用于免费额度）。
    """
    if credentials is None:
        return f"anon-{uuid.uuid4().hex[:8]}"
    payload = verify_token(credentials.credentials)
    return payload.get("sub", "unknown")
