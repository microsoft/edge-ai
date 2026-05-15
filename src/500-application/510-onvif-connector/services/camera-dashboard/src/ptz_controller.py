"""ONVIF PTZ camera controller.

Manages ONVIF PTZ service connections per camera with lazy initialization.
Continuous moves are automatically stopped after a short delay to prevent
runaway camera motion.
"""
import asyncio
import logging
import os

from onvif import ONVIFCamera

logger = logging.getLogger(__name__)

_WSDL_DIR = os.path.join(os.path.dirname(os.path.abspath(__import__("onvif").__file__)), "wsdl")


class PTZController:
    """Executes ONVIF PTZ operations on registered cameras."""

    def __init__(self):
        self._cameras = {}
        self._stop_tasks = {}

    def register(self, camera_id, host, username, password, port=80):
        """Register ONVIF credentials for a camera. Connection is deferred."""
        self._cameras[camera_id] = {
            "host": host,
            "port": port,
            "username": username,
            "password": password,
            "ptz_service": None,
            "profile_token": None,
        }

    def has_ptz(self, camera_id):
        """Return True if the camera has registered ONVIF PTZ credentials."""
        return camera_id in self._cameras

    async def _ensure_connected(self, camera_id):
        """Lazily initialize the ONVIF PTZ service connection for a camera."""
        entry = self._cameras.get(camera_id)
        if not entry:
            return None
        if entry["ptz_service"]:
            return entry
        try:
            cam = ONVIFCamera(
                entry["host"], entry["port"],
                entry["username"], entry["password"],
                wsdl_dir=_WSDL_DIR,
            )
            await cam.update_xaddrs()
            ptz = await cam.create_ptz_service()
            media = await cam.create_media_service()
            profiles = await media.GetProfiles()
            if not profiles:
                logger.warning("No media profiles for camera %s", camera_id)
                return None
            entry["ptz_service"] = ptz
            entry["profile_token"] = profiles[0].token
            return entry
        except Exception:
            logger.exception("ONVIF PTZ connection failed for %s", camera_id)
            entry["ptz_service"] = None
            entry["profile_token"] = None
            return None

    async def pan(self, camera_id, direction, speed=0.5):
        """Start continuous horizontal pan. Auto-stops after 0.5s."""
        entry = await self._ensure_connected(camera_id)
        if not entry:
            return False
        x = speed if direction == "right" else -speed
        await entry["ptz_service"].ContinuousMove({
            "ProfileToken": entry["profile_token"],
            "Velocity": {"PanTilt": {"x": x, "y": 0}},
        })
        self._schedule_stop(camera_id)
        return True

    async def tilt(self, camera_id, direction, speed=0.5):
        """Start continuous vertical tilt. Auto-stops after 0.5s."""
        entry = await self._ensure_connected(camera_id)
        if not entry:
            return False
        y = speed if direction == "up" else -speed
        await entry["ptz_service"].ContinuousMove({
            "ProfileToken": entry["profile_token"],
            "Velocity": {"PanTilt": {"x": 0, "y": y}},
        })
        self._schedule_stop(camera_id)
        return True

    async def zoom(self, camera_id, direction, speed=0.3):
        """Start continuous zoom in/out. Auto-stops after 0.5s."""
        entry = await self._ensure_connected(camera_id)
        if not entry:
            return False
        z = speed if direction == "in" else -speed
        await entry["ptz_service"].ContinuousMove({
            "ProfileToken": entry["profile_token"],
            "Velocity": {"Zoom": {"x": z}},
        })
        self._schedule_stop(camera_id)
        return True

    async def home(self, camera_id):
        """Move camera to its preset home position."""
        entry = await self._ensure_connected(camera_id)
        if not entry:
            return False
        await entry["ptz_service"].GotoHomePosition({
            "ProfileToken": entry["profile_token"],
        })
        return True

    async def stop(self, camera_id):
        """Immediately stop all pan, tilt, and zoom movement."""
        entry = self._cameras.get(camera_id)
        if not entry or not entry["ptz_service"]:
            return False
        await entry["ptz_service"].Stop({
            "ProfileToken": entry["profile_token"],
            "PanTilt": True,
            "Zoom": True,
        })
        return True

    def _schedule_stop(self, camera_id, delay=0.5):
        """Schedule an auto-stop task, cancelling any existing one for this camera."""
        existing = self._stop_tasks.get(camera_id)
        if existing and not existing.done():
            existing.cancel()
        loop = asyncio.get_event_loop()
        self._stop_tasks[camera_id] = loop.create_task(
            self._delayed_stop(camera_id, delay)
        )

    async def _delayed_stop(self, camera_id, delay):
        await asyncio.sleep(delay)
        await self.stop(camera_id)
