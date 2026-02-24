"""Camera registry and state management."""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class Camera:
    """Represents a simulated ONVIF camera with streaming configuration."""

    id: str
    name: str
    source_path: str
    source_type: str
    resolution: str = "640x480"
    framerate: int = 5
    status: str = "stopped"
    ffmpeg_pid: int | None = None


class CameraManager:
    """Manages camera registration, lookup, and state transitions."""

    def __init__(self) -> None:
        self._cameras: dict[str, Camera] = {}

    def load_from_env(self) -> None:
        """Load camera definitions from environment variables.

        Reads CAMERAS (comma-separated IDs), then for each ID reads
        CAM{KEY}_NAME, CAM{KEY}_SOURCE, CAM{KEY}_TYPE, CAM{KEY}_RESOLUTION,
        CAM{KEY}_FRAMERATE where KEY is the uppercased ID with hyphens
        replaced by underscores.
        """
        cameras_raw = os.getenv("CAMERAS", "")
        if not cameras_raw.strip():
            logger.warning("No CAMERAS environment variable set")
            return

        camera_ids = [cid.strip()
                      for cid in cameras_raw.split(",") if cid.strip()]
        for cam_id in camera_ids:
            env_key = cam_id.upper().replace("-", "_")
            name = os.getenv(f"{env_key}_NAME", cam_id)
            source = os.getenv(f"{env_key}_SOURCE", "")
            source_type = os.getenv(f"{env_key}_TYPE", "jpeg")
            resolution = os.getenv(f"{env_key}_RESOLUTION", "640x480")
            framerate = int(os.getenv(f"{env_key}_FRAMERATE", "5"))

            if not source and source_type != "pattern":
                logger.warning(
                    "No source path configured for camera %s", cam_id)
                continue

            if source_type == "pattern" and not source:
                source = "testsrc"

            self.add_camera(cam_id, name, source, source_type,
                            resolution, framerate)
            logger.info("Loaded camera %s (%s) from environment", cam_id, name)

    def add_camera(
        self,
        id: str,
        name: str,
        source_path: str,
        source_type: str,
        resolution: str = "640x480",
        framerate: int = 5,
    ) -> Camera:
        """Register a new camera."""
        camera = Camera(
            id=id,
            name=name,
            source_path=source_path,
            source_type=source_type,
            resolution=resolution,
            framerate=framerate,
        )
        self._cameras[id] = camera
        logger.info("Added camera %s (%s)", id, name)
        return camera

    def remove_camera(self, id: str) -> Camera | None:
        """Remove and return a camera by ID, or None if not found."""
        camera = self._cameras.pop(id, None)
        if camera:
            logger.info("Removed camera %s", id)
        return camera

    def get_camera(self, id: str) -> Camera | None:
        """Return a camera by ID, or None if not found."""
        return self._cameras.get(id)

    def get_all_cameras(self) -> list[Camera]:
        """Return all registered cameras."""
        return list(self._cameras.values())

    def update_source(self, id: str, source_path: str, source_type: str) -> None:
        """Update the media source for a camera."""
        camera = self._cameras.get(id)
        if camera is None:
            raise KeyError(f"Camera {id} not found")
        camera.source_path = source_path
        camera.source_type = source_type
        logger.info("Updated source for camera %s: %s (%s)",
                    id, source_path, source_type)

    def update_status(self, id: str, status: str, ffmpeg_pid: int | None = None) -> None:
        """Update streaming status and optional FFmpeg PID for a camera."""
        camera = self._cameras.get(id)
        if camera is None:
            raise KeyError(f"Camera {id} not found")
        camera.status = status
        camera.ffmpeg_pid = ffmpeg_pid
        logger.debug("Camera %s status=%s pid=%s", id, status, ffmpeg_pid)

    def to_dict(
        self,
        camera: Camera,
        device_hostname: str = "",
        rtsp_port: int = 8554,
        onvif_port: int = 8080,
    ) -> dict:
        """Serialize a Camera to a JSON-compatible dict."""
        data = {
            "id": camera.id,
            "name": camera.name,
            "source_path": camera.source_path,
            "source_type": camera.source_type,
            "resolution": camera.resolution,
            "framerate": camera.framerate,
            "status": camera.status,
            "ffmpeg_pid": camera.ffmpeg_pid,
        }
        if device_hostname:
            data["rtsp_uri"] = f"rtsp://{device_hostname}:{rtsp_port}/{camera.id}"
            data["onvif_uri"] = f"http://{device_hostname}:{onvif_port}/onvif/device_service"
        return data
