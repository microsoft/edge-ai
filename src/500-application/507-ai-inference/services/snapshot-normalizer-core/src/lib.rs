//! Transport-independent normalization core for camera snapshot payloads.
//!
//! The crate classifies raw binary JPEG payloads, enforces caller-configured
//! size bounds, encodes accepted payloads with Base64, and builds the canonical
//! `image_snapshot` v1 request value. It also provides bounded duplicate
//! detection, byte-free payload hashing, and a fixed-cardinality counter set.
//!
//! Envelope construction is pure. It reads no clock, draws no randomness,
//! performs no input or output, and depends on no transport. Every value that
//! reaches an envelope is supplied by the caller.
//!
//! # Envelope contract
//!
//! The `image_snapshot` v1 value carries six required fields and two
//! producer-emitted optional fields:
//!
//! | Field | Requirement | JSON type |
//! |-------|-------------|-----------|
//! | `message_type` | Required | string, constant `image_snapshot` |
//! | `schema_version` | Required | string |
//! | `camera_id` | Required | string |
//! | `timestamp` | Required | integer, epoch seconds |
//! | `image_data` | Required | string, standard-alphabet Base64 |
//! | `device_name` | Required | string |
//! | `metadata` | Optional | object, free-form, defaults to empty |
//! | `correlation_id` | Optional | string |
//!
//! Readers are tolerant: unknown fields are accepted and discarded rather than
//! rejected, so adding a field later stays non-breaking. Optional fields are
//! omitted when absent rather than emitted as `null`.
//!
//! A `location` field is reserved in the published contract as an optional
//! `[latitude, longitude]` pair for compatibility with other producers. This
//! crate declares no location member and emits no `location` key.
//!
//! # Size bounds
//!
//! No size bound is baked into this library. [`SizeLimits`] holds
//! caller-supplied maxima so the crate stays deployment-neutral. A length equal
//! to a maximum is accepted; only a greater length is rejected.
//!
//! # Identifiers
//!
//! `camera_id` and `device_name` are opaque caller-supplied strings. This crate
//! applies no character-set check and no length bound to them.

#![deny(missing_docs)]

use std::collections::{HashSet, VecDeque};
use std::sync::atomic::{AtomicU64, Ordering};

use base64::Engine;
use serde::{Deserialize, Serialize};

/// Canonical message type carried by every envelope this crate builds.
pub const MESSAGE_TYPE: &str = "image_snapshot";

/// Canonical envelope schema version carried by every envelope this crate
/// builds.
pub const SCHEMA_VERSION: &str = "1.0";

/// JPEG start-of-image marker followed by the first marker byte.
pub const JPEG_SOI: [u8; 3] = [0xFF, 0xD8, 0xFF];

/// FNV-1a 64-bit offset basis.
const FNV_OFFSET_BASIS_64: u64 = 0xcbf2_9ce4_8422_2325;

/// FNV-1a 64-bit prime.
const FNV_PRIME_64: u64 = 0x0000_0100_0000_01B3;

/// Reason a payload is rejected.
///
/// The variant set is fixed and bounded so counter cardinality stays constant.
/// Every label is a stable literal that contains no payload-derived content.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RejectReason {
    /// Payload carried no bytes.
    Empty,
    /// Payload did not begin with the JPEG start-of-image marker.
    NotJpeg,
    /// Payload or resulting envelope exceeded a caller-configured maximum.
    Oversize,
}

/// Caller-configured size bounds applied before and after normalization.
///
/// Both maxima are supplied by the caller. The crate defines no default.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SizeLimits {
    /// Maximum accepted raw JPEG length in bytes.
    pub max_jpeg_bytes: usize,
    /// Maximum accepted serialized envelope length in bytes.
    pub max_envelope_bytes: usize,
}

/// Inputs required to build an envelope from validated JPEG bytes.
///
/// Identifiers are supplied directly by the caller. This type exposes no
/// transport parameter and derives no identifier from any transport value.
pub struct EnvelopeInput<'a> {
    /// Opaque camera identifier.
    pub camera_id: &'a str,
    /// Opaque device identifier.
    pub device_name: &'a str,
    /// Raw JPEG bytes, already classified and size-checked.
    pub jpeg: &'a [u8],
    /// Epoch seconds for the snapshot.
    pub timestamp: i64,
    /// Free-form caller-supplied metadata. Empty when the caller supplies none.
    pub metadata: serde_json::Map<String, serde_json::Value>,
    /// Optional caller-supplied correlation identifier.
    pub correlation_id: Option<String>,
}

/// Canonical `image_snapshot` v1 request value.
///
/// Member order matches the published contract field order. Unknown input
/// fields are accepted and discarded rather than preserved or rejected.
#[derive(Clone, PartialEq, Serialize, Deserialize)]
pub struct SnapshotEnvelope {
    /// Constant message type discriminator.
    pub message_type: String,
    /// Envelope schema version.
    pub schema_version: String,
    /// Opaque camera identifier.
    pub camera_id: String,
    /// Epoch seconds for the snapshot.
    pub timestamp: i64,
    /// Standard-alphabet Base64 encoding of the JPEG payload.
    pub image_data: String,
    /// Opaque device identifier.
    pub device_name: String,
    /// Free-form metadata. Absent from output when empty.
    #[serde(default, skip_serializing_if = "serde_json::Map::is_empty")]
    pub metadata: serde_json::Map<String, serde_json::Value>,
    /// Optional correlation identifier. Absent from output when unset.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub correlation_id: Option<String>,
}

// Debug is hand-written for both payload-bearing types: deriving it would render
// raw JPEG and Base64 content, breaking the byte-free guarantee.
impl std::fmt::Debug for EnvelopeInput<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("EnvelopeInput")
            .field("camera_id", &self.camera_id)
            .field("device_name", &self.device_name)
            .field("jpeg_len", &self.jpeg.len())
            .field("timestamp", &self.timestamp)
            .field("metadata_len", &self.metadata.len())
            .field("correlation_id", &self.correlation_id)
            .finish()
    }
}

impl std::fmt::Debug for SnapshotEnvelope {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SnapshotEnvelope")
            .field("message_type", &self.message_type)
            .field("schema_version", &self.schema_version)
            .field("camera_id", &self.camera_id)
            .field("timestamp", &self.timestamp)
            .field("image_data_len", &self.image_data.len())
            .field("device_name", &self.device_name)
            .field("metadata_len", &self.metadata.len())
            .field("correlation_id", &self.correlation_id)
            .finish()
    }
}

/// Bounded duplicate detector keyed by a payload hash.
///
/// Memory is capped at `capacity` entries with oldest-first eviction. A repeat
/// observation does not refresh recency. No payload byte is retained.
///
/// Duplication here means content equality within the retained window. It is
/// not a retransmission check: two fresh captures with identical bytes hash
/// equally, and a repeated hash stays retained until enough distinct hashes
/// evict it. Callers whose producers can legitimately repeat identical payloads,
/// such as periodic snapshots of a static scene, should key the hash on a
/// producer-supplied capture or message identifier rather than on content alone.
#[derive(Debug)]
pub struct BoundedDedup {
    capacity: usize,
    seen: HashSet<u64>,
    order: VecDeque<u64>,
}

/// Fixed-cardinality counters for observability.
///
/// Counter names are a bounded, static set; only their monotonic values change.
/// The crate drives the rejection counters through [`Counters::record_reject`];
/// callers increment the remaining counters at their own pipeline boundaries.
#[derive(Debug, Default)]
pub struct Counters {
    /// Payloads taken in for normalization.
    pub received: AtomicU64,
    /// Payloads that passed classification and size checks.
    pub accepted: AtomicU64,
    /// Payloads rejected because they carried no bytes.
    pub rejected_empty: AtomicU64,
    /// Payloads rejected because they were not JPEG.
    pub rejected_not_jpeg: AtomicU64,
    /// Payloads rejected because a size maximum was exceeded.
    pub rejected_oversize: AtomicU64,
    /// Payloads suppressed as duplicates.
    pub duplicate: AtomicU64,
}

/// Serializable point-in-time view of [`Counters`].
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CountersSnapshot {
    /// Payloads taken in for normalization.
    pub received: u64,
    /// Payloads that passed classification and size checks.
    pub accepted: u64,
    /// Payloads rejected because they carried no bytes.
    pub rejected_empty: u64,
    /// Payloads rejected because they were not JPEG.
    pub rejected_not_jpeg: u64,
    /// Payloads rejected because a size maximum was exceeded.
    pub rejected_oversize: u64,
    /// Payloads suppressed as duplicates.
    pub duplicate: u64,
}

impl std::fmt::Display for RejectReason {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

impl RejectReason {
    /// Stable, byte-free label for logging and metrics.
    pub const fn as_str(self) -> &'static str {
        match self {
            RejectReason::Empty => "empty",
            RejectReason::NotJpeg => "not_jpeg",
            RejectReason::Oversize => "oversize",
        }
    }
}

impl SizeLimits {
    /// Rejects raw JPEG payloads longer than the configured maximum.
    ///
    /// A length equal to the maximum is accepted. A zero length is not an
    /// oversize condition; emptiness is classified elsewhere.
    pub const fn check_jpeg(&self, jpeg_len: usize) -> Result<(), RejectReason> {
        if jpeg_len > self.max_jpeg_bytes {
            Err(RejectReason::Oversize)
        } else {
            Ok(())
        }
    }

    /// Rejects serialized envelopes longer than the configured maximum.
    ///
    /// Base64 inflates a payload by roughly one third, so the bound applies to
    /// the serialized envelope rather than to the raw payload.
    pub const fn check_envelope(&self, envelope_len: usize) -> Result<(), RejectReason> {
        if envelope_len > self.max_envelope_bytes {
            Err(RejectReason::Oversize)
        } else {
            Ok(())
        }
    }
}

impl BoundedDedup {
    /// Creates a detector holding at most `capacity` recent hashes.
    ///
    /// A requested capacity below one is clamped to one.
    pub fn new(capacity: usize) -> Self {
        Self {
            capacity: capacity.max(1),
            seen: HashSet::new(),
            order: VecDeque::new(),
        }
    }

    /// Records a hash and returns true when it was already present.
    pub fn observe(&mut self, hash: u64) -> bool {
        if self.seen.contains(&hash) {
            return true;
        }
        if self.order.len() >= self.capacity {
            if let Some(evicted) = self.order.pop_front() {
                self.seen.remove(&evicted);
            }
        }
        self.seen.insert(hash);
        self.order.push_back(hash);
        false
    }
}

impl Counters {
    /// Increments the rejection counter matching the reason.
    pub fn record_reject(&self, reason: RejectReason) {
        match reason {
            RejectReason::Empty => self.rejected_empty.fetch_add(1, Ordering::Relaxed),
            RejectReason::NotJpeg => self.rejected_not_jpeg.fetch_add(1, Ordering::Relaxed),
            RejectReason::Oversize => self.rejected_oversize.fetch_add(1, Ordering::Relaxed),
        };
    }

    /// Captures a serializable point-in-time copy of every counter.
    pub fn snapshot(&self) -> CountersSnapshot {
        CountersSnapshot {
            received: self.received.load(Ordering::Relaxed),
            accepted: self.accepted.load(Ordering::Relaxed),
            rejected_empty: self.rejected_empty.load(Ordering::Relaxed),
            rejected_not_jpeg: self.rejected_not_jpeg.load(Ordering::Relaxed),
            rejected_oversize: self.rejected_oversize.load(Ordering::Relaxed),
            duplicate: self.duplicate.load(Ordering::Relaxed),
        }
    }
}

/// Returns true when the byte slice starts with the JPEG start-of-image marker.
///
/// Matching is a prefix test, so a slice shorter than the marker cannot match
/// and a marker that does not begin at offset zero does not match.
pub fn is_jpeg(bytes: &[u8]) -> bool {
    bytes.len() >= JPEG_SOI.len() && bytes[..JPEG_SOI.len()] == JPEG_SOI
}

/// Base64-encodes JPEG bytes with the standard alphabet.
pub fn encode_jpeg(jpeg: &[u8]) -> String {
    base64::engine::general_purpose::STANDARD.encode(jpeg)
}

/// Builds the canonical envelope value for the supplied input.
///
/// The result is a pure function of the input: the same input always yields the
/// same envelope.
pub fn build_envelope(input: EnvelopeInput<'_>) -> SnapshotEnvelope {
    SnapshotEnvelope {
        message_type: MESSAGE_TYPE.to_string(),
        schema_version: SCHEMA_VERSION.to_string(),
        camera_id: input.camera_id.to_string(),
        timestamp: input.timestamp,
        image_data: encode_jpeg(input.jpeg),
        device_name: input.device_name.to_string(),
        metadata: input.metadata,
        correlation_id: input.correlation_id,
    }
}

/// Serializes an envelope to a compact JSON string.
pub fn serialize_envelope(envelope: &SnapshotEnvelope) -> Result<String, serde_json::Error> {
    serde_json::to_string(envelope)
}

/// Hashes a scope key and a payload into a byte-free 64-bit digest.
///
/// The algorithm is FNV-1a 64-bit applied to the scope byte length as eight
/// little-endian bytes, then the scope bytes, then the payload bytes. Framing
/// the length first makes the encoding unambiguous, so no pair of distinct
/// scope and payload inputs can produce the same byte sequence. The algorithm
/// is fixed here rather than delegated to a standard-library hasher, whose
/// output is not stable across releases.
///
/// Digests are not a cryptographic commitment. Payload bytes are never stored,
/// logged, or rendered by this function.
pub fn payload_hash(scope: &str, payload: &[u8]) -> u64 {
    let scope_bytes = scope.as_bytes();
    let mut digest = FNV_OFFSET_BASIS_64;
    for byte in (scope_bytes.len() as u64)
        .to_le_bytes()
        .iter()
        .chain(scope_bytes)
        .chain(payload)
    {
        digest ^= u64::from(*byte);
        digest = digest.wrapping_mul(FNV_PRIME_64);
    }
    digest
}

#[cfg(test)]
mod tests {
    use super::*;

    const FIXTURE_CAMERA_ID: &str = "camera-01";
    const FIXTURE_DEVICE_NAME: &str = "device-01";
    const FIXTURE_CORRELATION_ID: &str = "correlation-01";
    const FIXTURE_TIMESTAMP: i64 = 1_767_225_600;
    const FIXTURE_JPEG: [u8; 6] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
    const FIXTURE_IMAGE_DATA: &str = "/9j/4AAQ";

    const CANONICAL_JSON: &str = concat!(
        r#"{"message_type":"image_snapshot","schema_version":"1.0","#,
        r#""camera_id":"camera-01","timestamp":1767225600,"#,
        r#""image_data":"/9j/4AAQ","device_name":"device-01","#,
        r#""metadata":{"sample":"example-01"},"correlation_id":"correlation-01"}"#
    );

    const MINIMAL_JSON: &str = concat!(
        r#"{"message_type":"image_snapshot","schema_version":"1.0","#,
        r#""camera_id":"camera-01","timestamp":1767225600,"#,
        r#""image_data":"/9j/4AAQ","device_name":"device-01"}"#
    );

    fn metadata(pairs: &[(&str, serde_json::Value)]) -> serde_json::Map<String, serde_json::Value> {
        pairs
            .iter()
            .map(|(key, value)| ((*key).to_string(), value.clone()))
            .collect()
    }

    fn canonical_envelope() -> SnapshotEnvelope {
        build_envelope(EnvelopeInput {
            camera_id: FIXTURE_CAMERA_ID,
            device_name: FIXTURE_DEVICE_NAME,
            jpeg: &FIXTURE_JPEG,
            timestamp: FIXTURE_TIMESTAMP,
            metadata: metadata(&[("sample", serde_json::json!("example-01"))]),
            correlation_id: Some(FIXTURE_CORRELATION_ID.to_string()),
        })
    }

    fn minimal_envelope() -> SnapshotEnvelope {
        build_envelope(EnvelopeInput {
            camera_id: FIXTURE_CAMERA_ID,
            device_name: FIXTURE_DEVICE_NAME,
            jpeg: &FIXTURE_JPEG,
            timestamp: FIXTURE_TIMESTAMP,
            metadata: serde_json::Map::new(),
            correlation_id: None,
        })
    }

    /// Collects top-level object keys in document order.
    ///
    /// Parsing into `serde_json::Value` would sort keys alphabetically, which
    /// would hide the contract field order these fixtures assert. Every fixture
    /// document is compact, so a key is always followed immediately by a colon.
    fn keys(json: &str) -> Vec<String> {
        serde_json::from_str::<serde_json::Value>(json).expect("valid json");

        let bytes = json.as_bytes();
        let mut collected = Vec::new();
        let mut depth = 0usize;
        let mut index = 0usize;
        while index < bytes.len() {
            match bytes[index] {
                b'{' | b'[' => depth += 1,
                b'}' | b']' => depth -= 1,
                b'"' => {
                    let start = index + 1;
                    let mut end = start;
                    while end < bytes.len() && bytes[end] != b'"' {
                        end += if bytes[end] == b'\\' { 2 } else { 1 };
                    }
                    let after = end + 1;
                    if depth == 1 && after < bytes.len() && bytes[after] == b':' {
                        collected.push(json[start..end].to_string());
                    }
                    index = end;
                }
                _ => {}
            }
            index += 1;
        }
        collected
    }

    // JPEG marker classification.

    #[test]
    fn prefix_match_at_exact_marker_length() {
        assert!(is_jpeg(&[0xFF, 0xD8, 0xFF]));
    }

    #[test]
    fn prefix_match_with_trailing_bytes() {
        assert!(is_jpeg(&[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]));
    }

    #[test]
    fn empty_input_is_not_jpeg() {
        assert!(!is_jpeg(&[]));
    }

    #[test]
    fn single_byte_is_not_jpeg() {
        assert!(!is_jpeg(&[0xFF]));
    }

    #[test]
    fn two_bytes_are_not_jpeg() {
        assert!(!is_jpeg(&[0xFF, 0xD8]));
    }

    #[test]
    fn near_miss_on_third_marker_byte() {
        assert!(!is_jpeg(&[0xFF, 0xD8, 0xFE]));
    }

    #[test]
    fn non_jpeg_bytes_at_marker_length() {
        assert!(!is_jpeg(&[0x00, 0x01, 0x02, 0x03]));
    }

    #[test]
    fn marker_not_at_offset_zero() {
        assert!(!is_jpeg(&[0x00, 0xFF, 0xD8, 0xFF]));
    }

    // Bounded rejection taxonomy.

    #[test]
    fn variant_set_cardinality_is_three() {
        let variants = [
            RejectReason::Empty,
            RejectReason::NotJpeg,
            RejectReason::Oversize,
        ];
        let labels: HashSet<&str> = variants.iter().map(|reason| reason.as_str()).collect();
        assert_eq!(variants.len(), 3);
        assert_eq!(labels.len(), 3);

        // Exhaustive match proves no fourth variant exists.
        for reason in variants {
            match reason {
                RejectReason::Empty | RejectReason::NotJpeg | RejectReason::Oversize => {}
            }
        }
    }

    #[test]
    fn no_topic_derived_variant_exists() {
        let labels: Vec<&str> = [
            RejectReason::Empty,
            RejectReason::NotJpeg,
            RejectReason::Oversize,
        ]
        .iter()
        .map(|reason| reason.as_str())
        .collect();
        assert!(!labels.iter().any(|label| label.contains("topic")));
    }

    #[test]
    fn label_text_is_pinned() {
        assert_eq!(RejectReason::Empty.as_str(), "empty");
        assert_eq!(RejectReason::NotJpeg.as_str(), "not_jpeg");
        assert_eq!(RejectReason::Oversize.as_str(), "oversize");
    }

    #[test]
    fn display_matches_label() {
        for reason in [
            RejectReason::Empty,
            RejectReason::NotJpeg,
            RejectReason::Oversize,
        ] {
            assert_eq!(reason.to_string(), reason.as_str());
        }
    }

    #[test]
    fn label_is_stable_across_calls() {
        let reason = RejectReason::Oversize;
        assert_eq!(reason.as_str(), reason.as_str());
        assert!(reason.as_str().is_ascii());
    }

    // Size limit enforcement.

    fn synthetic_limits() -> SizeLimits {
        SizeLimits {
            max_jpeg_bytes: 16,
            max_envelope_bytes: 24,
        }
    }

    #[test]
    fn raw_payload_under_limit_is_accepted() {
        assert_eq!(synthetic_limits().check_jpeg(8), Ok(()));
    }

    #[test]
    fn raw_payload_at_limit_is_accepted() {
        assert_eq!(synthetic_limits().check_jpeg(16), Ok(()));
    }

    #[test]
    fn raw_payload_over_limit_is_rejected() {
        assert_eq!(
            synthetic_limits().check_jpeg(17),
            Err(RejectReason::Oversize)
        );
    }

    #[test]
    fn zero_length_payload_is_not_oversize() {
        assert_eq!(synthetic_limits().check_jpeg(0), Ok(()));
    }

    #[test]
    fn envelope_under_limit_is_accepted() {
        assert_eq!(synthetic_limits().check_envelope(12), Ok(()));
    }

    #[test]
    fn envelope_at_limit_is_accepted() {
        assert_eq!(synthetic_limits().check_envelope(24), Ok(()));
    }

    #[test]
    fn envelope_over_limit_is_rejected() {
        assert_eq!(
            synthetic_limits().check_envelope(25),
            Err(RejectReason::Oversize)
        );
    }

    #[test]
    fn degenerate_limit_of_one_byte() {
        let limits = SizeLimits {
            max_jpeg_bytes: 1,
            max_envelope_bytes: 1,
        };
        assert_eq!(limits.check_jpeg(1), Ok(()));
        assert_eq!(limits.check_jpeg(2), Err(RejectReason::Oversize));
        assert_eq!(limits.check_envelope(1), Ok(()));
        assert_eq!(limits.check_envelope(2), Err(RejectReason::Oversize));
    }

    #[test]
    fn canonical_bounds_stay_caller_supplied() {
        let limits = SizeLimits {
            max_jpeg_bytes: 7,
            max_envelope_bytes: 9,
        };
        assert_eq!(limits.max_jpeg_bytes, 7);
        assert_eq!(limits.max_envelope_bytes, 9);
        assert_ne!(limits.max_jpeg_bytes, 4_194_304);
        assert_ne!(limits.max_envelope_bytes, 8_388_608);
    }

    #[test]
    fn canonical_recommended_defaults_are_pinned() {
        const RECOMMENDED_MAX_RAW_JPEG_BYTES: usize = 4_194_304;
        const RECOMMENDED_MAX_SERIALIZED_ENVELOPE_BYTES: usize = 8_388_608;
        assert_eq!(RECOMMENDED_MAX_RAW_JPEG_BYTES, 4 * 1024 * 1024);
        assert_eq!(RECOMMENDED_MAX_SERIALIZED_ENVELOPE_BYTES, 8 * 1024 * 1024);

        let limits = SizeLimits {
            max_jpeg_bytes: RECOMMENDED_MAX_RAW_JPEG_BYTES,
            max_envelope_bytes: RECOMMENDED_MAX_SERIALIZED_ENVELOPE_BYTES,
        };
        assert_eq!(limits.check_jpeg(RECOMMENDED_MAX_RAW_JPEG_BYTES), Ok(()));
        assert_eq!(
            limits.check_jpeg(RECOMMENDED_MAX_RAW_JPEG_BYTES + 1),
            Err(RejectReason::Oversize)
        );
    }

    // Base64 payload encoding.

    #[test]
    fn encoding_at_exact_marker_length() {
        assert_eq!(encode_jpeg(&[0xFF, 0xD8, 0xFF]), "/9j/");
    }

    #[test]
    fn encoding_of_six_byte_input() {
        assert_eq!(encode_jpeg(&FIXTURE_JPEG), FIXTURE_IMAGE_DATA);
    }

    #[test]
    fn single_padding_character() {
        assert_eq!(encode_jpeg(&[0x00, 0x01, 0x02, 0x03]), "AAECAw==");
    }

    #[test]
    fn double_padding_character() {
        assert_eq!(encode_jpeg(&[0x41]), "QQ==");
    }

    #[test]
    fn empty_input_encodes_to_empty_string() {
        assert_eq!(encode_jpeg(&[]), "");
    }

    #[test]
    fn encoding_is_deterministic() {
        assert_eq!(encode_jpeg(&FIXTURE_JPEG), encode_jpeg(&FIXTURE_JPEG));
    }

    #[test]
    fn standard_alphabet_not_url_safe() {
        let encoded = encode_jpeg(&[0x3E, 0xFB, 0xFF]);
        assert_eq!(encoded, "Pvv/");
        assert_ne!(encoded, "Pvv_");
    }

    // Envelope construction and serialization.

    #[test]
    fn construction_and_serialization_are_deterministic() {
        let first = serialize_envelope(&canonical_envelope()).expect("serializes");
        let second = serialize_envelope(&canonical_envelope()).expect("serializes");
        assert_eq!(first, second);
        assert_eq!(first, CANONICAL_JSON);
    }

    #[test]
    fn field_cardinality() {
        let canonical = serialize_envelope(&canonical_envelope()).expect("serializes");
        let minimal = serialize_envelope(&minimal_envelope()).expect("serializes");
        assert_eq!(keys(&canonical).len(), 8);
        assert_eq!(
            keys(&minimal),
            vec![
                "message_type",
                "schema_version",
                "camera_id",
                "timestamp",
                "image_data",
                "device_name",
            ]
        );
        assert!(!keys(&canonical).contains(&"location".to_string()));
        assert!(!keys(&minimal).contains(&"location".to_string()));
    }

    #[test]
    fn schema_version_is_a_present_string() {
        let minimal = serialize_envelope(&minimal_envelope()).expect("serializes");
        let value: serde_json::Value = serde_json::from_str(&minimal).expect("valid json");
        assert!(value["schema_version"].is_string());
        assert_eq!(value["schema_version"], serde_json::json!(SCHEMA_VERSION));
    }

    #[test]
    fn unknown_field_is_accepted_and_ignored() {
        let input = CANONICAL_JSON.replace(
            r#""device_name":"device-01""#,
            r#""device_name":"device-01","unknown_field":"ignored""#,
        );
        let parsed: SnapshotEnvelope = serde_json::from_str(&input).expect("tolerant parse");
        assert_eq!(parsed, canonical_envelope());
    }

    #[test]
    fn metadata_optionality_and_shape() {
        let minimal = serialize_envelope(&minimal_envelope()).expect("serializes");
        assert!(!keys(&minimal).contains(&"metadata".to_string()));

        let reparsed: SnapshotEnvelope = serde_json::from_str(&minimal).expect("parses");
        assert!(reparsed.metadata.is_empty());

        let with_metadata = MINIMAL_JSON.replace(
            r#""device_name":"device-01""#,
            r#""device_name":"device-01","metadata":{"sample":"example-02"}"#,
        );
        let parsed: SnapshotEnvelope = serde_json::from_str(&with_metadata).expect("parses");
        assert_eq!(
            parsed.metadata,
            metadata(&[("sample", serde_json::json!("example-02"))])
        );
        assert!(!parsed.metadata.contains_key("source_topic"));
    }

    #[test]
    fn correlation_identifier_present_and_absent() {
        let canonical = canonical_envelope();
        assert_eq!(
            canonical.correlation_id.as_deref(),
            Some(FIXTURE_CORRELATION_ID)
        );
        let round_tripped: SnapshotEnvelope =
            serde_json::from_str(&serialize_envelope(&canonical).expect("serializes"))
                .expect("parses");
        assert_eq!(round_tripped.correlation_id, canonical.correlation_id);

        let minimal = serialize_envelope(&minimal_envelope()).expect("serializes");
        assert!(!keys(&minimal).contains(&"correlation_id".to_string()));
        let reparsed: SnapshotEnvelope = serde_json::from_str(&minimal).expect("parses");
        assert_eq!(reparsed.correlation_id, None);
    }

    #[test]
    fn capture_timestamp_is_not_an_approved_field() {
        let input = CANONICAL_JSON.replace(
            r#""device_name":"device-01""#,
            r#""device_name":"device-01","capture_timestamp":1767225600"#,
        );
        let parsed: SnapshotEnvelope = serde_json::from_str(&input).expect("tolerant parse");
        assert_eq!(parsed, canonical_envelope());
        let reserialized = serialize_envelope(&parsed).expect("serializes");
        assert!(!keys(&reserialized).contains(&"capture_timestamp".to_string()));
    }

    #[test]
    fn full_expected_serialized_json() {
        assert_eq!(
            serialize_envelope(&canonical_envelope()).expect("serializes"),
            CANONICAL_JSON
        );
    }

    #[test]
    fn identifiers_are_opaque_strings() {
        let long_id = "a".repeat(200);
        for (camera_id, device_name) in [
            (FIXTURE_CAMERA_ID, FIXTURE_DEVICE_NAME),
            ("c", "d"),
            (long_id.as_str(), long_id.as_str()),
        ] {
            let envelope = build_envelope(EnvelopeInput {
                camera_id,
                device_name,
                jpeg: &FIXTURE_JPEG,
                timestamp: FIXTURE_TIMESTAMP,
                metadata: serde_json::Map::new(),
                correlation_id: None,
            });
            assert_eq!(envelope.camera_id, camera_id);
            assert_eq!(envelope.device_name, device_name);
        }
    }

    #[test]
    fn schema_version_literal_is_pinned() {
        assert_eq!(SCHEMA_VERSION, "1.0");
        assert_eq!(MESSAGE_TYPE, "image_snapshot");
        assert_eq!(canonical_envelope().schema_version, "1.0");
    }

    #[test]
    fn unknown_field_is_not_re_emitted() {
        let input = CANONICAL_JSON.replace(
            r#""device_name":"device-01""#,
            r#""device_name":"device-01","unknown_field":"ignored""#,
        );
        let parsed: SnapshotEnvelope = serde_json::from_str(&input).expect("tolerant parse");
        assert_eq!(
            serialize_envelope(&parsed).expect("serializes"),
            CANONICAL_JSON
        );
    }

    #[test]
    fn optional_fields_are_omitted_not_null() {
        let minimal = serialize_envelope(&minimal_envelope()).expect("serializes");
        assert_eq!(minimal, MINIMAL_JSON);
        assert!(!minimal.contains("null"));
        assert!(!minimal.contains("metadata"));
        assert!(!minimal.contains("correlation_id"));
        assert!(!minimal.contains("location"));
    }

    #[test]
    fn location_is_never_produced() {
        for json in [
            serialize_envelope(&canonical_envelope()).expect("serializes"),
            serialize_envelope(&minimal_envelope()).expect("serializes"),
        ] {
            assert!(!keys(&json).contains(&"location".to_string()));
        }

        // Exhaustive destructuring proves the producer type declares no
        // location member; adding one would fail to compile.
        let SnapshotEnvelope {
            message_type: _,
            schema_version: _,
            camera_id: _,
            timestamp: _,
            image_data: _,
            device_name: _,
            metadata: _,
            correlation_id: _,
        } = canonical_envelope();
    }

    #[test]
    fn inbound_location_is_tolerated_in_either_shape() {
        for injected in [
            r#""location":[0.0,0.0]"#,
            r#""location":{"latitude":0.0,"longitude":0.0}"#,
        ] {
            let input = CANONICAL_JSON.replace(
                r#""device_name":"device-01""#,
                &format!(r#""device_name":"device-01",{injected}"#),
            );
            let parsed: SnapshotEnvelope = serde_json::from_str(&input).expect("tolerant parse");
            let reserialized = serialize_envelope(&parsed).expect("serializes");
            assert_eq!(reserialized, CANONICAL_JSON);
            assert!(!keys(&reserialized).contains(&"location".to_string()));
        }
    }

    #[test]
    fn rfc3339_timestamp_is_a_parse_failure() {
        let input = CANONICAL_JSON.replace(
            r#""timestamp":1767225600"#,
            r#""timestamp":"2026-01-01T00:00:00Z""#,
        );
        let parsed: Result<SnapshotEnvelope, _> = serde_json::from_str(&input);
        assert!(parsed.is_err());
    }

    #[test]
    fn field_order_is_independent_of_construction_order() {
        let mut later_metadata = serde_json::Map::new();
        later_metadata.insert("sample".to_string(), serde_json::json!("example-01"));
        let correlation_id = Some(FIXTURE_CORRELATION_ID.to_string());
        let timestamp = FIXTURE_TIMESTAMP;
        let reordered = build_envelope(EnvelopeInput {
            correlation_id,
            metadata: later_metadata,
            timestamp,
            jpeg: &FIXTURE_JPEG,
            device_name: FIXTURE_DEVICE_NAME,
            camera_id: FIXTURE_CAMERA_ID,
        });
        assert_eq!(
            serialize_envelope(&reordered).expect("serializes"),
            serialize_envelope(&canonical_envelope()).expect("serializes")
        );
        assert_eq!(
            keys(&serialize_envelope(&reordered).expect("serializes")),
            vec![
                "message_type",
                "schema_version",
                "camera_id",
                "timestamp",
                "image_data",
                "device_name",
                "metadata",
                "correlation_id",
            ]
        );
    }

    #[test]
    fn integer_epoch_timestamp_round_trip() {
        for timestamp in [FIXTURE_TIMESTAMP, 0, -1] {
            let envelope = build_envelope(EnvelopeInput {
                camera_id: FIXTURE_CAMERA_ID,
                device_name: FIXTURE_DEVICE_NAME,
                jpeg: &FIXTURE_JPEG,
                timestamp,
                metadata: serde_json::Map::new(),
                correlation_id: None,
            });
            let json = serialize_envelope(&envelope).expect("serializes");
            assert!(json.contains(&format!(r#""timestamp":{timestamp}"#)));
            let parsed: SnapshotEnvelope = serde_json::from_str(&json).expect("parses");
            assert_eq!(parsed.timestamp, timestamp);
        }
    }

    #[test]
    fn envelope_input_takes_caller_supplied_identifiers() {
        // Exhaustive construction proves the input type declares exactly these
        // members: no identity member and no transport parameter.
        let input = EnvelopeInput {
            camera_id: FIXTURE_CAMERA_ID,
            device_name: FIXTURE_DEVICE_NAME,
            jpeg: &FIXTURE_JPEG,
            timestamp: FIXTURE_TIMESTAMP,
            metadata: serde_json::Map::new(),
            correlation_id: None,
        };
        let debug = format!("{input:?}");
        assert!(!debug.contains("topic"));
        assert!(!debug.contains("identity"));

        let envelope = build_envelope(input);
        assert_eq!(envelope.camera_id, FIXTURE_CAMERA_ID);
        assert_eq!(envelope.device_name, FIXTURE_DEVICE_NAME);
    }

    #[test]
    fn debug_reports_payload_lengths_without_rendering_content() {
        let jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0xDE, 0xAD, 0xBE, 0xEF];
        let input = EnvelopeInput {
            camera_id: FIXTURE_CAMERA_ID,
            device_name: FIXTURE_DEVICE_NAME,
            jpeg: &jpeg,
            timestamp: FIXTURE_TIMESTAMP,
            metadata: serde_json::Map::new(),
            correlation_id: None,
        };
        let input_debug = format!("{input:?}");
        assert!(
            input_debug.contains("jpeg_len: 8"),
            "input debug must report payload length"
        );
        assert!(
            !input_debug.contains("222"),
            "input debug must not render raw payload bytes"
        );

        let envelope = build_envelope(input);
        let envelope_debug = format!("{envelope:?}");
        assert!(
            envelope_debug.contains("image_data_len"),
            "envelope debug must report encoded length"
        );
        assert!(
            !envelope_debug.contains(envelope.image_data.as_str()),
            "envelope debug must not render the encoded payload"
        );
    }

    #[test]
    fn metadata_is_free_form_with_no_carried_sequence_number() {
        assert!(minimal_envelope().metadata.is_empty());

        let supplied = metadata(&[
            ("sequence_number", serde_json::json!(1)),
            ("operator", serde_json::json!("example")),
        ]);
        let envelope = build_envelope(EnvelopeInput {
            camera_id: FIXTURE_CAMERA_ID,
            device_name: FIXTURE_DEVICE_NAME,
            jpeg: &FIXTURE_JPEG,
            timestamp: FIXTURE_TIMESTAMP,
            metadata: supplied.clone(),
            correlation_id: None,
        });
        assert_eq!(envelope.metadata, supplied);
        assert!(!envelope.metadata.contains_key("source_topic"));

        let json = serialize_envelope(&envelope).expect("serializes");
        let parsed: SnapshotEnvelope = serde_json::from_str(&json).expect("parses");
        assert_eq!(parsed.metadata, supplied);

        assert!(!canonical_envelope()
            .metadata
            .contains_key("sequence_number"));
    }

    // Bounded duplicate detection.

    #[test]
    fn first_observation_is_new() {
        let mut dedup = BoundedDedup::new(3);
        assert!(!dedup.observe(1));
    }

    #[test]
    fn repeat_observation_is_reported() {
        let mut dedup = BoundedDedup::new(3);
        assert!(!dedup.observe(1));
        assert!(dedup.observe(1));
    }

    #[test]
    fn eviction_once_capacity_is_exceeded() {
        let mut dedup = BoundedDedup::new(3);
        for hash in [1, 2, 3, 4] {
            assert!(!dedup.observe(hash));
        }
        assert!(!dedup.observe(1));
    }

    #[test]
    fn retention_within_capacity() {
        let mut dedup = BoundedDedup::new(3);
        for hash in [1, 2, 3] {
            assert!(!dedup.observe(hash));
        }
        assert!(dedup.observe(1));
    }

    #[test]
    fn minimum_capacity_of_one() {
        let mut dedup = BoundedDedup::new(0);
        assert!(!dedup.observe(1));
        assert!(!dedup.observe(2));
        assert!(!dedup.observe(1));
    }

    #[test]
    fn repeat_observation_does_not_refresh_recency() {
        let mut dedup = BoundedDedup::new(2);
        assert!(!dedup.observe(1));
        assert!(!dedup.observe(2));
        assert!(dedup.observe(1));
        assert!(!dedup.observe(3));
        assert!(!dedup.observe(1));
    }

    // Byte-free payload hashing.

    #[test]
    fn determinism_for_identical_input() {
        let payload = [0xFF, 0xD8, 0xFF, 0xE0];
        assert_eq!(
            payload_hash("site-01", &payload),
            payload_hash("site-01", &payload)
        );
    }

    #[test]
    fn scope_sensitivity() {
        let payload = [0xFF, 0xD8, 0xFF, 0xE0];
        assert_ne!(
            payload_hash("site-01", &payload),
            payload_hash("asset-01", &payload)
        );
    }

    #[test]
    fn payload_sensitivity() {
        assert_ne!(
            payload_hash("site-01", &[0xFF, 0xD8, 0xFF, 0xE0]),
            payload_hash("site-01", &[0xFF, 0xD8, 0xFF, 0xE1])
        );
    }

    #[test]
    fn empty_payload_is_hashable() {
        assert_eq!(payload_hash("site-01", &[]), payload_hash("site-01", &[]));
    }

    #[test]
    fn scope_and_payload_occupy_distinct_domains() {
        // A byte moved across the scope boundary must change the digest.
        assert_ne!(payload_hash("ab", b"c"), payload_hash("a", b"bc"));
    }

    #[test]
    fn pinned_fnv1a_digest_values() {
        assert_eq!(
            payload_hash("site-01", &[0xFF, 0xD8, 0xFF, 0xE0]),
            16_442_020_789_369_212_119
        );
        assert_eq!(
            payload_hash("asset-01", &[0xFF, 0xD8, 0xFF, 0xE0]),
            1_979_264_352_941_264_301
        );
        assert_eq!(
            payload_hash("site-01", &[0xFF, 0xD8, 0xFF, 0xE1]),
            16_442_019_689_857_583_908
        );
        assert_eq!(payload_hash("site-01", &[]), 6_220_004_804_106_676_311);
    }

    // Fixed-cardinality counters.

    #[test]
    fn fixed_cardinality_of_six() {
        let json = serde_json::to_string(&Counters::default().snapshot()).expect("serializes");
        assert_eq!(
            keys(&json),
            vec![
                "received",
                "accepted",
                "rejected_empty",
                "rejected_not_jpeg",
                "rejected_oversize",
                "duplicate",
            ]
        );
    }

    #[test]
    fn denied_counters_are_absent() {
        let json = serde_json::to_string(&Counters::default().snapshot()).expect("serializes");
        for denied in ["published", "dropped_publish", "rejected_bad_topic"] {
            assert!(!keys(&json).contains(&denied.to_string()));
        }
    }

    #[test]
    fn increment_isolation() {
        let counters = Counters::default();
        counters.record_reject(RejectReason::Empty);
        let snapshot = counters.snapshot();
        assert_eq!(snapshot.rejected_empty, 1);
        assert_eq!(snapshot.received, 0);
        assert_eq!(snapshot.accepted, 0);
        assert_eq!(snapshot.rejected_not_jpeg, 0);
        assert_eq!(snapshot.rejected_oversize, 0);
        assert_eq!(snapshot.duplicate, 0);
    }

    #[test]
    fn monotonic_accumulation() {
        let counters = Counters::default();
        let mut previous = 0;
        for expected in 1..=3 {
            counters.record_reject(RejectReason::Oversize);
            let current = counters.snapshot().rejected_oversize;
            assert_eq!(current, expected);
            assert!(current >= previous);
            previous = current;
        }
    }

    #[test]
    fn snapshot_stability() {
        let counters = Counters::default();
        counters.record_reject(RejectReason::NotJpeg);
        assert_eq!(counters.snapshot(), counters.snapshot());
    }

    #[test]
    fn snapshot_is_a_point_in_time_copy() {
        let counters = Counters::default();
        let first = counters.snapshot();
        counters.record_reject(RejectReason::NotJpeg);
        assert_eq!(first.rejected_not_jpeg, 0);
        assert_eq!(counters.snapshot().rejected_not_jpeg, 1);
    }

    #[test]
    fn initial_counter_state_is_zero() {
        assert_eq!(
            Counters::default().snapshot(),
            CountersSnapshot {
                received: 0,
                accepted: 0,
                rejected_empty: 0,
                rejected_not_jpeg: 0,
                rejected_oversize: 0,
                duplicate: 0,
            }
        );
    }

    #[test]
    fn caller_drives_received_accepted_and_duplicate() {
        let counters = Counters::default();
        counters.received.fetch_add(1, Ordering::Relaxed);
        counters.accepted.fetch_add(1, Ordering::Relaxed);
        counters.duplicate.fetch_add(1, Ordering::Relaxed);
        counters.record_reject(RejectReason::Empty);

        let snapshot = counters.snapshot();
        assert_eq!(snapshot.received, 1);
        assert_eq!(snapshot.accepted, 1);
        assert_eq!(snapshot.duplicate, 1);
        assert_eq!(snapshot.rejected_empty, 1);
    }
}
