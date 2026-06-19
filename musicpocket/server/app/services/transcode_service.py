import asyncio
import subprocess
from pathlib import Path
import structlog
from ..config import get_settings

logger = structlog.get_logger()

SUPPORTED_FORMATS = {
    "mp3": {"codec": "libmp3lame", "ext": "mp3"},
    "m4a": {"codec": "aac", "ext": "m4a"},
    "aac": {"codec": "aac", "ext": "aac"},
    "opus": {"codec": "libopus", "ext": "opus"},
}


class TranscodeService:
    """
    使用 FFmpeg 将视频/音频文件转码为目标音频格式。

    支持：
    - 视频转音频（去视频流）
    - 音频格式转换
    - 比特率调整
    - 音量标准化
    """

    def __init__(self):
        self.settings = get_settings()

    async def transcode(
        self,
        input_path: Path,
        task_id: str,
        audio_format: str = "mp3",
        bitrate: str = "192k",
        normalize: bool = True,
    ) -> Path:
        fmt = SUPPORTED_FORMATS.get(audio_format)
        if not fmt:
            raise ValueError(f"不支持的音频格式: {audio_format}")

        output_path = input_path.parent / f"{task_id}.{fmt['ext']}"

        cmd = [
            self.settings.ffmpeg_path,
            "-i", str(input_path),
            "-vn",  # 去掉视频流
            "-c:a", fmt["codec"],
            "-b:a", bitrate,
        ]

        if normalize:
            cmd.extend(["-af", "loudnorm=I=-16:TP=-1.5:LRA=11"])

        cmd.extend([
            "-y",
            str(output_path),
        ])

        logger.info("transcode_start", task_id=task_id, format=audio_format, bitrate=bitrate)

        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await proc.communicate()

        if proc.returncode != 0:
            error_msg = stderr.decode("utf-8", errors="replace")[-500:]
            raise RuntimeError(f"FFmpeg 转码失败: {error_msg}")

        file_size = output_path.stat().st_size
        logger.info("transcode_complete", task_id=task_id, size_mb=round(file_size / 1024 / 1024, 2))
        return output_path

    async def get_duration(self, file_path: Path) -> int:
        """获取音频时长（秒）"""
        cmd = [
            self.settings.ffmpeg_path.replace("ffmpeg", "ffprobe"),
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            str(file_path),
        ]
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        try:
            return int(float(stdout.decode().strip()))
        except (ValueError, AttributeError):
            return 0
