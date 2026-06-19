import time
from collections import defaultdict
from fastapi import HTTPException, Request
from starlette.middleware.base import BaseHTTPMiddleware


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    简单的内存限流中间件。
    生产环境应替换为 Redis 滑动窗口限流。

    规则：
    - 匿名用户：每分钟 5 次请求
    - 设备认证用户：每分钟 30 次
    - 仅对 /api/v1/convert 接口限流
    """

    def __init__(self, app, requests_per_minute: int = 30):
        super().__init__(app)
        self.rpm = requests_per_minute
        self._window: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        if not request.url.path.startswith("/api/v1/convert"):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        auth_header = request.headers.get("authorization", "")
        key = auth_header[:20] if auth_header else client_ip

        now = time.time()
        window = self._window[key]
        # 清理过期记录
        window[:] = [t for t in window if now - t < 60]

        limit = self.rpm if auth_header else 5
        if len(window) >= limit:
            raise HTTPException(
                status_code=429,
                detail=f"请求过于频繁，每分钟最多 {limit} 次",
            )

        window.append(now)
        return await call_next(request)
