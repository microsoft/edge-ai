"""REST API for camera management and media operations."""

from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import TYPE_CHECKING

import aiohttp
from aiohttp import web

from src.patterns import AVAILABLE_PATTERNS, list_patterns

if TYPE_CHECKING:
    from src.camera_manager import CameraManager
    from src.rtsp_manager import RTSPManager

logger = logging.getLogger(__name__)

ALLOWED_MEDIA_EXTENSIONS = {".jpg", ".jpeg", ".png", ".mp4", ".avi"}

WHEP_PROXY_HEADERS = {
    "Content-Type",
    "Accept",
    "If-Match",
}


class WebAPI:
    """REST API for managing cameras and media files."""

    def __init__(
        self,
        camera_manager: CameraManager,
        rtsp_manager: RTSPManager,
        media_dir: str,
        device_hostname: str = "localhost",
        rtsp_port: int = 8554,
        onvif_port: int = 8080,
        webrtc_port: int = 8889,
        upload_dir: str = "/app/uploads",
    ) -> None:
        self.camera_manager = camera_manager
        self.rtsp_manager = rtsp_manager
        self.media_dir = Path(media_dir)
        self.upload_dir = Path(upload_dir)
        self.device_hostname = device_hostname
        self.rtsp_port = rtsp_port
        self.onvif_port = onvif_port
        self.webrtc_port = webrtc_port
        self._http_session: aiohttp.ClientSession | None = None

    def setup_routes(self, app: web.Application) -> None:
        """Register REST API routes on the application."""
        app.router.add_get("/api/cameras", self.list_cameras)
        app.router.add_get("/api/cameras/{id}", self.get_camera)
        app.router.add_post("/api/cameras", self.add_camera)
        app.router.add_put("/api/cameras/{id}", self.update_camera)
        app.router.add_put("/api/cameras/{id}/source", self.swap_source)
        app.router.add_delete("/api/cameras/{id}", self.remove_camera)
        app.router.add_get("/api/media", self.list_media)
        app.router.add_post("/api/media/upload", self.upload_media)
        app.router.add_get("/api/patterns", self.list_patterns)

        # WHEP proxy routes for WebRTC stream preview
        app.router.add_post("/api/cameras/{id}/whep", self.whep_offer)
        app.router.add_patch(
            "/api/cameras/{id}/whep/{session:.*}", self.whep_patch)
        app.router.add_delete(
            "/api/cameras/{id}/whep/{session:.*}", self.whep_delete)

        app.on_cleanup.append(self._close_http_session)

    async def list_patterns(self, _request: web.Request) -> web.Response:
        """Return the list of available test patterns."""
        return web.json_response(list_patterns())

    async def list_cameras(self, _request: web.Request) -> web.Response:
        """Return JSON array of all registered cameras."""
        cameras = self.camera_manager.get_all_cameras()
        return web.json_response([
            self.camera_manager.to_dict(
                c, self.device_hostname, self.rtsp_port, self.onvif_port)
            for c in cameras
        ])

    async def get_camera(self, request: web.Request) -> web.Response:
        """Return a single camera by ID."""
        camera_id = request.match_info["id"]
        camera = self.camera_manager.get_camera(camera_id)
        if camera is None:
            return web.json_response({"error": "Camera not found"}, status=404)
        return web.json_response(self.camera_manager.to_dict(
            camera, self.device_hostname, self.rtsp_port, self.onvif_port))

    async def add_camera(self, request: web.Request) -> web.Response:
        """Add a new camera from JSON body."""
        data = await request.json()
        required = ("id", "name", "source_path", "source_type")
        missing = [f for f in required if f not in data]
        if missing:
            return web.json_response(
                {"error": f"Missing fields: {', '.join(missing)}"},
                status=400,
            )

        resolved_path = self._resolve_source_path(
            data["source_path"], data["source_type"])

        camera = self.camera_manager.add_camera(
            id=data["id"],
            name=data["name"],
            source_path=resolved_path,
            source_type=data["source_type"],
            resolution=data.get("resolution", "1920x1080"),
            framerate=data.get("framerate", 25),
        )

        self.camera_manager.update_status(camera.id, "starting")
        await self.rtsp_manager.start_stream(camera)
        process = self.rtsp_manager._ffmpeg_processes.get(camera.id)
        pid = process.pid if process else None
        self.camera_manager.update_status(camera.id, "streaming", pid)

        return web.json_response(self.camera_manager.to_dict(
            camera, self.device_hostname, self.rtsp_port, self.onvif_port), status=201)

    async def update_camera(self, request: web.Request) -> web.Response:
        """Update camera fields (name, resolution, framerate)."""
        camera_id = request.match_info["id"]
        camera = self.camera_manager.get_camera(camera_id)
        if camera is None:
            return web.json_response({"error": "Camera not found"}, status=404)

        data = await request.json()
        if "name" in data:
            camera.name = data["name"]
        if "resolution" in data:
            camera.resolution = data["resolution"]
        if "framerate" in data:
            camera.framerate = data["framerate"]

        return web.json_response(self.camera_manager.to_dict(
            camera, self.device_hostname, self.rtsp_port, self.onvif_port))

    async def swap_source(self, request: web.Request) -> web.Response:
        """Hot-swap the media source for a camera and restart its stream."""
        camera_id = request.match_info["id"]
        camera = self.camera_manager.get_camera(camera_id)
        if camera is None:
            return web.json_response({"error": "Camera not found"}, status=404)

        data = await request.json()
        source_path = data.get("source_path")
        source_type = data.get("source_type")
        if not source_path or not source_type:
            return web.json_response(
                {"error": "source_path and source_type required"},
                status=400,
            )

        resolved_path = self._resolve_source_path(source_path, source_type)
        self.camera_manager.update_source(
            camera_id, resolved_path, source_type)
        self.camera_manager.update_status(camera_id, "starting")
        await self.rtsp_manager.restart_stream(camera)
        process = self.rtsp_manager._ffmpeg_processes.get(camera_id)
        pid = process.pid if process else None
        self.camera_manager.update_status(camera_id, "streaming", pid)

        return web.json_response(self.camera_manager.to_dict(
            camera, self.device_hostname, self.rtsp_port, self.onvif_port))

    async def remove_camera(self, request: web.Request) -> web.Response:
        """Stop a camera's stream and remove it."""
        camera_id = request.match_info["id"]
        camera = self.camera_manager.get_camera(camera_id)
        if camera is None:
            return web.json_response({"error": "Camera not found"}, status=404)

        await self.rtsp_manager.stop_stream(camera_id)
        self.camera_manager.remove_camera(camera_id)
        return web.json_response({"status": "removed", "id": camera_id})

    async def list_media(self, _request: web.Request) -> web.Response:
        """Scan media_dir and upload_dir for supported media files."""
        files: list[dict] = []

        for scan_dir in (self.media_dir, self.upload_dir):
            if not scan_dir.exists():
                continue
            for entry in sorted(scan_dir.iterdir()):
                if not entry.is_file():
                    continue
                if entry.suffix.lower() not in ALLOWED_MEDIA_EXTENSIONS:
                    continue
                files.append({
                    "name": entry.name,
                    "size": entry.stat().st_size,
                    "type": entry.suffix.lstrip(".").lower(),
                })

        return web.json_response(files)

    async def upload_media(self, request: web.Request) -> web.Response:
        """Accept multipart file upload and save to upload_dir."""
        self.upload_dir.mkdir(parents=True, exist_ok=True)

        reader = await request.multipart()
        field = await reader.next()
        if field is None or field.filename is None:
            return web.json_response({"error": "No file provided"}, status=400)

        filename = Path(field.filename).name
        dest = self.upload_dir / filename

        with open(dest, "wb") as f:
            while True:
                chunk = await field.read_chunk()
                if not chunk:
                    break
                f.write(chunk)

        logger.info("Uploaded media file: %s (%d bytes)",
                    filename, dest.stat().st_size)
        return web.json_response({
            "name": filename,
            "size": dest.stat().st_size,
            "path": str(dest),
        }, status=201)

    def _resolve_source_path(self, source_path: str, source_type: str) -> str:
        """Resolve a media filename to its full filesystem path.

        For pattern sources the value is returned unchanged. For image and
        video sources the method searches media_dir then upload_dir for a
        matching file and returns the absolute path.
        """
        if source_type == "pattern":
            return source_path

        path = Path(source_path)
        if path.is_absolute() and path.exists():
            return source_path

        for directory in (self.media_dir, self.upload_dir):
            candidate = directory / path.name
            if candidate.exists():
                return str(candidate)

        return source_path

    # -- WHEP proxy methods --------------------------------------------------

    async def _get_http_session(self) -> aiohttp.ClientSession:
        """Lazily create a shared HTTP client session."""
        if self._http_session is None or self._http_session.closed:
            self._http_session = aiohttp.ClientSession()
        return self._http_session

    async def _close_http_session(self, _app: web.Application) -> None:
        """Close the shared HTTP client session on app cleanup."""
        if self._http_session and not self._http_session.closed:
            await self._http_session.close()

    def _whep_upstream_url(self, camera_id: str, suffix: str = "") -> str:
        """Build the upstream MediaMTX WHEP URL for a camera."""
        base = f"http://127.0.0.1:{self.webrtc_port}/{camera_id}/whep"
        return f"{base}/{suffix}" if suffix else base

    def _rewrite_location(self, camera_id: str, location: str) -> str:
        """Rewrite the MediaMTX Location header to the proxy path."""
        prefix = f"/{camera_id}/whep/"
        if prefix in location:
            session_id = location.split(prefix, 1)[1]
            return f"/api/cameras/{camera_id}/whep/{session_id}"
        return location

    async def whep_offer(self, request: web.Request) -> web.Response:
        """Proxy WHEP SDP offer to MediaMTX and return the SDP answer."""
        camera_id = request.match_info["id"]
        if self.camera_manager.get_camera(camera_id) is None:
            return web.json_response({"error": "Camera not found"}, status=404)

        session = await self._get_http_session()
        headers = {
            k: v for k, v in request.headers.items()
            if k in WHEP_PROXY_HEADERS
        }

        body = await request.read()
        url = self._whep_upstream_url(camera_id)

        try:
            async with session.post(url, data=body, headers=headers) as resp:
                resp_body = await resp.read()
                proxy_resp = web.Response(
                    body=resp_body,
                    status=resp.status,
                    content_type=resp.content_type or "application/sdp",
                )
                if "Location" in resp.headers:
                    proxy_resp.headers["Location"] = self._rewrite_location(
                        camera_id, resp.headers["Location"])
                if "ETag" in resp.headers:
                    proxy_resp.headers["ETag"] = resp.headers["ETag"]
                return proxy_resp
        except aiohttp.ClientError:
            logger.exception("WHEP proxy error for camera %s", camera_id)
            return web.json_response(
                {"error": "Stream not available"}, status=502)

    async def whep_patch(self, request: web.Request) -> web.Response:
        """Proxy WHEP ICE candidate trickle to MediaMTX."""
        camera_id = request.match_info["id"]
        session_suffix = request.match_info["session"]

        session = await self._get_http_session()
        headers = {
            k: v for k, v in request.headers.items()
            if k in WHEP_PROXY_HEADERS
        }

        body = await request.read()
        url = self._whep_upstream_url(camera_id, session_suffix)

        try:
            async with session.patch(url, data=body, headers=headers) as resp:
                resp_body = await resp.read()
                return web.Response(
                    body=resp_body,
                    status=resp.status,
                    content_type=resp.content_type,
                )
        except aiohttp.ClientError:
            logger.exception("WHEP PATCH proxy error for camera %s", camera_id)
            return web.json_response(
                {"error": "Proxy error"}, status=502)

    async def whep_delete(self, request: web.Request) -> web.Response:
        """Proxy WHEP session teardown to MediaMTX."""
        camera_id = request.match_info["id"]
        session_suffix = request.match_info["session"]

        session = await self._get_http_session()
        url = self._whep_upstream_url(camera_id, session_suffix)

        try:
            async with session.delete(url) as resp:
                return web.Response(status=resp.status)
        except aiohttp.ClientError:
            logger.exception(
                "WHEP DELETE proxy error for camera %s", camera_id)
            return web.json_response(
                {"error": "Proxy error"}, status=502)
