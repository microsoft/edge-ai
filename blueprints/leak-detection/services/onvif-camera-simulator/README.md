---
title: ONVIF Camera Simulator
description: Python-based ONVIF camera simulator with real RTSP streaming for the leak-detection blueprint
author: Edge AI Team
ms.date: 2026-02-23
ms.topic: reference
keywords:
  - onvif
  - camera-simulator
  - rtsp
  - leak-detection
estimated_reading_time: 5
---

## Overview

The ONVIF Camera Simulator provides a fully functional ONVIF-compliant virtual camera that produces real RTSP video streams. It combines Python-based ONVIF SOAP endpoints with an embedded MediaMTX RTSP server and FFmpeg for stream generation, allowing development and testing of vision pipelines without physical cameras.

## Features

* **ONVIF Profile S and T** support with valid SOAP XML responses
* **Real RTSP streams** via embedded MediaMTX and FFmpeg
* **JPEG and MP4 source types** producing H.264 RTSP output
* **Web management UI** for camera listing, status monitoring, source hot-swap, and live stream preview
* **WebRTC stream preview** with sub-second latency directly in the browser via WHEP protocol
* **REST API** for programmatic camera management and media upload
* **Multi-camera support** with independent stream lifecycles
* **Hot-swap capable** media source changes without dropping RTSP connections
* **Docker Compose** integration for local development
* **Kustomize packaging** for Kubernetes edge deployment

## Quick Start

From the blueprint root directory:

```bash
cd blueprints/leak-detection
docker compose up --build
```

Access the services:

* Web UI: <http://localhost:8080/>
* ONVIF SOAP: <http://localhost:8080/onvif/device_service>
* RTSP Stream: `rtsp://localhost:8554/cam1`
* Health Check: <http://localhost:8080/health>

Click the **Preview** button on any streaming camera card to view a live WebRTC stream directly in the browser.

## Configuration

Environment variables control camera definitions and server behavior.

### Server Settings

| Variable             | Default              | Description                       |
| -------------------- | -------------------- | --------------------------------- |
| `ONVIF_PORT`         | `8080`               | HTTP port for ONVIF and Web UI    |
| `MEDIAMTX_RTSP_PORT` | `8554`               | RTSP server port                  |
| `DEVICE_HOSTNAME`    | `localhost`           | Hostname in ONVIF RTSP URIs       |
| `MEDIAMTX_PATH`      | `/usr/local/bin/mediamtx` | Path to MediaMTX binary      |
| `MEDIAMTX_CONFIG`    | `/app/mediamtx.yml`  | Path to MediaMTX configuration    |
| `LOG_LEVEL`          | `INFO`               | Python logging level              |

### WebRTC Preview Settings

The web UI includes a live stream preview using WebRTC (WHEP protocol). MediaMTX handles WebRTC
internally and the signaling is proxied through the HTTP port.

| Variable                     | Default     | Description                                              |
| ---------------------------- | ----------- | -------------------------------------------------------- |
| `WEBRTC_MEDIA_PORT`          | `8189`      | UDP/TCP port for WebRTC media transport                  |
| `MEDIAMTX_WEBRTC_PORT`       | `8889`      | Internal WebRTC/WHEP signaling port (not exposed)        |
| `MTX_WEBRTCADDITIONALHOSTS`  | —           | Externally-reachable hostname/IP for WebRTC ICE candidates |

### Camera Definitions

Define cameras using a comma-separated list and per-camera environment variables:

| Variable                | Description                                  |
| ----------------------- | -------------------------------------------- |
| `CAMERAS`               | Comma-separated list of camera IDs           |
| `CAM{KEY}_NAME`         | Display name for the camera                  |
| `CAM{KEY}_SOURCE`       | Path to JPEG or MP4 media file               |
| `CAM{KEY}_TYPE`         | Source type: `jpeg` or `mp4`                 |
| `CAM{KEY}_RESOLUTION`   | Stream resolution (default: `1920x1080`)     |
| `CAM{KEY}_FRAMERATE`    | Stream framerate (default: `15`)             |

`{KEY}` is the uppercased camera ID with hyphens replaced by underscores.

### Example Configuration

```bash
CAMERAS=cam1,cam2
CAM1_NAME=Leak Detector Front
CAM1_SOURCE=/data/front.jpg
CAM1_TYPE=jpeg
CAM2_NAME=Leak Detector Rear
CAM2_SOURCE=/data/rear.mp4
CAM2_TYPE=mp4
```

## Architecture

```text
┌──────────────────────────────────────────────────────┐
│                  Container                           │
│                                                      │
│  ┌──────────────────────┐                            │
│  │   Python Application │                            │
│  │                      │                            │
│  │  ┌────────────────┐  │   ┌──────────────────────┐ │
│  │  │ ONVIF SOAP     │  │   │   MediaMTX            │ │
│  │  │ :8080/onvif/*  │  │   │   RTSP  :8554         │ │
│  │  ├────────────────┤  │   │   WebRTC :8889 (int)  │ │
│  │  │ REST API       │  │   │   Media  :8189 (ext)  │ │
│  │  │ :8080/api/*    │  │   └─────────▲─────────────┘ │
│  │  │ WHEP Proxy     │──┼────────────►│               │
│  │  ├────────────────┤  │    ┌────────┴─────────┐    │
│  │  │ Web UI         │  │    │   FFmpeg          │    │
│  │  │ :8080/         │  │    │   (per camera)    │    │
│  │  ├────────────────┤  │    └────────▲──────────┘    │
│  │  │ Camera Manager │──┼────────────►│               │
│  │  │ RTSP Manager   │  │      start/stop            │
│  │  └────────────────┘  │                            │
│  └──────────────────────┘                            │
└──────────────────────────────────────────────────────┘
```

## API Reference

### REST Endpoints

| Method | Path                       | Description                        |
| ------ | -------------------------- | ---------------------------------- |
| GET    | `/api/cameras`             | List all cameras with status       |
| POST   | `/api/cameras`             | Add a new camera                   |
| GET    | `/api/cameras/{id}`        | Get camera details                 |
| PUT    | `/api/cameras/{id}`        | Update camera configuration        |
| DELETE | `/api/cameras/{id}`        | Remove a camera and stop stream    |
| PUT    | `/api/cameras/{id}/source` | Hot-swap media source              |
| GET    | `/api/media`               | List available media files         |
| POST   | `/api/media/upload`        | Upload a new media file            |
| GET    | `/health`                  | Health check endpoint              |
| GET    | `/snapshot/{camera_id}`    | Capture JPEG snapshot from stream  |

### WHEP Proxy Endpoints (WebRTC Preview)

| Method | Path                                | Description                        |
| ------ | ----------------------------------- | ---------------------------------- |
| POST   | `/api/cameras/{id}/whep`            | Send SDP offer, receive SDP answer |
| PATCH  | `/api/cameras/{id}/whep/{session}`  | Trickle ICE candidates             |
| DELETE | `/api/cameras/{id}/whep/{session}`  | Tear down WebRTC session           |

### ONVIF SOAP Endpoints

| Path                        | ONVIF Service         |
| --------------------------- | --------------------- |
| `/onvif/device_service`     | Device Management     |
| `/onvif/media_service`      | Media (Profile S)     |
| `/onvif/media2_service`     | Media2 (Profile T)    |
| `/onvif/ptz_service`        | PTZ Control           |
| `/onvif/event_service`      | Event Handling        |
| `/onvif/imaging_service`    | Imaging Settings      |

## Adding Media

Place JPEG or MP4 files in the `media/` directory. The simulator mounts this directory as `/data` inside the container.

Supported formats:

* **JPEG** (`.jpg`, `.jpeg`): Still images streamed as continuous H.264 video
* **MP4** (`.mp4`): Video files looped continuously as H.264 RTSP streams

Generate a test image with FFmpeg:

```bash
ffmpeg -f lavfi -i color=c=blue:s=1920x1080:d=1 -frames:v 1 media/test.jpg
```

## Kubernetes Deployment

Deploy to an Arc-connected cluster using Kustomize:

```bash
cd blueprints/leak-detection/services/onvif-camera-simulator

charts/gen-patch.sh \
  --acr-name myacr \
  --image-name onvif-camera-simulator \
  --image-version v1.0.0 \
  --namespace azure-iot-operations

kubectl apply -k charts/
```

### gen-patch.sh Flags

| Flag              | Default                  | Description              |
| ----------------- | ------------------------ | ------------------------ |
| `--acr-name`      | `acrmodules01`           | Azure Container Registry |
| `--image-name`    | `onvif-camera-simulator` | Container image name     |
| `--image-version` | `latest`                 | Image tag                |
| `--namespace`     | `azure-iot-operations`   | Kubernetes namespace     |

## Integration

The ONVIF Camera Simulator integrates with the leak-detection pipeline as the video source layer. Akri Media Connector discovers the simulator via its ONVIF endpoints and consumes the RTSP streams for downstream vision processing.

```text
ONVIF Camera Simulator → Akri Media Connector → AI Inference → Action
```

## Stream Preview

The web UI includes a live stream preview for each camera. Clicking **Preview** on a streaming camera card opens a WebRTC connection with sub-second latency.

### How it works

1. The browser creates an SDP offer and POSTs it to `/api/cameras/{id}/whep`
2. The Python app proxies the WHEP signaling to MediaMTX's internal WebRTC endpoint
3. MediaMTX returns an SDP answer with ICE candidates
4. WebRTC media (RTP) flows directly between MediaMTX port 8189 and the browser

### Network requirements

* **Port 8080** (TCP): HTTP — WHEP signaling, REST API, Web UI, ONVIF SOAP
* **Port 8554** (TCP): RTSP streams
* **Port 8189** (UDP+TCP): WebRTC media transport — must be reachable from the browser

When running in Docker or Kubernetes, set `MTX_WEBRTCADDITIONALHOSTS` to the externally-reachable hostname or IP so that MediaMTX ICE candidates use the correct address.

```bash
# Docker Compose example
DEVICE_HOSTNAME=192.168.1.100 docker compose up
```
