"""Exercise the installed FFmpeg decoder with local synthetic data only."""

import socket
import threading
import time

import camera_preflight as preflight
import pytest


def test_native_ffmpeg_decodes_local_synthetic_frames(tmp_path):
    cv2 = pytest.importorskip("cv2")
    numpy = pytest.importorskip("numpy")
    video = tmp_path / "synthetic.avi"
    writer = cv2.VideoWriter(str(video), cv2.VideoWriter_fourcc(*"MJPG"), 5, (32, 24))
    try:
        assert writer.isOpened(), "The installed OpenCV must support the local MJPG fixture"
        for _ in range(3):
            writer.write(numpy.zeros((24, 32, 3), dtype=numpy.uint8))
    finally:
        writer.release()
    result = preflight.verify_rtsp_feed(str(video), timeout_seconds=1)
    assert result == {
        "status": "verified_live_feed", "frame_width": 32, "frame_height": 24,
    }


def test_native_rtsp_open_timeout_on_isolated_loopback_listener():
    pytest.importorskip("cv2")
    stop = threading.Event()
    accepted = threading.Event()
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(0.1)

        def stall_rtsp():
            while not stop.is_set():
                try:
                    connection, _address = listener.accept()
                    break
                except TimeoutError:
                    continue
                except OSError:
                    return
            else:
                return
            with connection:
                accepted.set()
                stop.wait(5)

        worker = threading.Thread(target=stall_rtsp, daemon=True)
        worker.start()
        try:
            started = time.monotonic()
            result = preflight.verify_rtsp_feed(
                f"rtsp://127.0.0.1:{listener.getsockname()[1]}/stall",
                timeout_seconds=0.2,
            )
            elapsed = time.monotonic() - started
            assert accepted.is_set()
            assert result["status"] == "feed_verification_failed"
            assert 0.05 <= elapsed < 5, f"Native open timeout took {elapsed:.3f}s"
        finally:
            stop.set()
            worker.join(timeout=3)
            assert not worker.is_alive()
