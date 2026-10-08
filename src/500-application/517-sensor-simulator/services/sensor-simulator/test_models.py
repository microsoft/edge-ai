"""Unit tests for simulator configuration and message models."""

import pytest
from models import (
    ControlCommand,
    SensorModality,
    SimulatorConfig,
    describe_config_error,
)
from pydantic import ValidationError


class TestTopics:
    def test_default_topics_follow_versioned_grammar(self):
        config = SimulatorConfig()
        assert config.topic_for(SensorModality.VIBRATION) == "telemetry/v1/sensor-simulator/asset/asset-01/vibration"
        assert config.control_topic == "control/v1/sensor-simulator/asset/asset-01/anomaly"

    def test_control_topic_never_shares_a_domain_with_telemetry(self):
        with pytest.raises(ValidationError, match="CONTROL_DOMAIN"):
            SimulatorConfig(control_domain="telemetry")

    @pytest.mark.parametrize("asset_id", ["Asset-01", "asset/01", "asset+", "a#", "", "a" * 65])
    def test_rejects_asset_ids_that_are_not_topic_segments(self, asset_id):
        with pytest.raises(ValidationError, match="ASSET_ID"):
            SimulatorConfig(asset_id=asset_id)

    @pytest.mark.parametrize("sensor_id", ["Sensor-01", "sensor 01", "s/1", "", "s" * 65])
    def test_rejects_sensor_ids_that_are_not_opaque_identifiers(self, sensor_id):
        with pytest.raises(ValidationError, match="SENSOR_ID"):
            SimulatorConfig(sensor_id=sensor_id)

    @pytest.mark.parametrize("event_source", ["urn:edge-ai:sensor-simulator", "/plant/line-1", "sensor-simulator"])
    def test_accepts_uri_reference_event_sources(self, event_source):
        assert SimulatorConfig(event_source=event_source).event_source == event_source

    @pytest.mark.parametrize("event_source", ["", "has space", "a?b=1", "a#frag", "x" * 129])
    def test_rejects_invalid_event_sources(self, event_source):
        with pytest.raises(ValidationError, match="EVENT_SOURCE"):
            SimulatorConfig(event_source=event_source)


class TestTransportSecurity:
    def test_sat_requires_tls(self):
        with pytest.raises(ValidationError, match="sat_file requires use_tls"):
            SimulatorConfig(use_tls=False)

    def test_sat_requires_tls_from_environment(self):
        with pytest.raises(ValidationError, match="set AIO_SAT_FILE empty"):
            SimulatorConfig.from_env({"AIO_MQTT_USE_TLS": "false"})

    def test_plain_mqtt_without_sat_is_allowed(self):
        config = SimulatorConfig.from_env({"AIO_MQTT_USE_TLS": "false", "AIO_SAT_FILE": ""})
        assert config.use_tls is False
        assert config.sat_file is None

    def test_empty_ca_file_uses_system_trust_store(self):
        assert SimulatorConfig.from_env({"AIO_TLS_CA_FILE": " "}).ca_file is None


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
            ("ACOUSTIC_SAMPLE_COUNT", "2047"),
            ("ACOUSTIC_SAMPLE_COUNT", "65537"),
            ("ACOUSTIC_SAMPLE_RATE", "7999"),
            ("ACOUSTIC_SAMPLE_RATE", "192001"),
            ("DATA_SCHEMA", "not a uri"),
        ],
    )
    def test_rejects_out_of_range_values(self, name, raw):
        with pytest.raises(ValidationError):
            SimulatorConfig.from_env({name: raw})

    def test_acoustic_bounds_are_inclusive(self):
        low = SimulatorConfig.from_env({"ACOUSTIC_SAMPLE_COUNT": "2048", "ACOUSTIC_SAMPLE_RATE": "8000"})
        high = SimulatorConfig.from_env({"ACOUSTIC_SAMPLE_COUNT": "65536", "ACOUSTIC_SAMPLE_RATE": "192000"})
        assert (low.acoustic_sample_count, low.acoustic_sample_rate) == (2048, 8000)
        assert (high.acoustic_sample_count, high.acoustic_sample_rate) == (65536, 192000)

    def test_reads_optional_data_schema(self):
        uri = "https://example.com/schemas/sensor-reading-v1.schema.json"
        assert SimulatorConfig.from_env({"DATA_SCHEMA": uri}).data_schema == uri
        assert SimulatorConfig.from_env({"DATA_SCHEMA": ""}).data_schema is None


class TestDescribeConfigError:
    def test_maps_fields_to_variables_without_echoing_input(self):
        with pytest.raises(ValidationError) as caught:
            SimulatorConfig.from_env({"ACOUSTIC_SAMPLE_COUNT": "777", "ASSET_ID": "Secret Site"})
        lines = describe_config_error(caught.value)
        assert any(line.startswith("ACOUSTIC_SAMPLE_COUNT: ") for line in lines)
        assert not any("777" in line or "Secret Site" in line for line in lines)

    def test_model_errors_name_the_variable(self):
        with pytest.raises(ValidationError) as caught:
            SimulatorConfig.from_env({"ASSET_ID": "Secret Site"})
        assert describe_config_error(caught.value) == [
            "ASSET_ID must be 1-64 lowercase letters, digits, '.', '_', or '-'"
        ]

    def test_conversion_errors_do_not_echo_input(self):
        with pytest.raises(ValueError) as caught:
            SimulatorConfig.from_env({"AIO_BROKER_TCP_PORT": "secret-port"})
        assert describe_config_error(caught.value) == ["AIO_BROKER_TCP_PORT is invalid: expected an integer"]


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
