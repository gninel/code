import uuid
from fastapi import APIRouter, Depends
from ..middleware.auth import create_device_token, get_current_device

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register-device")
async def register_device():
    """
    注册匿名设备，获取 JWT token。
    客户端首次启动时调用，后续请求携带此 token。
    """
    device_id = str(uuid.uuid4())
    token = create_device_token(device_id)
    return {
        "device_id": device_id,
        "token": token,
        "daily_quota": 10,
    }


@router.get("/me")
async def get_device_info(device_id: str = Depends(get_current_device)):
    """查询当前设备信息和剩余额度"""
    return {
        "device_id": device_id,
        "daily_quota": 10,
        "used_today": 0,  # TODO: 从数据库读取
    }
