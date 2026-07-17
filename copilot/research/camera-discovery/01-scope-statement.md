# Camera Discovery Schema: Scope Statement

## Purpose

A machine-readable contract that tells consumers what they can do with each discovered camera on a network. Not a spec dump — a curated manifest shaped by what downstream tools act on.

## Target Users

On-field engineers provisioning shipments of 3-100 cameras with varying capabilities and access requirements.

## Consumers

| # | Consumer | Need | Priority |
|---|---|---|---|
| 1 | VMS (Video Management System) | Stream access: what URLs to subscribe to, what format to expect | High |
| 2 | Compliance / Security | Identity verification: is this camera what we expect, is it secured properly | High |
| 3 | Edge Inference Pipeline | Compute sizing: resolution, frame rate, codec to allocate resources | Medium |
| 4 | Camera Control Tools | Command safety: what operations are valid for this camera | High |

## Core Fields Per Consumer

### VMS (Stream Access)

- RTSP URL (main stream)
- RTSP URL (sub stream)
- Codec per stream (H.264, H.265, MJPEG)
- Resolution per stream
- Authentication method (digest, token, basic)

### Compliance / Security

- Manufacturer, model, serial number, MAC address
- Firmware version
- HTTPS enabled
- ONVIF enabled
- Discovered timestamp

### Edge Inference (Compute Sizing)

- Max resolution (width x height)
- Max frame rate
- Codec
- Bitrate (or bitrate mode: CBR/VBR)
- Stream URL to subscribe to

### Camera Control (Command Safety)

- PTZ type (fixed, motorized varifocal, mechanical PTZ, ePTZ)
- Pan range and speed
- Tilt range and speed
- Zoom type (optical, digital, none) and ratio
- Preset positions available
- IR control mode (auto, manual, off)
- Focus mode (auto, manual)

## Schema Design Principles

- **Timestamp every manifest**: include `discovered_at` so consumers know how fresh the data is.
- **Current state only**: no desired-state or drift detection. Consumers own comparison logic.
- **Null means not supported**: use `null` for capabilities the camera lacks (PTZ fields on fixed cameras).
- **Curated, not exhaustive**: include only fields that consumers act on. Expand when real consumers request more.
- **Discoverable from network**: every field must be derivable from API/ONVIF/RTSP probes (no manual spec entry required).

## Scope Boundaries

### In Scope

- Discover cameras from IP + credentials (single or batch)
- Produce a YAML manifest per camera with ~20-25 curated fields
- Support multi-camera site manifests (batch discovery)
- Schema optimized for VMS, compliance, inference, and control consumers

### Out of Scope (for now)

- Pushing configuration to cameras
- Desired-state management or policy enforcement
- Drift detection logic (consumers own that)
- Manual spec entry for fields not discoverable from the network
- Camera firmware updates or management

## Lifecycle

The manifest is a **snapshot**: generated during onboarding, re-runnable on demand. It is not a continuously monitored document. Re-run the tool to get a fresh timestamp and updated state.

## Input Shape

Minimal seed: IP address(es) + credentials. Tool discovers everything else.

```yaml
# Input example
cameras:
  - ip: 192.168.1.221
    username: admin
    password: "********"
  - ip: 192.168.1.64
    username: admin
    password: "********"
```

## Output Shape

One manifest per camera (or combined site manifest). Fields sourced from live discovery.

```yaml
# Output example (single camera)
discovered_at: "2026-05-18T20:33:55Z"
manufacturer: Reolink
model: RLC-520A
serial_number: "00000000524288"
mac_address: "ec:71:db:23:21:91"
firmware_version: v3.0.0.2417_23070501
ip_address: 192.168.1.221

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
