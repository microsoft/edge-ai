"""Smoke fuzz harness — minimal Atheris stub to exercise CI plumbing."""
import sys

import atheris


def TestOneInput(data: bytes) -> None:  # noqa: N802
    _ = bytes(data)


if __name__ == "__main__":
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()
