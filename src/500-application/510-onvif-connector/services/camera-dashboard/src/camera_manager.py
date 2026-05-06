"""RTSP camera capture and registry.

Provides background-threaded RTSP frame capture with automatic reconnection
and a CameraManager registry for managing multiple concurrent camera feeds.
"""
import threading
import time

import cv2


class RTSPCapture:
    """Background thread capturing frames from an RTSP stream with auto-reconnection."""

    def __init__(self, rtsp_url, reconnect_delay=5):
        self.url = rtsp_url
        self.frame = None
        self.running = True
        self.lock = threading.Lock()
        self.reconnect_delay = reconnect_delay
        self.thread = threading.Thread(target=self._capture_loop, daemon=True)
        self.thread.start()

    def _capture_loop(self):
        """Continuously capture frames; reconnect on stream failure."""
        while self.running:
            cap = cv2.VideoCapture(self.url)
            while self.running and cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    with self.lock:
                        self.frame = None
                    break
                with self.lock:
                    self.frame = frame
            cap.release()
            if self.running:
                with self.lock:
                    self.frame = None
                time.sleep(self.reconnect_delay)

    def read(self):
        """Return (success, frame) with a copy of the latest captured frame."""
        with self.lock:
            if self.frame is not None:
                return True, self.frame.copy()
            return False, None

    def stop(self):
        """Signal the capture thread to stop and wait for it to exit."""
        self.running = False
        self.thread.join(timeout=10)


class CameraManager:
    """Registry of cameras, each backed by an RTSPCapture thread."""

    def __init__(self):
        self._cameras = {}

    def add_camera(self, camera_id, rtsp_url):
        """Add a camera and start its RTSP capture thread. Replaces existing entry."""
        if camera_id in self._cameras:
            self.remove_camera(camera_id)
        self._cameras[camera_id] = {
            "url": rtsp_url, "capture": RTSPCapture(rtsp_url)}

    def remove_camera(self, camera_id):
        """Stop capture and remove a camera from the registry."""
        entry = self._cameras.pop(camera_id, None)
        if entry:
            entry["capture"].stop()

    def get_frame(self, camera_id):
        """Return (success, frame) for the given camera ID."""
        entry = self._cameras.get(camera_id)
        if entry:
            return entry["capture"].read()
        return False, None

    def list_cameras(self):
        """Return a list of dicts with 'id' and 'url' for all registered cameras."""
        return [{"id": cid, "url": entry["url"]} for cid, entry in self._cameras.items()]

    def stop_all(self):
        """Stop all capture threads and clear the registry."""
        for entry in self._cameras.values():
            entry["capture"].stop()
        self._cameras.clear()
