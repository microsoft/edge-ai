"""Unit tests for Pydantic models in the sensor simulator."""

import pytest
from models import (
    DataType,
    FieldConfig,
    FieldsArrayResponse,
    FieldValueResponse,
    SimulatorMetadata,
)
from pydantic import ValidationError


class TestFieldConfigValidation:
    def test_valid_integer_field(self):
        cfg = FieldConfig(name="temp", data_type=DataType.INTEGER,
                          min_value=0, max_value=100)
        assert cfg.name == "temp"
        assert cfg.data_type == DataType.INTEGER

    def test_valid_float_field(self):
        cfg = FieldConfig(
            name="pressure", data_type=DataType.FLOAT, min_value=0.0, max_value=1.0)
        assert cfg.min_value == 0.0

    def test_valid_string_field_with_options(self):
        cfg = FieldConfig(name="status", data_type=DataType.STRING,
                          string_options=["on", "off"])
        assert cfg.string_options == ["on", "off"]

    def test_valid_boolean_field(self):
        cfg = FieldConfig(name="active", data_type=DataType.BOOLEAN)
        assert cfg.data_type == DataType.BOOLEAN

    def test_string_type_requires_string_options(self):
        with pytest.raises(ValidationError, match="string_options required"):
            FieldConfig(name="tag", data_type=DataType.STRING)

    def test_string_type_rejects_empty_options(self):
        with pytest.raises(ValidationError, match="string_options required"):
            FieldConfig(name="tag", data_type=DataType.STRING,
                        string_options=[])

    def test_max_less_than_min_rejected(self):
        with pytest.raises(ValidationError, match="max_value must be greater"):
            FieldConfig(name="x", data_type=DataType.INTEGER,
                        min_value=10, max_value=5)

    def test_equal_min_max_accepted(self):
        cfg = FieldConfig(name="fixed", data_type=DataType.FLOAT,
                          min_value=5.0, max_value=5.0)
        assert cfg.min_value == cfg.max_value

    def test_numeric_without_range_accepted(self):
        cfg = FieldConfig(name="unbounded", data_type=DataType.INTEGER)
        assert cfg.min_value is None
        assert cfg.max_value is None

    def test_metadata_defaults_to_empty_dict(self):
        cfg = FieldConfig(name="m", data_type=DataType.BOOLEAN)
        assert cfg.metadata == {}


class TestFieldValueResponseValidation:
    def _base(self, **overrides):
        defaults = {
            "field_id": "f1",
            "name": "temp",
            "data_type": DataType.INTEGER,
            "value": 42,
            "units": "C",
            "timestamp": "2025-01-01T00:00:00Z",
        }
        defaults.update(overrides)
        return FieldValueResponse(**defaults)

    def test_valid_integer_value(self):
        resp = self._base()
        assert resp.value == 42

    def test_valid_float_value(self):
        resp = self._base(data_type=DataType.FLOAT, value=3.14)
        assert resp.value == 3.14

    def test_int_accepted_as_float(self):
        resp = self._base(data_type=DataType.FLOAT, value=7)
        assert resp.value == 7

    def test_valid_string_value(self):
        resp = self._base(data_type=DataType.STRING, value="ok")
        assert resp.value == "ok"

    def test_valid_boolean_value(self):
        resp = self._base(data_type=DataType.BOOLEAN, value=True)
        assert resp.value is True

    def test_rejects_string_for_integer_type(self):
        with pytest.raises(ValidationError, match="Expected int for INTEGER"):
            self._base(data_type=DataType.INTEGER, value="not_int")

    def test_rejects_bool_for_integer_type(self):
        with pytest.raises(ValidationError, match="Expected int for INTEGER"):
            self._base(data_type=DataType.INTEGER, value=True)

    def test_rejects_bool_for_float_type(self):
        with pytest.raises(ValidationError, match="Expected float for FLOAT"):
            self._base(data_type=DataType.FLOAT, value=False)

    def test_rejects_int_for_boolean_type(self):
        with pytest.raises(ValidationError, match="Expected bool for BOOLEAN"):
            self._base(data_type=DataType.BOOLEAN, value=1)

    def test_rejects_int_for_string_type(self):
        with pytest.raises(ValidationError, match="Expected str for STRING"):
            self._base(data_type=DataType.STRING, value=123)

    def test_quality_defaults_to_good(self):
        resp = self._base()
        assert resp.quality == "good"


class TestFieldsArrayResponseValidation:
    def _field(self, fid="f1"):
        return FieldValueResponse(
            field_id=fid,
            name="x",
            data_type=DataType.INTEGER,
            value=1,
            units="",
            timestamp="2025-01-01T00:00:00Z",
        )

    def test_valid_count_matches_fields(self):
        resp = FieldsArrayResponse(fields=[self._field()], count=1)
        assert resp.count == 1

    def test_mismatched_count_rejected(self):
        with pytest.raises(ValidationError, match="does not match actual length"):
            FieldsArrayResponse(fields=[self._field()], count=5)

    def test_empty_list_with_zero_count(self):
        resp = FieldsArrayResponse(fields=[], count=0)
        assert resp.count == 0


class TestSimulatorMetadata:
    def test_defaults(self):
        meta = SimulatorMetadata()
        assert meta.device_id == "field-sensor-simulator-001"
        assert meta.version == "2.0.0"
