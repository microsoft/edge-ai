"""Unit tests for simulator configuration and message models."""

import pytest
from models import (
    ControlCommand,
    SensorModality,
    SimulatorConfig,
)
from pydantic import ValidationError


class TestTopics:
    def test_default_topics_follow_versioned_grammar(self):
        config = SimulatorConfig()
        assert config.topic_for(SensorModality.VIBRATION) == "telemetry/v1/sensor-simulator/asset/asset-01/vibration"
        assert config.control_topic == "control/v1/sensor-simulator/asset/asset-01/anomaly"

    def test_control_topic_never_shares_a_domain_with_telemetry(self):
        with pytest.raises(ValidationError, match="control_domain"):
            SimulatorConfig(control_domain="telemetry")

    @pytest.mark.parametrize("asset_id", ["Asset-01", "asset/01", "asset+", "a#", "", "a" * 65])
    def test_rejects_asset_ids_that_are_not_topic_segments(self, asset_id):
        with pytest.raises(ValidationError, match="asset_id"):
            SimulatorConfig(asset_id=asset_id)


class TestFromEnv:
    def test_defaults_without_environment(self):
        config = SimulatorConfig.from_env({})
        assert config == SimulatorConfig()
        assert config.control_enabled is False
        assert config.qos == 1
        assert config.modalities == tuple(SensorModality)

    def test_reads_aio_connection_variables(self):
        config = SimulatorConfig.from_env(
            {
                "AIO_BROKER_HOSTNAME": "broker",
                "AIO_BROKER_TCP_PORT": "1883",
                "AIO_MQTT_USE_TLS": "false",
                "AIO_MQTT_CLIENT_ID": "sensor-simulator-pod-1",
                "AIO_SAT_FILE": "",
            }
        )
        assert config.broker_host == "broker"
        assert config.broker_port == 1883
        assert config.use_tls is False
        assert config.client_id == "sensor-simulator-pod-1"
        assert config.sat_file is None

    def test_parses_modalities_and_seed(self):
        config = SimulatorConfig.from_env({"MODALITIES": "temperature, vibration,temperature", "SIMULATOR_SEED": "7"})
        assert config.modalities == (SensorModality.TEMPERATURE, SensorModality.VIBRATION)
        assert config.seed == 7

    @pytest.mark.parametrize(
        ("name", "raw"),
        [
            ("MODALITIES", "pressure"),
            ("AIO_MQTT_USE_TLS", "maybe"),
            ("AIO_BROKER_TCP_PORT", "port"),
            ("PUBLISH_INTERVAL_SECONDS", "soon"),
        ],
    )
    def test_reports_the_invalid_variable(self, name, raw):
        with pytest.raises(ValueError, match=name):
            SimulatorConfig.from_env({name: raw})

    @pytest.mark.parametrize(
        ("name", "raw"),
        [
            ("MQTT_QOS", "2"),
            ("PUBLISH_INTERVAL_SECONDS", "0"),
            ("FAULTY_BAND_CENTER", "1.0"),
            ("TEMPERATURE_FAULTY_C", "10"),
            ("ACOUSTIC_SAMPLE_COUNT", "0"),
        ],
    )
    def test_rejects_out_of_range_values(self, name, raw):
        with pytest.raises(ValidationError):
            SimulatorConfig.from_env({name: raw})


class TestControlCommand:
    def test_accepts_boolean(self):
        assert ControlCommand.model_validate_json(b'{"inject_anomaly": true}').inject_anomaly

    @pytest.mark.parametrize(
        "payload",
        [b'{"inject_anomaly": "true"}', b'{"inject_anomaly": 1}', b'{"other": true}', b"[]"],
    )
    def test_rejects_non_boolean_or_unknown_fields(self, payload):
        with pytest.raises(ValidationError):
            ControlCommand.model_validate_json(payload)
