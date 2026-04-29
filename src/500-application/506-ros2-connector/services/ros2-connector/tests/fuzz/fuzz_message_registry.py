"""Atheris fuzz harness for ros2-connector MessageTypeRegistry.get_handler."""
# trigger fuzz CI
import sys
from pathlib import Path

import atheris

SERVICE_ROOT = Path(__file__).resolve().parents[2]
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

with atheris.instrument_imports():
    from src.message_types.registry import MessageTypeRegistry


_REGISTRY = MessageTypeRegistry()


def TestOneInput(data: bytes) -> None:  # noqa: N802
    fdp = atheris.FuzzedDataProvider(data)
    message_type = fdp.ConsumeUnicodeNoSurrogates(64)
    try:
        _REGISTRY.get_handler(message_type)
    except (KeyError, ValueError, TypeError):
        pass


if __name__ == "__main__":
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()
