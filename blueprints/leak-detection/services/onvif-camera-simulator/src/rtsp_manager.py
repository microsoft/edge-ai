"""MediaMTX and FFmpeg process management for RTSP streaming."""

from __future__ import annotations

import asyncio
import logging
import os
import signal
from typing import TYPE_CHECKING

from src.patterns import get_pattern_filter

if TYPE_CHECKING:
    from src.camera_manager import Camera, CameraManager

logger = logging.getLogger(__name__)

_FALLBACK_PATTERN = "testsrc"


class RTSPManager:
    """Manages MediaMTX server and per-camera FFmpeg streaming processes."""

    def __init__(
        self,
        mediamtx_config: str,
        mediamtx_binary: str,
        rtsp_port: int,
    ) -> None:
        self.mediamtx_config = mediamtx_config
        self.mediamtx_binary = mediamtx_binary
        self.rtsp_port = rtsp_port
        self._mediamtx_process: asyncio.subprocess.Process | None = None
        self._ffmpeg_processes: dict[str, asyncio.subprocess.Process] = {}
        self._monitor_task: asyncio.Task | None = None

    async def start_mediamtx(self) -> None:
        """Start the MediaMTX RTSP server as an asyncio subprocess."""
        logger.info("Starting MediaMTX: %s", self.mediamtx_binary)
        self._mediamtx_process = await asyncio.create_subprocess_exec(
            self.mediamtx_binary,
            self.mediamtx_config,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        logger.info("MediaMTX started with PID %d", self._mediamtx_process.pid)

    async def stop_mediamtx(self) -> None:
        """Gracefully terminate the MediaMTX process."""
        if self._mediamtx_process is None:
            return
        logger.info("Stopping MediaMTX (PID %d)", self._mediamtx_process.pid)
        try:
            self._mediamtx_process.terminate()
            await asyncio.wait_for(self._mediamtx_process.wait(), timeout=10)
        except (ProcessLookupError, asyncio.TimeoutError):
            self._mediamtx_process.kill()
        self._mediamtx_process = None

    async def start_stream(self, camera: Camera) -> None:
        """Start an FFmpeg process pushing RTSP to MediaMTX for a camera."""
        if camera.id in self._ffmpeg_processes:
            logger.warning("Stream already running for camera %s", camera.id)
            return

        cmd = self._build_ffmpeg_cmd(camera)
        logger.info("Starting FFmpeg for camera %s: %s",
                    camera.id, " ".join(cmd))

        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.PIPE,
        )
        self._ffmpeg_processes[camera.id] = process
        logger.info("FFmpeg started for camera %s with PID %d",
                    camera.id, process.pid)

    async def stop_stream(self, camera_id: str) -> None:
        """Stop the FFmpeg process for a camera via SIGTERM."""
        process = self._ffmpeg_processes.pop(camera_id, None)
        if process is None:
            return
        logger.info("Stopping FFmpeg for camera %s (PID %d)",
                    camera_id, process.pid)
        try:
            process.terminate()
            await asyncio.wait_for(process.wait(), timeout=10)
        except (ProcessLookupError, asyncio.TimeoutError):
            process.kill()
        logger.info("FFmpeg stopped for camera %s", camera_id)

    async def restart_stream(self, camera: Camera) -> None:
        """Stop then start the stream for hot-swapping sources."""
        await self.stop_stream(camera.id)
        await self.start_stream(camera)

    async def monitor_streams(self, camera_manager: CameraManager) -> None:
        """Background task: check FFmpeg PIDs every 5s and restart crashed ones."""
        while True:
            await asyncio.sleep(5)
            for camera in camera_manager.get_all_cameras():
                if camera.status != "streaming":
                    continue

                pid = camera.ffmpeg_pid
                if pid is None:
                    continue

                try:
                    os.kill(pid, 0)
                except OSError:
                    logger.warning(
                        "FFmpeg crashed for camera %s (PID %d), restarting", camera.id, pid)
                    self._ffmpeg_processes.pop(camera.id, None)
                    camera_manager.update_status(camera.id, "starting")
                    try:
                        await self.start_stream(camera)
                        process = self._ffmpeg_processes.get(camera.id)
                        new_pid = process.pid if process else None
                        camera_manager.update_status(
                            camera.id, "streaming", new_pid)
                    except Exception:
                        logger.exception(
                            "Failed to restart stream for camera %s", camera.id)
                        camera_manager.update_status(camera.id, "error")

    def _build_ffmpeg_cmd(self, camera: Camera) -> list[str]:
        """Build the FFmpeg command based on the camera source type.

        Falls back to a test-pattern stream when the configured source
        file does not exist on disk.
        """
        w, h = camera.resolution.split("x")
        fps = str(camera.framerate)
        gop = str(camera.framerate * 2)
        rtsp_url = f"rtsp://127.0.0.1:{self.rtsp_port}/{camera.id}"

        if camera.source_type != "pattern" and not os.path.isfile(camera.source_path):
            logger.warning(
                "Source file %s not found for camera %s, falling back to test pattern",
                camera.source_path, camera.id)
            lavfi = get_pattern_filter(_FALLBACK_PATTERN, w, h, fps)
            return [
                "ffmpeg",
                "-re",
                "-f", "lavfi",
                "-i", lavfi,
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-tune", "zerolatency",
                "-pix_fmt", "yuv420p",
                "-r", fps,
                "-g", gop,
                "-f", "rtsp",
                "-rtsp_transport", "tcp",
                rtsp_url,
            ]

        if camera.source_type == "pattern":
            lavfi = get_pattern_filter(camera.source_path, w, h, fps)
            return [
                "ffmpeg",
                "-re",
                "-f", "lavfi",
                "-i", lavfi,
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-tune", "zerolatency",
                "-pix_fmt", "yuv420p",
                "-r", fps,
                "-g", gop,
                "-f", "rtsp",
                "-rtsp_transport", "tcp",
                rtsp_url,
            ]

        if camera.source_type in ("jpeg", "image"):
            return [
                "ffmpeg",
                "-re", "-loop", "1",
                "-i", camera.source_path,
                "-vf", f"scale={w}:{h}",
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-tune", "stillimage",
                "-pix_fmt", "yuv420p",
                "-r", fps,
                "-g", gop,
                "-f", "rtsp",
                "-rtsp_transport", "tcp",
                rtsp_url,
            ]

        return [
            "ffmpeg",
            "-re", "-stream_loop", "-1",
            "-i", camera.source_path,
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-tune", "zerolatency",
            "-vf", f"scale={w}:{h}",
            "-pix_fmt", "yuv420p",
            "-r", fps,
            "-g", gop,
            "-an",
            "-f", "rtsp",
            "-rtsp_transport", "tcp",
            rtsp_url,
        ]
