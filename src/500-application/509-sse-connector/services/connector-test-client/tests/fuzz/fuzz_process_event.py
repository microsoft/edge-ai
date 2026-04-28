"""Atheris fuzz harness for sse-connector ConnectorClient.process_event."""
import asyncio
import sys
from pathlib import Path

import atheris

SERVICE_ROOT = Path(__file__).resolve().parents[2]
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

with atheris.instrument_imports():
    from connector_client import ConnectorClient


_CLIENT = ConnectorClient()


def TestOneInput(data: bytes) -> None:  # noqa: N802
    fdp = atheris.FuzzedDataProvider(data)
    event_type = fdp.ConsumeUnicodeNoSurrogates(32)
    event_data = fdp.ConsumeUnicodeNoSurrogates(512)
    try:
        asyncio.run(_CLIENT.process_event(event_type, event_data))
    except (ValueError, TypeError, KeyError, RuntimeError):
        pass


if __name__ == "__main__":
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()
