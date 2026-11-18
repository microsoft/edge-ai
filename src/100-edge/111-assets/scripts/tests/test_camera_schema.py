"""Check camera proposals against the repository's actual Terraform types."""

import json
import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[5]
BLUEPRINT = ROOT / "blueprints/full-multi-node-cluster/terraform/variables.tf"
COMPONENT = ROOT / "src/100-edge/111-assets/terraform/variables.tf"
CLI = ROOT / "src/100-edge/111-assets/scripts/camera_onboarding.py"
README = CLI.with_name("README.md")


def variable_blocks(path, names):
    source = path.read_text(encoding="utf-8")
    blocks = []
    for name in names:
        match = re.search(
            rf'^variable "{name}" \{{.*?^\}}', source, re.MULTILINE | re.DOTALL
        )
        assert match is not None, f"Missing actual variable schema: {name}"
        blocks.append(match.group())
    return "\n\n".join(blocks)


def evaluate_variables(tmp_path, schema_path, proposal):
    terraform = shutil.which("terraform")
    if terraform is None:
        pytest.skip("Terraform is required for actual HCL type evaluation")
    schemas = variable_blocks(
        schema_path, ["namespaced_devices", "namespaced_assets"]
    )
    schemas += "\n\n" + variable_blocks(
        BLUEPRINT,
        ["should_enable_akri_onvif_connector", "should_enable_akri_media_connector"],
    )
    (tmp_path / "variables.tf").write_text(schemas, encoding="utf-8")
    result = subprocess.run(
        [terraform, f"-chdir={tmp_path}", "console", f"-var-file={proposal}"],
        input=(
            "jsonencode({devices=var.namespaced_devices,assets=var.namespaced_assets,"
            "onvif=var.should_enable_akri_onvif_connector,"
            "media=var.should_enable_akri_media_connector})\n"
        ),
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(json.loads(result.stdout))


@pytest.mark.parametrize("schema_path", [COMPONENT, BLUEPRINT])
def test_generated_proposal_has_typed_media_task_and_resolvable_references(
    tmp_path, schema_path
):
    import runpy

    sample = re.search(
        r'```json\n(\{\s*"cameras".*?)\n```',
        README.read_text(encoding="utf-8"),
        re.DOTALL,
    )
    assert sample is not None
    cameras = json.loads(sample.group(1))["cameras"]
    renderer = runpy.run_path(str(CLI))
    proposal = tmp_path / "proposal.tfvars"
    proposal.write_text(renderer["render_tfvars"](cameras), encoding="utf-8")
    values = evaluate_variables(tmp_path, schema_path, proposal)

    assert values["onvif"] is True
    assert values["media"] is True
    devices = {device["name"]: device for device in values["devices"]}
    assert len(devices) == 2
    assert {
        endpoint["endpoint_type"]
        for device in devices.values()
        for endpoint in device["endpoints"]["inbound"].values()
    } == {"Microsoft.Onvif", "Microsoft.Media"}
    for asset in values["assets"]:
        device_ref = asset["device_ref"]
        endpoint = devices[device_ref["device_name"]]["endpoints"]["inbound"][
            device_ref["endpoint_name"]
        ]
        credentials = endpoint["authentication"]["usernamePasswordCredentials"]
        assert credentials["usernameSecretName"] == cameras[0]["username_secret_name"]
        assert credentials["passwordSecretName"] == cameras[0]["password_secret_name"]
        if asset["streams"]:
            assert endpoint["endpoint_type"] == "Microsoft.Media"
            assert len(asset["streams"]) == 1
            stream = asset["streams"][0]
            assert json.loads(stream["stream_configuration"]) == {
                "taskType": "snapshot-to-mqtt",
                "autostart": True,
                "format": "jpeg",
                "snapshotsPerSecond": cameras[0]["capture"]["snapshots_per_second"],
            }
            assert len(stream["destinations"]) == 1
            destination = stream["destinations"][0]
            assert destination["target"] == "Mqtt"
            assert destination["configuration"]["topic"] == cameras[0]["capture"]["topic"]
        else:
            assert endpoint["endpoint_type"] == "Microsoft.Onvif"
            assert asset["management_groups"]
            for group in asset["management_groups"]:
                for action in group["actions"]:
                    assert action["action_type"] == "Call"
                    assert action["target_uri"] == f"dtmi:onvif:ptz:{action['name']};1"


def test_documented_onvif_example_is_a_valid_typed_variable_file(tmp_path):
    proposal = BLUEPRINT.with_name("onvif-connector-assets.tfvars.example")
    values = evaluate_variables(tmp_path, BLUEPRINT, proposal)
    assert values["onvif"] is True
    for device in values["devices"]:
        for endpoint in device["endpoints"]["inbound"].values():
            assert endpoint["endpoint_type"] == "Microsoft.Onvif"
            if endpoint["authentication"]["method"] == "UsernamePassword":
                credentials = endpoint["authentication"]["usernamePasswordCredentials"]
                assert "/" in credentials["usernameSecretName"]
                assert "/" in credentials["passwordSecretName"]
