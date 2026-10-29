"""Exercise dashboard callbacks without camera, MQTT, or browser connections."""

import asyncio
import importlib.util
import sys
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

SOURCE = Path(__file__).resolve().parents[1] / "src"


@pytest.fixture
def dashboard(monkeypatch):
    nodes = []
    routes = {}

    def element(kind, *args, **kwargs):
        node = MagicMock()
        node.value = kwargs.get("value", "")
        for method in ("classes", "props", "style", "tooltip", "on"):
            getattr(node, method).return_value = node
        nodes.append((kind, args, kwargs, node))
        return node

    ui = MagicMock()
    for kind in (
        "input", "checkbox", "button", "label", "column", "row", "card",
        "header", "grid", "element", "html", "select", "log", "dialog",
    ):
        getattr(ui, kind).side_effect = lambda *a, _kind=kind, **kw: element(_kind, *a, **kw)

    def page(route):
        def decorate(function):
            routes[route] = function
            return function
        return decorate

    ui.page.side_effect = page
    cameras = {}
    manager = MagicMock()
    manager.add_camera.side_effect = lambda name, url: cameras.update({name: url})
    manager.list_cameras.side_effect = lambda: [{"id": name} for name in cameras]
    mqtt = MagicMock()
    ptz = MagicMock()
    ptz.has_ptz.return_value = False
    inspect = MagicMock()
    inspect.return_value.get_stream_uri = AsyncMock(return_value="rtsp://127.0.0.1/live")
    discover = AsyncMock(return_value=[])
    modules = {
        "nicegui": SimpleNamespace(app=MagicMock(), ui=ui),
        "camera_manager": SimpleNamespace(CameraManager=lambda: manager),
        "mqtt_handler": SimpleNamespace(MQTTHandler=lambda **kwargs: mqtt),
        "ptz_controller": SimpleNamespace(PTZController=lambda: ptz),
        "mjpeg_server": SimpleNamespace(register_mjpeg_routes=MagicMock()),
        "onvif_discovery": SimpleNamespace(ONVIFDiscovery=inspect, discover_onvif_devices=discover),
    }
    for name, module in modules.items():
        monkeypatch.setitem(sys.modules, name, module)
    monkeypatch.setenv("CAMERA_NAMES", "env-camera")
    monkeypatch.setenv("CAMERA_URLS", "rtsp://127.0.0.1/env")
    spec = importlib.util.spec_from_file_location("dashboard_under_test", SOURCE / "app.py")
    app = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app)
    app.dashboard()

    def find(kind, label):
        return next((kwargs, node) for k, args, kwargs, node in reversed(nodes)
                    if k == kind and args and args[0] == label)

    return SimpleNamespace(
        app=app, ui=ui, nodes=nodes, find=find, discover=discover,
        inspect=inspect, cameras=cameras, mqtt=mqtt, routes=routes,
    )


def test_discovery_consent_and_result_states(dashboard):
    target = dashboard.find("input", "Target IP(s)")[1]
    consent = dashboard.find("checkbox", "Allow WS-Discovery multicast on the local network")[1]
    assert consent.value is False
    target.value = "127.0.0.1:8000"
    dashboard.discover.return_value = [
        {"host": "127.0.0.1", "port": 8000, "name": state, "status": state, "evidence": []}
        for state in ("candidate", "unreachable", "unknown")
    ]
    discover_click = dashboard.find("button", "Discover Cameras")[0]["on_click"]
    asyncio.run(discover_click())
    dashboard.discover.assert_awaited_once_with(
        timeout=5, target_hosts="127.0.0.1:8000", multicast=False,
    )
    labels = [args[0] for kind, args, _, _ in dashboard.nodes if kind == "label"]
    for state in ("candidate", "unreachable", "unknown"):
        assert f"Status: {state}" in labels
    assert len([n for n in dashboard.nodes if n[0] == "button" and n[1] == ("Add",)]) == 1
    dashboard.inspect.assert_not_called()
    assert dashboard.find("input", "Username")[1].value == ""
    assert dashboard.find("input", "Password")[1].value == ""
    dashboard.find("input", "Username")[1].value = "operator"
    dashboard.find("input", "Password")[1].value = "provided"
    asyncio.run(dashboard.find("button", "Add")[0]["on_click"]())
    dashboard.inspect.assert_called_once_with("127.0.0.1", 8000, "operator", "provided")
    assert "candidate" in dashboard.cameras
    target.value = ""
    consent.value = True
    asyncio.run(discover_click())
    dashboard.discover.assert_awaited_with(timeout=5, target_hosts=None, multicast=True)


def test_discovery_error_clears_loading(dashboard):
    dashboard.discover.side_effect = ValueError("Invalid scope")
    kwargs, button = dashboard.find("button", "Discover Cameras")
    asyncio.run(kwargs["on_click"]())
    dashboard.ui.notify.assert_called_once_with("Discovery error: Invalid scope", type="negative")
    button.props.assert_called_with(remove="loading")


def test_existing_dashboard_features(dashboard):
    assert dashboard.cameras["env-camera"] == "rtsp://127.0.0.1/env"
    dashboard.find("input", "RTSP URL")[1].value = "rtsp://127.0.0.1/manual"
    dashboard.find("input", "Camera Name")[1].value = "manual"
    dashboard.find("button", "Add Camera")[0]["on_click"]()
    assert dashboard.cameras["manual"] == "rtsp://127.0.0.1/manual"
    html = [args[0] for kind, args, _, _ in dashboard.nodes if kind == "html"]
    assert any("/mjpeg/manual" in item for item in html)
    asyncio.run(dashboard.find("button", "Left")[0]["on_click"]())
    dashboard.mqtt.pan.assert_called_once_with("env-camera", direction="left")
    dashboard.app.on_mqtt_event("events/camera", {"type": "motion", "timestamp": "now"})
    asyncio.run(dashboard.find("button", "Refresh")[0]["on_click"]())
    log = next(node for kind, _, _, node in dashboard.nodes if kind == "log")
    log.push.assert_called_once_with("[now] events/camera: motion")
    assert set(dashboard.routes) == {"/", "/camera/{cam_id}"}
    dashboard.app.camera_view("manual")
    assert "/mjpeg/manual" in [args[0] for kind, args, _, _ in dashboard.nodes if kind == "html"][-1]
