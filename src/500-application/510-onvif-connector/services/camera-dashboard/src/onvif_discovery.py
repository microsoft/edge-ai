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
import math
import os
import socket
import threading
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


def _discover_sync(timeout, stop):
    """Send a WS-Discovery multicast probe and collect ONVIF device responses."""
    if stop.is_set():
        return []
    probe = _PROBE_TEMPLATE.format(message_id=uuid.uuid4()).encode("utf-8")
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
        sock.settimeout(0.1)
        if stop.is_set():
            return []
        sock.sendto(probe, _WS_DISCOVERY_MULTICAST)
        devices = {}
        end = time.monotonic() + timeout
        while not stop.is_set() and time.monotonic() < end:
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
        try:
            parsed = urlparse(xaddr)
            host = str(ipaddress.IPv4Address(parsed.hostname))
            port = parsed.port if parsed.port is not None else 80
            if parsed.scheme not in ("http", "https") or not 1 <= port <= 65535:
                continue
        except ValueError:
            continue
        scopes = scopes_el.text.strip() if scopes_el is not None and scopes_el.text else ""
        name = _name_from_scopes(scopes) or f"Camera ({host})"
        key = f"{host}:{port}"
        if key not in devices:
            devices[key] = {
                "host": host, "port": port, "name": name,
                "status": "candidate", "evidence": ["ws_discovery_probe_match"],
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
    """Collect unauthenticated TCP candidate evidence, not ONVIF capabilities."""
    host = str(ipaddress.IPv4Address(host))
    if isinstance(port, bool) or not isinstance(port, int) or not 1 <= port <= 65535:
        raise ValueError("Port must be an integer between 1 and 65535")
    stop = threading.Event()

    def _probe():
        if stop.is_set():
            return None
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            sock.settimeout(2)
            sock.connect((host, port))
            return {
                "host": host, "port": port, "name": f"Candidate ({host})",
                "status": "candidate", "evidence": ["tcp_port_open"],
            }
        except OSError:
            return {
                "host": host, "port": port, "name": f"Unreachable ({host})",
                "status": "unreachable", "evidence": [],
            }
        finally:
            sock.close()

    if semaphore:
        async with semaphore:
            return await _run_worker(_probe, stop=stop)
    return await _run_worker(_probe, stop=stop)


async def _run_worker(function, *args, stop=None):
    """Drain socket workers before cancellation releases their concurrency slot."""
    worker = asyncio.create_task(asyncio.to_thread(function, *args))
    try:
        return await asyncio.shield(worker)
    except asyncio.CancelledError:
        if stop is not None:
            stop.set()
        while not worker.done():
            try:
                await asyncio.shield(worker)
            except asyncio.CancelledError:
                continue
            except Exception:
                break
        if not worker.cancelled():
            worker.exception()
        raise


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
    plans = []
    total = 0
    for token in raw.split(","):
        token = token.strip()
        if not token:
            continue
        port = 80
        if ":" in token:
            token, raw_port = token.rsplit(":", 1)
            if not raw_port.isascii() or not raw_port.isdecimal():
                raise ValueError("Port must be an integer between 1 and 65535")
            port = int(raw_port)
        if not 1 <= port <= 65535:
            raise ValueError("Port must be an integer between 1 and 65535")
        if "/" in token:
            network = ipaddress.IPv4Network(token, strict=False)
            count = network.num_addresses
            if network.prefixlen < 31:
                count -= 2
            plan = (network, None, port)
        elif "-" in token:
            start_text, end_text = token.split("-", 1)
            start = ipaddress.IPv4Address(start_text)
            if not end_text.isascii() or not end_text.isdecimal():
                raise ValueError(f"Invalid IPv4 range: {token}")
            end_octet = int(end_text)
            if not int(start) % 256 <= end_octet <= 255:
                raise ValueError(f"Invalid IPv4 range: {token}")
            end = int(start) - int(start) % 256 + end_octet
            count = end - int(start) + 1
            plan = (int(start), end, port)
        else:
            plan = (int(ipaddress.IPv4Address(token)), None, port)
            count = 1
        total += count
        if total > 4096:
            raise ValueError("Approved discovery scope cannot exceed 4096 endpoints")
        plans.append(plan)

    results = []
    for start, end, port in plans:
        if isinstance(start, ipaddress.IPv4Network):
            addresses = start.hosts()
        else:
            addresses = (
                ipaddress.IPv4Address(value)
                for value in range(start, (end if end is not None else start) + 1)
            )
        results.extend((str(address), port) for address in addresses)
    return list(dict.fromkeys(results))


async def discover_onvif_devices(timeout=5, target_hosts=None, multicast=False):
    """Discover unauthenticated candidates within an explicitly approved scope.

    Supported target_hosts formats (comma-separated):
      - Single IP or IP:port
      - CIDR subnet: 192.168.1.0/24 or 192.168.1.0/24:8000
      - IP range: 192.168.1.1-254 or 192.168.1.1-254:8000
    Multicast requires explicit consent and cannot be combined with targets.
    """
    if target_hosts and multicast:
        raise ValueError("Choose targeted probing or multicast, not both")
    if target_hosts:
        pairs = _expand_targets(target_hosts)
        if not pairs:
            return []
        sem = asyncio.Semaphore(50)
        tasks = [asyncio.create_task(probe_onvif_device(h, p, semaphore=sem)) for h, p in pairs]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return [
            {
                "host": host, "port": port, "name": f"Unknown ({host})",
                "status": "unknown", "evidence": [],
            } if isinstance(result, Exception) else result
            for (host, port), result in zip(pairs, results, strict=True)
        ]
    if multicast:
        if not math.isfinite(timeout) or timeout <= 0:
            raise ValueError("Multicast timeout must be positive and finite")
        stop = threading.Event()
        return await _run_worker(_discover_sync, timeout, stop, stop=stop)
    raise ValueError("Provide an approved target scope or explicitly enable multicast")
