---
title: Snapshot Normalizer
description: Normalize binary JPEG MQTT messages into image snapshot envelopes
author: Edge AI Team
ms.date: 2026-10-01
ms.topic: reference
keywords:
    - jpeg
    - mqtt
    - azure iot operations
    - edge inference
estimated_reading_time: 5
---

## Snapshot Normalizer

The crate provides a transport-independent normalization library and an Azure
IoT Operations MQTT adapter for camera snapshot payloads.

The crate turns a raw binary JPEG payload into the canonical `image_snapshot`
v1 request value. The library carries no transport, runtime, or I/O: every
value that reaches an envelope is supplied by the caller, and the same input
always produces the same output. The binary in `src/main.rs` supplies
transport, configuration, timestamps, and I/O around that pure surface.

## MQTT adapter

The adapter subscribes to raw binary JPEG messages, normalizes accepted
payloads, and publishes the canonical JSON envelope at MQTT QoS 1. Camera and
device identity are explicit configuration values and are never derived from
topic segments.

| Variable             | Required | Default                         |
|----------------------|----------|---------------------------------|
| `CAMERA_ID`          | Yes      |                                 |
| `DEVICE_NAME`        | Yes      |                                 |
| `INPUT_TOPIC`        | No       | `edge-ai/cameras/snapshots/raw` |
| `OUTPUT_TOPIC`       | No       | `edge-ai/inference/requests`    |
| `MAX_JPEG_BYTES`     | No       | `4194304`                       |
| `MAX_ENVELOPE_BYTES` | No       | `8388608`                       |
| `DEDUP_CAPACITY`     | No       | `1024`                          |

MQTT connection settings use the standard Azure IoT Operations SDK
environment variables, including `AIO_BROKER_HOSTNAME`,
`AIO_BROKER_TCP_PORT`, `AIO_TLS_CA_FILE`, `AIO_SAT_FILE`, and
`AIO_MQTT_CLIENT_ID`.

## Purpose

A producer that captures snapshots needs four things before it can hand a
payload to any transport: a classification decision, a size decision, a stable
encoding, and a canonical request value. This crate provides those four and
nothing else, so the same logic can be exercised offline, in unit tests, and
on hardware that has no transport, cluster, or accelerator attached.

## Public surface

| Item                                                                        | Purpose                                                                     |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| `JPEG_SOI`, `is_jpeg`                                                       | Classify a byte slice as JPEG by its start-of-image marker prefix           |
| `RejectReason`                                                              | Fixed, bounded rejection set: `Empty`, `NotJpeg`, `Oversize`                |
| `SizeLimits`, `check_jpeg`, `check_envelope`                                | Caller-configured maxima for the raw payload and the serialized envelope    |
| `encode_jpeg`                                                               | Standard-alphabet Base64 encoding                                           |
| `EnvelopeInput`, `SnapshotEnvelope`, `build_envelope`, `serialize_envelope` | Deterministic envelope construction and compact JSON serialization          |
| `MESSAGE_TYPE`, `SCHEMA_VERSION`                                            | Envelope constants                                                          |
| `BoundedDedup`                                                              | Fixed-capacity recent-hash set with oldest-first eviction                   |
| `payload_hash`                                                              | Byte-free FNV-1a 64-bit digest over a scope key and a payload               |
| `Counters`, `CountersSnapshot`                                              | Fixed-cardinality monotonic counters with a serializable point-in-time view |

## Envelope contract

Six fields are required and two optional fields are emitted when the caller
supplies them:

| Field            | Requirement | JSON type                            |
|------------------|-------------|--------------------------------------|
| `message_type`   | Required    | string, constant `image_snapshot`    |
| `schema_version` | Required    | string                               |
| `camera_id`      | Required    | string                               |
| `timestamp`      | Required    | integer, epoch seconds               |
| `image_data`     | Required    | string, standard-alphabet Base64     |
| `device_name`    | Required    | string                               |
| `metadata`       | Optional    | object, free-form, defaults to empty |
| `correlation_id` | Optional    | string                               |

Serialized key order follows the table. Optional fields are omitted when absent
rather than emitted as `null`.

### Tolerant reading

Unknown fields are accepted and discarded rather than rejected, so a later
field addition stays non-breaking. Discarded fields are not re-emitted. A known
field carrying the wrong JSON type is still a parse failure: a `timestamp`
written as a formatted string fails, because the approved representation is
integer epoch seconds.

The published contract reserves an optional `location` field as a
`[latitude, longitude]` pair so consumers keep accepting envelopes that carry
it from other producers. This crate declares no location member and emits no
`location` key; an inbound value is discarded like any other unknown field.

## Caller-configured bounds

No size bound is baked into the library. `SizeLimits` holds caller-supplied
maxima so the crate stays deployment-neutral. A length equal to a maximum is
accepted; only a greater length is rejected. Recommended starting values are
4 MiB for the raw JPEG and 8 MiB for the serialized envelope, published as
schema documentation rather than as library constants.

## Identifiers

`camera_id` and `device_name` are opaque caller-supplied strings. The crate
applies no character-set check and no length bound, and derives no identifier
from any transport value.

## Payload hashing

`payload_hash` applies FNV-1a 64-bit to the scope byte length as eight
little-endian bytes, then the scope bytes, then the payload bytes. Framing the
length first makes the encoding unambiguous, so no pair of distinct scope and
payload inputs can produce the same byte sequence.

The algorithm is fixed in this crate rather than delegated to a standard-library
hasher, whose output is not stable across releases. Digests are not a
cryptographic commitment. Payload bytes are never stored, logged, or rendered;
`Debug` on the payload-bearing types reports lengths rather than content.

## Usage

```rust
use snapshot_normalizer_core::{
    build_envelope, is_jpeg, serialize_envelope, EnvelopeInput, RejectReason, SizeLimits,
};

fn normalize(jpeg: &[u8], timestamp: i64, limits: SizeLimits) -> Result<String, RejectReason> {
    if jpeg.is_empty() {
        return Err(RejectReason::Empty);
    }
    if !is_jpeg(jpeg) {
        return Err(RejectReason::NotJpeg);
    }
    limits.check_jpeg(jpeg.len())?;

    let envelope = build_envelope(EnvelopeInput {
        camera_id: "camera-01",
        device_name: "device-01",
        jpeg,
        timestamp,
        metadata: serde_json::Map::new(),
        correlation_id: None,
    });
    let json = serialize_envelope(&envelope).map_err(|_| RejectReason::Oversize)?;
    limits.check_envelope(json.len())?;
    Ok(json)
}
```

## Dependencies

All dependencies resolve from crates.io. The crate declares no path, git,
private registry, or optional dependency.

## Testing

```bash
cargo test --locked
cargo clippy --locked --all-targets -- -D warnings
```

Every test is a unit test inside the crate and uses hand-built synthetic byte
arrays and neutral identifiers. No test requires a network, a transport, a
cluster, an accelerator, a camera, a model, or a credential.

## Container build

Build the workload from the service directory:

```bash
docker build -t snapshot-normalizer:0.1.0 .
```

The Helm chart is located at `../../charts/snapshot-normalizer`. Set
`image.repository` to the registry where you published the image:

```bash
helm upgrade --install snapshot-normalizer ../../charts/snapshot-normalizer \
    --namespace azure-iot-operations \
    --set image.repository=example.azurecr.io/snapshot-normalizer \
    --set normalizer.cameraId=camera-01 \
    --set normalizer.deviceName=camera-device-01
```

## License

MIT
