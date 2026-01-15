from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import init_db
from .routers import auth_router, sync_router

# 创建应用
app = FastAPI(
    title="语音自传 API",
    description="语音自传应用的后端API服务，提供用户认证和数据同步功能",
    version="1.0.0"
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境应限制为特定域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth_router)
app.include_router(sync_router)


@app.on_event("startup")
async def startup_event():
    """应用启动时初始化数据库"""
    init_db()


@app.get("/")
def read_root():
    """健康检查"""
    return {"status": "ok", "message": "语音自传API服务运行中"}


@app.get("/health")
def health_check():
    """健康检查端点"""
    return {"status": "healthy"}
