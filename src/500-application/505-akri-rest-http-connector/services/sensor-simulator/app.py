#!/usr/bin/env python3
"""Field-based sensor simulator Flask application."""

from __future__ import annotations

import logging
import os
import random
from datetime import datetime, timezone
from typing import Any, Callable

from flask import Flask, jsonify, request
from pydantic import ValidationError

from models import DataType, FieldValueResponse, FieldsArrayResponse, FieldsConfig


def _configure_logging() -> logging.Logger:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    return logging.getLogger("sensor-simulator")


logger = _configure_logging()
app = Flask(__name__)

PORT = int(os.environ.get("PORT", 8081))
DEVICE_ID = os.environ.get("DEVICE_ID", "field-sensor-simulator-001")
SENSOR_TYPE = os.environ.get("SENSOR_TYPE", "field-sensor")
QUALITY_OPTIONS = ("excellent", "good", "fair")


def _load_config() -> FieldsConfig:
    try:
        loaded = FieldsConfig.load_default()
        logger.info("Loaded %s field configurations", len(loaded.fields))
        return loaded
    except Exception as exc:  # noqa: BLE001
        logger.exception("Failed to load field configuration")
        raise RuntimeError("Field configuration load failed") from exc


CONFIG = _load_config()


def _select_quality() -> str:
    return random.choice(QUALITY_OPTIONS)


def _generate_value(field_id: str) -> Any:
    field_config = CONFIG.fields[field_id]

    if field_config.data_type == DataType.INTEGER:
        lower = int(field_config.min_value or 0)
        upper = int(field_config.max_value or 100)
        if lower > upper:
            logger.error(
                "Invalid bounds for field %s: min_value=%s, max_value=%s", field_id, lower, upper)
            raise ValueError(
                f"Invalid bounds for field {field_id}: min_value={lower}, max_value={upper}")
        return random.randint(lower, upper)

    if field_config.data_type == DataType.FLOAT:
        lower = field_config.min_value or 0.0
        upper = field_config.max_value or 100.0
        return round(random.uniform(lower, upper), 2)

    if field_config.data_type == DataType.STRING:
        options = field_config.string_options or ["OK", "WARNING", "ERROR"]
        return random.choice(options)

    if field_config.data_type == DataType.BOOLEAN:
        return random.choice([True, False])

    raise ValueError(f"Unsupported data type for field {field_id}")


def _build_response(field_id: str, timestamp: str) -> FieldValueResponse:
    field_config = CONFIG.fields[field_id]
    return FieldValueResponse(
        field_id=field_id,
        name=field_config.name,
        data_type=field_config.data_type,
        value=_generate_value(field_id),
        units=field_config.units,
        timestamp=timestamp,
        quality=_select_quality(),
        metadata=field_config.metadata,
    )


def _respond_with_validation(builder: Callable[[], FieldsArrayResponse | FieldValueResponse]):
    try:
        payload = builder()
        return jsonify(payload.model_dump()), 200
    except (ValidationError, ValueError) as exc:
        logger.exception("Payload validation failed: %s", exc)
        return jsonify({"error": "Internal validation error"}), 500


def _current_timestamp() -> str:
    return datetime.now(timezone.utc).isoformat()


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify(
        {
            "status": "healthy",
            "timestamp": _current_timestamp(),
            "device_id": DEVICE_ID,
            "sensor_type": SENSOR_TYPE,
            "fields_configured": len(CONFIG.fields),
        }
    )


@app.route("/sensor/fields/<field_id>", methods=["GET"])
def get_field(field_id: str):
    if field_id not in CONFIG.fields:
        return jsonify({"error": f"Field '{field_id}' not found"}), 404

    timestamp = _current_timestamp()
    return _respond_with_validation(lambda: _build_response(field_id, timestamp))


@app.route("/sensor/array/field", methods=["GET"])
def get_fields_array():
    field_ids = request.args.getlist("field_id")
    if not field_ids:
        return jsonify({"error": "No field_id parameters provided"}), 400

    missing = [field_id for field_id in field_ids if field_id not in CONFIG.fields]
    if missing:
        return jsonify({"error": f"Fields not found: {', '.join(missing)}"}), 404

    timestamp = _current_timestamp()

    def build() -> FieldsArrayResponse:
        responses = [_build_response(field_id, timestamp)
                     for field_id in field_ids]
        return FieldsArrayResponse(fields=responses, count=len(responses))

    return _respond_with_validation(build)


@app.route("/sensor/fields", methods=["GET"])
def list_fields():
    fields_summary = [
        {
            "field_id": field_id,
            "name": field_config.name,
            "data_type": field_config.data_type.value,
            "units": field_config.units,
        }
        for field_id, field_config in CONFIG.fields.items()
    ]
    return jsonify({"fields": fields_summary, "count": len(fields_summary)})


@app.route("/api/sensor/status", methods=["GET"])
def get_sensor_status():
    return jsonify(
        {
            "device_id": DEVICE_ID,
            "sensor_type": SENSOR_TYPE,
            "status": "online",
            "last_reading": _current_timestamp(),
            "total_readings": random.randint(1_000, 10_000),
            "error_count": random.randint(0, 5),
            "calibration_date": "2025-09-01T12:00:00Z",
            "next_calibration": "2026-03-01T12:00:00Z",
            "firmware_version": "2.1.4",
            "hardware_revision": "Rev C",
        }
    )


@app.route("/api/device/info", methods=["GET"])
def get_device_info():
    return jsonify(
        {
            "device_id": DEVICE_ID,
            "device_type": "sensor",
            "sensor_type": SENSOR_TYPE,
            "manufacturer": "MockSensors Inc",
            "model": "MS-TH-2024",
            "serial_number": f"MS{random.randint(100000, 999999)}",
            "firmware_version": "2.1.4",
            "supported_protocols": ["http"],
            "data_formats": ["json"],
            "measurement_ranges": {
                "temperature": {"min_celsius": -40, "max_celsius": 80, "accuracy": "±2°C"},
                "humidity": {"min_percent": 0, "max_percent": 100, "accuracy": "±5%"},
            },
            "endpoints": {
                "sensor_status": "/api/sensor/status",
                "device_info": "/api/device/info",
                "fields": "/sensor/fields",
                "field_single": "/sensor/fields/<field_id>",
                "fields_array": "/sensor/array/field",
                "health": "/health",
            },
            "polling_recommendations": {
                "minimum_interval_seconds": 5,
                "recommended_interval_seconds": 15,
                "maximum_rate_per_minute": 60,
            },
        }
    )


@app.route("/", methods=["GET"])
def root():
    return jsonify(
        {
            "service": "Field-Based Sensor Simulator",
            "device_id": DEVICE_ID,
            "sensor_type": SENSOR_TYPE,
            "version": "2.0.0",
            "endpoints": [
                "/health",
                "/sensor/fields",
                "/sensor/fields/<field_id>",
                "/sensor/array/field?field_id=...",
                "/api/sensor/status",
                "/api/device/info",
            ],
            "documentation": "https://github.com/microsoft/edge-ai/tree/main/src/500-application/505-akri-rest-http-connector",
        }
    )


if __name__ == "__main__":
    logger.info("Starting Field-Based Sensor Simulator for %s (%s)",
                DEVICE_ID, SENSOR_TYPE)
    logger.info("Listening on port %s", PORT)
    app.run(host="0.0.0.0", port=PORT, debug=False)
