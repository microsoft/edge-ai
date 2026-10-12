"""ONVIF camera discovery and stream URI retrieval.

Supports two discovery modes:
    - Targeted probe: direct TCP connection to specified hosts (IP, CIDR, range)
    - Multicast discovery: WS-Discovery UDP probe to 239.255.255.250:3702

Also provides ONVIFDiscovery for retrieving media profiles and RTSP stream
URIs from a known ONVIF camera endpoint.
"""
import asyncio
import ipaddress
import logging
import os
import socket
import time
import uuid
from urllib.parse import urlparse

from defusedxml.ElementTree import ParseError, fromstring
from onvif import ONVIFCamera

logger = logging.getLogger(__name__)

_WSDL_DIR = os.path.join(os.path.dirname(
    os.path.abspath(__import__("onvif").__file__)), "wsdl")


class ONVIFDiscovery:
    """Connects to an ONVIF camera and retrieves available stream URIs."""

    def __init__(self, host, port, username, password):
        self.host = host
        self.port = port
        self.username = username
        self.password = password

    async def discover(self):
        """Return device info and all available media profiles with stream URIs."""
        cam = ONVIFCamera(self.host, self.port, self.username,
                          self.password, wsdl_dir=_WSDL_DIR)
        try:
            await cam.update_xaddrs()
            device = await cam.create_devicemgmt_service()
            info = await device.GetDeviceInformation()
            media = await cam.create_media_service()
            profiles = await media.GetProfiles()
            cameras = []
            for profile in profiles:
                uri = await media.GetStreamUri(
                    {
                        "StreamSetup": {
                            "Stream": "RTP-Unicast",
                            "Transport": {"Protocol": "RTSP"},
                        },
                        "ProfileToken": profile.token,
                    }
                )
                encoder = getattr(profile, "VideoEncoderConfiguration", None)
                resolution = getattr(encoder, "Resolution", None)
                rate_control = getattr(encoder, "RateControl", None)
                cameras.append(
                    {
                        "name": str(profile.Name),
                        "token": str(profile.token),
                        "stream_uri": str(uri.Uri),
                        "encoding": _string_value(encoder, "Encoding"),
                        "resolution": _resolution_value(resolution),
                        "frame_rate": _number_value(
                            rate_control, "FrameRateLimit"
                        ),
                        "bitrate_kbps": _number_value(
                            rate_control, "BitrateLimit"
                        ),
                        "supports_ptz": getattr(
                            profile, "PTZConfiguration", None
                        ) is not None,
                    }
                )
            return {
                "status": "capabilities_inspected",
                "device": {
                    "manufacturer": _string_value(info, "Manufacturer"),
                    "model": _string_value(info, "Model"),
                    "firmware_version": _string_value(
                        info, "FirmwareVersion"
                    ),
                    "serial_number": _string_value(info, "SerialNumber"),
                    "hardware_id": _string_value(info, "HardwareId"),
                },
                "profiles": cameras,
            }
        finally:
            await cam.close()

    async def get_stream_uri(self, profile_token=None):
        """Return the RTSP stream URI for the given profile, or the first available."""
        result = await self.discover()
        if not result["profiles"]:
            return None
        if profile_token:
            for cam in result["profiles"]:
                if cam["token"] == profile_token:
                    return cam["stream_uri"]
        return result["profiles"][0]["stream_uri"]

    async def get_profiles(self):
        """Return all available media profiles with their stream URIs."""
        result = await self.discover()
        return result["profiles"]


def _string_value(value, attribute):
    result = getattr(value, attribute, None)
    return str(result) if result is not None else None


def _number_value(value, attribute):
    result = getattr(value, attribute, None)
    return result if isinstance(result, (int, float)) else None


def _resolution_value(value):
    width = getattr(value, "Width", None)
    height = getattr(value, "Height", None)
    if isinstance(width, int) and isinstance(height, int):
        return f"{width}x{height}"
    return None


_WS_DISCOVERY_MULTICAST = ("239.255.255.250", 3702)

_PROBE_TEMPLATE = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"'
    ' xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"'
    ' xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery"'
    ' xmlns:dn="http://www.onvif.org/ver10/network/wsdl">'
    '<s:Header>'
    '<a:Action s:mustUnderstand="1">'
    'http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe'
    '</a:Action>'
    '<a:MessageID>uuid:{message_id}</a:MessageID>'
    '<a:ReplyTo>'
    '<a:Address>'
    'http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous'
    '</a:Address>'
    '</a:ReplyTo>'
    '<a:To s:mustUnderstand="1">'
    'urn:schemas-xmlsoap-org:ws:2005:04:discovery'
    '</a:To>'
    '</s:Header>'
    '<s:Body>'
    '<d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types></d:Probe>'
    '</s:Body>'
    '</s:Envelope>'
)


def _discover_sync(timeout):
    """Send a WS-Discovery multicast probe and collect ONVIF device responses."""
    probe = _PROBE_TEMPLATE.format(message_id=uuid.uuid4()).encode("utf-8")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
    sock.settimeout(1.0)
    try:
        sock.sendto(probe, _WS_DISCOVERY_MULTICAST)
        devices = {}
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            try:
                data, _ = sock.recvfrom(65535)
                _parse_probe_match(data, devices)
            except TimeoutError:
                continue
        return list(devices.values())
    finally:
        sock.close()


def _parse_probe_match(data, devices):
    """Extract device info from a WS-Discovery ProbeMatch response."""
    ns = {
        "s": "http://www.w3.org/2003/05/soap-envelope",
        "d": "http://schemas.xmlsoap.org/ws/2005/04/discovery",
        "a": "http://schemas.xmlsoap.org/ws/2004/08/addressing",
    }
    try:
        root = fromstring(data.decode("utf-8"))
    except (ParseError, UnicodeDecodeError):
        return
    for match in root.findall(".//d:ProbeMatch", ns):
        xaddrs_el = match.find("d:XAddrs", ns)
        scopes_el = match.find("d:Scopes", ns)
        if xaddrs_el is None or not xaddrs_el.text:
            continue
        xaddr = xaddrs_el.text.strip().split()[0]
        parsed = urlparse(xaddr)
        host = parsed.hostname
        port = parsed.port or 80
        scopes = scopes_el.text.strip() if scopes_el is not None and scopes_el.text else ""
        name = _name_from_scopes(scopes) or f"Camera ({host})"
        key = f"{host}:{port}"
        if key not in devices:
            devices[key] = {
                "host": host,
                "port": port,
                "name": name,
                "status": "candidate",
                "evidence": ["ws_discovery_probe_match"],
            }


def _name_from_scopes(scopes):
    """Extract a human-readable name from ONVIF discovery scopes."""
    for scope in scopes.split():
        if "/name/" in scope:
            return scope.rsplit("/name/", 1)[-1].replace("%20", " ")
    for scope in scopes.split():
        if "/hardware/" in scope:
            return scope.rsplit("/hardware/", 1)[-1].replace("%20", " ")
    return ""


async def probe_onvif_device(host, port=80, semaphore=None):
    """Collect bounded candidate evidence for one explicitly approved endpoint."""
    def _probe():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        try:
            sock.connect((host, port))
            return {
                "host": host,
                "port": port,
                "name": f"Candidate ({host})",
                "status": "candidate",
                "evidence": ["tcp_port_open"],
            }
        except (OSError, TimeoutError) as exc:
            return {
                "host": host,
                "port": port,
                "name": f"Unreachable ({host})",
                "status": "unreachable",
                "evidence": [],
                "error": str(exc),
            }
        finally:
            sock.close()
    if semaphore:
        async with semaphore:
            return await asyncio.to_thread(_probe)
    return await asyncio.to_thread(_probe)


def _expand_targets(raw):
    """Expand comma-separated targets into (host, port) tuples.

    Supported formats:
      - Single IP: 192.168.1.100
      - IP:port: 192.168.1.100:8000
      - CIDR: 192.168.1.0/24
      - CIDR:port: 192.168.1.0/24:8000
      - Range: 192.168.1.1-254
      - Range:port: 192.168.1.1-254:8000
    """
    results = []
    for token in raw.split(","):
        token = token.strip()
        if not token:
            continue
        port = 80
        # Extract trailing :port if present and last segment is numeric
        if ":" in token:
            base, maybe_port = token.rsplit(":", 1)
            if maybe_port.isdigit():
                port = int(maybe_port)
                token = base
        if not 1 <= port <= 65535:
            raise ValueError(f"Port is outside the approved range: {port}")
        if "/" in token:
            network = ipaddress.IPv4Network(token, strict=False)
            for addr in network.hosts():
                results.append((str(addr), port))
        elif "-" in token.split(".")[-1]:
            parts = token.split(".")
            prefix = ".".join(parts[:3])
            last = parts[3]
            if "-" in last:
                lo, hi = last.split("-", 1)
                start = int(lo)
                end = int(hi)
                if not 0 <= start <= end <= 255:
                    raise ValueError(f"Invalid IPv4 range: {token}")
                for i in range(start, end + 1):
                    results.append((f"{prefix}.{i}", port))
        else:
            results.append((str(ipaddress.IPv4Address(token)), port))
        if len(results) > 4096:
            raise ValueError("Approved discovery scope cannot exceed 4096 endpoints")
    return list(dict.fromkeys(results))


async def discover_onvif_devices(timeout=5, target_hosts=None, multicast=False):
    """Discover ONVIF candidates within an explicitly approved scope.

    Supported target_hosts formats (comma-separated):
      - Single IP or IP:port
      - CIDR subnet: 192.168.1.0/24 or 192.168.1.0/24:8000
      - IP range: 192.168.1.1-254 or 192.168.1.1-254:8000
    Multicast is used only when multicast=True.
    """
    if target_hosts:
        pairs = _expand_targets(target_hosts)
        if not pairs:
            return []
        sem = asyncio.Semaphore(50)
        tasks = [probe_onvif_device(h, p, semaphore=sem) for h, p in pairs]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        candidates = []
        for (host, port), result in zip(pairs, results, strict=True):
            if isinstance(result, Exception):
                logger.warning(
                    "Candidate probe failed with %s",
                    type(result).__name__,
                )
                candidates.append(
                    {
                        "host": host,
                        "port": port,
                        "name": f"Unknown ({host})",
                        "status": "unknown",
                        "evidence": [],
                        "error": "Candidate probe failed for an unknown reason",
                    }
                )
            elif result:
                candidates.append(result)
        return candidates
    if multicast:
        return await asyncio.get_event_loop().run_in_executor(
            None, _discover_sync, timeout
        )
    raise ValueError("Provide an approved target scope or explicitly enable multicast")
