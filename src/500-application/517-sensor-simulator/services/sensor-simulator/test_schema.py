"""Contract tests for the sensor reading JSON schema and its example fixtures."""

import copy
import json
import random
from datetime import UTC, datetime
from pathlib import Path

import pytest
from app import SignalGenerator
from jsonschema import Draft202012Validator
from models import SensorModality, SimulatorConfig

SCHEMAS = Path(__file__).resolve().parents[2] / "resources" / "schemas"
SCHEMA = json.loads((SCHEMAS / "sensor-reading-v1.schema.json").read_text(encoding="utf-8"))
VALIDATOR = Draft202012Validator(SCHEMA)
EXAMPLES = sorted((SCHEMAS / "examples").glob("*.json"))
MOMENT = datetime(2026, 1, 2, 3, 4, 5, 678000, tzinfo=UTC)
MAX_ACOUSTIC_PAYLOAD_BYTES = 640_000


def _example(name: str) -> dict:
    return json.loads((SCHEMAS / "examples" / f"{name}.json").read_text(encoding="utf-8"))


def test_schema_is_valid_draft_2020_12():
    Draft202012Validator.check_schema(SCHEMA)


def test_examples_cover_every_modality():
    modalities = {json.loads(path.read_text(encoding="utf-8"))["modality"] for path in EXAMPLES}
    assert modalities == {modality.value for modality in SensorModality}


@pytest.mark.parametrize("path", EXAMPLES, ids=lambda path: path.stem)
def test_examples_conform(path):
    VALIDATOR.validate(json.loads(path.read_text(encoding="utf-8")))


@pytest.mark.parametrize("modality", list(SensorModality))
@pytest.mark.parametrize("faulty", [False, True])
def test_generated_readings_conform(modality, faulty):
    generator = SignalGenerator(SimulatorConfig(), random.Random(3))
    VALIDATOR.validate(json.loads(generator.reading(modality, faulty, MOMENT).model_dump_json()))


def test_largest_acoustic_reading_conforms_and_fits_the_documented_bound():
    config = SimulatorConfig(acoustic_sample_count=65536, acoustic_sample_rate=192000)
    payload = SignalGenerator(config, random.Random(3)).reading(SensorModality.ACOUSTIC, True, MOMENT)
    encoded = payload.model_dump_json()
    VALIDATOR.validate(json.loads(encoded))
    assert len(encoded.encode("utf-8")) < MAX_ACOUSTIC_PAYLOAD_BYTES


def test_unknown_fields_are_accepted():
    reading = _example("vibration-healthy")
    reading["added_in_1_1"] = "ok"
    reading["schema_version"] = "1.1"
    VALIDATOR.validate(reading)


@pytest.mark.parametrize(
    ("name", "mutate"),
    [
        ("vibration-healthy", lambda r: r.pop("value")),
        ("vibration-healthy", lambda r: r.update(unit="in/s")),
        ("vibration-healthy", lambda r: r.update(value="10.8")),
        ("vibration-healthy", lambda r: r.pop("timestamp")),
        ("vibration-healthy", lambda r: r.update(timestamp="2026-01-02T03:04:05+00:00")),
        ("vibration-healthy", lambda r: r.update(asset_id="Plant A")),
        ("vibration-healthy", lambda r: r.update(schema_version="2.0")),
        ("temperature-faulty", lambda r: r.update(unit="degF")),
        ("temperature-faulty", lambda r: r.update(health_state="unknown")),
        ("acoustic-faulty", lambda r: r.pop("samples")),
        ("acoustic-faulty", lambda r: r.update(sample_rate=4000)),
        ("acoustic-faulty", lambda r: r.update(sample_rate=192001)),
        ("acoustic-faulty", lambda r: r.update(sample_rate=16000.5)),
        ("acoustic-faulty", lambda r: r.update(samples=r["samples"][:2047])),
        ("acoustic-faulty", lambda r: r["samples"].__setitem__(0, 1.5)),
        ("acoustic-faulty", lambda r: r["samples"].__setitem__(0, -1.01)),
        ("acoustic-faulty", lambda r: r.update(modality="pressure")),
    ],
)
def test_invalid_readings_are_rejected(name, mutate):
    reading = copy.deepcopy(_example(name))
    mutate(reading)
    assert not VALIDATOR.is_valid(reading)
