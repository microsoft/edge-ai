"""FFmpeg lavfi test-pattern definitions for synthetic camera streams."""

from __future__ import annotations

AVAILABLE_PATTERNS: dict[str, dict[str, str]] = {
    "testsrc": {
        "label": "Test Source",
        "description": "Classic moving test pattern with timestamp",
        "filter": "testsrc=size={w}x{h}:rate={fps}",
    },
    "smptebars": {
        "label": "SMPTE Bars",
        "description": "Standard SMPTE color bars",
        "filter": "smptebars=size={w}x{h}:rate={fps}",
    },
    "smptehdbars": {
        "label": "SMPTE HD Bars",
        "description": "SMPTE high-definition color bars",
        "filter": "smptehdbars=size={w}x{h}:rate={fps}",
    },
    "color": {
        "label": "Solid Color",
        "description": "Solid blue background",
        "filter": "color=c=blue:size={w}x{h}:rate={fps}",
    },
    "rgbtestsrc": {
        "label": "RGB Test",
        "description": "RGB test circles pattern",
        "filter": "rgbtestsrc=size={w}x{h}:rate={fps}",
    },
    "mandelbrot": {
        "label": "Mandelbrot",
        "description": "Animated Mandelbrot fractal zoom",
        "filter": "mandelbrot=size={w}x{h}:rate={fps}",
    },
}

DEFAULT_PATTERN = "testsrc"


def get_pattern_filter(name: str, width: str, height: str, fps: str) -> str:
    """Return the formatted lavfi filter string for a given pattern name.

    Falls back to the default test source when the name is unrecognized.
    """
    entry = AVAILABLE_PATTERNS.get(name, AVAILABLE_PATTERNS[DEFAULT_PATTERN])
    return entry["filter"].format(w=width, h=height, fps=fps)


def list_patterns() -> list[dict[str, str]]:
    """Return serializable list of available patterns for the REST API."""
    return [
        {"name": name, "label": info["label"],
            "description": info["description"]}
        for name, info in AVAILABLE_PATTERNS.items()
    ]
