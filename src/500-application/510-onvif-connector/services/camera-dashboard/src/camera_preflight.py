"""Authenticated inspection and point-in-time decoded-frame verification."""

import asyncio
import math
import os
from urllib.parse import quote, urlsplit, urlunsplit

os.environ["OPENCV_FFMPEG_LOGLEVEL"] = "-8"
os.environ["OPENCV_LOG_LEVEL"] = "SILENT"


def classify_inspection_error(error):
    """Return bounded diagnostics without including camera response contents."""
    message = str(error).lower()
    if any(word in message for word in ("unauthorized", "not authorized", "401", "authentication")):
        return {"status": "unauthorized", "error": "ONVIF authentication was rejected"}
    if any(word in message for word in ("not supported", "no service", "404", "method not allowed")):
        return {"status": "unsupported", "error": "Required ONVIF services are unavailable"}
    if isinstance(error, (TimeoutError, ConnectionError, OSError)) or any(
        word in message for word in ("timeout", "timed out", "unreachable", "connection refused")
    ):
        return {"status": "unreachable", "error": "ONVIF endpoint could not be reached"}
    return {"status": "unknown", "error": "ONVIF inspection failed"}


def credential_free_uri(uri, schemes=("rtsp",)):
    """Strip userinfo, query and fragment before retaining or exporting a URI."""
    try:
        parsed = urlsplit(uri)
        if parsed.scheme not in schemes or not parsed.hostname:
            raise ValueError
        host = f"[{parsed.hostname}]" if ":" in parsed.hostname else parsed.hostname
        authority = f"{host}:{parsed.port}" if parsed.port else host
        return urlunsplit((parsed.scheme, authority, parsed.path, "", ""))
    except (ValueError, TypeError):
        raise ValueError("Invalid camera URI") from None


def authenticated_uri(uri, username, password):
    """Construct an ephemeral decoder URI; never retain it as evidence."""
    parsed = urlsplit(uri)
    if username or password:
        safe = urlsplit(credential_free_uri(uri))
        authority = f"{quote(username, safe='')}:{quote(password, safe='')}@{safe.netloc}"
        return urlunsplit((parsed.scheme, authority, parsed.path, parsed.query, parsed.fragment))
    return uri


async def inspect_camera(endpoint, username, password):
    """Inspect an explicitly chosen ONVIF endpoint independently of discovery."""
    from onvif import ONVIFCamera
    from onvif_discovery import _WSDL_DIR

    endpoint = credential_free_uri(endpoint, ("http", "https"))
    parsed = urlsplit(endpoint)
    class EndpointCamera(ONVIFCamera):
        def get_definition(self, name, port_type=None):
            address, wsdl, binding = super().get_definition(name, port_type)
            return (endpoint if name == "devicemgmt" else address), wsdl, binding

    camera = EndpointCamera(
        parsed.hostname, parsed.port or (443 if parsed.scheme == "https" else 80),
        username, password, wsdl_dir=_WSDL_DIR,
    )
    try:
        async with asyncio.timeout(20):
            device = await camera.create_devicemgmt_service()
            capabilities = await device.GetCapabilities({"Category": "All"})
            media_capability = getattr(capabilities, "Media", None)
            if media_capability is None or not getattr(media_capability, "XAddr", None):
                raise ValueError("Required ONVIF media service not supported")
            camera.xaddrs["http://www.onvif.org/ver10/media/wsdl"] = credential_free_uri(
                media_capability.XAddr, ("http", "https"),
            )
            media = await camera.create_media_service()
            profiles = []
            for profile in await media.GetProfiles():
                stream = await media.GetStreamUri({
                    "StreamSetup": {"Stream": "RTP-Unicast", "Transport": {"Protocol": "RTSP"}},
                    "ProfileToken": profile.token,
                })
                profiles.append({
                    "token": profile.token, "name": profile.Name, "stream_uri": stream.Uri,
                })
            ptz = getattr(capabilities, "PTZ", None)
            return {
                "status": "inspected", "supports_ptz": bool(ptz and getattr(ptz, "XAddr", None)),
                "profiles": profiles,
            }
    finally:
        await camera.close()


def verify_rtsp_feed(rtsp_uri, timeout_seconds=10):
    """Decode one frame with FFmpeg's supported open-only timeout parameters."""
    import cv2

    if not math.isfinite(timeout_seconds) or timeout_seconds <= 0:
        raise ValueError("Frame timeout must be positive and finite")
    timeout_ms = max(1, int(timeout_seconds * 1000))
    capture = cv2.VideoCapture()
    failure = {"status": "feed_verification_failed", "error": "No decoded RTSP frame received"}
    try:
        opened = capture.open(rtsp_uri, cv2.CAP_FFMPEG, [
            cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, timeout_ms,
            cv2.CAP_PROP_READ_TIMEOUT_MSEC, timeout_ms,
        ])
        if not opened:
            return {**failure, "error": "RTSP stream could not be opened"}
        received, frame = capture.read()
        if (
            not received or frame is None or not frame.size
            or len(frame.shape) < 2 or frame.shape[0] <= 0 or frame.shape[1] <= 0
        ):
            return failure
        return {
            "status": "verified_live_feed",
            "frame_width": int(frame.shape[1]), "frame_height": int(frame.shape[0]),
        }
    except cv2.error:
        return {**failure, "error": "RTSP decoder failed"}
    finally:
        capture.release()
