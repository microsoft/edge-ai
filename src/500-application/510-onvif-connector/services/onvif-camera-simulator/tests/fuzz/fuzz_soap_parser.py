"""Atheris fuzz harness for onvif-camera-simulator SOAP XML parser (XXE-hardened)."""
import sys
from pathlib import Path

import atheris

SERVICE_ROOT = Path(__file__).resolve().parents[2]
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

with atheris.instrument_imports():
    from lxml import etree
    from onvif_camera import ONVIF_NAMESPACES


def TestOneInput(data: bytes) -> None:  # noqa: N802
    try:
        parser = etree.XMLParser(resolve_entities=False, no_network=True)
        root = etree.fromstring(data, parser=parser)
        root.find(".//soap:Body", ONVIF_NAMESPACES)
    except (etree.XMLSyntaxError, ValueError, TypeError):
        pass


if __name__ == "__main__":
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()
