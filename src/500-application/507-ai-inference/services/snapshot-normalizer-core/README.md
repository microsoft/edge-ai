# Snapshot Normalizer Core

Transport-independent normalization core for camera snapshot payloads.

The crate turns a raw binary JPEG payload into the canonical `image_snapshot`
v1 request value. It carries no transport, no runtime, and no I/O: every value
that reaches an envelope is supplied by the caller, and the same input always
produces the same output.

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

| Crate        | Version | Features |
|--------------|---------|----------|
| `base64`     | 0.22    | default  |
| `serde`      | 1.0     | `derive` |
| `serde_json` | 1.0     | default  |

All three resolve from crates.io. The crate declares no path dependency, no git
dependency, no optional dependency, and no feature flag.

## Testing

```bash
cargo test --locked
```

Every test is a unit test inside the crate and uses hand-built synthetic byte
arrays and neutral identifiers. No test requires a network, a transport, a
cluster, an accelerator, a camera, a model, or a credential.

## License

MIT
