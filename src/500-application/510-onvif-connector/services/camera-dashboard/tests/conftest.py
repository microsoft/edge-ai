"""Use dashboard source modules while keeping mocked NiceGUI clients isolated."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))


@pytest.fixture(autouse=True)
def dashboard_source(monkeypatch):
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[1] / "src"))
    monkeypatch.delitem(sys.modules, "camera_onboarding_ui", raising=False)
