"""Revision-bound onboarding state and the fixed asset CLI subprocess adapter."""

import asyncio
import copy
import json
import math
import os
import re
import secrets
import stat
import sys
from pathlib import Path

from camera_preflight import (
    authenticated_uri,
    classify_inspection_error,
    credential_free_uri,
    inspect_camera,
    verify_rtsp_feed,
)

PACKAGED_CLI = Path("/app/camera-tools/camera_onboarding.py")
SOURCE_CLI = Path(__file__).resolve().parents[5] / "100-edge/111-assets/scripts/camera_onboarding.py"
OUTPUT_NAMES = {
    "discovery_path": "camera-discovery-results.json",
    "tfvars_path": "camera-onboarding.tfvars.example",
}


class OnboardingError(ValueError):
    """A bounded onboarding error safe to display in the dashboard."""

    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


class CameraOnboarding:
    """Keep ephemeral credentials separate from exportable evidence."""

    def __init__(self, endpoint, display_name):
        self.endpoint = endpoint
        self.display_name = display_name
        self.username = ""
        self.password = ""
        self.profile = None
        self.profiles = []
        self.inspection = None
        self.verification = None
        self.revision = secrets.token_urlsafe(24)
        self.status = "candidate"
        self.selected = False

    def edit_connection(self, endpoint, username, password):
        if (endpoint, username, password) == (self.endpoint, self.username, self.password):
            return
        self.endpoint, self.username, self.password = endpoint, username, password
        self.profiles = []
        self.profile = None
        self.inspection = None
        self._invalidate()

    def edit_profile(self, token, name, stream_uri):
        profile = {"token": token, "name": name, "stream_uri": stream_uri}
        if self.profile != profile:
            self.profile = profile
            self._invalidate()

    def _invalidate(self):
        self.revision = secrets.token_urlsafe(24)
        self.verification = None
        self.status = "inspected" if self.inspection else "candidate"

    async def inspect(self):
        self._invalidate()
        revision = self.revision
        self.inspection = None
        self.profiles = []
        self.profile = None
        self.status = "candidate"
        try:
            result = await inspect_camera(self.endpoint, self.username, self.password)
            profiles = copy.deepcopy(result["profiles"])
            for profile in profiles:
                credential_free_uri(profile["stream_uri"])
                if not profile["token"] or not profile["name"]:
                    raise ValueError("Invalid inspected profile")
            if result["status"] != "inspected" or type(result["supports_ptz"]) is not bool:
                raise ValueError("Invalid inspection")
        except asyncio.CancelledError:
            raise
        except Exception as error:
            if self.revision == revision:
                self.status = classify_inspection_error(error)["status"]
            return False
        if self.revision != revision:
            return False
        self.profiles = profiles
        self.inspection = {"status": "inspected", "supports_ptz": result["supports_ptz"]}
        self.status = "inspected"
        return True

    async def verify(self):
        if not self.inspection or not self.profile:
            raise OnboardingError("incomplete", "Inspect and explicitly select a profile first")
        self._invalidate()
        revision = self.revision
        binding = {
            "onvif_endpoint": credential_free_uri(self.endpoint, ("http", "https")),
            "profile_token": self.profile["token"],
            "stream_uri": credential_free_uri(self.profile["stream_uri"]),
            "credential_revision": revision,
        }
        uri = authenticated_uri(self.profile["stream_uri"], self.username, self.password)
        try:
            result = await asyncio.to_thread(verify_rtsp_feed, uri)
        except asyncio.CancelledError:
            raise
        except Exception:
            if self.revision == revision:
                self.status = "feed_verification_failed"
            return False
        if self.revision != revision:
            return False
        self.status = result["status"]
        if self.status != "verified_live_feed":
            return False
        self.verification = {**result, **binding}
        return True

    def proposal(self, topic, snapshots_per_second, username_secret, password_secret):
        if not self.selected or not self.inspection or not self.profile or not self.verification:
            raise OnboardingError("incomplete", "Select an inspected camera with decoded-frame evidence")
        try:
            rate = float(snapshots_per_second)
            if not math.isfinite(rate) or rate <= 0:
                raise ValueError
        except (ValueError, TypeError, OverflowError):
            raise OnboardingError("capture", "Enter a positive finite snapshot rate") from None
        if not isinstance(topic, str) or not topic.strip() or "+" in topic or "#" in topic:
            raise OnboardingError("capture", "Enter an explicit MQTT publish topic without wildcards")
        for reference in (username_secret, password_secret):
            if not isinstance(reference, str) or not re.fullmatch(
                r"[a-z0-9][a-z0-9.-]*/[A-Za-z0-9._-]+", reference,
            ):
                raise OnboardingError("secret", "Enter Kubernetes secret-name/key references")
        profile = {**self.profile, "stream_uri": credential_free_uri(self.profile["stream_uri"])}
        endpoint = credential_free_uri(self.endpoint, ("http", "https"))
        expected = {
            "onvif_endpoint": endpoint, "profile_token": profile["token"],
            "stream_uri": profile["stream_uri"], "credential_revision": self.revision,
        }
        if any(self.verification.get(key) != value for key, value in expected.items()):
            raise OnboardingError("stale", "Camera selection changed; verify its feed again")
        return {
            "display_name": self.display_name, "onvif_endpoint": endpoint,
            "selected_profile": profile, "inspection": dict(self.inspection),
            "credential_revision": self.revision, "feed_verification": dict(self.verification),
            "username_secret_name": username_secret, "password_secret_name": password_secret,
            "capture": {
                "task_type": "snapshot-to-mqtt", "topic": topic, "snapshots_per_second": rate,
            },
        }


def asset_cli_path():
    """Resolve only the repository CLI or its fixed packaged location."""
    configured = os.environ.get("CAMERA_ONBOARDING_CLI")
    if configured is not None and configured != str(PACKAGED_CLI):
        raise OnboardingError("missing_cli", "Only the fixed packaged asset CLI path is supported")
    path = PACKAGED_CLI if configured is not None else SOURCE_CLI
    if not path.is_file():
        raise OnboardingError("missing_cli", "Asset CLI is missing; use the repository tree or dashboard image")
    return path


def sanitized_proposal(camera):
    """Reject unexpected fields and sanitize both sides of the evidence binding."""
    try:
        if set(camera) != {
            "display_name", "onvif_endpoint", "selected_profile", "inspection",
            "credential_revision", "feed_verification", "username_secret_name",
            "password_secret_name", "capture",
        }:
            raise ValueError
        expected = {
            "selected_profile": {"token", "name", "stream_uri"},
            "inspection": {"status", "supports_ptz"},
            "feed_verification": {
                "status", "onvif_endpoint", "profile_token", "stream_uri",
                "credential_revision", "frame_width", "frame_height",
            },
            "capture": {"task_type", "topic", "snapshots_per_second"},
        }
        for field, keys in expected.items():
            if not isinstance(camera[field], dict) or set(camera[field]) != keys:
                raise ValueError
        result = copy.deepcopy(camera)
        result["onvif_endpoint"] = credential_free_uri(result["onvif_endpoint"], ("http", "https"))
        result["selected_profile"]["stream_uri"] = credential_free_uri(
            result["selected_profile"]["stream_uri"],
        )
        verification = result["feed_verification"]
        verification["onvif_endpoint"] = credential_free_uri(
            verification["onvif_endpoint"], ("http", "https"),
        )
        verification["stream_uri"] = credential_free_uri(verification["stream_uri"])
        return result
    except (ValueError, KeyError, TypeError):
        raise OnboardingError("input", "Invalid camera proposal fields") from None


async def _drain(task):
    """Finish child-process cleanup despite repeated cancellation requests."""
    while not task.done():
        try:
            await asyncio.shield(task)
        except asyncio.CancelledError:
            continue
    return task.result()


async def generate_proposal(cameras, output_directory):
    """Pass sanitized JSON over stdin to the single, standard-library renderer."""
    cli = asset_cli_path()
    if not isinstance(cameras, list) or not cameras:
        raise OnboardingError("input", "Select at least one verified camera")
    cameras = [sanitized_proposal(camera) for camera in cameras]
    try:
        output = Path(output_directory).absolute()
        if output.exists() or output.is_symlink() or not output.parent.is_dir():
            raise OSError
        payload = json.dumps({"cameras": cameras}, allow_nan=False).encode("utf-8")
    except (OSError, ValueError, TypeError):
        raise OnboardingError("filesystem", "Choose a new output directory beneath an existing parent") from None
    process = None
    try:
        spawn = asyncio.create_task(asyncio.create_subprocess_exec(
            sys.executable, str(cli), "--input", "-", "--output-directory", str(output),
            stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        ))
        try:
            process = await asyncio.shield(spawn)
        except asyncio.CancelledError:
            process = await _drain(spawn)
            raise
        stdout, _stderr = await process.communicate(payload)
        if process.returncode:
            raise OnboardingError("nonzero", "Asset CLI rejected the proposal or could not write private output")
    except asyncio.CancelledError:
        if process is not None:
            if process.returncode is None:
                try:
                    process.kill()
                except ProcessLookupError:
                    pass
            await _drain(asyncio.create_task(process.wait()))
        raise
    except OSError:
        raise OnboardingError("filesystem", "Unable to execute the asset CLI") from None
    try:
        result = json.loads(stdout)
        if not isinstance(result, dict) or set(result) != set(OUTPUT_NAMES):
            raise ValueError
        directory_mode = output.lstat().st_mode
        if not stat.S_ISDIR(directory_mode) or directory_mode & 0o077:
            raise ValueError
        for key, filename in OUTPUT_NAMES.items():
            path = Path(result[key])
            if path != output / filename:
                raise ValueError
            mode = path.lstat().st_mode
            if not stat.S_ISREG(mode) or mode & 0o077:
                raise ValueError
        return result
    except (OSError, ValueError, TypeError, KeyError, UnicodeError):
        raise OnboardingError("malformed_result", "Asset CLI did not return valid private output paths") from None
