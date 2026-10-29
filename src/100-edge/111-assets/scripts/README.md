---
title: IoT Assets Scripts
description: Scripts for checking ONVIF camera connectivity, media profiles, and pan-tilt-zoom control before registering the camera with Azure IoT Operations
author: Edge AI Team
ms.date: 2026-10-29
ms.topic: reference
keywords:
  - onvif
  - camera
  - ptz
  - azure iot operations
---

## IoT Assets Scripts

## camera_onboarding.py

Generates a review-only Terraform variable proposal and confidential discovery
evidence from inspected, frame-verified camera selections. The generator uses
Python 3.11 or later and the standard library only. It does not import camera
libraries, contact cameras, resolve secrets, apply infrastructure, or update an
operational registry.

### CLI usage

Run on a POSIX filesystem that supports no-follow directory operations. Supply a
new output directory beneath an existing parent. Existing directories, including
private empty directories, are rejected rather than overwritten.

```bash
python src/100-edge/111-assets/scripts/camera_onboarding.py \
  --input - --output-directory ./private-camera-proposal < selections.json
```

Only stdin input (`--input -`) is supported. Keep `selections.json` private and
outside source control and container build contexts. Dashboard callers should
send the same sanitized JSON directly through subprocess stdin without a shell;
never put credentials in command arguments or this document.

Successful stdout is one JSON object with absolute paths:

```json
{
  "discovery_path": "/private/output/camera-discovery-results.json",
  "tfvars_path": "/private/output/camera-onboarding.tfvars.example"
}
```

Errors return exit code `2`, with a diagnostic on stderr and no success object.
Diagnostics identify contract fields or filesystem failure categories, not input
values, rejected keys, URLs, credentials, or output paths. `--help` returns `0`.

### Exact selection contract

The root object has exactly one field, `cameras`, a nonempty array. Each entry
must have exactly the fields below; every nested object also has an exact
allowlist. There is no `selected` flag: all submitted records must be inspected
and verified. Unknown fields, including raw credentials, metadata blobs, and
credential hashes, are rejected rather than copied or silently dropped.
Duplicate JSON fields and nonfinite numbers are rejected.

This complete example uses documentation-only addresses and an example rate.
The topic and rate are required operator choices, not defaults.

```json
{
  "cameras": [
    {
      "display_name": "Loading dock",
      "onvif_endpoint": "http://192.0.2.10/onvif/device_service",
      "selected_profile": {
        "token": "main",
        "name": "Main stream",
        "stream_uri": "rtsp://192.0.2.10:554/main"
      },
      "inspection": {
        "status": "inspected",
        "supports_ptz": true
      },
      "credential_revision": "sNzI3h7p9Rq6vT2k",
      "feed_verification": {
        "status": "verified_live_feed",
        "onvif_endpoint": "http://192.0.2.10/onvif/device_service",
        "profile_token": "main",
        "stream_uri": "rtsp://192.0.2.10:554/main",
        "credential_revision": "sNzI3h7p9Rq6vT2k",
        "frame_width": 1920,
        "frame_height": 1080
      },
      "username_secret_name": "camera-credentials/username",
      "password_secret_name": "camera-credentials/password",
      "capture": {
        "task_type": "snapshot-to-mqtt",
        "topic": "cameras/loading-dock/snapshots",
        "snapshots_per_second": 0.2
      }
    }
  ]
}
```

Validation rules:

* `display_name`, profile `token`, and profile `name` must be nonempty printable
  UTF-8 text, at most 256 characters.
* ONVIF endpoints must use `http` or `https`; stream URIs must use `rtsp`.
  URIs are limited to 8192 characters and must contain a valid DNS host or IP
  address, with any explicit port between 1 and 65535. User information, query
  strings (even empty), fragments, whitespace, backslashes, malformed percent
  escapes, and encoded path control characters are rejected. Do not send
  token-bearing or credential-bearing addresses.
* `inspection.status` must be `inspected`, and `supports_ptz` must be a JSON
  boolean. TCP reachability and a profile listing are not decoded-frame evidence.
* `credential_revision` must be an opaque UI-generated random token, 16-128
  ASCII letters, digits, underscores, or hyphens. Generate a fresh token whenever
  credentials change. Do not derive it from a username, password, or credential
  hash. The CLI validates its shape, not its randomness.
* Verification requires `verified_live_feed`, positive integer frame dimensions,
  and exact matches for the current ONVIF endpoint, profile token, stream URI,
  and credential revision. URI spellings are not normalized. Changing any bound
  value requires new decoded-frame evidence. The CLI trusts these point-in-time
  assertions from its caller; it cannot authenticate them or guarantee freshness
  or continuing camera health.
* Each credential reference must be `secret-name/key`. The secret name is a
  lowercase Kubernetes DNS subdomain, at most 253 characters with labels of at
  most 63 characters. The key is independently validated: 1-253 ASCII letters,
  digits, `.`, `_`, or `-`, excluding `.` and names starting with `..`.
  Username and password references may use different secrets and keys.
* `capture.task_type` must be `snapshot-to-mqtt`. `topic` must be a nonblank
  printable UTF-8 MQTT publish topic, at most 65535 encoded bytes, without `+`
  or `#`. `snapshots_per_second` must be a positive finite JSON number
  representable as a finite Python float; booleans and numeric strings are invalid.
  No task, topic, or rate is inferred.

### Generated resources and identities

Every selection generates separate `Microsoft.Onvif` and `Microsoft.Media`
devices with `UsernamePassword` secret/key references. The proposal enables
both `should_enable_akri_onvif_connector` and
`should_enable_akri_media_connector`. The snapshot asset references the generated
Media device and endpoint through `device_ref`; its `snapshots` stream contains
the media connector's real task configuration:

```json
{
  "taskType": "snapshot-to-mqtt",
  "autostart": true,
  "format": "jpeg",
  "snapshotsPerSecond": 0.2
}
```

The stream has a `Mqtt` destination whose configuration contains the explicit
topic. Inspected PTZ support additionally generates an ONVIF management asset
with the quickstart's `Call` actions: `RelativeMove`, `ContinuousMove`, `Stop`,
`GotoHomePosition`, and `GotoPreset`. No event groups or event destinations
are invented.

Resource names use a digest of the exact ONVIF endpoint, profile token, RTSP URI,
task type, and topic, not the RTSP URI alone or credential material. Labels,
rates, and credential revisions do not change resource identities. Repeated
identities are rejected; changing the endpoint, profile, stream, or task topic
creates a different identity. Digest-prefix collisions receive deterministic
suffixes sorted by identity. Camera order does not affect either output file.
HCL strings preserve literal `${...}` and `%{...}` sequences through Terraform
template escaping, including object keys.

The proposal follows the
[111-assets variable schemas](../terraform/variables.tf),
[508 snapshot contract](../../../500-application/508-media-connector/README.md#configuring-media-connector-assets),
and [ONVIF PTZ quickstart](../../../../docs/getting-started/onvif-camera-quickstart.md#step-4-add-the-ptz-control-asset).
Review generated lists against existing ADR resources. A tfvars list replaces a
variable value, not appends to it: merge resources into the deployment's existing
variables, and do not also import discovered resources for the same endpoint/task
under different names. The proposal is not evidence of deployment or MQTT delivery.

### Private output and failure handling

All records are validated and both documents are rendered before creating the
output directory. No output directory or files are created for invalid input.
Existing targets and symlinks in any path component are rejected; parent
directories must already exist. Directory-relative, no-follow operations create
the new directory with mode `0700` and exclusive files with mode `0600`, without
a permissive create-then-chmod window.

Both files are staged with `.partial` suffixes, flushed and synced, then renamed
within the private directory. Each rename is atomic, but the pair is not a
filesystem transaction. Write, sync, or rename failures trigger removal of the
new files and directory; there is no success fallback. If cleanup fails, the
error explicitly warns that private partial files may remain. A process kill or
crash can also leave a private directory. Inspect and remove that directory
before retrying with a new destination. If stdout fails after publication, the
CLI returns an error but leaves the complete private files available for review.

`camera-discovery-results.json` contains the validated allowlisted contract plus
each selection's generated `resource_name`, sorted deterministically. It retains
the opaque credential revision and frame binding, not credentials. Both evidence
and the proposal are confidential: internal addresses, profile identifiers,
topics, labels, and secret names are not public data.

### Direct API and focused validation

The same module exposes `render_tfvars(cameras) -> str`,
`render_discovery(cameras) -> str`, and
`write_onboarding_outputs(cameras, output_directory) -> tuple[Path, Path]`.
These functions take the root document's `cameras` array, not the wrapper object.
The returned paths are discovery first, tfvars second. Validation and output
errors raise `OnboardingError` with payload-free messages. Direct render and CLI
output bytes are identical.

Run the focused tests and Ruff from the repository root with your isolated
Python environment. The test base directory stays inside the worktree.

```bash
PYTHONDONTWRITEBYTECODE=1 python -m pytest -q -p no:cacheprovider \
  --basetemp=.pytest-camera-onboarding \
  src/100-edge/111-assets/scripts/tests/test_camera_onboarding.py
python -m ruff check src/100-edge/111-assets/scripts/camera_onboarding.py \
  src/100-edge/111-assets/scripts/tests/test_camera_onboarding.py
```

These offline checks cover contract validation, task semantics, evidence binding,
HCL literals, identities, private writes, failure rollback, and subprocess results.
They do not replace Terraform schema/plan validation or approved camera/AIO MQTT
delivery checks. Keep deployment and operational validation as separate gates.

## onvif-ptz-check.sh

Checks an ONVIF camera directly over ONVIF SOAP, independent of Azure IoT Operations. Use it to confirm the camera's service addresses, find a media profile token, and verify pan and tilt control before you register the camera as a device and asset. The [ONVIF Camera Deployment Guide](../../../../docs/getting-started/onvif-camera-quickstart.md) covers registration.

| Command    | ONVIF operation                 | Output                                                   |
|------------|---------------------------------|----------------------------------------------------------|
| `services` | Device `GetServices`            | Device, Media, Media2, PTZ, and other service addresses  |
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

`profiles` queries the ONVIF Media (ver10) service. A camera that lists only Media2 supports Profile T without Profile S, and `profiles` might fail for it.

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
