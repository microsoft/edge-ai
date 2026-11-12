"""Exercise revision invalidation, subprocess boundaries, and real CLI output."""

import asyncio
import copy
import json
import stat
import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

import camera_onboarding as onboarding
import pytest


@pytest.fixture
def camera(monkeypatch):
    state = onboarding.CameraOnboarding("http://camera/onvif/device_service", "Lobby")
    state.edit_connection(state.endpoint, "operator", "sensitive-password")
    monkeypatch.setattr(onboarding, "inspect_camera", AsyncMock(return_value={
        "status": "inspected", "supports_ptz": True,
        "profiles": [{
            "token": "main", "name": "Main",
            "stream_uri": "rtsp://operator:sensitive-password@camera/live?token=private",
        }],
    }))
    monkeypatch.setattr(onboarding, "verify_rtsp_feed", MagicMock(return_value={
        "status": "verified_live_feed", "frame_width": 640, "frame_height": 480,
    }))
    assert asyncio.run(state.inspect())
    state.edit_profile(**state.profiles[0])
    assert asyncio.run(state.verify())
    state.selected = True
    return state


def proposal(camera):
    return camera.proposal("lobby/snapshots", "0.5", "camera-auth/username", "camera-auth/password")


def test_evidence_has_opaque_revision_and_no_credentials(camera):
    document = proposal(camera)
    serialized = json.dumps(document)
    assert document["feed_verification"]["credential_revision"] == camera.revision
    assert len(camera.revision) >= 16
    assert document["inspection"]["supports_ptz"] is True
    for secret in ("operator:", "sensitive-password", "?token", "private"):
        assert secret not in serialized
    assert "password" not in camera.revision


@pytest.mark.parametrize("field", ["endpoint", "username", "password", "token", "name", "stream_uri"])
def test_every_binding_edit_invalidates_frame(camera, field):
    revision = camera.revision
    if field in ("endpoint", "username", "password"):
        values = {key: getattr(camera, key) for key in ("endpoint", "username", "password")}
        values[field] += "-edited"
        camera.edit_connection(**values)
        assert camera.inspection is None
    else:
        values = dict(camera.profile)
        values[field] += "-edited"
        camera.edit_profile(**values)
    assert camera.revision != revision
    assert camera.verification is None
    with pytest.raises(onboarding.OnboardingError):
        proposal(camera)


@pytest.mark.parametrize("operation", ["inspect", "verify"])
@pytest.mark.parametrize("edit", ["credentials", "endpoint", "profile", "uri"])
def test_inflight_results_cannot_install_stale_evidence(camera, monkeypatch, operation, edit):
    async def scenario():
        started = asyncio.Event()
        finish = asyncio.Event()

        async def inspect(*_args):
            started.set()
            await finish.wait()
            return {"status": "inspected", "supports_ptz": True, "profiles": []}

        async def decode(_function, *_args):
            started.set()
            await finish.wait()
            return {"status": "verified_live_feed", "frame_width": 1, "frame_height": 1}

        monkeypatch.setattr(onboarding, "inspect_camera", inspect)
        monkeypatch.setattr(onboarding.asyncio, "to_thread", decode)
        task = asyncio.create_task(getattr(camera, operation)())
        await started.wait()
        if edit == "credentials":
            camera.edit_connection(camera.endpoint, "new-user", "new-password")
        elif edit == "endpoint":
            camera.edit_connection(camera.endpoint + "-new", camera.username, camera.password)
        else:
            camera.edit_profile("new" if edit == "profile" else "main", "Main", "rtsp://camera/new")
        finish.set()
        assert await task is False
        assert camera.verification is None
        if operation == "inspect":
            assert camera.inspection is None

    asyncio.run(scenario())


@pytest.mark.parametrize("rate", ["", "0", "-1", "nan", "inf", "not-a-number"])
def test_rate_must_be_explicit_positive_finite(camera, rate):
    with pytest.raises(onboarding.OnboardingError, match="positive finite"):
        camera.proposal("lobby/snapshots", rate, "auth/username", "auth/password")


def test_explicit_selection_topic_and_secret_key_are_required(camera):
    for topic, username in [("", "auth/username"), ("lobby/#", "auth/username"), ("lobby", "bare-name")]:
        with pytest.raises(onboarding.OnboardingError):
            camera.proposal(topic, 1, username, "auth/password")
    camera.selected = False
    with pytest.raises(onboarding.OnboardingError):
        proposal(camera)


def test_no_stale_directly_mutated_evidence(camera):
    camera.verification["profile_token"] = camera.profile["token"] + "-other"
    with pytest.raises(onboarding.OnboardingError, match="changed"):
        proposal(camera)


def test_actual_cli_contract_private_output(camera, tmp_path):
    output = tmp_path / "proposal"
    result = asyncio.run(onboarding.generate_proposal([proposal(camera)], output))
    assert set(result) == {"discovery_path", "tfvars_path"}
    assert stat.S_IMODE(output.stat().st_mode) == 0o700
    for path in result.values():
        artifact = Path(path)
        assert stat.S_IMODE(artifact.stat().st_mode) == 0o600
        assert "sensitive-password" not in artifact.read_text()
        assert "operator:" not in artifact.read_text()
    assert "snapshot-to-mqtt" in Path(result["tfvars_path"]).read_text()
    with pytest.raises(onboarding.OnboardingError) as error:
        asyncio.run(onboarding.generate_proposal([proposal(camera)], output))
    assert error.value.code == "filesystem"


def test_fixed_cli_paths_only(monkeypatch):
    monkeypatch.setenv("CAMERA_ONBOARDING_CLI", "/untrusted/script.py")
    with pytest.raises(onboarding.OnboardingError) as error:
        onboarding.asset_cli_path()
    assert error.value.code == "missing_cli"
    monkeypatch.delenv("CAMERA_ONBOARDING_CLI")
    monkeypatch.setattr(onboarding, "SOURCE_CLI", Path("missing-cli.py"))
    with pytest.raises(onboarding.OnboardingError) as error:
        onboarding.asset_cli_path()
    assert error.value.code == "missing_cli"


def test_subprocess_uses_interpreter_stdin_sanitization_and_no_shell(camera, tmp_path, monkeypatch):
    process = MagicMock(returncode=2, communicate=AsyncMock(return_value=(b"", b"secret diagnostics")))
    spawn = AsyncMock(return_value=process)
    monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", spawn)
    document = proposal(camera)
    document["selected_profile"]["stream_uri"] = "rtsp://user:sensitive-password@camera/live?token=private"
    document["feed_verification"]["stream_uri"] = document["selected_profile"]["stream_uri"]
    with pytest.raises(onboarding.OnboardingError) as error:
        asyncio.run(onboarding.generate_proposal([document], tmp_path / "new"))
    assert error.value.code == "nonzero" and "secret" not in str(error.value)
    args, kwargs = spawn.call_args
    assert args[:4] == (sys.executable, str(onboarding.SOURCE_CLI), "--input", "-")
    assert set(kwargs) == {"stdin", "stdout", "stderr"}
    assert "sensitive-password" not in str(args)
    sent = process.communicate.call_args.args[0]
    assert b"sensitive-password" not in sent and b"?token" not in sent
    assert set(json.loads(sent)) == {"cameras"}


@pytest.mark.parametrize("stdout", [b"not json", b"[]", b'{"discovery_path":"/elsewhere"}', b"\xff"])
def test_malformed_subprocess_result(camera, tmp_path, monkeypatch, stdout):
    process = MagicMock(returncode=0, communicate=AsyncMock(return_value=(stdout, b"secret")))
    monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", AsyncMock(return_value=process))
    with pytest.raises(onboarding.OnboardingError) as error:
        asyncio.run(onboarding.generate_proposal([proposal(camera)], tmp_path / "new"))
    assert error.value.code == "malformed_result"


def test_subprocess_filesystem_error(camera, tmp_path, monkeypatch):
    monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", AsyncMock(side_effect=OSError("secret")))
    with pytest.raises(onboarding.OnboardingError) as error:
        asyncio.run(onboarding.generate_proposal([proposal(camera)], tmp_path / "new"))
    assert error.value.code == "filesystem" and "secret" not in str(error.value)


def test_cancellation_kills_and_waits_for_child(camera, tmp_path, monkeypatch):
    async def scenario():
        started = asyncio.Event()

        async def communicate(_payload):
            started.set()
            await asyncio.Event().wait()

        process = MagicMock(returncode=None, communicate=communicate, wait=AsyncMock())
        monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", AsyncMock(return_value=process))
        task = asyncio.create_task(onboarding.generate_proposal([proposal(camera)], tmp_path / "new"))
        await started.wait()
        task.cancel()
        with pytest.raises(asyncio.CancelledError):
            await task
        process.kill.assert_called_once()
        process.wait.assert_awaited_once()

    asyncio.run(scenario())


def test_unknown_fields_never_reach_cli(camera, tmp_path, monkeypatch):
    spawn = AsyncMock()
    monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", spawn)
    document = copy.deepcopy(proposal(camera))
    document["selected_profile"]["password"] = camera.password
    with pytest.raises(onboarding.OnboardingError) as error:
        asyncio.run(onboarding.generate_proposal([document], tmp_path / "new"))
    assert error.value.code == "input"
    spawn.assert_not_called()


@pytest.mark.parametrize("unsafe", ["outside", "symlink", "public_file", "public_directory", "missing"])
def test_output_paths_and_privacy_are_checked(camera, tmp_path, monkeypatch, unsafe):
    output = tmp_path / "new"
    output.mkdir(mode=0o700)
    paths = {key: output / name for key, name in onboarding.OUTPUT_NAMES.items()}
    for path in paths.values():
        path.write_text("{}")
        path.chmod(0o600)
    discovery = paths["discovery_path"]
    if unsafe == "outside":
        paths["discovery_path"] = tmp_path / "outside.json"
    elif unsafe == "symlink":
        discovery.unlink()
        discovery.symlink_to(paths["tfvars_path"])
    elif unsafe == "public_file":
        discovery.chmod(0o644)
    elif unsafe == "public_directory":
        output.chmod(0o755)
    else:
        discovery.unlink()
    result = json.dumps({key: str(path) for key, path in paths.items()}).encode()
    process = MagicMock(returncode=0, communicate=AsyncMock(return_value=(result, b"")))

    async def spawn(*_args, **_kwargs):
        return process

    monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", spawn)
    original_exists = Path.exists
    monkeypatch.setattr(Path, "exists", lambda path: False if path == output else original_exists(path))
    with pytest.raises(onboarding.OnboardingError) as error:
        asyncio.run(onboarding.generate_proposal([proposal(camera)], output))
    assert error.value.code == "malformed_result"


def test_cancellation_during_spawn_still_reaps_child(camera, tmp_path, monkeypatch):
    async def scenario():
        spawning = asyncio.Event()
        finish_spawn = asyncio.Event()
        process = MagicMock(returncode=None, wait=AsyncMock())

        async def spawn(*_args, **_kwargs):
            spawning.set()
            await finish_spawn.wait()
            return process

        monkeypatch.setattr(onboarding.asyncio, "create_subprocess_exec", spawn)
        task = asyncio.create_task(onboarding.generate_proposal([proposal(camera)], tmp_path / "new"))
        await spawning.wait()
        task.cancel()
        await asyncio.sleep(0)
        finish_spawn.set()
        with pytest.raises(asyncio.CancelledError):
            await task
        process.kill.assert_called_once()
        process.wait.assert_awaited_once()

    asyncio.run(scenario())
