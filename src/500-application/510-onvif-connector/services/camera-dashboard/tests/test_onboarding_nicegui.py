"""Construct onboarding controls using the installed NiceGUI runtime offline."""

import importlib
import sys

import pytest


def test_real_nicegui_onboarding_controls(monkeypatch):
    nicegui = pytest.importorskip("nicegui")
    monkeypatch.delitem(sys.modules, "camera_onboarding_ui", raising=False)
    controls = importlib.import_module("camera_onboarding_ui")
    with nicegui.ui.card() as container:
        username = nicegui.ui.input("Runtime username")
        password = nicegui.ui.input("Runtime password", password=True)
        proposal = controls.render_camera_onboarding(
            {"host": "127.0.0.1", "port": 8000, "name": "Local fixture"}, username, password,
        )
        controls.render_proposal_export([proposal])
    assert proposal() is None
    assert len(container.default_slot.children) > 10
    container.delete()
