"""Shared pytest configuration for the sensor simulator test suite.

Sets FIELD_CONFIG_PATH before any test module imports `app`, since
`app.py` loads field configuration at module import time.
"""

import os
from pathlib import Path

_RESOURCES_CONFIG = Path(__file__).resolve(
).parent.parent.parent / "resources" / "field_sources.json"

os.environ.setdefault("FIELD_CONFIG_PATH", str(_RESOURCES_CONFIG))
