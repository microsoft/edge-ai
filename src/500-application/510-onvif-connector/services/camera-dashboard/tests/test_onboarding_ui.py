"""Drive the actual onboarding callbacks without browser or camera services."""

import asyncio
import sys
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import camera_onboarding as onboarding
import pytest
from test_dashboard_discovery import dashboard as dashboard


def discover_candidate(dashboard):
    dashboard.discover.return_value = [{
        "host": "127.0.0.1", "port": 8000, "name": "Lobby",
        "status": "candidate", "evidence": [],
    }]
    dashboard.find("input", "Target IP(s)")[1].value = "127.0.0.1:8000"
    asyncio.run(dashboard.find("button", "Discover Cameras")[0]["on_click"]())


def inspect_and_select(dashboard, monkeypatch):
    monkeypatch.setattr(onboarding, "inspect_camera", AsyncMock(return_value={
        "status": "inspected", "supports_ptz": False,
        "profiles": [{"token": "main", "name": "Main", "stream_uri": "rtsp://camera/live"}],
    }))
    monkeypatch.setattr(onboarding, "verify_rtsp_feed", MagicMock(return_value={
        "status": "verified_live_feed", "frame_width": 8, "frame_height": 6,
    }))
    asyncio.run(dashboard.find("button", "Inspect ONVIF")[0]["on_click"]())
    _, profile = next(
        (kwargs, node) for kind, _, kwargs, node in reversed(dashboard.nodes)
        if kind == "select" and kwargs.get("label") == "Inspected media profile"
    )
    assert profile.value is None
    profile.on_value_change.call_args.args[0](SimpleNamespace(value="main"))
    asyncio.run(dashboard.find("button", "Verify decoded frame")[0]["on_click"]())


def test_ui_requires_selection_topic_rate_and_secret_keys(dashboard, monkeypatch):
    discover_candidate(dashboard)
    inspect_and_select(dashboard, monkeypatch)
    generate = AsyncMock(return_value={
        "discovery_path": "/private/camera-discovery-results.json",
        "tfvars_path": "/private/camera-onboarding.tfvars.example",
    })
    monkeypatch.setattr(sys.modules["camera_onboarding_ui"], "generate_proposal", generate)
    submit = dashboard.find("button", "Generate asset proposal")[0]["on_click"]
    asyncio.run(submit())
    generate.assert_not_called()
    dashboard.find("checkbox", "Include camera in proposal")[1].value = True
    assert dashboard.find("input", "Snapshot MQTT topic")[1].value == ""
    assert dashboard.find("input", "Snapshots per second")[1].value == ""
    dashboard.find("input", "Snapshot MQTT topic")[1].value = "lobby/snapshots"
    dashboard.find("input", "Snapshots per second")[1].value = "1"
    dashboard.find("input", "Username secret/key")[1].value = "bare-name"
    dashboard.find("input", "Password secret/key")[1].value = "auth/password"
    dashboard.find("input", "New private output directory")[1].value = "/private/new"
    asyncio.run(submit())
    generate.assert_not_called()
    dashboard.find("input", "Username secret/key")[1].value = "auth/username"
    asyncio.run(submit())
    generate.assert_awaited_once()
    documents, directory = generate.call_args.args
    assert directory == "/private/new"
    assert documents[0]["inspection"] == {"status": "inspected", "supports_ptz": False}
    assert documents[0]["capture"]["topic"] == "lobby/snapshots"
    assert documents[0]["selected_profile"]["token"] == documents[0]["feed_verification"]["profile_token"]
    assert set(dashboard.cameras) == {"env-camera"}


@pytest.mark.parametrize("control", ["ONVIF endpoint", "Username", "Password", "Selected RTSP URI"])
def test_ui_edits_invalidate_evidence_without_erasing_preview(dashboard, monkeypatch, control):
    discover_candidate(dashboard)
    inspect_and_select(dashboard, monkeypatch)
    dashboard.find("checkbox", "Include camera in proposal")[1].value = True
    node = dashboard.find("input", control)[1]
    node.value += "-edited"
    node.on_value_change.call_args.args[0](SimpleNamespace(value=node.value))
    generate = AsyncMock()
    monkeypatch.setattr(sys.modules["camera_onboarding_ui"], "generate_proposal", generate)
    asyncio.run(dashboard.find("button", "Generate asset proposal")[0]["on_click"]())
    generate.assert_not_called()
    assert set(dashboard.cameras) == {"env-camera"}


def test_ui_inspection_and_export_failures_are_safe(dashboard, monkeypatch):
    discover_candidate(dashboard)
    monkeypatch.setattr(
        onboarding, "inspect_camera", AsyncMock(side_effect=RuntimeError("rtsp://user:secret@camera")),
    )
    asyncio.run(dashboard.find("button", "Inspect ONVIF")[0]["on_click"]())
    assert "secret" not in str(dashboard.ui.notify.call_args)
    assert set(dashboard.cameras) == {"env-camera"}
