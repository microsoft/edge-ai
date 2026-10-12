"""Deterministic camera onboarding output and RTSP feed verification."""

import hashlib
import json
import re
import time
from pathlib import Path
from urllib.parse import SplitResult, urlsplit, urlunsplit


class OnboardingError(ValueError):
    """Raised when onboarding state is incomplete or unsafe to render."""


def classify_inspection_error(error):
    """Classify ONVIF inspection failures without retaining sensitive details."""
    message = str(error).lower()
    if any(
        marker in message
        for marker in ("unauthorized", "not authorized", "401", "authentication")
    ):
        return {
            "status": "unauthorized",
            "error": "ONVIF authentication was rejected",
        }
    if any(
        marker in message
        for marker in ("not supported", "no service", "404", "method not allowed")
    ):
        return {
            "status": "unsupported",
            "error": "The endpoint does not expose the required ONVIF services",
        }
    if any(
        marker in message
        for marker in ("connection refused", "timed out", "timeout", "unreachable")
    ):
        return {
            "status": "unreachable",
            "error": "The ONVIF endpoint could not be reached",
        }
    return {
        "status": "unknown",
        "error": "ONVIF inspection failed for an unknown reason",
    }


def credential_free_uri(uri):
    """Remove user information from a URI without changing its endpoint."""
    parsed = urlsplit(uri)
    if not parsed.hostname:
        raise OnboardingError("Stream URI must include a host")
    if parsed.query or parsed.fragment:
        raise OnboardingError(
            "Credential-bearing or tokenized stream URI parameters cannot be rendered"
        )
    host = f"[{parsed.hostname}]" if ":" in parsed.hostname else parsed.hostname
    netloc = f"{host}:{parsed.port}" if parsed.port else host
    return urlunsplit(
        SplitResult(parsed.scheme, netloc, parsed.path, parsed.query, parsed.fragment)
    )


def verify_rtsp_feed(rtsp_uri, timeout_seconds=10):
    """Verify an RTSP stream by receiving and decoding at least one frame."""
    import cv2

    capture = cv2.VideoCapture()
    capture.set(cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, timeout_seconds * 1000)
    capture.set(cv2.CAP_PROP_READ_TIMEOUT_MSEC, timeout_seconds * 1000)
    deadline = time.monotonic() + timeout_seconds
    try:
        if not capture.open(rtsp_uri):
            return {
                "status": "feed_verification_failed",
                "error": "RTSP stream could not be opened",
            }
        while time.monotonic() < deadline:
            received, frame = capture.read()
            if received and frame is not None and frame.size:
                return {
                    "status": "verified_live_feed",
                    "frame_width": int(frame.shape[1]),
                    "frame_height": int(frame.shape[0]),
                }
        return {
            "status": "feed_verification_failed",
            "error": "No decodable frame was received before the timeout",
        }
    finally:
        capture.release()


def write_onboarding_outputs(cameras, output_directory):
    """Write confidential evidence and a deterministic Terraform proposal."""
    normalized = _normalize_cameras(cameras)
    tfvars = render_tfvars(normalized)
    discovery_results = [_sanitize_discovery_record(camera) for camera in cameras]
    output_path = Path(output_directory)
    output_path.mkdir(mode=0o700, parents=True, exist_ok=True)

    discovery_path = output_path / "camera-discovery-results.json"
    tfvars_path = output_path / "camera-onboarding.tfvars.example"

    discovery_path.write_text(
        json.dumps(
            {"cameras": discovery_results}, indent=2, sort_keys=True
        ) + "\n",
        encoding="utf-8",
    )
    discovery_path.chmod(0o600)
    tfvars_path.write_text(tfvars, encoding="utf-8")
    tfvars_path.chmod(0o600)
    return discovery_path, tfvars_path


def render_tfvars(cameras):
    """Render verified camera selections using current blueprint variable types."""
    normalized = _normalize_cameras(cameras)
    devices = []
    assets = []
    for camera in normalized:
        if camera["feed_verification"]["status"] != "verified_live_feed":
            raise OnboardingError(
                f"Camera '{camera['name']}' does not have a verified live feed"
            )

        endpoint_name = f"{camera['name']}-media"
        devices.append(
            {
                "name": camera["name"],
                "enabled": True,
                "endpoints": {
                    "outbound": {"assigned": {}},
                    "inbound": {
                        endpoint_name: {
                            "endpoint_type": "Microsoft.Media",
                            "address": credential_free_uri(
                                camera["selected_profile"]["stream_uri"]
                            ),
                            "authentication": {
                                "method": "UsernamePassword",
                                "usernamePasswordCredentials": {
                                    "usernameSecretName": camera[
                                        "username_secret_name"
                                    ],
                                    "passwordSecretName": camera[
                                        "password_secret_name"
                                    ],
                                },
                            },
                        }
                    },
                },
            }
        )

        attributes = {
            "feedVerification": "frame-received",
            "onvifProfileName": camera["selected_profile"]["name"],
            "onvifProfileToken": camera["selected_profile"]["token"],
            "streamUri": credential_free_uri(
                camera["selected_profile"]["stream_uri"]
            ),
        }
        _add_verified_profile_attributes(attributes, camera["selected_profile"])
        assets.append(
            {
                "name": f"{camera['name']}-asset",
                "display_name": camera["display_name"],
                "enabled": True,
                "device_ref": {
                    "device_name": camera["name"],
                    "endpoint_name": endpoint_name,
                },
                "manufacturer": camera["device"].get("manufacturer"),
                "model": camera["device"].get("model"),
                "serial_number": camera["device"].get("serial_number"),
                "software_revision": camera["device"].get("firmware_version"),
                "attributes": attributes,
                "streams": [
                    {
                        "name": _stable_name(camera["selected_profile"]["name"]),
                        "stream_configuration": json.dumps(
                            {
                                "profileToken": camera["selected_profile"]["token"],
                                "streamUri": credential_free_uri(
                                    camera["selected_profile"]["stream_uri"]
                                ),
                                "verification": "frame-received",
                            },
                            separators=(",", ":"),
                            sort_keys=True,
                        ),
                    }
                ],
            }
        )

    document = {
        "should_enable_akri_media_connector": True,
        "namespaced_devices": devices,
        "namespaced_assets": assets,
    }
    return "\n".join(
        [
            "// Generated camera onboarding proposal. Review before use; do not auto-apply.",
            f"should_enable_akri_media_connector = {_render_hcl(document['should_enable_akri_media_connector'])}",
            "",
            f"namespaced_devices = {_render_hcl(document['namespaced_devices'])}",
            "",
            f"namespaced_assets = {_render_hcl(document['namespaced_assets'])}",
            "",
        ]
    )


def _normalize_cameras(cameras):
    normalized = []
    names = {}
    endpoints = set()
    for camera in cameras:
        if not camera.get("selected"):
            continue
        required = (
            "display_name",
            "device",
            "selected_profile",
            "feed_verification",
            "username_secret_name",
            "password_secret_name",
        )
        missing = [key for key in required if not camera.get(key)]
        if missing:
            raise OnboardingError(
                f"Selected camera is missing required fields: {', '.join(missing)}"
            )
        if camera["feed_verification"]["status"] != "verified_live_feed":
            raise OnboardingError(
                f"Camera '{camera['display_name']}' does not have a verified live feed"
            )
        stream_uri = camera["selected_profile"].get("stream_uri", "")
        if not stream_uri.lower().startswith("rtsp://"):
            raise OnboardingError("Selected profile must provide an RTSP stream URI")
        if (
            camera["feed_verification"].get("profile_token")
            != camera["selected_profile"].get("token")
        ):
            raise OnboardingError(
                "The selected media profile has not received a verified frame"
            )
        if not _valid_secret_name(camera["username_secret_name"]):
            raise OnboardingError("Username secret name is invalid")
        if not _valid_secret_name(camera["password_secret_name"]):
            raise OnboardingError("Password secret name is invalid")

        base_name = _stable_name(camera["display_name"])
        endpoint_key = credential_free_uri(stream_uri)
        if endpoint_key in endpoints:
            continue
        endpoints.add(endpoint_key)
        if base_name in names and names[base_name] != endpoint_key:
            suffix = hashlib.sha256(endpoint_key.encode("utf-8")).hexdigest()[:8]
            name = f"{base_name[:54]}-{suffix}"
        else:
            name = base_name
        names[name] = endpoint_key

        safe_camera = {
            **camera,
            "name": name,
            "selected_profile": {
                **camera["selected_profile"],
                "stream_uri": endpoint_key,
            },
        }
        normalized.append(safe_camera)

    if not normalized:
        raise OnboardingError("Select at least one camera for output")
    return sorted(normalized, key=lambda camera: (camera["name"], camera["display_name"]))


def _sanitize_discovery_record(camera):
    record = json.loads(json.dumps(camera))
    profile = record.get("selected_profile")
    if profile and profile.get("stream_uri"):
        profile["stream_uri"] = credential_free_uri(profile["stream_uri"])
    inspection = record.get("inspection") or {}
    inspection_profiles = inspection.get("profiles", [])
    for inspection_profile in inspection_profiles:
        if inspection_profile.get("stream_uri"):
            inspection_profile["stream_uri"] = credential_free_uri(
                inspection_profile["stream_uri"]
            )
    return record


def _add_verified_profile_attributes(attributes, profile):
    mapping = {
        "encoding": "encoding",
        "resolution": "resolution",
        "frame_rate": "frameRate",
        "bitrate_kbps": "bitrateKbps",
        "supports_ptz": "supportsPtz",
    }
    for source, target in mapping.items():
        value = profile.get(source)
        if value is not None:
            attributes[target] = str(value).lower() if isinstance(value, bool) else str(value)


def _stable_name(value):
    name = re.sub(r"[^a-z0-9-]+", "-", value.strip().lower())
    name = re.sub(r"-+", "-", name).strip("-")
    if not name:
        raise OnboardingError("Camera and profile names must contain letters or numbers")
    return name[:63]


def _valid_secret_name(value):
    return bool(re.fullmatch(r"[a-z0-9](?:[-a-z0-9]*[a-z0-9])?", value))


def _render_hcl(value, level=0):
    indent = "  " * level
    child_indent = "  " * (level + 1)
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        if not value:
            return "[]"
        items = [f"{child_indent}{_render_hcl(item, level + 1)}" for item in value]
        return "[\n" + ",\n".join(items) + f"\n{indent}]"
    if isinstance(value, dict):
        entries = []
        for key in sorted(value):
            item = value[key]
            if item is None:
                continue
            rendered_key = (
                key
                if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_-]*", key)
                else json.dumps(key)
            )
            entries.append((rendered_key, item))
        if not entries:
            return "{}"
        widths = {}
        scalar_group = []
        for index, (key, item) in enumerate(entries + [(None, {})]):
            if not isinstance(item, (dict, list)):
                scalar_group.append((index, key))
                continue
            if scalar_group:
                width = max(len(group_key) for _, group_key in scalar_group)
                widths.update(
                    {group_index: width for group_index, _ in scalar_group}
                )
                scalar_group = []
        items = []
        for index, (key, item) in enumerate(entries):
            rendered_key = key.ljust(widths.get(index, len(key)))
            items.append(
                f"{child_indent}{rendered_key} = "
                f"{_render_hcl(item, level + 1)}"
            )
        return "{\n" + "\n".join(items) + f"\n{indent}}}"
    raise OnboardingError(f"Unsupported Terraform value type: {type(value).__name__}")
