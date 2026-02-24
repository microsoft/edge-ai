"""Application entry point for the ONVIF Camera Simulator service.

Orchestrates CameraManager, RTSPManager, ONVIFService, WebAPI, and WebUI
into a single aiohttp application with lifecycle management.
"""

from __future__ import annotations

import asyncio
import logging
import os
import socket

from aiohttp import web

from src.camera_manager import CameraManager
from src.onvif_service import ONVIFService
from src.rtsp_manager import RTSPManager
from src.web_api import WebAPI
from src.web_ui import WebUI

logger = logging.getLogger(__name__)


async def capture_snapshot(
    request: web.Request,
    camera_manager: CameraManager,
    rtsp_port: int,
) -> web.Response:
    """Capture a single JPEG frame from a camera's RTSP stream via FFmpeg."""
    camera_id = request.match_info["camera_id"]
    camera = camera_manager.get_camera(camera_id)
    if camera is None:
        return web.json_response({"error": "Camera not found"}, status=404)

    rtsp_url = f"rtsp://127.0.0.1:{rtsp_port}/{camera_id}"
    cmd = [
        "ffmpeg", "-y",
        "-rtsp_transport", "tcp",
        "-i", rtsp_url,
        "-frames:v", "1",
        "-f", "image2pipe",
        "-vcodec", "mjpeg",
        "pipe:1",
    ]

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=10)
        if proc.returncode != 0 or not stdout:
            return web.json_response({"error": "Snapshot capture failed"}, status=500)
        return web.Response(body=stdout, content_type="image/jpeg")
    except asyncio.TimeoutError:
        return web.json_response({"error": "Snapshot capture timed out"}, status=504)
    except Exception:
        logger.exception("Snapshot capture error for camera %s", camera_id)
        return web.json_response({"error": "Snapshot capture error"}, status=500)


def create_app() -> web.Application:
    """Build and configure the aiohttp application."""
    onvif_port = int(os.getenv("ONVIF_PORT", "8080"))
    rtsp_port = int(os.getenv("MEDIAMTX_RTSP_PORT", "8554"))
    webrtc_port = int(os.getenv("MEDIAMTX_WEBRTC_PORT", "8889"))
    mediamtx_binary = os.getenv("MEDIAMTX_BINARY", "/usr/local/bin/mediamtx")
    mediamtx_config = os.getenv("MEDIAMTX_CONFIG", "/app/mediamtx.yml")
    media_dir = os.getenv("MEDIA_DIR", "/data")
    upload_dir = os.getenv("UPLOAD_DIR", "/app/uploads")
    static_dir = os.getenv("STATIC_DIR", "/app/static")
    device_hostname = os.getenv("DEVICE_HOSTNAME", socket.gethostname())
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    camera_manager = CameraManager()
    rtsp_manager = RTSPManager(mediamtx_config, mediamtx_binary, rtsp_port)
    onvif_service = ONVIFService(
        camera_manager, device_hostname, onvif_port, rtsp_port)
    web_api = WebAPI(
        camera_manager, rtsp_manager, media_dir,
        device_hostname, rtsp_port, onvif_port,
        webrtc_port, upload_dir)
    web_ui = WebUI(static_dir)

    app = web.Application()

    onvif_service.setup_routes(app)
    web_api.setup_routes(app)
    web_ui.setup_routes(app)

    app.router.add_get(
        "/health", lambda req: _health_handler(req, camera_manager, rtsp_manager))
    app.router.add_get(
        "/snapshot/{camera_id}",
        lambda req: capture_snapshot(req, camera_manager, rtsp_port),
    )

    monitor_task_holder: dict[str, asyncio.Task] = {}

    async def on_startup(_app: web.Application) -> None:
        logger.info("Starting MediaMTX server")
        await rtsp_manager.start_mediamtx()
        await asyncio.sleep(2)

        logger.info("Loading cameras from environment")
        camera_manager.load_from_env()

        for camera in camera_manager.get_all_cameras():
            camera_manager.update_status(camera.id, "starting")
            await rtsp_manager.start_stream(camera)
            process = rtsp_manager._ffmpeg_processes.get(camera.id)
            pid = process.pid if process else None
            camera_manager.update_status(camera.id, "streaming", pid)
            logger.info("Camera %s streaming (PID %s)", camera.id, pid)

        task = asyncio.create_task(
            rtsp_manager.monitor_streams(camera_manager))
        monitor_task_holder["monitor"] = task
        logger.info("Stream monitor started")

    async def on_cleanup(_app: web.Application) -> None:
        logger.info("Shutting down")
        task = monitor_task_holder.get("monitor")
        if task:
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass

        for camera in camera_manager.get_all_cameras():
            await rtsp_manager.stop_stream(camera.id)

        await rtsp_manager.stop_mediamtx()
        logger.info("Shutdown complete")

    app.on_startup.append(on_startup)
    app.on_cleanup.append(on_cleanup)

    return app


async def _health_handler(
    _request: web.Request,
    camera_manager: CameraManager,
    rtsp_manager: RTSPManager,
) -> web.Response:
    """Return service health status."""
    mediamtx_running = (
        rtsp_manager._mediamtx_process is not None
        and rtsp_manager._mediamtx_process.returncode is None
    )
    return web.json_response({
        "status": "healthy" if mediamtx_running else "degraded",
        "camera_count": len(camera_manager.get_all_cameras()),
        "mediamtx_status": "running" if mediamtx_running else "stopped",
    })


if __name__ == "__main__":
    web.run_app(create_app(), port=int(os.getenv("ONVIF_PORT", "8080")))
