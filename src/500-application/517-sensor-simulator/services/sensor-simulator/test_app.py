"""Unit tests for simulator message construction and control handling."""

import json
import random
from datetime import UTC, datetime

from app import (
    MAX_CONTROL_BYTES,
    SAT_AUTH_METHOD,
    SignalGenerator,
    connect_properties,
    parse_control,
    publish_properties,
)
from models import AcousticReading, HealthState, ScalarReading, SensorModality, SimulatorConfig

MOMENT = datetime(2026, 1, 2, 3, 4, 5, 678000, tzinfo=UTC)


def _generator(seed: int = 1, **overrides) -> SignalGenerator:
    return SignalGenerator(SimulatorConfig(**overrides), random.Random(seed))


class TestSignalGenerator:
    def test_seeded_generators_are_deterministic(self):
        first = _generator(seed=42).reading(SensorModality.VIBRATION, False, MOMENT)
        second = _generator(seed=42).reading(SensorModality.VIBRATION, False, MOMENT)
        assert first == second

    def test_faulty_state_shifts_scalar_bands(self):
        config = SimulatorConfig(band_jitter=0.0, temperature_jitter_c=0.0)
        generator = SignalGenerator(config, random.Random(1))
        healthy = generator.reading(SensorModality.VIBRATION, False, MOMENT)
        faulty = generator.reading(SensorModality.VIBRATION, True, MOMENT)
        assert isinstance(healthy, ScalarReading)
        assert healthy.value == config.healthy_band_center
        assert faulty.value == config.faulty_band_center
        assert faulty.health_state is HealthState.FAULTY
        hot = generator.reading(SensorModality.TEMPERATURE, True, MOMENT)
        assert hot.value == config.temperature_faulty_c
        assert hot.unit == "degC"

    def test_acoustic_window_has_configured_length(self):
        reading = _generator(acoustic_sample_count=64).reading(SensorModality.ACOUSTIC, True, MOMENT)
        assert isinstance(reading, AcousticReading)
        assert len(reading.samples) == 64
        assert reading.sample_rate == 16000

    def test_payload_carries_no_site_or_model_identity(self):
        reading = _generator().reading(SensorModality.VIBRATION, False, MOMENT)
        payload = json.loads(reading.model_dump_json())
        assert set(payload) == {
            "schema_version",
            "asset_id",
            "sensor_id",
            "modality",
            "health_state",
            "timestamp",
            "value",
            "unit",
        }
        assert payload["timestamp"] == "2026-01-02T03:04:05.678Z"


class TestProperties:
    def test_publish_properties_carry_cloud_events_attributes(self):
        properties = publish_properties(SimulatorConfig(), SensorModality.ACOUSTIC, "event-1", MOMENT)
        attributes = dict(properties.UserProperty)
        assert attributes == {
            "specversion": "1.0",
            "type": "edge-ai.sensor.acoustic",
            "source": "sensor-simulator",
            "id": "event-1",
            "time": "2026-01-02T03:04:05.678Z",
            "subject": "asset-01",
            "datacontenttype": "application/json",
        }
        assert properties.ContentType == "application/json"
        assert properties.PayloadFormatIndicator == 1

    def test_connect_properties_use_sat_enhanced_authentication(self, tmp_path):
        token_file = tmp_path / "token"
        token_file.write_text("first\n", encoding="utf-8")
        config = SimulatorConfig(sat_file=str(token_file))
        properties = connect_properties(config)
        assert properties.AuthenticationMethod == SAT_AUTH_METHOD
        assert properties.AuthenticationData == b"first"

        token_file.write_text("rotated", encoding="utf-8")
        assert connect_properties(config).AuthenticationData == b"rotated"

    def test_connect_properties_are_omitted_without_sat(self):
        assert connect_properties(SimulatorConfig(sat_file=None)) is None


class TestParseControl:
    def test_valid_command(self):
        assert parse_control(b'{"inject_anomaly": false}').inject_anomaly is False

    def test_invalid_and_oversize_payloads_are_ignored(self):
        assert parse_control(b"not json") is None
        assert parse_control(b'{"inject_anomaly": "yes"}') is None
        padded = b'{"inject_anomaly": true' + b" " * MAX_CONTROL_BYTES + b"}"
        assert parse_control(padded) is None
