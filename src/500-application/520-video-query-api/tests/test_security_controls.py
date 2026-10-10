"""Unit tests for the video query API security controls.

These tests import the function app directly and need no deployed API,
storage account, or Event Grid namespace.
"""

import json
import sys
from pathlib import Path
from unittest.mock import MagicMock

import azure.functions as func

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import function_app  # noqa: E402


def _request(route: str, method: str = "GET", params: dict | None = None) -> func.HttpRequest:
    return func.HttpRequest(
        method=method,
        url=f"/api/{route}",
        params=params or {},
        body=b"",
    )


def _json(response: func.HttpResponse) -> dict:
    return json.loads(response.get_body())


class TestHealth:
    def test_health_returns_status_only(self, monkeypatch):
        def fail(*args, **kwargs):
            raise AssertionError("liveness must not touch storage")

        monkeypatch.setenv("STORAGE_ACCOUNT_NAME", "examplestorage")
        monkeypatch.setattr(function_app.BlobServiceClient, "from_connection_string", fail)
        monkeypatch.setattr(function_app, "BlobServiceClient", fail)

        response = function_app.health_check(_request("health"))

        assert response.status_code == 200
        assert _json(response) == {"status": "healthy"}


class TestReadiness:
    def test_ready_reports_status_only_on_success(self, monkeypatch):
        client = MagicMock()
        monkeypatch.setenv("STORAGE_CONNECTION_STRING", "UseDevelopmentStorage=true")
        monkeypatch.setattr(function_app.BlobServiceClient, "from_connection_string", lambda _cs: client)

        response = function_app.readiness_check(_request("ready"))

        assert response.status_code == 200
        assert _json(response) == {"status": "ready"}
        client.get_container_client.return_value.get_container_properties.assert_called_once()

    def test_ready_hides_failure_details(self, monkeypatch):
        client = MagicMock()
        client.get_container_client.return_value.get_container_properties.side_effect = RuntimeError(
            "account examplestorage container video-recordings denied"
        )
        monkeypatch.setenv("STORAGE_CONNECTION_STRING", "UseDevelopmentStorage=true")
        monkeypatch.setattr(function_app.BlobServiceClient, "from_connection_string", lambda _cs: client)

        response = function_app.readiness_check(_request("ready"))
        body = response.get_body().decode()

        assert response.status_code == 503
        assert json.loads(body) == {"status": "not_ready"}
        assert "examplestorage" not in body
        assert "video-recordings" not in body

    def test_ready_without_storage_configuration(self, monkeypatch):
        monkeypatch.delenv("STORAGE_CONNECTION_STRING", raising=False)
        monkeypatch.delenv("STORAGE_ACCOUNT_NAME", raising=False)

        response = function_app.readiness_check(_request("ready"))

        assert response.status_code == 503
        assert _json(response) == {"status": "not_ready"}


class TestTriggerAllowList:
    def test_trigger_disabled_without_configuration(self, monkeypatch):
        monkeypatch.delenv("TRIGGER_ALLOWED_CAMERAS", raising=False)

        response = function_app.trigger_capture(_request("trigger", "POST", {"camera": "camera-01"}))

        assert response.status_code == 503
        assert _json(response) == {"error": "Trigger not configured"}

    def test_trigger_rejects_unlisted_camera_without_echo(self, monkeypatch):
        monkeypatch.setenv("TRIGGER_ALLOWED_CAMERAS", "camera-01,camera-02")
        probe = "camera-03' OR camera_id='x"

        response = function_app.trigger_capture(_request("trigger", "POST", {"camera": probe}))
        body = response.get_body().decode()

        assert response.status_code == 400
        assert json.loads(body) == {"error": "Invalid camera"}
        assert "camera-01" not in body
        assert "OR" not in body

    def test_trigger_requires_camera_parameter(self, monkeypatch):
        monkeypatch.setenv("TRIGGER_ALLOWED_CAMERAS", "camera-01")

        response = function_app.trigger_capture(_request("trigger", "POST"))

        assert response.status_code == 400

    def test_allow_list_ignores_invalid_entries(self, monkeypatch):
        monkeypatch.setenv("TRIGGER_ALLOWED_CAMERAS", " camera-01 , bad'id, ,camera_02 ")

        assert function_app._allowed_trigger_cameras() == {"camera-01", "camera_02"}


class TestVideoQueryValidation:
    def test_rejects_unsafe_camera_parameter(self):
        response = function_app.get_video(
            _request(
                "video",
                params={
                    "camera": "camera-01' OR '1'='1",
                    "start": "2026-01-01T00:00:00Z",
                    "end": "2026-01-01T01:00:00Z",
                },
            )
        )

        assert response.status_code == 400
        assert _json(response) == {"error": "Invalid camera_id format"}

    def test_invalid_timestamp_returns_generic_message(self):
        response = function_app.get_video(
            _request(
                "video",
                params={"camera": "camera-01", "start": "not-a-time", "end": "also-not"},
            )
        )

        assert response.status_code == 400
        assert _json(response) == {"error": "Invalid timestamp format; use ISO 8601"}
