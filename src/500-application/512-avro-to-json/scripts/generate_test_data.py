#!/usr/bin/env python3
"""Test utility for generating sample Avro data for the avro-to-json module."""

import json
import io
from pathlib import Path
from typing import Any

try:
    import avro.schema
    import avro.io
    import avro.datafile
except ImportError:
    print("Error: avro-python3 package required. Install with:")
    print("  pip install avro-python3")
    exit(1)

SCRIPT_DIR = Path(__file__).resolve().parent
SCHEMA_PATH = SCRIPT_DIR / ".." / "resources" / "schemas" / "equipment-telemetry.avsc"


def load_schema() -> str:
    """Load the Avro schema from the resources directory."""
    schema_file = SCHEMA_PATH.resolve()
    if not schema_file.exists():
        print(f"Error: Schema file not found at {schema_file}")
        exit(1)
    return schema_file.read_text()


def create_sample_data() -> dict[str, Any]:
    """Create sample EquipmentTelemetry data."""
    return {
        "equipmentId": "EQUIP-PRESS-042",
        "sensorType": "TEMPERATURE",
        "value": 78.5,
        "unit": "celsius",
        "timestamp": 1771342450362,
        "qualityCode": {"int": 192},
        "location": {
            "plant": "contoso-east",
            "line": "assembly-line-3",
            "station": "station-7",
        },
    }


def encode_avro_binary(schema_str: str, data: dict[str, Any]) -> bytes:
    """Encode data as Avro binary using the provided schema."""
    schema = avro.schema.parse(schema_str)
    writer = avro.io.DatumWriter(schema)
    bytes_writer = io.BytesIO()
    encoder = avro.io.BinaryEncoder(bytes_writer)
    writer.write(data, encoder)
    return bytes_writer.getvalue()


def encode_avro_container_file(
    schema_str: str, data: dict[str, Any]
) -> bytes:
    """Encode data as Avro Object Container File (includes schema)."""
    schema = avro.schema.parse(schema_str)
    bytes_writer = io.BytesIO()
    writer = avro.datafile.DataFileWriter(
        bytes_writer, avro.io.DatumWriter(), schema
    )
    writer.append(data)
    writer.flush()
    return bytes_writer.getvalue()


def main() -> None:
    """Generate test Avro files."""
    print("Generating test Avro data...")

    schema_str = load_schema()
    sample_data = create_sample_data()

    print("\n1. Binary format (schema required):")
    binary_data = encode_avro_binary(schema_str, sample_data)
    with open("test_binary.avro", "wb") as f:
        f.write(binary_data)
    print(f"   Created: test_binary.avro ({len(binary_data)} bytes)")
    print("   Note: Requires schema in configuration to decode")

    print("\n2. Object Container File format (schema embedded):")
    container_data = encode_avro_container_file(schema_str, sample_data)
    with open("test_container.avro", "wb") as f:
        f.write(container_data)
    print(f"   Created: test_container.avro ({len(container_data)} bytes)")
    print("   Note: Contains embedded schema - auto-detected by module")

    with open("schema.json", "w") as f:
        json.dump(json.loads(schema_str), f, indent=2)
    print("\n3. Schema saved: schema.json")

    with open("expected_output.json", "w") as f:
        json.dump(sample_data, f, indent=2)
    print("4. Expected JSON output saved: expected_output.json")

    print("\nTest files generated successfully")


if __name__ == "__main__":
    main()
