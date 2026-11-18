"""Verify authenticated inspection and bounded, decoded-frame evidence offline."""

import asyncio
import sys
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import camera_preflight as preflight
import pytest


@pytest.mark.parametrize(("error", "status"), [
    (ValueError("401 password=sensitive"), "unauthorized"),
    (ValueError("not supported secret"), "unsupported"),
    (TimeoutError("secret"), "unreachable"),
    (ConnectionError("secret"), "unreachable"),
    (ValueError("unexpected sensitive"), "unknown"),
])
def test_inspection_errors_are_bounded(error, status):
    result = preflight.classify_inspection_error(error)
    assert result["status"] == status
    assert "sensitive" not in str(result) and "secret" not in str(result)


@pytest.mark.parametrize("uri", [
    "rtsp://operator:sensitive@camera.local/live?token=sensitive#secret",
    "rtsp://camera.local/live?token=sensitive",
])
def test_uri_sanitization(uri):
    assert preflight.credential_free_uri(uri) == "rtsp://camera.local/live"


@pytest.mark.parametrize("case", ["success", "open", "read", "empty", "none", "error", "open_error"])
def test_decoder_uses_open_only_timeouts_and_releases(monkeypatch, case):
    class DecoderError(Exception):
        pass

    capture = MagicMock()
    capture.open.return_value = case != "open"
    frame = SimpleNamespace(size=6, shape=(2, 3, 3))
    capture.read.return_value = (case != "read", frame)
    if case == "empty":
        frame.size = 0
    if case == "none":
        capture.read.return_value = (True, None)
    if case == "error":
        capture.read.side_effect = DecoderError("rtsp://user:secret@camera/")
    if case == "open_error":
        capture.open.side_effect = DecoderError("secret")
    cv2 = SimpleNamespace(
        VideoCapture=MagicMock(return_value=capture), CAP_FFMPEG=1900,
        CAP_PROP_OPEN_TIMEOUT_MSEC=53, CAP_PROP_READ_TIMEOUT_MSEC=54, error=DecoderError,
    )
    monkeypatch.setitem(sys.modules, "cv2", cv2)
    result = preflight.verify_rtsp_feed("rtsp://camera/live", timeout_seconds=2)
    capture.open.assert_called_once_with("rtsp://camera/live", 1900, [53, 2000, 54, 2000])
    capture.set.assert_not_called()
    capture.release.assert_called_once()
    assert "secret" not in str(result)
    if case == "success":
        assert result == {"status": "verified_live_feed", "frame_width": 3, "frame_height": 2}
    else:
        assert result["status"] == "feed_verification_failed"


def test_authenticated_inspection_uses_selected_endpoint_and_closes(monkeypatch):
    device = SimpleNamespace(GetCapabilities=AsyncMock(return_value=SimpleNamespace(
        Media=SimpleNamespace(XAddr="http://camera/media"),
        PTZ=SimpleNamespace(XAddr="http://camera/ptz"),
    )))
    media = SimpleNamespace(
        GetProfiles=AsyncMock(return_value=[SimpleNamespace(**{"token": "main", "Name": "Main"})]),
        GetStreamUri=AsyncMock(return_value=SimpleNamespace(Uri="rtsp://camera/live")),
    )
    camera = SimpleNamespace(
        xaddrs={}, create_devicemgmt_service=AsyncMock(return_value=device),
        create_media_service=AsyncMock(return_value=media), close=AsyncMock(),
    )
    factory = MagicMock()

    class StubCamera:
        def __init__(self, *args, **kwargs):
            factory(*args, **kwargs)
            self.__dict__.update(camera.__dict__)
            self.create_devicemgmt_service = AsyncMock(side_effect=self.device_service)

        def get_definition(self, name, port_type=None):
            return "http://default/onvif/device_service", "device.wsdl", "device-binding"

        async def device_service(self):
            assert self.get_definition("devicemgmt")[0] == "http://camera:8000/custom"
            return device

    monkeypatch.setitem(sys.modules, "onvif", SimpleNamespace(ONVIFCamera=StubCamera))
    monkeypatch.setitem(sys.modules, "onvif_discovery", SimpleNamespace(_WSDL_DIR="wsdl"))
    result = asyncio.run(preflight.inspect_camera("http://camera:8000/custom", "user", "secret"))
    assert camera.xaddrs["http://www.onvif.org/ver10/media/wsdl"] == "http://camera/media"
    assert result == {
        "status": "inspected", "supports_ptz": True,
        "profiles": [{"token": "main", "name": "Main", "stream_uri": "rtsp://camera/live"}],
    }
    factory.assert_called_once_with("camera", 8000, "user", "secret", wsdl_dir="wsdl")
    camera.close.assert_awaited_once()
    media.GetProfiles.side_effect = TimeoutError("secret")
    with pytest.raises(TimeoutError):
        asyncio.run(preflight.inspect_camera("http://camera:8000/custom", "user", "secret"))
    assert camera.close.await_count == 2
