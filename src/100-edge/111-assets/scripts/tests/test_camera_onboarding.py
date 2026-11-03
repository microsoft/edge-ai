"""Contract, proposal semantics, and private filesystem tests without camera access."""

import copy
import importlib.util
import io
import json
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "camera_onboarding.py"
SPEC = importlib.util.spec_from_file_location("asset_camera_onboarding", SCRIPT)
onboarding = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(onboarding)


@pytest.fixture
def camera():
    return {
        "display_name": "Loading dock",
        "onvif_endpoint": "http://192.0.2.10/onvif/device_service",
        "selected_profile": {
            "token": "main",
            "name": "Main stream",
            "stream_uri": "rtsp://192.0.2.10:554/main",
        },
        "inspection": {"status": "inspected", "supports_ptz": True},
        "credential_revision": "sNzI3h7p9Rq6vT2k",
        "feed_verification": {
            "status": "verified_live_feed",
            "onvif_endpoint": "http://192.0.2.10/onvif/device_service",
            "profile_token": "main",
            "stream_uri": "rtsp://192.0.2.10:554/main",
            "credential_revision": "sNzI3h7p9Rq6vT2k",
            "frame_width": 1920,
            "frame_height": 1080,
        },
        "username_secret_name": "camera-credentials/username",
        "password_secret_name": "different.camera-credentials/Password_1",
        "capture": {
            "task_type": "snapshot-to-mqtt",
            "topic": "cameras/loading-dock/snapshots",
            "snapshots_per_second": 0.2,
        },
    }


def _set(camera, path, value):
    keys = path.split(".")
    target = camera
    for key in keys[:-1]:
        target = target[key]
    target[keys[-1]] = value


def _run_cli(text, output, *arguments):
    return subprocess.run(
        [sys.executable, "-B", str(SCRIPT), "--input", "-", "--output-directory", str(output), *arguments],
        input=text, capture_output=True, text=True, check=False,
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
    )


def test_schema_and_snapshot_semantics(camera, monkeypatch):
    documents = {}
    original = onboarding._hcl

    def observe(value, level=0):
        if level == 0 and isinstance(value, list):
            documents["devices" if "endpoints" in value[0] else "assets"] = value
        return original(value, level)

    monkeypatch.setattr(onboarding, "_hcl", observe)
    rendered = onboarding.render_tfvars([camera])
    assert "should_enable_akri_onvif_connector = true" in rendered
    assert "should_enable_akri_media_connector = true" in rendered
    devices = {device["name"]: device for device in documents["devices"]}
    assert len(devices) == 2
    assert {
        endpoint["endpoint_type"]
        for device in devices.values()
        for endpoint in device["endpoints"]["inbound"].values()
    } == {"Microsoft.Onvif", "Microsoft.Media"}
    for device in devices.values():
        assert device["enabled"] is True
        endpoint = next(iter(device["endpoints"]["inbound"].values()))
        assert endpoint["authentication"] == {
            "method": "UsernamePassword",
            "usernamePasswordCredentials": {
                "usernameSecretName": camera["username_secret_name"],
                "passwordSecretName": camera["password_secret_name"],
            },
        }
    snapshot, ptz = documents["assets"]
    for asset in (snapshot, ptz):
        reference = asset["device_ref"]
        assert reference["endpoint_name"] in devices[reference["device_name"]]["endpoints"]["inbound"]
    assert snapshot["device_ref"]["device_name"].endswith("-media")
    stream, = snapshot["streams"]
    assert stream["name"] == "snapshots"
    assert json.loads(stream["stream_configuration"]) == {
        "taskType": "snapshot-to-mqtt", "autostart": True, "format": "jpeg",
        "snapshotsPerSecond": 0.2,
    }
    assert stream["destinations"] == [{
        "target": "Mqtt", "configuration": {"topic": camera["capture"]["topic"]},
    }]
    assert ptz["device_ref"]["device_name"].endswith("-onvif")
    assert ptz["management_groups"] == [{
        "name": "ptz",
        "actions": [{
            "name": action, "action_type": "Call", "target_uri": f"dtmi:onvif:ptz:{action};1",
        } for action in (
            "RelativeMove", "ContinuousMove", "Stop", "GotoHomePosition", "GotoPreset",
        )],
    }]


def test_documented_complete_contract_example():
    readme = (SCRIPT.parent / "README.md").read_text()
    documents = [
        json.loads(block.split("```", 1)[0])
        for block in readme.split("```json\n")[1:]
    ]
    document, = [value for value in documents if "cameras" in value]
    assert set(document) == {"cameras"}
    assert len(document["cameras"]) == 1
    assert "snapshot-to-mqtt" in onboarding.render_tfvars(document["cameras"])
    assert json.loads(onboarding.render_discovery(document["cameras"]))["cameras"]


def test_no_ptz_asset_without_inspected_support(camera):
    camera["inspection"]["supports_ptz"] = False
    assert "management_groups" not in onboarding.render_tfvars([camera])


@pytest.mark.parametrize("path,value", [
    ("inspection.status", "candidate"),
    ("inspection.status", "unauthorized"),
    ("inspection.supports_ptz", 1),
    ("feed_verification.status", "opened"),
    ("feed_verification.onvif_endpoint", "http://different/onvif"),
    ("feed_verification.profile_token", "different"),
    ("feed_verification.stream_uri", "rtsp://different/main"),
    ("feed_verification.credential_revision", "different-revision"),
    ("credential_revision", "short"),
    ("credential_revision", "x" * 15),
    ("credential_revision", "x" * 129),
    ("credential_revision", "x" * 15 + "/"),
    ("display_name", ""),
    ("display_name", " " * 4),
    ("display_name", "\ud800"),
    ("display_name", "x" * 257),
    ("selected_profile.token", ""),
    ("selected_profile.token", "x" * 257),
    ("selected_profile.name", ""),
    ("selected_profile.name", "x" * 257),
    ("capture.task_type", "snapshot-to-fs"),
    ("capture.topic", ""),
    ("capture.topic", " \t"),
    ("capture.topic", "a/#"),
    ("capture.topic", "+"),
    ("capture.topic", "a\0b"),
    ("capture.topic", "x" * 65536),
    ("capture.topic", "é" * 32768),
    ("capture.snapshots_per_second", 0),
    ("capture.snapshots_per_second", -0.1),
    ("capture.snapshots_per_second", True),
    ("capture.snapshots_per_second", "0.2"),
    ("capture.snapshots_per_second", None),
    ("capture.snapshots_per_second", float("nan")),
    ("capture.snapshots_per_second", float("inf")),
    ("capture.snapshots_per_second", -float("inf")),
    ("capture.snapshots_per_second", 10 ** 400),
    ("feed_verification.frame_width", 0),
    ("feed_verification.frame_height", -1),
    ("feed_verification.frame_width", 1.0),
    ("feed_verification.frame_height", True),
])
def test_reject_invalid_contract_before_io(camera, path, value, tmp_path):
    _set(camera, path, value)
    output = tmp_path / "must-not-exist"
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs([camera], output)
    assert not output.exists()
    assert list(tmp_path.iterdir()) == []


@pytest.mark.parametrize("path", [
    "display_name", "onvif_endpoint", "selected_profile", "selected_profile.token",
    "selected_profile.name", "selected_profile.stream_uri", "inspection",
    "inspection.supports_ptz", "credential_revision", "feed_verification",
    "feed_verification.frame_width", "feed_verification.credential_revision",
    "capture", "capture.topic", "capture.snapshots_per_second", "capture.task_type",
    "username_secret_name", "password_secret_name",
])
def test_missing_required_fields(camera, path):
    keys = path.split(".")
    target = camera if len(keys) == 1 else camera[keys[0]]
    del target[keys[-1]]
    with pytest.raises(onboarding.OnboardingError):
        onboarding.render_tfvars([camera])


@pytest.mark.parametrize("section", [
    None, "selected_profile", "inspection", "feed_verification", "capture",
])
@pytest.mark.parametrize("key", ["password", "username", "credentials", "unrecognized_input"])
def test_allowlist_at_every_level(camera, section, key, tmp_path):
    target = camera if section is None else camera[section]
    target[key] = {"password": "do-not-leak"}
    with pytest.raises(onboarding.OnboardingError) as error:
        onboarding.write_onboarding_outputs([camera], tmp_path / "invalid")
    assert "do-not-leak" not in str(error.value)
    assert key not in str(error.value)
    assert list(tmp_path.iterdir()) == []


@pytest.mark.parametrize("value", [None, {}, "", [], [None], [1]])
def test_invalid_camera_arrays(value, tmp_path):
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs(value, tmp_path / "invalid")
    assert list(tmp_path.iterdir()) == []


def test_all_records_validated_not_silently_skipped(camera, tmp_path):
    invalid = copy.deepcopy(camera)
    invalid["inspection"]["status"] = "unreachable"
    invalid["selected_profile"]["token"] += "-other"
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs([camera, invalid], tmp_path / "invalid")
    assert list(tmp_path.iterdir()) == []


@pytest.mark.parametrize("reference", [
    "bare-secret", "/key", "secret/", "secret/key/more", "Secret/key",
    "-secret/key", "secret-/key", "secret..name/key", "secret/name with spaces",
    "secret/key:password", "secret/.", "secret/..", "secret/..hidden",
    "s" * 64 + "/key", "s/" + "k" * 254, "s/key\n", "a/" + "é",
    ".".join(["a" * 63] * 4) + "/key",
])
@pytest.mark.parametrize("field", ["username_secret_name", "password_secret_name"])
def test_secret_and_key_validated_separately(camera, reference, field):
    camera[field] = reference
    with pytest.raises(onboarding.OnboardingError):
        onboarding.render_tfvars([camera])


@pytest.mark.parametrize("reference", [
    "a/key", "camera.creds/User_Name-1.0", "a/.password",
    ".".join(["a" * 63] * 3 + ["b" * 61]) + "/" + "K" * 253,
])
def test_valid_secret_reference_boundaries(camera, reference):
    camera["username_secret_name"] = reference
    assert reference in onboarding.render_tfvars([camera])


@pytest.mark.parametrize("field,value", [
    ("onvif_endpoint", "http://user:do-not-leak@camera/onvif"),
    ("onvif_endpoint", "http://camera/onvif?password=do-not-leak"),
    ("onvif_endpoint", "http://camera/onvif#fragment"),
    ("onvif_endpoint", "http://camera/onvif?"),
    ("onvif_endpoint", "http://camera/onvif#"),
    ("onvif_endpoint", "http://camera:0/onvif"),
    ("onvif_endpoint", "http://camera:65536/onvif"),
    ("onvif_endpoint", "http://camera:/onvif"),
    ("onvif_endpoint", "http://[::1]junk/onvif"),
    ("onvif_endpoint", "http://[bad]/onvif"),
    ("onvif_endpoint", "http://999.0.0.1/onvif"),
    ("onvif_endpoint", "http:///onvif"),
    ("onvif_endpoint", "https://camera/%0A"),
    ("onvif_endpoint", "http://camera/%oops"),
    ("onvif_endpoint", "http://camera\\evil/onvif"),
    ("onvif_endpoint", "http://cam%40era/onvif"),
    ("onvif_endpoint", "http://camera/\n"),
    ("onvif_endpoint", "rtsp://camera/onvif"),
    ("selected_profile.stream_uri", "http://camera/main"),
    ("selected_profile.stream_uri", "rtsps://camera/main"),
    ("selected_profile.stream_uri", "rtsp://do-not-leak@camera/main"),
    ("selected_profile.stream_uri", "rtsp://camera/main?token=do-not-leak"),
])
def test_reject_unsafe_uris(camera, field, value):
    _set(camera, field, value)
    evidence_field = "stream_uri" if field.startswith("selected_profile") else field
    camera["feed_verification"][evidence_field] = value
    with pytest.raises(onboarding.OnboardingError) as error:
        onboarding.render_tfvars([camera])
    assert "do-not-leak" not in str(error.value)


@pytest.mark.parametrize("endpoint", [
    "https://camera.example:65535/onvif/device_service",
    "http://192.0.2.10:1/onvif",
    "https://[2001:db8::1]:443/onvif",
])
def test_valid_endpoint_forms(camera, endpoint):
    camera["onvif_endpoint"] = endpoint
    camera["feed_verification"]["onvif_endpoint"] = endpoint
    assert endpoint in onboarding.render_tfvars([camera])


@pytest.mark.parametrize("field", ["onvif_endpoint", "selected_profile.stream_uri"])
@pytest.mark.parametrize("length,valid", [(8192, True), (8193, False)])
def test_uri_length_boundaries(camera, field, length, valid):
    base = "http://camera/" if field == "onvif_endpoint" else "rtsp://camera/"
    value = base + "x" * (length - len(base))
    _set(camera, field, value)
    evidence_field = "stream_uri" if field.startswith("selected_profile") else field
    camera["feed_verification"][evidence_field] = value
    if valid:
        assert value in onboarding.render_tfvars([camera])
    else:
        with pytest.raises(onboarding.OnboardingError):
            onboarding.render_tfvars([camera])


def test_label_length_boundaries(camera):
    camera["display_name"] = "D" * 256
    camera["selected_profile"]["name"] = "N" * 256
    camera["selected_profile"]["token"] = "T" * 256
    camera["feed_verification"]["profile_token"] = camera["selected_profile"]["token"]
    assert camera["display_name"] in onboarding.render_tfvars([camera])


@pytest.mark.parametrize("rate", [1, 0.000001, 5e-324, 1.7976931348623157e308])
def test_positive_finite_rates(camera, rate):
    camera["capture"]["snapshots_per_second"] = rate
    camera["feed_verification"].update(frame_width=1, frame_height=1)
    camera["credential_revision"] = "R" * 128
    camera["feed_verification"]["credential_revision"] = camera["credential_revision"]
    assert "snapshot-to-mqtt" in onboarding.render_tfvars([camera])


@pytest.mark.parametrize("topic", ["x", "x" * 65535, "é" * 32767 + "x", "a//b"])
def test_mqtt_utf8_topic_boundaries(camera, topic):
    camera["capture"]["topic"] = topic
    assert onboarding.render_tfvars([camera])


def test_hcl_literal_escaping_including_map_keys(camera):
    camera["display_name"] = '${value} %{if true} "quoted" \\path'
    camera["capture"]["topic"] = "cameras/${value}/%{value}"
    camera["selected_profile"]["stream_uri"] += "/${value}"
    camera["feed_verification"]["stream_uri"] = camera["selected_profile"]["stream_uri"]
    rendered = onboarding.render_tfvars([camera])
    assert '$${value} %%{if true} \\"quoted\\" \\\\path' in rendered
    assert "cameras/$${value}/%%{value}" in rendered
    assert "/$${value}" in rendered
    assert onboarding._hcl({"${key}": "%{value}"}) == '{\n  "$${key}" = "%%{value}"\n}'
    assert "${value}" in onboarding.render_discovery([camera])
    assert "$${value}" not in onboarding.render_discovery([camera])


def test_hcl_non_bmp_unicode_is_not_a_surrogate_escape(camera):
    camera["display_name"] = "Camera 📷"
    camera["capture"]["topic"] = "cameras/📷"
    rendered = onboarding.render_tfvars([camera])
    assert '"Camera 📷"' in rendered
    assert '"cameras/📷"' in rendered
    assert "\\ud83d" not in rendered


def test_generated_hcl_parses_with_terraform(camera):
    terraform = shutil.which("terraform")
    if terraform is None:
        pytest.skip("Terraform is not installed; HCL parse gate requires existing tooling")
    camera["display_name"] = 'Camera 📷 ${literal} %{literal} "quoted" \\path'
    camera["capture"]["topic"] = "cameras/${literal}/%{literal}/📷"
    result = subprocess.run(
        [terraform, "fmt", "-"], input=onboarding.render_tfvars([camera]),
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    assert "$${literal}" in result.stdout
    assert "%%{literal}" in result.stdout
    assert "📷" in result.stdout


def test_identity_ordering_and_shared_rtsp(camera):
    alternatives = []
    for path, value, evidence in (
        ("onvif_endpoint", "http://other-camera/onvif", "onvif_endpoint"),
        ("selected_profile.token", "other-profile", "profile_token"),
        ("capture.topic", "other/task", None),
    ):
        alternative = copy.deepcopy(camera)
        _set(alternative, path, value)
        if evidence:
            alternative["feed_verification"][evidence] = value
        alternatives.append(alternative)
    cameras = [camera, *alternatives]
    first = onboarding.render_tfvars(cameras)
    assert first == onboarding.render_tfvars(list(reversed(cameras)))
    assert onboarding.render_discovery(cameras) == onboarding.render_discovery(list(reversed(cameras)))
    names = [entry["resource_name"] for entry in json.loads(onboarding.render_discovery(cameras))["cameras"]]
    assert len(set(names)) == 4
    assert all(len(name + "-snapshots") <= 63 for name in names)
    for alternate in alternatives:
        assert onboarding._identity(camera) != onboarding._identity(alternate)


def test_stable_identity_ignores_labels_rate_and_credential_revision(camera):
    alternate = copy.deepcopy(camera)
    alternate["display_name"] = "Renamed"
    alternate["capture"]["snapshots_per_second"] = 1
    alternate["credential_revision"] = "new-opaque-revision"
    alternate["feed_verification"]["credential_revision"] = alternate["credential_revision"]
    assert onboarding._identity(camera) == onboarding._identity(alternate)
    assert json.loads(onboarding.render_discovery([camera]))["cameras"][0]["resource_name"] == (
        json.loads(onboarding.render_discovery([alternate]))["cameras"][0]["resource_name"]
    )


def test_deterministic_digest_collision_handling(camera, monkeypatch):
    alternate = copy.deepcopy(camera)
    alternate["capture"]["topic"] = "different/task"
    monkeypatch.setattr(onboarding, "_identity_digest", lambda _identity: "a" * 40)
    assert onboarding.render_tfvars([camera, alternate]) == onboarding.render_tfvars([alternate, camera])
    entries = json.loads(onboarding.render_discovery([alternate, camera]))["cameras"]
    assert {entry["resource_name"] for entry in entries} == {"cam-" + "a" * 40 + "-1", "cam-" + "a" * 40 + "-2"}


def test_duplicate_identity_rejected_before_io(camera, tmp_path):
    with pytest.raises(onboarding.OnboardingError, match="duplicate"):
        onboarding.write_onboarding_outputs([camera, copy.deepcopy(camera)], tmp_path / "invalid")
    assert list(tmp_path.iterdir()) == []


def test_cli_direct_bytes_and_private_modes(camera, tmp_path):
    output = tmp_path / "new"
    result = _run_cli(json.dumps({"cameras": [camera]}), output)
    assert result.returncode == 0, result.stderr
    assert result.stderr == ""
    paths = json.loads(result.stdout)
    assert set(paths) == {"discovery_path", "tfvars_path"}
    discovery = Path(paths["discovery_path"])
    tfvars = Path(paths["tfvars_path"])
    assert discovery.read_bytes() == onboarding.render_discovery([camera]).encode()
    assert tfvars.read_bytes() == onboarding.render_tfvars([camera]).encode()
    assert stat.S_IMODE(output.stat().st_mode) == 0o700
    assert stat.S_IMODE(discovery.stat().st_mode) == 0o600
    assert stat.S_IMODE(tfvars.stat().st_mode) == 0o600
    assert {entry.name for entry in output.iterdir()} == {onboarding.DISCOVERY_FILENAME, onboarding.TFVARS_FILENAME}
    evidence = json.loads(discovery.read_text())
    assert set(evidence) == {"cameras"}
    assert set(evidence["cameras"][0]) == set(camera) | {"resource_name"}
    assert camera == {key: evidence["cameras"][0][key] for key in camera}


def test_private_permissions_from_creation(camera, tmp_path, monkeypatch):
    original_open = os.open
    original_mkdir = os.mkdir
    creations = []

    def observe_open(path, flags, mode=0o777, *, dir_fd=None):
        descriptor = original_open(path, flags, mode, dir_fd=dir_fd)
        if flags & os.O_CREAT:
            creations.append(("file", mode, stat.S_IMODE(os.fstat(descriptor).st_mode)))
            assert flags & os.O_EXCL
            assert flags & os.O_NOFOLLOW
        return descriptor

    def observe_mkdir(path, mode=0o777, *, dir_fd=None):
        original_mkdir(path, mode, dir_fd=dir_fd)
        creations.append(("directory", mode, stat.S_IMODE(os.stat(path, dir_fd=dir_fd).st_mode)))

    monkeypatch.setattr(onboarding.os, "open", observe_open)
    monkeypatch.setattr(onboarding.os, "mkdir", observe_mkdir)
    onboarding.write_onboarding_outputs([camera], tmp_path / "new")
    assert creations == [("directory", 0o700, 0o700), ("file", 0o600, 0o600), ("file", 0o600, 0o600)]


@pytest.mark.parametrize("kind", ["directory", "file", "symlink", "broken-symlink"])
def test_existing_target_never_modified(camera, tmp_path, kind):
    target = tmp_path / "existing"
    sentinel = tmp_path / "sentinel"
    sentinel.write_text("unchanged")
    if kind == "directory":
        target.mkdir(mode=0o755)
        (target / onboarding.DISCOVERY_FILENAME).symlink_to(sentinel)
    elif kind == "file":
        target.write_text("unchanged")
    else:
        target.symlink_to(sentinel if kind == "symlink" else tmp_path / "missing")
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs([camera], target)
    assert sentinel.read_text() == "unchanged"
    assert target.exists() or target.is_symlink()
    if kind == "file":
        assert target.read_text() == "unchanged"
    elif kind == "directory":
        assert (target / onboarding.DISCOVERY_FILENAME).is_symlink()
        assert stat.S_IMODE(target.stat().st_mode) == 0o755


def test_symlink_parent_rejected(camera, tmp_path):
    real = tmp_path / "real"
    real.mkdir()
    link = tmp_path / "link"
    link.symlink_to(real, target_is_directory=True)
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs([camera], link / "new")
    assert list(real.iterdir()) == []


@pytest.mark.parametrize("value", ["", ".", "..", "new/../target", "/", "new\0path"])
def test_unsafe_output_paths(camera, value):
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs([camera], value)


def test_missing_parent_does_not_create_directories(camera, tmp_path):
    with pytest.raises(onboarding.OnboardingError):
        onboarding.write_onboarding_outputs([camera], tmp_path / "missing" / "new")
    assert list(tmp_path.iterdir()) == []


@pytest.mark.parametrize("operation", ["write", "rename", "fsync"])
def test_partial_failures_rollback_without_success(camera, tmp_path, monkeypatch, operation):
    target = tmp_path / "new"
    attribute = {"write": "_write_file", "rename": "rename", "fsync": "fsync"}[operation]
    owner = onboarding if operation == "write" else onboarding.os
    original = getattr(owner, attribute)
    calls = 0

    def fail_second(*args, **kwargs):
        nonlocal calls
        calls += 1
        if calls == 2:
            raise OSError("sensitive filesystem error must not leak")
        return original(*args, **kwargs)

    monkeypatch.setattr(owner, attribute, fail_second)
    with pytest.raises(onboarding.OnboardingError) as error:
        onboarding.write_onboarding_outputs([camera], target)
    assert "sensitive" not in str(error.value)
    assert not target.exists()
    assert list(tmp_path.iterdir()) == []


def test_cleanup_failure_explicit_and_partial_files_remain_private(camera, tmp_path, monkeypatch):
    target = tmp_path / "new"
    original = onboarding._write_file
    calls = 0

    def fail_second(*args):
        nonlocal calls
        calls += 1
        if calls == 2:
            raise OSError("do-not-leak")
        return original(*args)

    def deny_unlink(*_args, **_kwargs):
        raise PermissionError("do-not-leak")

    with monkeypatch.context() as patch:
        patch.setattr(onboarding, "_write_file", fail_second)
        patch.setattr(onboarding.os, "unlink", deny_unlink)
        with pytest.raises(onboarding.OnboardingError, match="private partial files may remain") as error:
            onboarding.write_onboarding_outputs([camera], target)
        assert "do-not-leak" not in str(error.value)
    assert stat.S_IMODE(target.stat().st_mode) == 0o700
    assert all(stat.S_IMODE(path.stat().st_mode) == 0o600 for path in target.iterdir())
    for path in target.iterdir():
        path.unlink()
    target.rmdir()


@pytest.mark.parametrize("text", [
    "", "not JSON do-not-leak", '{"password":"do-not-leak"}',
    '{"cameras":[]}', '{"cameras":{},"password":"do-not-leak"}',
    '{"cameras":[],"cameras":[]}', '{"cameras":NaN}', '{"cameras":Infinity}',
    '{"cameras":-Infinity}', "[" * 1100,
])
def test_cli_invalid_json_or_document(text, tmp_path):
    result = _run_cli(text, tmp_path / "new")
    assert result.returncode == 2
    assert result.stdout == ""
    assert result.stderr.startswith("camera-onboarding:")
    assert "do-not-leak" not in result.stderr
    assert "Traceback" not in result.stderr
    assert list(tmp_path.iterdir()) == []


def test_cli_invalid_camera_never_echoes_credentials(camera, tmp_path):
    camera["password"] = "do-not-leak"  # noqa: S105 - Synthetic credential-rejection fixture.
    result = _run_cli(json.dumps({"cameras": [camera]}), tmp_path / "new")
    assert result.returncode == 2
    assert result.stdout == ""
    assert "do-not-leak" not in result.stderr
    assert list(tmp_path.iterdir()) == []


def test_cli_nested_duplicate_fields_rejected(camera, tmp_path):
    text = json.dumps({"cameras": [camera]}).replace(
        '"supports_ptz": true', '"supports_ptz": true, "supports_ptz": false',
    )
    result = _run_cli(text, tmp_path / "new")
    assert result.returncode == 2
    assert result.stdout == ""
    assert "duplicate" in result.stderr
    assert list(tmp_path.iterdir()) == []


def test_cli_output_error_nonzero_without_sensitive_path(camera, tmp_path):
    target = tmp_path / "do-not-leak"
    target.mkdir()
    result = _run_cli(json.dumps({"cameras": [camera]}), target)
    assert result.returncode == 2
    assert result.stdout == ""
    assert "do-not-leak" not in result.stderr
    assert list(target.iterdir()) == []


def test_cli_filesystem_failure_never_reports_success(camera, tmp_path, monkeypatch, capsys):
    def fail(*_args, **_kwargs):
        raise OSError("do-not-leak")

    monkeypatch.setattr(onboarding.os, "mkdir", fail)
    monkeypatch.setattr(onboarding.sys, "stdin", io.StringIO(json.dumps({"cameras": [camera]})))
    assert onboarding.main(["--input", "-", "--output-directory", str(tmp_path / "new")]) == 2
    stdout, stderr = capsys.readouterr()
    assert stdout == ""
    assert "do-not-leak" not in stderr
    assert list(tmp_path.iterdir()) == []


def test_cli_stdout_failure_is_nonzero_with_complete_private_outputs(camera, tmp_path, monkeypatch, capsys):
    class BrokenOutput:
        def write(self, _text):
            raise OSError("do-not-leak")

    output = tmp_path / "new"
    monkeypatch.setattr(onboarding.sys, "stdin", io.StringIO(json.dumps({"cameras": [camera]})))
    with monkeypatch.context() as patch:
        patch.setattr(onboarding.sys, "stdout", BrokenOutput())
        assert onboarding.main(["--input", "-", "--output-directory", str(output)]) == 2
    stdout, stderr = capsys.readouterr()
    assert stdout == ""
    assert "do-not-leak" not in stderr
    assert len(list(output.iterdir())) == 2
    assert all(stat.S_IMODE(path.stat().st_mode) == 0o600 for path in output.iterdir())


def test_cli_argument_errors_do_not_echo_payload(tmp_path):
    result = _run_cli("{}", tmp_path / "new", "--password", "do-not-leak")
    assert result.returncode == 2
    assert result.stdout == ""
    assert "do-not-leak" not in result.stderr


def test_cli_help_needs_no_runtime_dependencies(tmp_path):
    result = subprocess.run(
        [sys.executable, "-I", "-S", "-B", str(SCRIPT), "--help"],
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0
    assert "--input" in result.stdout
    assert result.stderr == ""
    assert list(tmp_path.iterdir()) == []


def test_isolated_stdlib_cli_generation(camera, tmp_path):
    result = subprocess.run(
        [sys.executable, "-I", "-S", "-B", str(SCRIPT), "--input", "-",
         "--output-directory", str(tmp_path / "new")],
        input=json.dumps({"cameras": [camera]}), capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    assert Path(json.loads(result.stdout)["tfvars_path"]).read_text() == onboarding.render_tfvars([camera])
