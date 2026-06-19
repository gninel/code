from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import get_settings
from .routers.convert import router as convert_router
from .parsers.registry import get_registry
from .parsers.douyin import DouyinParser
from .parsers.tiktok import TikTokParser
from .parsers.bilibili import BilibiliParser
from .parsers.xiaohongshu import XiaohongshuParser


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        docs_url="/docs" if settings.debug else None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 注册平台解析器（插件式）
    registry = get_registry()
    registry.register(DouyinParser())
    registry.register(TikTokParser())
    registry.register(BilibiliParser())
    registry.register(XiaohongshuParser())

    app.include_router(convert_router)

    @app.get("/health")
    async def health():
        return {
            "status": "ok",
            "supported_platforms": registry.supported_platforms,
        }

    return app


app = create_app()
