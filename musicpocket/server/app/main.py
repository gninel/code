import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import get_settings
from .routers.convert import router as convert_router
from .routers.auth import router as auth_router
from .parsers.registry import get_registry
from .parsers.douyin import DouyinParser
from .parsers.tiktok import TikTokParser
from .parsers.bilibili import BilibiliParser
from .parsers.xiaohongshu import XiaohongshuParser
from .middleware.rate_limit import RateLimitMiddleware
from .services.cleanup_service import CleanupService
from .services.cookie_manager import CookieManager


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动：初始化后台清理任务
    cleanup = CleanupService()
    cleanup_task = asyncio.create_task(cleanup.start())

    # 初始化 Cookie 管理器
    app.state.cookie_manager = CookieManager()

    yield

    # 关闭：取消后台任务
    cleanup_task.cancel()
    try:
        await cleanup_task
    except asyncio.CancelledError:
        pass


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        docs_url="/docs" if settings.debug else None,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(RateLimitMiddleware, requests_per_minute=30)

    # 注册平台解析器（插件式）
    registry = get_registry()
    registry.register(DouyinParser())
    registry.register(TikTokParser())
    registry.register(BilibiliParser())
    registry.register(XiaohongshuParser())

    app.include_router(auth_router)
    app.include_router(convert_router)

    @app.get("/health")
    async def health():
        return {
            "status": "ok",
            "supported_platforms": registry.supported_platforms,
        }

    return app


app = create_app()
