"""Configuration and message models for the synthetic sensor simulator."""

from __future__ import annotations

import os
import re
from collections.abc import Callable, Mapping
from enum import StrEnum
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, ValidationError, model_validator

TOPIC_SEGMENT = re.compile(r"^[a-z0-9._-]{1,64}$")
# URI-reference characters without whitespace, query, or fragment.
EVENT_SOURCE = re.compile(r"^[A-Za-z0-9._~:/-]{1,128}$")
ABSOLUTE_URI = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:\S+$")
CONTRACT_VERSION = "v1"
SCHEMA_VERSION = "1.0"
MIN_ACOUSTIC_SAMPLES = 2048
MAX_ACOUSTIC_SAMPLES = 65536
MIN_SAMPLE_RATE = 8000
MAX_SAMPLE_RATE = 192000


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
    # None verifies the broker against the system trust store.
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
    data_schema: str | None = Field(default=None, max_length=2048)
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
    acoustic_sample_rate: int = Field(default=16000, ge=MIN_SAMPLE_RATE, le=MAX_SAMPLE_RATE)
    acoustic_sample_count: int = Field(default=2048, ge=MIN_ACOUSTIC_SAMPLES, le=MAX_ACOUSTIC_SAMPLES)

    @model_validator(mode="after")
    def _validate(self) -> SimulatorConfig:
        for name in (
            "topic_domain",
            "control_domain",
            "producer",
            "resource_kind",
            "asset_id",
            "sensor_id",
        ):
            if not TOPIC_SEGMENT.match(getattr(self, name)):
                raise ValueError(f"{ENV_NAMES[name]} must be 1-64 lowercase letters, digits, '.', '_', or '-'")
        if not EVENT_SOURCE.match(self.event_source):
            raise ValueError("EVENT_SOURCE must be 1-128 URI-reference characters without whitespace, '?', or '#'")
        if self.data_schema is not None and not ABSOLUTE_URI.match(self.data_schema):
            raise ValueError("DATA_SCHEMA must be an absolute URI")
        if self.topic_domain == self.control_domain:
            raise ValueError("CONTROL_DOMAIN must differ from TOPIC_DOMAIN")
        if not self.modalities:
            raise ValueError("MODALITIES must name at least one modality")
        if self.faulty_band_center <= self.healthy_band_center:
            raise ValueError("FAULTY_BAND_CENTER must exceed HEALTHY_BAND_CENTER")
        if self.temperature_faulty_c <= self.temperature_healthy_c:
            raise ValueError("TEMPERATURE_FAULTY_C must exceed TEMPERATURE_HEALTHY_C")
        if not self.client_id.strip():
            raise ValueError("AIO_MQTT_CLIENT_ID must not be empty")
        if self.sat_file and not self.use_tls:
            raise ValueError("sat_file requires use_tls; set AIO_SAT_FILE empty for non-TLS brokers")
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
        """Build configuration from environment variables.

        Empty values keep the default, except for the optional paths and URIs
        in NULLABLE_FIELDS, where an empty value disables the setting.
        """
        source = os.environ if env is None else env
        overrides: dict[str, object] = {}
        for field_name, (name, convert, expected) in ENV_FIELDS.items():
            if name not in source:
                continue
            raw = source[name].strip()
            if not raw:
                if field_name in NULLABLE_FIELDS:
                    overrides[field_name] = None
                continue
            try:
                overrides[field_name] = convert(raw)
            except ValueError as error:
                raise ValueError(f"{name} is invalid: expected {expected}") from error
        return cls(**overrides)


def _parse_bool(raw: str) -> bool:
    lowered = raw.lower()
    if lowered in ("1", "true", "yes", "on"):
        return True
    if lowered in ("0", "false", "no", "off"):
        return False
    raise ValueError("not a boolean")


def _parse_modalities(raw: str) -> tuple[SensorModality, ...]:
    names = [part.strip().lower() for part in raw.split(",") if part.strip()]
    return tuple(dict.fromkeys(SensorModality(name) for name in names))


_MODALITY_LIST = "a comma-separated list of " + ", ".join(modality.value for modality in SensorModality)

ENV_FIELDS: dict[str, tuple[str, Callable[[str], object], str]] = {
    "broker_host": ("AIO_BROKER_HOSTNAME", str, "a hostname"),
    "broker_port": ("AIO_BROKER_TCP_PORT", int, "an integer"),
    "use_tls": ("AIO_MQTT_USE_TLS", _parse_bool, "a boolean"),
    "ca_file": ("AIO_TLS_CA_FILE", str, "a file path"),
    "sat_file": ("AIO_SAT_FILE", str, "a file path"),
    "client_id": ("AIO_MQTT_CLIENT_ID", str, "a client ID"),
    "qos": ("MQTT_QOS", int, "an integer"),
    "topic_domain": ("TOPIC_DOMAIN", str, "a topic segment"),
    "control_domain": ("CONTROL_DOMAIN", str, "a topic segment"),
    "producer": ("PRODUCER", str, "a topic segment"),
    "resource_kind": ("RESOURCE_KIND", str, "a topic segment"),
    "asset_id": ("ASSET_ID", str, "a topic segment"),
    "sensor_id": ("SENSOR_ID", str, "an opaque identifier"),
    "event_source": ("EVENT_SOURCE", str, "a URI reference"),
    "data_schema": ("DATA_SCHEMA", str, "an absolute URI"),
    "modalities": ("MODALITIES", _parse_modalities, _MODALITY_LIST),
    "publish_interval_seconds": ("PUBLISH_INTERVAL_SECONDS", float, "a number"),
    "seed": ("SIMULATOR_SEED", int, "an integer"),
    "inject_anomaly": ("INJECT_ANOMALY", _parse_bool, "a boolean"),
    "control_enabled": ("CONTROL_ENABLED", _parse_bool, "a boolean"),
    "healthy_band_center": ("HEALTHY_BAND_CENTER", float, "a number"),
    "faulty_band_center": ("FAULTY_BAND_CENTER", float, "a number"),
    "band_jitter": ("BAND_JITTER", float, "a number"),
    "temperature_healthy_c": ("TEMPERATURE_HEALTHY_C", float, "a number"),
    "temperature_faulty_c": ("TEMPERATURE_FAULTY_C", float, "a number"),
    "temperature_jitter_c": ("TEMPERATURE_JITTER_C", float, "a number"),
    "acoustic_sample_rate": ("ACOUSTIC_SAMPLE_RATE", int, "an integer"),
    "acoustic_sample_count": ("ACOUSTIC_SAMPLE_COUNT", int, "an integer"),
}
ENV_NAMES = {field_name: spec[0] for field_name, spec in ENV_FIELDS.items()}
NULLABLE_FIELDS = frozenset({"ca_file", "sat_file", "data_schema"})


def describe_config_error(error: ValidationError | ValueError) -> list[str]:
    """Return one log-safe line per configuration error, without input values."""
    if not isinstance(error, ValidationError):
        return [str(error)]
    lines = []
    for detail in error.errors(include_input=False, include_url=False, include_context=False):
        message = detail["msg"].removeprefix("Value error, ")
        location = detail["loc"]
        if location and location[0] in ENV_NAMES:
            lines.append(f"{ENV_NAMES[location[0]]}: {message}")
        else:
            lines.append(message)
    return lines


AcousticSample = Annotated[float, Field(ge=-1.0, le=1.0)]


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

    sample_rate: int = Field(ge=MIN_SAMPLE_RATE, le=MAX_SAMPLE_RATE)
    samples: list[AcousticSample] = Field(min_length=MIN_ACOUSTIC_SAMPLES, max_length=MAX_ACOUSTIC_SAMPLES)


class ControlCommand(BaseModel):
    """Runtime anomaly-injection command received on the control topic."""

    model_config = ConfigDict(extra="forbid", strict=True)

    inject_anomaly: bool
