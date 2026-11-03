---
title: Camera Dashboard Source Modules
description: Python source modules for the camera-dashboard NiceGUI application including RTSP capture, MJPEG streaming, MQTT integration, ONVIF discovery, and PTZ control
author: Edge AI Team
ms.date: 2026-04-09
ms.topic: reference
keywords:
  - nicegui
  - rtsp
  - mjpeg
  - mqtt
  - onvif
  - ptz
  - camera
  - dashboard
estimated_reading_time: 3
---

## Camera Dashboard Source Modules

Python source modules for the camera-dashboard service. Each module encapsulates a single responsibility within the dashboard application.

## Module Overview

| Module                    | Purpose                                                                                |
|---------------------------|----------------------------------------------------------------------------------------|
| `app.py`                  | Application entry point — NiceGUI page definitions, camera registration, UI layout     |
| `camera_manager.py`       | RTSP capture threads with auto-reconnection and frame registry                         |
| `camera_preflight.py`     | Authenticated endpoint inspection and bounded decoded-frame verification               |
| `camera_onboarding.py`    | Revision-bound evidence and sanitized subprocess adapter for the fixed asset CLI       |
| `camera_onboarding_ui.py` | Explicit profile, capture, secret-reference, and private output controls               |
| `mjpeg_server.py`         | FastAPI MJPEG streaming endpoint and health check                                      |
| `mqtt_handler.py`         | MQTT client for PTZ command publishing and event subscription                          |
| `onvif_discovery.py`      | Opt-in WS-Discovery, bounded TCP candidate probing, authenticated stream URI retrieval |
| `ptz_controller.py`       | ONVIF PTZ operations (pan, tilt, zoom, home) with auto-stop scheduling                 |

## Module Details

### `app.py`

Application entry point that wires all modules together and defines the NiceGUI UI.

* **`/`** — Dashboard page with camera grid, add-camera form, network discovery dialog, PTZ controls, and MQTT event feed
* **`/camera/{cam_id}`** — Single-camera view with full-size MJPEG stream and dedicated PTZ controls
* `register_camera()` — Adds a camera to both the `CameraManager` capture registry and the `PTZController` ONVIF registry
* Loads initial cameras from `CAMERA_URLS` and `CAMERA_NAMES` environment variables

### `camera_manager.py`

* `RTSPCapture` — Background daemon thread that connects to an RTSP URL via OpenCV `VideoCapture`, stores the latest frame, and auto-reconnects on failure (configurable delay, default 5s)
* `CameraManager` — Dictionary-based registry mapping camera IDs to `RTSPCapture` instances. Provides `add_camera()`, `remove_camera()`, `get_frame()`, `list_cameras()`, and `stop_all()`

### `mjpeg_server.py`

* `generate_mjpeg()` — Generator yielding JPEG-encoded frames as multipart MJPEG chunks at a configurable FPS and quality
* `register_mjpeg_routes()` — Registers `/mjpeg/{camera_id}` (MJPEG stream) and `/health` (health check) on the NiceGUI FastAPI app

### `mqtt_handler.py`

* `MQTTHandler` — Wraps `paho-mqtt` for publishing PTZ commands and subscribing to camera events
* Publishes to `{topic_prefix}/ptz/command/{camera_id}/{action}` with JSON payloads
* Subscribes to `{topic_prefix}/events/#` and dispatches parsed events to a callback
* Convenience methods: `pan()`, `tilt()`, `zoom()`, `home()`

### `onvif_discovery.py`

* `ONVIFDiscovery` — Connects to a single ONVIF camera to retrieve device info, media profiles, and RTSP stream URIs
* `discover_onvif_devices()` supports two mutually exclusive, explicitly approved modes:
  * Targeted probing accepts IPv4 addresses, CIDR subnets, and last-octet ranges
    such as `192.168.1.1-254`, with optional `:port` and comma-separated tokens.
  * Multicast sends WS-Discovery UDP to `239.255.255.250:3702` only when
    `multicast=True` or the dashboard checkbox is selected. Empty targets never
    implicitly enable multicast.
* `_expand_targets()` validates every token and an arithmetic limit of 4096
  endpoints before materializing addresses or starting probes. Repeated tokens
  count toward the budget before deduplication. `/31` includes both addresses;
  `/32` includes its one address. Invalid IPv4 ranges and ports outside
  `1-65535` fail without network activity.
* TCP probes run in worker threads with at most 50 concurrent connections and
  two-second socket timeouts. Cancellation drains active workers and closes
  sockets before returning; pending probes do not start.
* Results distinguish `candidate` (open TCP port or WS-Discovery response),
  `unreachable` (connection failed), and `unknown` (unexpected probe failure).
  Candidates are not verified ONVIF cameras or decoded video streams.
* Discovery sends no credentials. The dialog requests credentials only for
  authenticated `ONVIFDiscovery` inspection when you add a candidate's stream.
  An unreachable or unknown result requires checking the endpoint and retrying.
  A multicast response may be absent on routed or multicast-filtered networks;
  use explicit targets instead.

### `ptz_controller.py`

* `PTZController` — Manages ONVIF PTZ connections per camera with lazy initialization
* Supports `pan()`, `tilt()`, `zoom()`, `home()`, and `stop()` operations via ONVIF `ContinuousMove` and `GotoHomePosition`
* Auto-stop scheduling — continuous moves are automatically stopped after 0.5s via `asyncio` tasks to prevent runaway motion

### `camera_preflight.py`

* `inspect_camera()` authenticates against an explicit ONVIF endpoint, retrieves
  media profiles, and records inspected PTZ support. This API is separate from
  unauthenticated candidate probing.
* `verify_rtsp_feed()` uses FFmpeg with `CAP_PROP_OPEN_TIMEOUT_MSEC` and
  `CAP_PROP_READ_TIMEOUT_MSEC` supplied to `VideoCapture.open()`, not `set()`.
  Only a nonempty decoded frame with positive dimensions succeeds. The capture
  is released after open failures, read failures, empty frames, and OpenCV errors.
* Userinfo, query strings, and fragments are stripped from exportable URIs.
  Credentials are used only for authenticated inspection and decoding; native
  decoder logging is disabled to avoid printing authenticated stream URIs.

### `camera_onboarding.py`

* `CameraOnboarding` binds frame evidence to the endpoint, profile token, stream
  URI, and random opaque credential revision. Connection edits invalidate
  inspection and frame evidence; profile edits invalidate frame evidence.
  In-flight results are ignored when their revision no longer matches.
* Export requires explicit camera selection, inspected PTZ support, a verified
  frame, an explicit MQTT publish topic, a positive finite snapshot rate, and
  username/password `secret-name/key` references.
* `generate_proposal()` calls the single asset renderer with
  `sys.executable` and `asyncio.create_subprocess_exec()`. Sanitized JSON travels
  on stdin, not command arguments. No renderer is duplicated in the dashboard.
* Source-tree execution uses `src/100-edge/111-assets/scripts/camera_onboarding.py`.
  The root-context dashboard image packages the CLI at
  `/app/camera-tools/camera_onboarding.py`; arbitrary script paths are rejected.
* Output must be a new private directory. Missing CLI, nonzero exit, malformed
  results, unexpected or nonprivate output paths, and filesystem failures produce
  bounded diagnostics. Cancellation kills and waits for the CLI subprocess.

### `camera_onboarding_ui.py`

* Adds onboarding controls to candidate cards without replacing existing manual
  add, preview, environment cameras, PTZ, MQTT events, or single-camera pages.
* Inspection does not automatically select a profile. Topic and snapshot rate
  start empty; secret references require an explicit key.
* Generation writes private discovery evidence and a Terraform proposal only.
  A decoded frame is point-in-time RTSP evidence, not proof of MQTT ingestion
  or deployment. Review output before using the existing asset deployment flow.

## Validation and Failure Recovery

From the repository root, in an environment with the hashed dashboard dependencies,
pytest, and Ruff installed:

```bash
python -m pytest -q src/500-application/510-onvif-connector/services/camera-dashboard/tests
python -m ruff check src/500-application/510-onvif-connector/services/camera-dashboard/src
```

Tests mock cameras, decoders, subprocess failures, and NiceGUI interactions; they
also run the actual shared CLI against private local output. When runtime
dependencies are available, native tests construct real NiceGUI controls, decode
a generated local MJPG file, and measure an FFmpeg open timeout against an
isolated loopback listener that does not answer RTSP requests. These tests do not
scan networks, contact hardware, or deploy infrastructure. Neither the synthetic
file nor the stalled listener proves live RTSP decoding, native read-timeout
behavior on a streaming camera, or MQTT delivery.

If inspection or verification fails, correct the current endpoint or profile and
retry; existing preview cameras remain intact. For generation failures, check
the fixed CLI installation, complete all capture and secret/key fields, and use
a new directory beneath an existing writable nonsymlink parent. Never reuse
partial output after cancellation. Container output needs a private writable
mount to survive container removal. See the [application README](../../../README.md)
for root-context image build instructions and detailed troubleshooting.

## Dependencies

* `nicegui` — Web UI framework (provides embedded FastAPI server)
* `opencv-python-headless` — RTSP capture and JPEG encoding
* `paho-mqtt` — MQTT client
* `onvif-zeep-async` — ONVIF camera communication and WS-Discovery
