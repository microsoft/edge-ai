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

| Module               | Purpose                                                                            |
|----------------------|------------------------------------------------------------------------------------|
| `app.py`             | Application entry point — NiceGUI page definitions, camera registration, UI layout |
| `camera_manager.py`  | RTSP capture threads with auto-reconnection and frame registry                     |
| `mjpeg_server.py`    | FastAPI MJPEG streaming endpoint and health check                                  |
| `mqtt_handler.py`    | MQTT client for PTZ command publishing and event subscription                      |
| `onvif_discovery.py` | WS-Discovery multicast probe, direct ONVIF device probing, stream URI retrieval    |
| `ptz_controller.py`  | ONVIF PTZ operations (pan, tilt, zoom, home) with auto-stop scheduling             |

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
* `discover_onvif_devices()` — Async entry point supporting two modes:
  * **Targeted probe** — Direct TCP connection to specified hosts (supports single IP, IP:port, CIDR subnets, IP ranges)
  * **Multicast discovery** — WS-Discovery UDP probe to `239.255.255.250:3702`
* `_expand_targets()` — Parses comma-separated target strings into `(host, port)` tuples with support for CIDR and range notation
* Concurrency-limited (semaphore of 50) for targeted subnet scans

### `ptz_controller.py`

* `PTZController` — Manages ONVIF PTZ connections per camera with lazy initialization
* Supports `pan()`, `tilt()`, `zoom()`, `home()`, and `stop()` operations via ONVIF `ContinuousMove` and `GotoHomePosition`
* Auto-stop scheduling — continuous moves are automatically stopped after 0.5s via `asyncio` tasks to prevent runaway motion

## Dependencies

* `nicegui` — Web UI framework (provides embedded FastAPI server)
* `opencv-python-headless` — RTSP capture and JPEG encoding
* `paho-mqtt` — MQTT client
* `onvif-zeep-async` — ONVIF camera communication and WS-Discovery
