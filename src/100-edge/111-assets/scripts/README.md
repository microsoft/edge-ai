---
title: IoT Assets Scripts
description: Scripts for checking ONVIF camera connectivity, media profiles, and pan-tilt-zoom control before registering the camera with Azure IoT Operations
author: Edge AI Team
ms.date: 2026-10-05
ms.topic: reference
keywords:
  - onvif
  - camera
  - ptz
  - azure iot operations
---

## IoT Assets Scripts

## onvif-ptz-check.sh

Checks an ONVIF camera directly over ONVIF SOAP, independent of Azure IoT Operations. Use it to confirm the camera's service addresses, find a media profile token, and verify pan and tilt control before you register the camera as a device and asset. The [ONVIF Camera Deployment Guide](../../../../docs/getting-started/onvif-camera-quickstart.md) covers registration.

| Command    | ONVIF operation                 | Output                                                   |
|------------|---------------------------------|----------------------------------------------------------|
| `services` | Device `GetServices`            | Media, PTZ, and other service addresses                  |
| `profiles` | Media `GetProfiles`             | Profile tokens, names, and whether each has a PTZ config |
| `move`     | PTZ `ContinuousMove` and `Stop` | Pans right and left, tilts up and down, then stops       |

### Usage

```bash
export CAMERA_HOST=<camera-ip>
export CAMERA_USERNAME=<camera-username>

./onvif-ptz-check.sh services
export ONVIF_MEDIA_URL=<media-service-address>
export ONVIF_PTZ_URL=<ptz-service-address>

./onvif-ptz-check.sh profiles
PROFILE_TOKEN=<profile-token> ./onvif-ptz-check.sh move
```

The script prompts for the password when `CAMERA_PASSWORD` is unset and it runs in a terminal. To read the credentials from an existing Kubernetes secret with `username` and `password` keys, set `K8S_SECRET_NAME` (and `K8S_NAMESPACE` if it isn't `azure-iot-operations`).

| Variable            | Default                 | Description                                    |
|---------------------|-------------------------|------------------------------------------------|
| `CAMERA_HOST`       | (required)              | Camera IP address or hostname                  |
| `CAMERA_PORT`       | `80`                    | ONVIF port                                     |
| `CAMERA_SCHEME`     | `http`                  | `http` or `https`                              |
| `ONVIF_DEVICE_PATH` | `/onvif/device_service` | Device service path                            |
| `ONVIF_MEDIA_URL`   | Device service URL      | Media service address from `services`          |
| `ONVIF_PTZ_URL`     | Device service URL      | PTZ service address from `services`            |
| `PROFILE_TOKEN`     | (required for `move`)   | Profile token from `profiles`                  |
| `MOVE_SECONDS`      | `2`                     | Seconds for each movement step                 |
| `CURL_MAX_TIME`     | `10`                    | Timeout in seconds for each request            |
| `CAMERA_USERNAME`   | (prompted)              | Camera username                                |
| `CAMERA_PASSWORD`   | (prompted)              | Camera password                                |
| `K8S_SECRET_NAME`   | (unset)                 | Kubernetes secret to read the credentials from |
| `K8S_NAMESPACE`     | `azure-iot-operations`  | Namespace of `K8S_SECRET_NAME`                 |

### Security Behavior

* Uses HTTP digest authentication and never falls back to basic authentication, so the password isn't sent in clear text over `http`.
* Passes credentials to `curl` through standard input, so they don't appear in the process list.
* Validates the host, port, paths, service URLs, and profile token before building requests.
* Sends `Stop` when a movement step fails or the script is interrupted.

For `https` cameras with a private certificate authority, set `CURL_CA_BUNDLE` to the CA certificate file.
