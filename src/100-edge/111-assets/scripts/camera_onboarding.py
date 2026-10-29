"""Generate review-only camera asset proposals using the Python standard library."""

from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import math
import os
import re
import stat
import sys
from contextlib import ExitStack
from pathlib import Path
from urllib.parse import unquote, urlsplit

DISCOVERY_FILENAME = "camera-discovery-results.json"
TFVARS_FILENAME = "camera-onboarding.tfvars.example"
PTZ_ACTIONS = (
    "RelativeMove",
    "ContinuousMove",
    "Stop",
    "GotoHomePosition",
    "GotoPreset",
)


class OnboardingError(ValueError):
    """Input or output is unsafe; messages never contain input values."""


def _object(value, keys, label):
    if not isinstance(value, dict) or set(value) != set(keys):
        raise OnboardingError(f"{label}: required fields missing or unexpected fields present")
    return value


def _text(value, label, maximum=256):
    if (
        not isinstance(value, str)
        or not value.strip()
        or len(value) > maximum
        or any(not character.isprintable() for character in value)
    ):
        raise OnboardingError(f"{label}: expected nonempty printable text")
    try:
        value.encode("utf-8")
    except UnicodeError:
        raise OnboardingError(f"{label}: invalid UTF-8 text") from None
    return value


def _dns_name(value):
    return len(value) <= 253 and all(
        re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label)
        for label in value.split(".")
    )


def _uri(value, schemes, label):
    _text(value, label, 8192)
    if (
        any(character.isspace() for character in value)
        or any(character in value for character in ("\\", "?", "#"))
        or re.search(r"%(?![0-9A-Fa-f]{2})", value)
    ):
        raise OnboardingError(f"{label}: expected credential-free URI without query or fragment")
    try:
        parsed = urlsplit(value)
        host = parsed.hostname
        port = parsed.port
        if (
            parsed.scheme not in schemes
            or not parsed.netloc
            or not host
            or parsed.username is not None
            or parsed.password is not None
            or "%" in parsed.netloc
            or (port is not None and not 1 <= port <= 65535)
            or parsed.netloc.endswith(":")
        ):
            raise ValueError
        try:
            ipaddress.ip_address(host)
        except ValueError:
            if not _dns_name(host) or re.fullmatch(r"[0-9.]+", host):
                raise ValueError from None
        authority_pattern = r"\[[0-9A-Fa-f:.]+\](?::[0-9]+)?" if ":" in host else r"[A-Za-z0-9.-]+(?::[0-9]+)?"
        if not re.fullmatch(authority_pattern, parsed.netloc):
            raise ValueError
        decoded_path = unquote(parsed.path, errors="strict")
        if any(not character.isprintable() for character in decoded_path):
            raise ValueError
    except (ValueError, UnicodeError):
        raise OnboardingError(f"{label}: invalid or credential-bearing URI") from None
    return value


def _secret_reference(value, label):
    _text(value, label, 507)
    parts = value.split("/")
    if (
        len(parts) != 2
        or not _dns_name(parts[0])
        or not re.fullmatch(r"[A-Za-z0-9._-]{1,253}", parts[1])
        or parts[1].startswith("..")
        or parts[1] == "."
    ):
        raise OnboardingError(f"{label}: expected Kubernetes secret-name/key reference")
    return value


def _topic(value):
    _text(value, "capture.topic", 65535)
    if len(value.encode("utf-8")) > 65535 or "+" in value or "#" in value:
        raise OnboardingError("capture.topic: expected MQTT publish topic without wildcards")
    return value


def _dimension(value):
    if type(value) is not int or value <= 0:
        raise OnboardingError("feed_verification: frame dimensions must be positive integers")
    return value


def _camera(value):
    value = _object(
        value,
        (
            "display_name", "onvif_endpoint", "selected_profile", "inspection",
            "credential_revision", "feed_verification", "username_secret_name",
            "password_secret_name", "capture",
        ),
        "camera",
    )
    display_name = _text(value["display_name"], "display_name")
    endpoint = _uri(value["onvif_endpoint"], {"http", "https"}, "onvif_endpoint")
    profile = _object(value["selected_profile"], ("token", "name", "stream_uri"), "selected_profile")
    profile = {
        "token": _text(profile["token"], "selected_profile.token"),
        "name": _text(profile["name"], "selected_profile.name"),
        "stream_uri": _uri(profile["stream_uri"], {"rtsp"}, "selected_profile.stream_uri"),
    }
    inspection = _object(value["inspection"], ("status", "supports_ptz"), "inspection")
    if inspection["status"] != "inspected" or type(inspection["supports_ptz"]) is not bool:
        raise OnboardingError("inspection: inspected status and boolean supports_ptz required")
    revision = value["credential_revision"]
    if not isinstance(revision, str) or not re.fullmatch(r"[A-Za-z0-9_-]{16,128}", revision):
        raise OnboardingError("credential_revision: expected opaque UI revision token (16-128 characters)")
    verification = _object(
        value["feed_verification"],
        ("status", "onvif_endpoint", "profile_token", "stream_uri", "credential_revision",
         "frame_width", "frame_height"),
        "feed_verification",
    )
    if (
        verification["status"] != "verified_live_feed"
        or verification["onvif_endpoint"] != endpoint
        or verification["profile_token"] != profile["token"]
        or verification["stream_uri"] != profile["stream_uri"]
        or verification["credential_revision"] != revision
    ):
        raise OnboardingError(
            "feed_verification: decoded frame evidence must match the current selection and credentials"
        )
    capture = _object(value["capture"], ("task_type", "topic", "snapshots_per_second"), "capture")
    if capture["task_type"] != "snapshot-to-mqtt":
        raise OnboardingError("capture.task_type: only snapshot-to-mqtt is supported")
    rate = capture["snapshots_per_second"]
    try:
        valid_rate = type(rate) in (int, float) and math.isfinite(rate) and rate > 0
    except OverflowError:
        valid_rate = False
    if not valid_rate:
        raise OnboardingError("capture.snapshots_per_second: expected positive finite number")
    return {
        "display_name": display_name,
        "onvif_endpoint": endpoint,
        "selected_profile": profile,
        "inspection": {"status": "inspected", "supports_ptz": inspection["supports_ptz"]},
        "credential_revision": revision,
        "feed_verification": {
            "status": "verified_live_feed",
            "onvif_endpoint": endpoint,
            "profile_token": profile["token"],
            "stream_uri": profile["stream_uri"],
            "credential_revision": revision,
            "frame_width": _dimension(verification["frame_width"]),
            "frame_height": _dimension(verification["frame_height"]),
        },
        "username_secret_name": _secret_reference(value["username_secret_name"], "username_secret_name"),
        "password_secret_name": _secret_reference(value["password_secret_name"], "password_secret_name"),
        "capture": {
            "task_type": "snapshot-to-mqtt",
            "topic": _topic(capture["topic"]),
            "snapshots_per_second": rate,
        },
    }


def _json(value, *, pretty=False):
    return json.dumps(
        value, ensure_ascii=True, allow_nan=False, sort_keys=True,
        indent=2 if pretty else None, separators=None if pretty else (",", ":"),
    )


def _identity(camera):
    return _json([
        camera["onvif_endpoint"], camera["selected_profile"]["token"],
        camera["selected_profile"]["stream_uri"], camera["capture"]["task_type"],
        camera["capture"]["topic"],
    ])


def _identity_digest(identity):
    return hashlib.sha256(identity.encode("utf-8")).hexdigest()[:40]


def _normalize_cameras(cameras):
    if not isinstance(cameras, list) or not cameras:
        raise OnboardingError("cameras: expected a nonempty array of inspected selections")
    normalized = [_camera(camera) for camera in cameras]
    keyed = sorted(
        ((_identity(camera), camera) for camera in normalized),
        key=lambda item: item[0],
    )
    identities = [identity for identity, _ in keyed]
    if len(set(identities)) != len(identities):
        raise OnboardingError("cameras: duplicate endpoint/profile/stream/task/topic selection")
    groups = {}
    for identity, camera in keyed:
        groups.setdefault(_identity_digest(identity), []).append(camera)
    for digest, group in groups.items():
        for index, camera in enumerate(group, 1):
            suffix = f"-{index}" if len(group) > 1 else ""
            camera["resource_name"] = f"cam-{digest}{suffix}"
    return [camera for _, camera in keyed]


def _hcl(value, level=0):
    indent = "  " * level
    child = "  " * (level + 1)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False).replace("${", "$${").replace("%{", "%%{")
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return _json(value)
    if isinstance(value, list):
        if not value:
            return "[]"
        return "[\n" + ",\n".join(child + _hcl(item, level + 1) for item in value) + f"\n{indent}]"
    if isinstance(value, dict):
        if not value:
            return "{}"
        entries = [
            f"{child}{_hcl(key)} = {_hcl(value[key], level + 1)}"
            for key in sorted(value)
        ]
        return "{\n" + "\n".join(entries) + f"\n{indent}}}"
    raise OnboardingError("Unsupported Terraform value type")


def _render_tfvars(cameras):
    devices = []
    assets = []
    for camera in cameras:
        base = camera["resource_name"]
        for role, endpoint_type, address in (
            ("onvif", "Microsoft.Onvif", camera["onvif_endpoint"]),
            ("media", "Microsoft.Media", camera["selected_profile"]["stream_uri"]),
        ):
            name = f"{base}-{role}"
            devices.append({
                "name": name,
                "enabled": True,
                "endpoints": {
                    "outbound": {"assigned": {}},
                    "inbound": {name: {
                        "endpoint_type": endpoint_type,
                        "address": address,
                        "authentication": {
                            "method": "UsernamePassword",
                            "usernamePasswordCredentials": {
                                "usernameSecretName": camera["username_secret_name"],
                                "passwordSecretName": camera["password_secret_name"],
                            },
                        },
                    }},
                },
            })
        assets.append({
            "name": f"{base}-snapshots",
            "display_name": camera["display_name"],
            "enabled": True,
            "device_ref": {"device_name": f"{base}-media", "endpoint_name": f"{base}-media"},
            "streams": [{
                "name": "snapshots",
                "stream_configuration": _json({
                    "taskType": "snapshot-to-mqtt", "autostart": True, "format": "jpeg",
                    "snapshotsPerSecond": camera["capture"]["snapshots_per_second"],
                }),
                "destinations": [{
                    "target": "Mqtt",
                    "configuration": {"topic": camera["capture"]["topic"]},
                }],
            }],
        })
        if camera["inspection"]["supports_ptz"]:
            assets.append({
                "name": f"{base}-ptz",
                "enabled": True,
                "device_ref": {"device_name": f"{base}-onvif", "endpoint_name": f"{base}-onvif"},
                "management_groups": [{
                    "name": "ptz",
                    "actions": [{
                        "name": action, "action_type": "Call",
                        "target_uri": f"dtmi:onvif:ptz:{action};1",
                    } for action in PTZ_ACTIONS],
                }],
            })
    return (
        "// Review-only proposal. Merge lists with existing resources before use.\n"
        "should_enable_akri_onvif_connector = true\n"
        "should_enable_akri_media_connector = true\n\n"
        f"namespaced_devices = {_hcl(devices)}\n\n"
        f"namespaced_assets = {_hcl(assets)}\n"
    )


def render_tfvars(cameras):
    """Validate all camera selections and return a deterministic HCL proposal."""
    return _render_tfvars(_normalize_cameras(cameras))


def render_discovery(cameras):
    """Validate and return confidential allowlisted evidence, without raw credentials."""
    return _json({"cameras": _normalize_cameras(cameras)}, pretty=True) + "\n"


def _open_parent(path, stack):
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    descriptor = os.open(path.anchor, flags)
    stack.callback(os.close, descriptor)
    for part in path.parts[1:-1]:
        descriptor = os.open(part, flags, dir_fd=descriptor)
        stack.callback(os.close, descriptor)
    return descriptor


def _write_file(directory, name, content):
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
    descriptor = os.open(name, flags, 0o600, dir_fd=directory)
    with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as output:
        output.write(content)
        output.flush()
        os.fsync(output.fileno())


def _write_private_outputs(path, outputs):
    with ExitStack() as stack:
        parent = _open_parent(path, stack)
        os.mkdir(path.name, mode=0o700, dir_fd=parent)
        directory = None
        try:
            directory = os.open(path.name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent)
            info = os.fstat(directory)
            if stat.S_IMODE(info.st_mode) != 0o700 or info.st_uid != os.geteuid():
                raise OSError("Output directory is not private")
            for name, content in outputs.items():
                _write_file(directory, name + ".partial", content)
            for name in outputs:
                os.rename(name + ".partial", name, src_dir_fd=directory, dst_dir_fd=directory)
            os.fsync(directory)
            os.fsync(parent)
        except BaseException:
            cleanup_failed = False
            if directory is not None:
                for name in outputs:
                    for candidate in (name, name + ".partial"):
                        try:
                            os.unlink(candidate, dir_fd=directory)
                        except FileNotFoundError:
                            pass
                        except OSError:
                            cleanup_failed = True
            try:
                os.rmdir(path.name, dir_fd=parent)
            except OSError:
                cleanup_failed = True
            if cleanup_failed:
                raise OnboardingError(
                    "Output failed; private partial files may remain. Remove the output directory."
                ) from None
            raise
        finally:
            if directory is not None:
                os.close(directory)


def write_onboarding_outputs(cameras, output_directory):
    """Validate before I/O, then write both private files or fail and roll back."""
    normalized = _normalize_cameras(cameras)
    outputs = {
        DISCOVERY_FILENAME: _json({"cameras": normalized}, pretty=True) + "\n",
        TFVARS_FILENAME: _render_tfvars(normalized),
    }
    if os.name != "posix" or not all(hasattr(os, flag) for flag in ("O_DIRECTORY", "O_NOFOLLOW")):
        raise OnboardingError("Private output requires a POSIX filesystem with no-follow directory operations")
    if (
        not isinstance(output_directory, (str, Path))
        or not str(output_directory).strip()
        or "\0" in str(output_directory)
    ):
        raise OnboardingError("Output directory: expected a new directory beneath an existing parent")
    supplied = Path(output_directory)
    if any(part == ".." for part in supplied.parts) or supplied.name in ("", ".", ".."):
        raise OnboardingError("Output directory: unsafe path")
    path = supplied.absolute()
    try:
        _write_private_outputs(path, outputs)
    except OSError:
        raise OnboardingError(
            "Output failed: use a new directory beneath an existing, accessible, nonsymlink parent"
        ) from None
    return path / DISCOVERY_FILENAME, path / TFVARS_FILENAME


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise OnboardingError("Input JSON contains duplicate fields")
        result[key] = value
    return result


def _reject_constant(_value):
    raise OnboardingError("Input JSON contains a nonfinite number")


class _ArgumentParser(argparse.ArgumentParser):
    def error(self, _message):
        self.exit(2, "camera-onboarding: invalid CLI arguments; use --help\n")


def main(argv=None):
    """Read the exact stdin contract and print paths only after successful writes."""
    parser = _ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, choices=["-"], help="Read sanitized JSON from stdin")
    parser.add_argument("--output-directory", required=True, help="New private directory; parent must exist")
    args = parser.parse_args(argv)
    try:
        document = json.load(sys.stdin, object_pairs_hook=_unique_object, parse_constant=_reject_constant)
        _object(document, ("cameras",), "input")
        discovery_path, tfvars_path = write_onboarding_outputs(document["cameras"], args.output_directory)
        print(_json({"discovery_path": str(discovery_path), "tfvars_path": str(tfvars_path)}), flush=True)
    except OnboardingError as error:
        print(f"camera-onboarding: {error}", file=sys.stderr)
        return 2
    except (OSError, ValueError, UnicodeError, RecursionError):
        print("camera-onboarding: unable to read valid input or write private output", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
