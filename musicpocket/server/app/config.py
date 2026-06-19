from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    app_name: str = "MusicPocket API"
    debug: bool = False

    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/musicpocket"
    redis_url: str = "redis://localhost:6379/0"

    # 对象存储（临时文件）
    s3_endpoint: str = ""
    s3_bucket: str = "musicpocket-temp"
    s3_access_key: str = ""
    s3_secret_key: str = ""

    # 临时文件保留时间（秒）
    temp_file_ttl: int = 3600 * 6  # 6小时后自动删除

    # FFmpeg
    ffmpeg_path: str = "ffmpeg"
    default_audio_format: str = "mp3"
    default_audio_bitrate: str = "192k"

    # 解析限制
    max_concurrent_tasks: int = 20
    task_timeout: int = 300  # 5分钟
    max_file_size_mb: int = 500

    # JWT
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 30  # 30天

    # 代理池（用于解析时轮换）
    proxy_pool_url: str = ""

    model_config = {"env_file": ".env", "env_prefix": "MP_"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
