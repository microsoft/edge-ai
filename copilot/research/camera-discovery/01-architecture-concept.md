# Camera Discovery: Architecture Concept

## System Overview

Two components working together:

```
┌─────────────────┐       ┌──────────────────────┐       ┌─────────────────┐
│  Input Manifest │──────▶│  Discovery Engine     │──────▶│ Output Manifest │
│  (YAML)         │       │  (Python)             │       │ (YAML)          │
│                 │       │                       │       │                 │
│ - IPs           │       │ ┌───────────────────┐ │       │ - Identity      │
│ - Credentials   │       │ │ Core Orchestrator │ │       │ - Streams       │
│                 │       │ └────────┬──────────┘ │       │ - Security      │
│                 │       │          │            │       │ - Control       │
│                 │       │ ┌────────▼──────────┐ │       │ - AI Detection  │
│                 │       │ │ Vendor Adapters   │ │       │ - Timestamp     │
│                 │       │ │ ├─ reolink.py     │ │       │                 │
│                 │       │ │ ├─ onvif.py       │ │       │                 │
│                 │       │ │ ├─ hikvision.py   │ │       │                 │
│                 │       │ │ └─ dahua.py       │ │       │                 │
│                 │       │ └───────────────────┘ │       │                 │
└─────────────────┘       └──────────────────────┘       └─────────────────┘
```

## Component Responsibilities

### Agent (camera-manifest.agent.md)

- Reads input YAML from user or file
- Invokes the discovery engine script per camera
- Collects results and assembles the site manifest
- Handles errors (camera unreachable, auth failed, unsupported vendor)
- Presents summary to user

### Discovery Engine (Python skill)

- Core orchestrator: accepts IP + credentials, returns structured dict
- Fingerprinting: determines vendor from HTTP headers, RTSP, or port signatures
- Vendor adapters: vendor-specific API logic (isolated, pluggable)
- Schema mapper: normalizes vendor-specific responses to the consumer-driven schema
- RTSP URL builder: constructs stream URLs using vendor patterns

## Vendor Adapter Pattern

Each adapter implements a common interface:

```python
class VendorAdapter:
    """Base class for vendor-specific camera discovery."""

    def authenticate(self, ip: str, username: str, password: str) -> Session:
        """Establish authenticated session. Return session/token."""
        ...

    def get_device_info(self, session: Session) -> dict:
        """Return manufacturer, model, serial, firmware, MAC."""
        ...

    def get_streams(self, session: Session) -> list[dict]:
        """Return stream configs (URL, codec, resolution, fps, bitrate)."""
        ...

    def get_security_state(self, session: Session) -> dict:
        """Return HTTPS, ONVIF, auth method status."""
        ...

    def get_control_capabilities(self, session: Session) -> dict:
        """Return PTZ type, ranges, IR mode, focus mode."""
        ...

    def get_ai_capabilities(self, session: Session) -> dict:
        """Return supported detection types."""
        ...
```

### Adapter Priority

1. **reolink.py** — first implementation, tested against RLC-520A
2. **onvif.py** — generic fallback using python-onvif-zeep (covers any ONVIF-compliant camera)
3. **hikvision.py** — ISAPI-based (future)
4. **dahua.py** — CGI-based (future)

### Fingerprinting and Adapter Selection

The orchestrator determines which adapter to use:

1. Port scan (8000 open = likely Hikvision/Reolink, 37777 = Dahua)
2. HTTP response (title, Server header, redirect patterns)
3. RTSP Server header
4. ONVIF GetDeviceInformation (if ONVIF is available)

If no vendor-specific adapter matches, fall back to the generic ONVIF adapter.

## Input Schema

```yaml
# site-cameras.yml (user provides this)
site:
  name: "Factory Floor A"
  location: "Building 3, Level 2"

cameras:
  - ip: 192.168.1.221
    username: admin
    password: "Marsden123"
    label: "Loading Dock East"   # optional human-friendly name
  - ip: 192.168.1.64
    username: admin
    password: "Camera456"
    label: "Assembly Line 1"
```

## Output Schema

```yaml
# site-manifest.yml (tool produces this)
site:
  name: "Factory Floor A"
  location: "Building 3, Level 2"
  discovered_at: "2026-05-18T20:33:55Z"
  camera_count: 2

cameras:
  - label: "Loading Dock East"
    ip_address: 192.168.1.221
    manufacturer: Reolink
    model: RLC-520A
    serial_number: "00000000524288"
    mac_address: "ec:71:db:23:21:91"
    firmware_version: v3.0.0.2417_23070501
    discovered_at: "2026-05-18T20:33:55Z"

    streams:
      main:
        url: "rtsp://admin:****@192.168.1.221:554/h264Preview_01_main"
        codec: h264
        resolution: "2560x1920"
        frame_rate: 30
        bitrate_kbps: 6144
        profile: High
      sub:
        url: "rtsp://admin:****@192.168.1.221:554/h264Preview_01_sub"
        codec: h264
        resolution: "640x480"
        frame_rate: 10
        bitrate_kbps: 256
        profile: High

    security:
      https_enabled: true
      onvif_enabled: true
      onvif_port: 8000
      auth_method: token

    control:
      ptz_type: fixed
      pan_range: null
      tilt_range: null
      zoom_type: null
      zoom_ratio: null
      presets_available: null
      ir_mode: Auto
      focus_mode: null

    ai_detection:
      person: true
      vehicle: true
      pet: true
      face: false

  - label: "Assembly Line 1"
    ip_address: 192.168.1.64
    # ... same structure
```

## Error Handling

When a camera fails discovery, include it in the output with an error field:

```yaml
  - label: "Assembly Line 1"
    ip_address: 192.168.1.64
    error: "Connection refused on all ports"
    discovered_at: "2026-05-18T20:34:02Z"
```

## Security Considerations

- Credentials in input YAML: user's responsibility to secure the file
- Credentials in output YAML: always masked (replace password with `****`)
- Session tokens: never persisted to output
- Network scanning: only IPs explicitly listed (no subnet sweeps without user consent)

## File Locations

| Component | Path |
|---|---|
| Agent | `.github/agents/experimental/camera-manifest.agent.md` |
| Skill | `.github/skills/experimental/camera-discovery/` |
| Discovery script | `.github/skills/experimental/camera-discovery/scripts/discover.py` |
| Vendor adapters | `.github/skills/experimental/camera-discovery/scripts/adapters/` |
| Skill instructions | `.github/skills/experimental/camera-discovery/SKILL.md` |

## Build Order

1. Reolink adapter (tested against live RLC-520A)
2. Core orchestrator + schema mapper
3. Agent file (invokes skill)
4. ONVIF generic adapter (fallback)
5. Additional vendor adapters as needed
