"""Configuration and message models for the synthetic sensor simulator."""

from __future__ import annotations

import os
import re
from collections.abc import Callable, Mapping
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, model_validator

TOPIC_SEGMENT = re.compile(r"^[a-z0-9._-]{1,64}$")
CONTRACT_VERSION = "v1"
SCHEMA_VERSION = "1.0"


class HealthState(StrEnum):
    """Synthetic ground-truth state carried by every reading."""

    HEALTHY = "healthy"
    FAULTY = "faulty"


class SensorModality(StrEnum):
    """Signal modalities the simulator can emit."""

    VIBRATION = "vibration"
    ACOUSTIC = "acoustic"
    TEMPERATURE = "temperature"


class SimulatorConfig(BaseModel):
    """Validated runtime configuration."""

    model_config = ConfigDict(frozen=True)

    broker_host: str = "aio-broker.azure-iot-operations"
    broker_port: int = Field(default=18883, gt=0, le=65535)
    use_tls: bool = True
    ca_file: str | None = "/var/run/certs/ca.crt"
    sat_file: str | None = "/var/run/secrets/tokens/mq-sat"
    client_id: str = "sensor-simulator"
    qos: int = Field(default=1, ge=0, le=1)

    topic_domain: str = "telemetry"
    control_domain: str = "control"
    producer: str = "sensor-simulator"
    resource_kind: str = "asset"
    asset_id: str = "asset-01"
    sensor_id: str = "sensor-01"
    event_source: str = "sensor-simulator"
    modalities: tuple[SensorModality, ...] = tuple(SensorModality)

    publish_interval_seconds: float = Field(default=2.0, gt=0, le=3600)
    seed: int | None = None
    inject_anomaly: bool = False
    control_enabled: bool = False

    healthy_band_center: float = 10.8
    faulty_band_center: float = 11.6
    band_jitter: float = Field(default=0.15, ge=0)
    temperature_healthy_c: float = 62.0
    temperature_faulty_c: float = 71.0
    temperature_jitter_c: float = Field(default=0.8, ge=0)
    acoustic_sample_rate: int = Field(default=16000, gt=0, le=192000)
    acoustic_sample_count: int = Field(default=2048, gt=0, le=65536)

    @model_validator(mode="after")
    def _validate(self) -> SimulatorConfig:
        for name in (
            "topic_domain",
            "control_domain",
            "producer",
            "resource_kind",
            "asset_id",
        ):
            if not TOPIC_SEGMENT.match(getattr(self, name)):
                raise ValueError(f"{name} must be 1-64 lowercase letters, digits, '.', '_', or '-'")
        if self.topic_domain == self.control_domain:
            raise ValueError("control_domain must differ from topic_domain")
        if not self.modalities:
            raise ValueError("at least one modality is required")
        if self.faulty_band_center <= self.healthy_band_center:
            raise ValueError("faulty_band_center must exceed healthy_band_center")
        if self.temperature_faulty_c <= self.temperature_healthy_c:
            raise ValueError("temperature_faulty_c must exceed temperature_healthy_c")
        if not self.client_id.strip():
            raise ValueError("client_id must not be empty")
        return self

    def topic_for(self, modality: SensorModality) -> str:
        """Return the versioned telemetry topic for a modality."""
        return "/".join(
            (
                self.topic_domain,
                CONTRACT_VERSION,
                self.producer,
                self.resource_kind,
                self.asset_id,
                modality.value,
            )
        )

    @property
    def control_topic(self) -> str:
        """Return the versioned anomaly-control topic."""
        return "/".join(
            (
                self.control_domain,
                CONTRACT_VERSION,
                self.producer,
                self.resource_kind,
                self.asset_id,
                "anomaly",
            )
        )

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> SimulatorConfig:
        """Build configuration from environment variables."""
        source = os.environ if env is None else env

        def value(name: str) -> str | None:
            raw = source.get(name)
            return raw.strip() if raw and raw.strip() else None

        overrides: dict[str, object] = {}

        def put(field: str, name: str, convert: Callable[[str], object] = str) -> None:
            raw = value(name)
            if raw is not None:
                try:
                    overrides[field] = convert(raw)
                except ValueError as error:
                    raise ValueError(f"{name} is invalid: {error}") from error

        put("broker_host", "AIO_BROKER_HOSTNAME")
        put("broker_port", "AIO_BROKER_TCP_PORT", int)
        put("use_tls", "AIO_MQTT_USE_TLS", _parse_bool)
        put("ca_file", "AIO_TLS_CA_FILE")
        put("sat_file", "AIO_SAT_FILE")
        put("client_id", "AIO_MQTT_CLIENT_ID")
        put("qos", "MQTT_QOS", int)
        put("topic_domain", "TOPIC_DOMAIN")
        put("control_domain", "CONTROL_DOMAIN")
        put("producer", "PRODUCER")
        put("resource_kind", "RESOURCE_KIND")
        put("asset_id", "ASSET_ID")
        put("sensor_id", "SENSOR_ID")
        put("event_source", "EVENT_SOURCE")
        put("modalities", "MODALITIES", _parse_modalities)
        put("publish_interval_seconds", "PUBLISH_INTERVAL_SECONDS", float)
        put("seed", "SIMULATOR_SEED", int)
        put("inject_anomaly", "INJECT_ANOMALY", _parse_bool)
        put("control_enabled", "CONTROL_ENABLED", _parse_bool)
        put("healthy_band_center", "HEALTHY_BAND_CENTER", float)
        put("faulty_band_center", "FAULTY_BAND_CENTER", float)
        put("band_jitter", "BAND_JITTER", float)
        put("temperature_healthy_c", "TEMPERATURE_HEALTHY_C", float)
        put("temperature_faulty_c", "TEMPERATURE_FAULTY_C", float)
        put("temperature_jitter_c", "TEMPERATURE_JITTER_C", float)
        put("acoustic_sample_rate", "ACOUSTIC_SAMPLE_RATE", int)
        put("acoustic_sample_count", "ACOUSTIC_SAMPLE_COUNT", int)

        if value("AIO_SAT_FILE") is None and "AIO_SAT_FILE" in source:
            overrides["sat_file"] = None
        return cls(**overrides)


def _parse_bool(raw: str) -> bool:
    lowered = raw.lower()
    if lowered in ("1", "true", "yes", "on"):
        return True
    if lowered in ("0", "false", "no", "off"):
        return False
    raise ValueError(f"expected a boolean, got {raw!r}")


def _parse_modalities(raw: str) -> tuple[SensorModality, ...]:
    names = [part.strip().lower() for part in raw.split(",") if part.strip()]
    try:
        modalities = tuple(dict.fromkeys(SensorModality(name) for name in names))
    except ValueError as error:
        allowed = ", ".join(modality.value for modality in SensorModality)
        raise ValueError(f"expected a list of {allowed}") from error
    return modalities


class Reading(BaseModel):
    """Fields shared by every reading payload."""

    schema_version: str = SCHEMA_VERSION
    asset_id: str
    sensor_id: str
    modality: SensorModality
    health_state: HealthState
    timestamp: str


class ScalarReading(Reading):
    """Single-value reading for vibration and temperature."""

    value: float
    unit: str


class AcousticReading(Reading):
    """Fixed-length waveform window for the acoustic modality."""

    sample_rate: int
    samples: list[float]


class ControlCommand(BaseModel):
    """Runtime anomaly-injection command received on the control topic."""

    model_config = ConfigDict(extra="forbid", strict=True)

    inject_anomaly: bool
