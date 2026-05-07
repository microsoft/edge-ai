"""MJPEG streaming server.

Registers FastAPI routes that serve live MJPEG video streams by reading
frames from CameraManager and encoding them as sequential JPEG images.
"""
import time

import cv2
from fastapi.responses import StreamingResponse


def generate_mjpeg(camera_manager, camera_id, fps=15, jpeg_quality=75):
    """Yield MJPEG multipart frames from a camera at the specified FPS."""
    while True:
        success, frame = camera_manager.get_frame(camera_id)
        if success:
            _, buf = cv2.imencode(
                ".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, jpeg_quality])
            yield b"--frame\r\nContent-Type: image/jpeg\r\n\r\n" + buf.tobytes() + b"\r\n"
        time.sleep(1.0 / fps)


def register_mjpeg_routes(app, camera_manager, fps=15, jpeg_quality=75):
    """Register /mjpeg/{camera_id} and /health routes on the FastAPI app."""
    @app.get("/mjpeg/{camera_id}")
    async def mjpeg_feed(camera_id: str):
        return StreamingResponse(
            generate_mjpeg(camera_manager, camera_id, fps, jpeg_quality),
            media_type="multipart/x-mixed-replace; boundary=frame",
        )

    @app.get("/health")
    async def health():
        return {"status": "ok"}
