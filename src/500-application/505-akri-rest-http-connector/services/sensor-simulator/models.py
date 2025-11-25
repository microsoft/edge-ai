from pydantic import BaseModel, Field, ValidationError, model_validator
from typing import Any
from pathlib import Path
from enum import Enum
import os
import json
"""Pydantic models supporting field-based sensor simulator configuration."""


FIELD_CONFIG_ENV_VAR = "FIELD_CONFIG_PATH"
DEFAULT_CONFIG_FILENAME = "field_sources.json"
DEFAULT_CONFIG_DIRECTORY = Path("/app")
DEFAULT_CONFIG_PATH = DEFAULT_CONFIG_DIRECTORY / DEFAULT_CONFIG_FILENAME


class DataType(str, Enum):
    """Supported field data types exposed by the simulator."""

    INTEGER = "integer"
    FLOAT = "float"
    STRING = "string"
    BOOLEAN = "boolean"


class FieldConfig(BaseModel):
    """Configuration describing a single field."""

    name: str = Field(..., description="Human-readable field name")
    data_type: DataType = Field(..., description="Field data type")
    units: str = Field(
        default="", description="Units associated with the field value")
    min_value: float | None = Field(
        default=None, description="Minimum value for numeric types")
    max_value: float | None = Field(
        default=None, description="Maximum value for numeric types")
    string_options: list[str] | None = Field(
        default=None, description="Allowed options for string data type")
    metadata: dict[str, Any] = Field(
        default_factory=dict, description="Additional metadata for the field")

    @model_validator(mode='after')
    def validate_field_config(self) -> 'FieldConfig':
        """Validate string options and numeric ranges."""

        # Require string_options when the field uses the STRING data type
        if self.data_type == DataType.STRING and not self.string_options:
            raise ValueError(
                "string_options required when data_type is STRING")

        # Ensure numeric ranges are coherent when both limits are provided
        if self.data_type in (DataType.INTEGER, DataType.FLOAT):
            if self.min_value is not None and self.max_value is not None:
                if self.max_value < self.min_value:
                    raise ValueError(
                        "max_value must be greater than or equal to min_value")

        return self


class SimulatorMetadata(BaseModel):
    """Metadata associated with the simulator instance."""

    device_id: str = Field(default="field-sensor-simulator-001")
    version: str = Field(default="2.0.0")
    description: str = Field(default="Field-based sensor data simulator")


class FieldsConfig(BaseModel):
    """Top-level configuration containing all field definitions."""

    fields: dict[str, FieldConfig] = Field(
        ..., description="Field configurations keyed by field identifier")
    simulator_metadata: SimulatorMetadata = Field(
        default_factory=SimulatorMetadata)

    @classmethod
    def load_from_file(cls, file_path: str | Path) -> "FieldsConfig":
        """Load configuration from a JSON file."""

        path = Path(file_path)
        try:
            with path.open("r", encoding="utf-8") as file_handle:
                data = json.load(file_handle)
        except FileNotFoundError as exc:
            raise FileNotFoundError(
                f"Configuration file not found: {path}") from exc
        except json.JSONDecodeError as exc:
            raise ValueError(
                f"Configuration file contains invalid JSON: {path}") from exc

        try:
            return cls(**data)
        except ValidationError as exc:
            raise ValueError(
                f"Configuration validation failed for {path}") from exc

    @classmethod
    def load_default(cls) -> "FieldsConfig":
        """Load configuration using the configured default resolution strategy."""

        candidate = os.getenv(FIELD_CONFIG_ENV_VAR)
        if candidate:
            return cls.load_from_file(candidate)

        fallback_path = DEFAULT_CONFIG_PATH
        if fallback_path.exists():
            return cls.load_from_file(fallback_path)

        module_default = Path(__file__).resolve().parent / \
            DEFAULT_CONFIG_FILENAME
        return cls.load_from_file(module_default)


class FieldValueResponse(BaseModel):
    """Response payload representing a single field value."""

    field_id: str
    name: str
    data_type: DataType
    value: int | float | str | bool
    units: str
    timestamp: str
    quality: str = Field(default="good")
    metadata: dict[str, Any] = Field(default_factory=dict)

    @model_validator(mode='after')
    def validate_value_type(self) -> 'FieldValueResponse':
        """Ensure value type matches declared data_type."""
        # Check BOOLEAN first since bool is a subclass of int in Python
        if self.data_type == DataType.BOOLEAN:
            if not isinstance(self.value, bool):
                raise ValueError(
                    f"Expected bool for BOOLEAN type, got {type(self.value).__name__}")
        elif self.data_type == DataType.INTEGER:
            if not isinstance(self.value, int) or isinstance(self.value, bool):
                raise ValueError(
                    f"Expected int for INTEGER type, got {type(self.value).__name__}")
        elif self.data_type == DataType.FLOAT:
            if not isinstance(self.value, (int, float)) or isinstance(self.value, bool):
                raise ValueError(
                    f"Expected float for FLOAT type, got {type(self.value).__name__}")
        elif self.data_type == DataType.STRING:
            if not isinstance(self.value, str):
                raise ValueError(
                    f"Expected str for STRING type, got {type(self.value).__name__}")
        return self


class FieldsArrayResponse(BaseModel):
    """Response payload representing multiple field values."""

    fields: list[FieldValueResponse]
    count: int

    @model_validator(mode='after')
    def validate_count(self) -> 'FieldsArrayResponse':
        """Ensure count matches the number of field entries."""
        actual_count = len(self.fields)
        if actual_count != self.count:
            raise ValueError(
                f"count value {self.count} does not match actual length {actual_count}")
        return self


def load_from_file(file_path: str | Path) -> FieldsConfig:
    """Convenience wrapper around FieldsConfig.load_from_file."""

    return FieldsConfig.load_from_file(file_path)


def load_default() -> FieldsConfig:
    """Convenience wrapper around FieldsConfig.load_default."""

    return FieldsConfig.load_default()


__all__ = [
    "DataType",
    "FieldConfig",
    "FieldValueResponse",
    "FieldsArrayResponse",
    "FieldsConfig",
    "SimulatorMetadata",
    "load_default",
    "load_from_file",
]
