//! Broker-independent message handling.
//!
//! [`prepare`] turns one received snapshot into a rejection, a duplicate, or a
//! publish-ready request. It performs no I/O, so every decision the adapter
//! makes about a message is covered by unit tests.

use std::collections::{HashSet, VecDeque};
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use azure_iot_operations_mqtt::aio::cloud_event::CloudEventBuilder;
use azure_iot_operations_mqtt::control_packet::{PayloadFormatIndicator, PublishProperties};
use chrono::{DateTime, Utc};
use snapshot_normalizer_core::{
    build_envelope, is_jpeg, serialize_envelope, EnvelopeInput, RejectReason, SizeLimits,
    MESSAGE_TYPE,
};
use uuid::Uuid;

use crate::config::Config;

/// CloudEvents `id` user property.
pub const ID_PROPERTY: &str = "id";
/// CloudEvents `source` user property.
pub const SOURCE_PROPERTY: &str = "source";
/// CloudEvents `time` user property.
pub const TIME_PROPERTY: &str = "time";
/// W3C Trace Context user property propagated from input to output.
pub const TRACEPARENT_PROPERTY: &str = "traceparent";
/// Media type of the published request.
pub const CONTENT_TYPE: &str = "application/json";
/// Longest producer identifier used as a deduplication key.
pub const MAX_PRODUCER_ID_LEN: usize = 256;

/// Separator between deduplication key parts. It can't appear in a topic name.
const KEY_SEPARATOR: char = '\u{0}';

/// Producer-keyed duplicate detector bounded by entry count and time window.
///
/// Keys are recorded only after a request has been published, so an input the
/// broker redelivers after a restart is published again unless this pod
/// already published it within the window.
#[derive(Debug)]
pub struct KeyedDedup {
    capacity: usize,
    window: Duration,
    seen: HashSet<String>,
    order: VecDeque<(Instant, String)>,
}

impl KeyedDedup {
    /// Creates a detector holding at most `capacity` keys for at most `window`.
    pub fn new(capacity: usize, window: Duration) -> Self {
        Self {
            capacity: capacity.max(1),
            window,
            seen: HashSet::new(),
            order: VecDeque::new(),
        }
    }

    /// Returns true when the key was recorded within the window.
    pub fn contains(&mut self, key: &str, now: Instant) -> bool {
        self.expire(now);
        self.seen.contains(key)
    }

    /// Records a key, evicting the oldest key when the detector is full.
    pub fn record(&mut self, key: String, now: Instant) {
        self.expire(now);
        if self.seen.contains(&key) {
            return;
        }
        if self.order.len() >= self.capacity {
            if let Some((_, evicted)) = self.order.pop_front() {
                self.seen.remove(&evicted);
            }
        }
        self.seen.insert(key.clone());
        self.order.push_back((now, key));
    }

    /// Number of keys currently retained.
    #[cfg(test)]
    pub fn len(&self) -> usize {
        self.order.len()
    }

    fn expire(&mut self, now: Instant) {
        while let Some((recorded, _)) = self.order.front() {
            if now.saturating_duration_since(*recorded) < self.window {
                break;
            }
            if let Some((_, key)) = self.order.pop_front() {
                self.seen.remove(&key);
            }
        }
    }
}

/// Request ready to publish.
#[derive(Debug)]
pub struct Prepared {
    /// Serialized `image_snapshot` v1 request.
    pub payload: String,
    /// Publish properties carrying the CloudEvents attributes.
    pub properties: PublishProperties,
    /// Deduplication key to record after a successful publish.
    pub dedup_key: Option<String>,
}

/// Outcome of handling one received message.
#[derive(Debug)]
pub enum Outcome {
    /// Payload failed classification or a size bound.
    Rejected(RejectReason),
    /// Producer identifier was already published within the window.
    Duplicate,
    /// Request is ready to publish.
    Publish(Box<Prepared>),
}

/// Handles one received message without performing I/O.
pub fn prepare(
    config: &Config,
    dedup: &mut KeyedDedup,
    topic: &str,
    payload: &[u8],
    properties: &PublishProperties,
    now: Instant,
    wall_clock: DateTime<Utc>,
) -> Result<Outcome> {
    if let Some(reason) = reject_reason(payload, config.limits) {
        return Ok(Outcome::Rejected(reason));
    }

    let dedup_key = producer_key(topic, properties);
    if let Some(key) = &dedup_key {
        if dedup.contains(key, now) {
            return Ok(Outcome::Duplicate);
        }
    }

    let event_id = event_id();
    let time = capture_time(properties).unwrap_or(wall_clock);
    let envelope = build_envelope(EnvelopeInput {
        camera_id: &config.camera_id,
        device_name: &config.device_name,
        jpeg: payload,
        timestamp: time.timestamp(),
        metadata: serde_json::Map::new(),
        correlation_id: Some(event_id.clone()),
    });
    let serialized = serialize_envelope(&envelope).context("failed to serialize envelope")?;
    if let Err(reason) = config.limits.check_envelope(serialized.len()) {
        return Ok(Outcome::Rejected(reason));
    }

    Ok(Outcome::Publish(Box::new(Prepared {
        payload: serialized,
        properties: publish_properties(config, event_id, time, traceparent(properties))?,
        dedup_key,
    })))
}

/// Returns the first rejection reason for a raw payload, if any.
pub fn reject_reason(payload: &[u8], limits: SizeLimits) -> Option<RejectReason> {
    if payload.is_empty() {
        return Some(RejectReason::Empty);
    }
    if !is_jpeg(payload) {
        return Some(RejectReason::NotJpeg);
    }
    limits.check_jpeg(payload.len()).err()
}

/// Builds the deduplication key from the producer-supplied CloudEvents `id`.
///
/// The key is scoped to the source topic and the optional `source` attribute,
/// so one producer's identifiers can't suppress another producer's messages.
/// Messages without a usable `id` are never deduplicated.
pub fn producer_key(topic: &str, properties: &PublishProperties) -> Option<String> {
    let id = user_property(properties, ID_PROPERTY)?;
    if id.is_empty() || id.len() > MAX_PRODUCER_ID_LEN {
        return None;
    }
    let source = user_property(properties, SOURCE_PROPERTY).unwrap_or_default();
    Some(format!("{topic}{KEY_SEPARATOR}{source}{KEY_SEPARATOR}{id}"))
}

/// Random output event identifier, also used as the request `correlation_id`.
///
/// Identifiers are never derived from producer IDs, topics, or content.
pub fn event_id() -> String {
    Uuid::new_v4().to_string()
}

/// Capture time from the producer's CloudEvents `time` attribute.
pub fn capture_time(properties: &PublishProperties) -> Option<DateTime<Utc>> {
    let raw = user_property(properties, TIME_PROPERTY)?;
    DateTime::parse_from_rfc3339(raw)
        .ok()
        .map(|time| time.with_timezone(&Utc))
}

/// Returns the input `traceparent` when it is a well-formed W3C version 00 value.
pub fn traceparent(properties: &PublishProperties) -> Option<&str> {
    user_property(properties, TRACEPARENT_PROPERTY).filter(|value| is_traceparent(value))
}

fn is_traceparent(value: &str) -> bool {
    let parts: Vec<&str> = value.split('-').collect();
    let lowercase_hex = |part: &str, len: usize| {
        part.len() == len
            && part
                .bytes()
                .all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b))
    };
    parts.len() == 4
        && parts[0] == "00"
        && lowercase_hex(parts[1], 32)
        && parts[1].bytes().any(|b| b != b'0')
        && lowercase_hex(parts[2], 16)
        && parts[2].bytes().any(|b| b != b'0')
        && lowercase_hex(parts[3], 2)
}

fn publish_properties(
    config: &Config,
    event_id: String,
    time: DateTime<Utc>,
    traceparent: Option<&str>,
) -> Result<PublishProperties> {
    let event = CloudEventBuilder::default()
        .source(config.event_source.clone())
        .event_type(MESSAGE_TYPE)
        .id(event_id)
        .time(Some(time))
        .subject(Some(config.camera_id.clone()))
        .data_content_type(Some(CONTENT_TYPE.to_string()))
        .data_schema(config.data_schema.clone())
        .build()
        .context("failed to build CloudEvents attributes")?;
    let mut properties = event.set_on_publish_properties(PublishProperties {
        payload_format_indicator: PayloadFormatIndicator::UTF8,
        ..PublishProperties::default()
    });
    if let Some(value) = traceparent {
        properties
            .user_properties
            .push((TRACEPARENT_PROPERTY.to_string(), value.to_string()));
    }
    Ok(properties)
}

fn user_property<'a>(properties: &'a PublishProperties, name: &str) -> Option<&'a str> {
    properties
        .user_properties
        .iter()
        .find(|(key, _)| key == name)
        .map(|(_, value)| value.as_str())
}

#[cfg(test)]
mod tests {
    use snapshot_normalizer_core::SnapshotEnvelope;

    use super::*;
    use crate::config::{
        CAMERA_ID_VAR, DATA_SCHEMA_VAR, DEVICE_NAME_VAR, INPUT_TOPIC_VAR, MAX_ENVELOPE_BYTES_VAR,
        MAX_JPEG_BYTES_VAR,
    };

    const TOPIC: &str = "media/v1/sample-connector/camera-01/snapshots";
    const JPEG: &[u8] = &[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0xFF, 0xD9];
    const TRACEPARENT: &str = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01";

    fn config_with(extra: &[(&str, &str)]) -> Config {
        let mut pairs = vec![
            (CAMERA_ID_VAR, "camera-01"),
            (DEVICE_NAME_VAR, "camera-device-01"),
            (INPUT_TOPIC_VAR, TOPIC),
        ];
        pairs.extend_from_slice(extra);
        Config::from_lookup(move |name| {
            pairs
                .iter()
                .find(|(key, _)| *key == name)
                .map(|(_, value)| (*value).to_string())
        })
        .unwrap()
    }

    fn props(pairs: &[(&str, &str)]) -> PublishProperties {
        PublishProperties {
            user_properties: pairs
                .iter()
                .map(|(k, v)| ((*k).to_string(), (*v).to_string()))
                .collect(),
            ..PublishProperties::default()
        }
    }

    fn wall_clock() -> DateTime<Utc> {
        DateTime::parse_from_rfc3339("2026-01-02T03:04:05Z")
            .unwrap()
            .with_timezone(&Utc)
    }

    fn run(
        config: &Config,
        dedup: &mut KeyedDedup,
        payload: &[u8],
        properties: &PublishProperties,
    ) -> Outcome {
        prepare(
            config,
            dedup,
            TOPIC,
            payload,
            properties,
            Instant::now(),
            wall_clock(),
        )
        .unwrap()
    }

    fn published(outcome: Outcome) -> Prepared {
        match outcome {
            Outcome::Publish(prepared) => *prepared,
            other => panic!("expected publish, got {other:?}"),
        }
    }

    fn property<'a>(prepared: &'a Prepared, name: &str) -> Option<&'a str> {
        user_property(&prepared.properties, name)
    }

    fn dedup() -> KeyedDedup {
        KeyedDedup::new(16, Duration::from_secs(60))
    }

    #[test]
    fn rejects_empty_non_jpeg_and_oversize_payloads() {
        let config = config_with(&[(MAX_JPEG_BYTES_VAR, "8")]);
        let mut dedup = dedup();
        let cases: [(&[u8], RejectReason); 3] = [
            (&[], RejectReason::Empty),
            (b"not a jpeg", RejectReason::NotJpeg),
            (
                &[0xFF, 0xD8, 0xFF, 0, 0, 0, 0, 0, 0],
                RejectReason::Oversize,
            ),
        ];
        for (payload, expected) in cases {
            match run(&config, &mut dedup, payload, &props(&[])) {
                Outcome::Rejected(reason) => assert_eq!(reason, expected),
                other => panic!("expected rejection, got {other:?}"),
            }
        }
    }

    #[test]
    fn rejects_oversize_envelope() {
        let config = config_with(&[(MAX_ENVELOPE_BYTES_VAR, "16")]);
        match run(&config, &mut dedup(), JPEG, &props(&[])) {
            Outcome::Rejected(reason) => assert_eq!(reason, RejectReason::Oversize),
            other => panic!("expected rejection, got {other:?}"),
        }
    }

    #[test]
    fn publishes_image_snapshot_envelope() {
        let config = config_with(&[]);
        let prepared = published(run(&config, &mut dedup(), JPEG, &props(&[])));
        let envelope: SnapshotEnvelope = serde_json::from_str(&prepared.payload).unwrap();
        assert_eq!(envelope.message_type, MESSAGE_TYPE);
        assert_eq!(envelope.camera_id, "camera-01");
        assert_eq!(envelope.device_name, "camera-device-01");
        assert_eq!(envelope.timestamp, wall_clock().timestamp());
        assert_eq!(
            envelope.correlation_id.as_deref(),
            property(&prepared, ID_PROPERTY)
        );
        assert!(prepared.dedup_key.is_none());
    }

    #[test]
    fn sets_cloud_event_attributes() {
        let config = config_with(&[(
            DATA_SCHEMA_VAR,
            "aio-sr://sample-namespace/image-snapshot:1",
        )]);
        let prepared = published(run(&config, &mut dedup(), JPEG, &props(&[])));
        assert_eq!(property(&prepared, "specversion"), Some("1.0"));
        assert_eq!(property(&prepared, "type"), Some(MESSAGE_TYPE));
        assert_eq!(property(&prepared, "source"), Some("snapshot-normalizer"));
        assert_eq!(property(&prepared, "subject"), Some("camera-01"));
        assert_eq!(property(&prepared, "time"), Some("2026-01-02T03:04:05Z"));
        assert_eq!(
            property(&prepared, "dataschema"),
            Some("aio-sr://sample-namespace/image-snapshot:1")
        );
        assert_eq!(
            prepared.properties.content_type.as_deref(),
            Some(CONTENT_TYPE)
        );
        assert_eq!(
            prepared.properties.payload_format_indicator,
            PayloadFormatIndicator::UTF8
        );
        assert!(Uuid::parse_str(property(&prepared, ID_PROPERTY).unwrap()).is_ok());
    }

    #[test]
    fn omits_data_schema_when_unset() {
        let prepared = published(run(&config_with(&[]), &mut dedup(), JPEG, &props(&[])));
        assert_eq!(property(&prepared, "dataschema"), None);
    }

    #[test]
    fn uses_producer_capture_time() {
        let input = props(&[(TIME_PROPERTY, "2025-12-31T23:59:58.5+01:00")]);
        let prepared = published(run(&config_with(&[]), &mut dedup(), JPEG, &input));
        let envelope: SnapshotEnvelope = serde_json::from_str(&prepared.payload).unwrap();
        assert_eq!(envelope.timestamp, 1_767_221_998);
        assert_eq!(property(&prepared, "time"), Some("2025-12-31T22:59:58Z"));
    }

    #[test]
    fn falls_back_to_wall_clock_for_invalid_time() {
        let input = props(&[(TIME_PROPERTY, "yesterday")]);
        let prepared = published(run(&config_with(&[]), &mut dedup(), JPEG, &input));
        assert_eq!(property(&prepared, "time"), Some("2026-01-02T03:04:05Z"));
    }

    #[test]
    fn propagates_only_valid_traceparent() {
        let config = config_with(&[]);
        let prepared = published(run(
            &config,
            &mut dedup(),
            JPEG,
            &props(&[(TRACEPARENT_PROPERTY, TRACEPARENT)]),
        ));
        assert_eq!(property(&prepared, TRACEPARENT_PROPERTY), Some(TRACEPARENT));

        for invalid in [
            "garbage",
            "01-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
            "00-00000000000000000000000000000000-00f067aa0ba902b7-01",
            "00-4bf92f3577b34da6a3ce929d0e0e4736-0000000000000000-01",
            "00-4BF92F3577B34DA6A3CE929D0E0E4736-00f067aa0ba902b7-01",
        ] {
            let prepared = published(run(
                &config,
                &mut dedup(),
                JPEG,
                &props(&[(TRACEPARENT_PROPERTY, invalid)]),
            ));
            assert_eq!(property(&prepared, TRACEPARENT_PROPERTY), None, "{invalid}");
        }
    }

    #[test]
    fn deduplicates_on_recorded_producer_id_only() {
        let config = config_with(&[]);
        let mut dedup = dedup();
        let input = props(&[
            (ID_PROPERTY, "capture-1"),
            (SOURCE_PROPERTY, "sample-connector"),
        ]);

        let first = published(run(&config, &mut dedup, JPEG, &input));
        let key = first.dedup_key.clone().unwrap();

        // An unrecorded key models an input redelivered before it was published.
        let retried = published(run(&config, &mut dedup, JPEG, &input));
        assert_eq!(retried.dedup_key, first.dedup_key);

        dedup.record(key, Instant::now());
        assert!(matches!(
            run(&config, &mut dedup, JPEG, &input),
            Outcome::Duplicate
        ));
    }

    #[test]
    fn identical_payloads_with_distinct_ids_are_not_duplicates() {
        let config = config_with(&[]);
        let mut dedup = dedup();
        for id in ["capture-1", "capture-2"] {
            let prepared = published(run(&config, &mut dedup, JPEG, &props(&[(ID_PROPERTY, id)])));
            dedup.record(prepared.dedup_key.unwrap(), Instant::now());
        }
        assert_eq!(dedup.len(), 2);
    }

    #[test]
    fn event_ids_are_random_v4_and_not_derived_from_producer_ids() {
        let config = config_with(&[]);
        let input = props(&[(ID_PROPERTY, "capture-1")]);
        let first = published(run(&config, &mut dedup(), JPEG, &input));
        let second = published(run(&config, &mut dedup(), JPEG, &input));
        let id = Uuid::parse_str(property(&first, ID_PROPERTY).unwrap()).unwrap();
        assert_eq!(id.get_version(), Some(uuid::Version::Random));
        assert_ne!(
            property(&first, ID_PROPERTY),
            property(&second, ID_PROPERTY)
        );
    }

    #[test]
    fn messages_without_ids_are_never_deduplicated() {
        let config = config_with(&[]);
        let mut dedup = dedup();
        let first = published(run(&config, &mut dedup, JPEG, &props(&[])));
        let second = published(run(&config, &mut dedup, JPEG, &props(&[])));
        assert!(first.dedup_key.is_none());
        assert_ne!(
            property(&first, ID_PROPERTY),
            property(&second, ID_PROPERTY)
        );
    }

    #[test]
    fn producer_key_is_scoped_to_topic_and_source() {
        let input = props(&[(ID_PROPERTY, "capture-1"), (SOURCE_PROPERTY, "connector-a")]);
        let other_source = props(&[(ID_PROPERTY, "capture-1"), (SOURCE_PROPERTY, "connector-b")]);
        let key = producer_key(TOPIC, &input).unwrap();
        assert_ne!(
            Some(key.clone()),
            producer_key("media/v1/other/camera-02/snapshots", &input)
        );
        assert_ne!(Some(key), producer_key(TOPIC, &other_source));
    }

    #[test]
    fn producer_key_ignores_empty_and_oversize_ids() {
        assert!(producer_key(TOPIC, &props(&[(ID_PROPERTY, "")])).is_none());
        let long = "x".repeat(MAX_PRODUCER_ID_LEN + 1);
        assert!(producer_key(TOPIC, &props(&[(ID_PROPERTY, long.as_str())])).is_none());
        let max = "x".repeat(MAX_PRODUCER_ID_LEN);
        assert!(producer_key(TOPIC, &props(&[(ID_PROPERTY, max.as_str())])).is_some());
    }

    #[test]
    fn dedup_expires_keys_after_window() {
        let start = Instant::now();
        let mut dedup = KeyedDedup::new(16, Duration::from_secs(10));
        dedup.record("a".to_string(), start);
        assert!(dedup.contains("a", start + Duration::from_secs(9)));
        assert!(!dedup.contains("a", start + Duration::from_secs(10)));
        assert_eq!(dedup.len(), 0);
    }

    #[test]
    fn dedup_evicts_oldest_key_at_capacity() {
        let now = Instant::now();
        let mut dedup = KeyedDedup::new(2, Duration::from_secs(60));
        for key in ["a", "b", "c"] {
            dedup.record(key.to_string(), now);
        }
        assert!(!dedup.contains("a", now));
        assert!(dedup.contains("b", now));
        assert!(dedup.contains("c", now));
        assert_eq!(dedup.len(), 2);
    }

    #[test]
    fn dedup_record_is_idempotent() {
        let now = Instant::now();
        let mut dedup = KeyedDedup::new(2, Duration::from_secs(60));
        dedup.record("a".to_string(), now);
        dedup.record("a".to_string(), now);
        assert_eq!(dedup.len(), 1);
    }
}
