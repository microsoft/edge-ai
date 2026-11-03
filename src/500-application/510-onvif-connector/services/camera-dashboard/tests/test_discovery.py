"""Discovery regression tests; real connections are restricted to loopback."""

import asyncio
import importlib.util
import socket
import threading
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest

SOURCE = Path(__file__).resolve().parents[1] / "src"
SPEC = importlib.util.spec_from_file_location("onvif_discovery", SOURCE / "onvif_discovery.py")
discovery = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(discovery)


@pytest.mark.parametrize(
    "raw",
    [
        "256.1.1.1", "10.0.256.1-2", "999.1.1.1-2", "10.0.1-2",
        "10.0.0.4-3", "10.0.0.0-256", "10.0.0.-1-2", "10.0.0.1-foo",
        "10.0.0.1:0", "10.0.0.1:65536", "10.0.0.1:abc",
        "10.0.0.1:-1", "10.0.0.1:", "10.0.0.1:1:80", "::1", "camera.local",
        "10.0.0.0/33", "10.0.0.0/24:0",
    ],
)
def test_invalid_scope_never_probes(monkeypatch, raw):
    probe = AsyncMock()
    multicast = AsyncMock()
    monkeypatch.setattr(discovery, "probe_onvif_device", probe)
    monkeypatch.setattr(discovery, "_discover_sync", multicast)
    with pytest.raises(ValueError):
        asyncio.run(discovery.discover_onvif_devices(target_hosts=f"127.0.0.1,{raw}"))
    probe.assert_not_called()
    multicast.assert_not_called()


def test_expansion_formats_and_deduplication():
    assert discovery._expand_targets("10.0.0.0/31:65535,10.0.0.2/32,10.0.0.1-3,10.0.0.2") == [
        ("10.0.0.0", 65535), ("10.0.0.1", 65535),
        ("10.0.0.2", 80), ("10.0.0.1", 80), ("10.0.0.3", 80),
    ]
    assert len(discovery._expand_targets("10.0.0.0/24")) == 254


@pytest.mark.parametrize(
    "raw",
    [
        "10.0.0.0/19",
        "10.0.0.0/20,10.0.16.0/31,10.0.16.2",
        ",".join(["127.0.0.1"] * 4097),
        "10.0.0.0/20,10.0.0.0/20",
    ],
)
def test_budget_rejected_before_any_expansion_or_probe(monkeypatch, raw):
    def forbidden(*args, **kwargs):
        pytest.fail("Over-budget scope was expanded")

    probe = AsyncMock()
    monkeypatch.setattr(discovery.ipaddress.IPv4Network, "hosts", forbidden)
    monkeypatch.setattr(discovery.ipaddress.IPv4Address, "__str__", forbidden)
    monkeypatch.setattr(discovery, "probe_onvif_device", probe)
    with pytest.raises(ValueError, match="4096"):
        asyncio.run(discovery.discover_onvif_devices(target_hosts=raw))
    probe.assert_not_called()


def test_full_list_validated_before_expansion(monkeypatch):
    def forbidden(*args):
        pytest.fail("Earlier valid token expanded before later invalid token validation")

    monkeypatch.setattr(discovery.ipaddress.IPv4Network, "hosts", forbidden)
    with pytest.raises(ValueError):
        discovery._expand_targets("10.0.0.0/24,10.0.0.1:bad")


def test_exact_budget_accepted(monkeypatch):
    assert len(discovery._expand_targets("10.0.0.0/20,10.0.16.0/31")) == 4096
    assert discovery._expand_targets(",".join(["127.0.0.1"] * 4096)) == [("127.0.0.1", 80)]
    probe = AsyncMock(return_value={"status": "candidate"})
    monkeypatch.setattr(discovery, "probe_onvif_device", probe)
    result = asyncio.run(discovery.discover_onvif_devices(target_hosts="10.0.0.0/20,10.0.16.0/31"))
    assert len(result) == probe.await_count == 4096


def test_multicast_requires_opt_in_and_conflicting_scope_is_rejected(monkeypatch):
    multicast = AsyncMock(return_value=[])
    monkeypatch.setattr(discovery, "_run_worker", multicast)
    for targets in (None, "", " , "):
        if targets == " , ":
            assert asyncio.run(discovery.discover_onvif_devices(target_hosts=targets)) == []
        else:
            with pytest.raises(ValueError, match="explicitly"):
                asyncio.run(discovery.discover_onvif_devices(target_hosts=targets))
    multicast.assert_not_called()
    with pytest.raises(ValueError, match="not both"):
        asyncio.run(discovery.discover_onvif_devices(target_hosts="127.0.0.1", multicast=True))
    assert asyncio.run(discovery.discover_onvif_devices(multicast=True)) == []
    multicast.assert_awaited_once()


def test_loopback_candidate_and_unreachable_without_credentials(monkeypatch):
    camera = AsyncMock()
    monkeypatch.setattr(discovery, "ONVIFCamera", camera)
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen()
        port = listener.getsockname()[1]
        result = asyncio.run(discovery.discover_onvif_devices(target_hosts=f"127.0.0.1:{port}"))
    assert result[0]["status"] == "candidate"
    assert result[0]["evidence"] == ["tcp_port_open"]
    result = asyncio.run(discovery.discover_onvif_devices(target_hosts=f"127.0.0.1:{port}"))
    assert result[0]["status"] == "unreachable"
    camera.assert_not_called()


def test_unknown_probe_failure_is_not_a_candidate(monkeypatch):
    monkeypatch.setattr(discovery, "probe_onvif_device", AsyncMock(side_effect=RuntimeError("failure")))
    result = asyncio.run(discovery.discover_onvif_devices(target_hosts="127.0.0.1"))
    assert result[0]["status"] == "unknown"
    assert result[0]["evidence"] == []


def test_threaded_probes_limit_timeout_cancellation_and_cleanup(monkeypatch):
    started = threading.Event()
    release = threading.Event()
    lock = threading.Lock()
    sockets = []
    active = 0
    peak = 0
    loop_thread = threading.get_ident()

    class FakeSocket:
        closed = False

        def __init__(self, *args):
            sockets.append(self)

        def settimeout(self, timeout):
            assert timeout == 2

        def connect(self, address):
            nonlocal active, peak
            assert threading.get_ident() != loop_thread
            with lock:
                active += 1
                peak = max(peak, active)
            started.set()
            assert release.wait(2)
            with lock:
                active -= 1

        def close(self):
            self.closed = True

    async def exercise():
        task = asyncio.create_task(discovery.discover_onvif_devices(target_hosts="10.0.0.1-100"))
        while not started.is_set():
            await asyncio.sleep(0.001)
        await asyncio.sleep(0.05)
        assert not task.done()
        task.cancel()
        await asyncio.sleep(0.01)
        assert not task.done()
        task.cancel()
        await asyncio.sleep(0.01)
        assert not task.done()
        release.set()
        with pytest.raises(asyncio.CancelledError):
            await task
        assert active == 0
        assert 1 < peak <= 50
        assert len(sockets) <= 50
        assert all(sock.closed for sock in sockets)

    # Construct the event loop before replacing its socket constructor.
    with asyncio.Runner() as runner:
        runner.get_loop().set_default_executor(ThreadPoolExecutor(max_workers=60))
        monkeypatch.setattr(discovery.socket, "socket", FakeSocket)
        runner.run(exercise())


def test_multicast_cancellation_closes_worker_socket(monkeypatch):
    started = threading.Event()
    closed = threading.Event()

    class FakeSocket:
        def __init__(self, *args):
            pass

        def setsockopt(self, *args):
            pass

        def settimeout(self, timeout):
            assert timeout <= 1

        def sendto(self, *args):
            started.set()

        def recvfrom(self, *args):
            closed.wait(0.01)
            raise TimeoutError

        def close(self):
            closed.set()

    async def exercise():
        task = asyncio.create_task(discovery.discover_onvif_devices(multicast=True))
        while not started.is_set():
            await asyncio.sleep(0.001)
        task.cancel()
        with pytest.raises(asyncio.CancelledError):
            await task
        assert closed.is_set()

    with asyncio.Runner() as runner:
        runner.get_loop()
        monkeypatch.setattr(discovery.socket, "socket", FakeSocket)
        runner.run(exercise())


def test_authenticated_inspection_api_stays_separate(monkeypatch):
    profile = SimpleNamespace(Name="Main", **{"token": "main"})
    media = SimpleNamespace(
        GetProfiles=AsyncMock(return_value=[profile]),
        GetStreamUri=AsyncMock(return_value=SimpleNamespace(Uri="rtsp://127.0.0.1/live")),
    )
    info = SimpleNamespace(Model="Camera")
    camera = SimpleNamespace(
        update_xaddrs=AsyncMock(),
        create_devicemgmt_service=AsyncMock(
            return_value=SimpleNamespace(GetDeviceInformation=AsyncMock(return_value=info))
        ),
        create_media_service=AsyncMock(return_value=media),
        close=AsyncMock(),
    )
    def constructor(*args, **kwargs):
        return camera

    monkeypatch.setattr(discovery, "ONVIFCamera", constructor)
    inspector = discovery.ONVIFDiscovery("127.0.0.1", 80, "operator", "provided")
    result = asyncio.run(inspector.discover())
    assert result == {
        "device": info,
        "cameras": [{"profile": "Main", "token": "main", "uri": "rtsp://127.0.0.1/live"}],
    }
    assert asyncio.run(inspector.get_stream_uri("main")) == "rtsp://127.0.0.1/live"
    assert asyncio.run(inspector.get_profiles()) == result["cameras"]
    assert camera.close.await_count == 3
    media.GetProfiles.side_effect = RuntimeError("inspection failed")
    with pytest.raises(RuntimeError, match="inspection failed"):
        asyncio.run(inspector.discover())
    assert camera.close.await_count == 4


@pytest.mark.parametrize("timeout", [0, -1, float("inf"), float("nan")])
def test_invalid_multicast_timeout_does_not_start_worker(monkeypatch, timeout):
    worker = AsyncMock()
    monkeypatch.setattr(discovery, "_run_worker", worker)
    with pytest.raises(ValueError, match="positive and finite"):
        asyncio.run(discovery.discover_onvif_devices(multicast=True, timeout=timeout))
    worker.assert_not_called()


def test_multicast_candidates_and_malformed_responses():
    devices = {}
    discovery._parse_probe_match(b"not xml", devices)
    discovery._parse_probe_match(b"\xff", devices)
    for endpoint in (
        "http://127.0.0.1:8000/onvif/device_service",
        "http://127.0.0.1:bad/onvif",
        "http://127.0.0.1:0/onvif",
        "http://127.0.0.1:65536/onvif",
        "http://[invalid/onvif",
        "http:///onvif",
        "file://127.0.0.1/onvif",
    ):
        response = (
            '<d:ProbeMatches xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery">'
            f"<d:ProbeMatch><d:XAddrs>{endpoint}</d:XAddrs>"
            "<d:Scopes>onvif://www.onvif.org/name/Loopback%20Camera</d:Scopes>"
            "</d:ProbeMatch></d:ProbeMatches>"
        ).encode()
        discovery._parse_probe_match(response, devices)
        discovery._parse_probe_match(response, devices)
    assert list(devices.values()) == [{
        "host": "127.0.0.1", "port": 8000, "name": "Loopback Camera",
        "status": "candidate", "evidence": ["ws_discovery_probe_match"],
    }]
