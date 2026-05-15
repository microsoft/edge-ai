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
                cameras.append(
                    {
                        "profile": profile.Name,
                        "token": profile.token,
                        "uri": uri.Uri,
                    }
                )
            return {"device": info, "cameras": cameras}
        finally:
            await cam.close()

    async def get_stream_uri(self, profile_token=None):
        """Return the RTSP stream URI for the given profile, or the first available."""
        result = await self.discover()
        if not result["cameras"]:
            return None
        if profile_token:
            for cam in result["cameras"]:
                if cam["token"] == profile_token:
                    return cam["uri"]
        return result["cameras"][0]["uri"]

    async def get_profiles(self):
        """Return all available media profiles with their stream URIs."""
        result = await self.discover()
        return result["cameras"]


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
            devices[key] = {"host": host, "port": port, "name": name}


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
    """Probe a single host via ONVIF GetDeviceInformation (TCP)."""
    async def _probe():
        try:
            cam = ONVIFCamera(host, port, "admin", "admin", wsdl_dir=_WSDL_DIR)
            try:
                await cam.update_xaddrs()
                device = await cam.create_devicemgmt_service()
                info = await device.GetDeviceInformation()
                name = getattr(info, "Model", None) or getattr(
                    info, "Manufacturer", None) or f"Camera ({host})"
                return {"host": host, "port": port, "name": str(name)}
            finally:
                try:
                    await cam.close()
                except Exception:
                    logger.debug(
                        "Failed to close ONVIF camera connection", exc_info=True)
        except Exception:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            try:
                sock.connect((host, port))
                sock.close()
                return {"host": host, "port": port, "name": f"Camera ({host})"}
            except (OSError, TimeoutError):
                return None
            finally:
                sock.close()
    if semaphore:
        async with semaphore:
            return await _probe()
    return await _probe()


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
        if "/" in token:
            for addr in ipaddress.IPv4Network(token, strict=False).hosts():
                results.append((str(addr), port))
        elif "-" in token.split(".")[-1]:
            parts = token.split(".")
            prefix = ".".join(parts[:3])
            last = parts[3]
            if "-" in last:
                lo, hi = last.split("-", 1)
                start = int(lo)
                end = int(hi)
                for i in range(start, end + 1):
                    results.append((f"{prefix}.{i}", port))
        else:
            results.append((token, port))
    return results


async def discover_onvif_devices(timeout=5, target_hosts=None):
    """Discover ONVIF cameras via multicast or direct probe.

    Supported target_hosts formats (comma-separated):
      - Single IP or IP:port
      - CIDR subnet: 192.168.1.0/24 or 192.168.1.0/24:8000
      - IP range: 192.168.1.1-254 or 192.168.1.1-254:8000
    Falls back to WS-Discovery multicast when target_hosts is empty.
    """
    if target_hosts:
        pairs = _expand_targets(target_hosts)
        if not pairs:
            return []
        sem = asyncio.Semaphore(50)
        tasks = [probe_onvif_device(h, p, semaphore=sem) for h, p in pairs]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return [r for r in results if r and not isinstance(r, Exception)]
    return await asyncio.get_event_loop().run_in_executor(None, _discover_sync, timeout)
