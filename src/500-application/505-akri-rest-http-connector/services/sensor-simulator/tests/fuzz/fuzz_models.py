"""Atheris fuzz harness for sensor-simulator FieldsConfig JSON parsing."""
import json
import sys
from pathlib import Path

import atheris

SERVICE_ROOT = Path(__file__).resolve().parents[2]
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

with atheris.instrument_imports():
    from models import FieldsConfig
    from pydantic import ValidationError


def TestOneInput(data: bytes) -> None:  # noqa: N802
    try:
        FieldsConfig.model_validate_json(data)
    except (ValidationError, ValueError, json.JSONDecodeError, UnicodeDecodeError):
        pass


if __name__ == "__main__":
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()
