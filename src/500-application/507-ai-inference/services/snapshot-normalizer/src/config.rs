//! Environment-driven adapter configuration.
//!
//! Every value is read through a caller-supplied lookup so the parsing and
//! validation rules can be exercised without touching the process environment.

use std::time::Duration;

use anyhow::{bail, Context, Result};
use azure_iot_operations_mqtt::aio::cloud_event::{
    CloudEventFields, DEFAULT_CLOUD_EVENT_SPEC_VERSION,
};
use azure_iot_operations_mqtt::control_packet::{TopicFilter, TopicName};
use snapshot_normalizer_core::SizeLimits;

pub const CAMERA_ID_VAR: &str = "CAMERA_ID";
pub const DEVICE_NAME_VAR: &str = "DEVICE_NAME";
pub const INPUT_TOPIC_VAR: &str = "INPUT_TOPIC";
pub const OUTPUT_TOPIC_VAR: &str = "OUTPUT_TOPIC";
pub const EVENT_SOURCE_VAR: &str = "EVENT_SOURCE";
pub const DATA_SCHEMA_VAR: &str = "DATA_SCHEMA";
pub const MAX_JPEG_BYTES_VAR: &str = "MAX_JPEG_BYTES";
pub const MAX_ENVELOPE_BYTES_VAR: &str = "MAX_ENVELOPE_BYTES";
pub const DEDUP_CAPACITY_VAR: &str = "DEDUP_CAPACITY";
pub const DEDUP_WINDOW_SECONDS_VAR: &str = "DEDUP_WINDOW_SECONDS";
pub const PUBLISH_ATTEMPTS_VAR: &str = "PUBLISH_ATTEMPTS";
pub const COUNTERS_INTERVAL_SECONDS_VAR: &str = "COUNTERS_INTERVAL_SECONDS";

pub const DEFAULT_EVENT_SOURCE: &str = "snapshot-normalizer";
pub const DEFAULT_MAX_JPEG_BYTES: usize = 4 * 1024 * 1024;
pub const DEFAULT_MAX_ENVELOPE_BYTES: usize = 8 * 1024 * 1024;
pub const DEFAULT_DEDUP_CAPACITY: usize = 1024;
pub const DEFAULT_DEDUP_WINDOW_SECONDS: u64 = 300;
pub const DEFAULT_PUBLISH_ATTEMPTS: u32 = 3;
pub const DEFAULT_COUNTERS_INTERVAL_SECONDS: u64 = 60;

/// Most publish attempts per request, bounding how long one request can hold
/// the in-order receive loop.
pub const MAX_PUBLISH_ATTEMPTS: u32 = 10;

/// Most unacknowledged QoS 1 inputs the broker may have in flight to the adapter.
pub const RECEIVE_MAX: u16 = 8;

/// Room above `MAX_JPEG_BYTES` for the fixed header, topic, and user properties
/// of an input PUBLISH.
pub const RECEIVE_PACKET_HEADROOM_BYTES: usize = 64 * 1024;

/// Longest accepted camera identifier, which also becomes a topic segment.
pub const MAX_CAMERA_ID_LEN: usize = 64;

/// Validated adapter configuration.
#[derive(Debug, Clone)]
pub struct Config {
    pub camera_id: String,
    pub device_name: String,
    pub input_filter: TopicFilter,
    pub output_topic: TopicName,
    pub event_source: String,
    pub data_schema: Option<String>,
    pub limits: SizeLimits,
    pub dedup_capacity: usize,
    pub dedup_window: Duration,
    pub publish_attempts: u32,
    pub counters_interval: Duration,
}

impl Config {
    /// Builds a configuration from the process environment.
    pub fn from_env() -> Result<Self> {
        Self::from_lookup(|name| std::env::var(name).ok())
    }

    /// Builds a configuration from an arbitrary variable lookup.
    pub fn from_lookup(lookup: impl Fn(&str) -> Option<String>) -> Result<Self> {
        let value = |name: &str| lookup(name).filter(|v| !v.trim().is_empty());

        let camera_id =
            value(CAMERA_ID_VAR).with_context(|| format!("{CAMERA_ID_VAR} must be set"))?;
        if !is_topic_segment(&camera_id) {
            bail!(
                "{CAMERA_ID_VAR} must be 1-{MAX_CAMERA_ID_LEN} characters of lowercase letters, digits, '.', '_', or '-'"
            );
        }
        let device_name =
            value(DEVICE_NAME_VAR).with_context(|| format!("{DEVICE_NAME_VAR} must be set"))?;

        let input_topic =
            value(INPUT_TOPIC_VAR).with_context(|| format!("{INPUT_TOPIC_VAR} must be set"))?;
        let input_filter = TopicFilter::new(input_topic).map_err(|error| {
            anyhow::anyhow!("{INPUT_TOPIC_VAR} is not a valid topic filter: {error}")
        })?;

        let output_topic =
            value(OUTPUT_TOPIC_VAR).unwrap_or_else(|| default_output_topic(&camera_id));
        let output_topic = TopicName::new(output_topic).map_err(|error| {
            anyhow::anyhow!("{OUTPUT_TOPIC_VAR} is not a valid topic name: {error}")
        })?;
        if output_topic.matches_topic_filter(&input_filter) {
            bail!("{OUTPUT_TOPIC_VAR} matches {INPUT_TOPIC_VAR}, which would republish the adapter's own output");
        }

        let event_source =
            value(EVENT_SOURCE_VAR).unwrap_or_else(|| DEFAULT_EVENT_SOURCE.to_string());
        CloudEventFields::Source
            .validate(&event_source, DEFAULT_CLOUD_EVENT_SPEC_VERSION)
            .map_err(|error| anyhow::anyhow!("{EVENT_SOURCE_VAR} is invalid: {error}"))?;

        let data_schema = value(DATA_SCHEMA_VAR);
        if let Some(schema) = &data_schema {
            CloudEventFields::DataSchema
                .validate(schema, DEFAULT_CLOUD_EVENT_SPEC_VERSION)
                .map_err(|error| anyhow::anyhow!("{DATA_SCHEMA_VAR} is invalid: {error}"))?;
        }

        Ok(Self {
            camera_id,
            device_name,
            input_filter,
            output_topic,
            event_source,
            data_schema,
            limits: SizeLimits {
                max_jpeg_bytes: positive(&value, MAX_JPEG_BYTES_VAR, DEFAULT_MAX_JPEG_BYTES)?,
                max_envelope_bytes: positive(
                    &value,
                    MAX_ENVELOPE_BYTES_VAR,
                    DEFAULT_MAX_ENVELOPE_BYTES,
                )?,
            },
            dedup_capacity: positive(&value, DEDUP_CAPACITY_VAR, DEFAULT_DEDUP_CAPACITY)?,
            dedup_window: Duration::from_secs(positive(
                &value,
                DEDUP_WINDOW_SECONDS_VAR,
                DEFAULT_DEDUP_WINDOW_SECONDS,
            )?),
            publish_attempts: publish_attempts(&value)?,
            counters_interval: Duration::from_secs(positive(
                &value,
                COUNTERS_INTERVAL_SECONDS_VAR,
                DEFAULT_COUNTERS_INTERVAL_SECONDS,
            )?),
        })
    }
}

impl Config {
    /// Largest input PUBLISH the adapter accepts from the broker: the JPEG bound
    /// plus header room, saturated to the MQTT maximum.
    pub fn receive_packet_size_max(&self) -> u32 {
        u32::try_from(
            self.limits
                .max_jpeg_bytes
                .saturating_add(RECEIVE_PACKET_HEADROOM_BYTES),
        )
        .unwrap_or(u32::MAX)
    }
}

/// Default versioned output topic for a camera, following the
/// `{domain}/{version}/{producer}/{resource-kind}/{resource-id}/{message-kind}`
/// grammar.
///
/// The topic matches the component 507 inference service's pinned
/// `edge-ai/v1/+/camera/+/snapshots` input filter.
pub fn default_output_topic(camera_id: &str) -> String {
    format!("edge-ai/v1/{DEFAULT_EVENT_SOURCE}/camera/{camera_id}/snapshots")
}

fn publish_attempts(value: &impl Fn(&str) -> Option<String>) -> Result<u32> {
    let attempts = positive(value, PUBLISH_ATTEMPTS_VAR, DEFAULT_PUBLISH_ATTEMPTS)?;
    if attempts > MAX_PUBLISH_ATTEMPTS {
        bail!("{PUBLISH_ATTEMPTS_VAR} must be at most {MAX_PUBLISH_ATTEMPTS}");
    }
    Ok(attempts)
}

/// Returns true when the value is a lowercase, URL-safe, single topic segment.
pub fn is_topic_segment(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= MAX_CAMERA_ID_LEN
        && value.bytes().all(|b| {
            b.is_ascii_lowercase() || b.is_ascii_digit() || matches!(b, b'.' | b'_' | b'-')
        })
}

fn positive<T>(value: &impl Fn(&str) -> Option<String>, name: &str, default: T) -> Result<T>
where
    T: std::str::FromStr + PartialOrd + Default + Copy,
{
    let parsed = match value(name) {
        Some(raw) => raw
            .trim()
            .parse::<T>()
            .map_err(|_| anyhow::anyhow!("{name} must be a positive integer"))?,
        None => default,
    };
    if parsed <= T::default() {
        bail!("{name} must be a positive integer");
    }
    Ok(parsed)
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::*;

    fn lookup(pairs: &[(&str, &str)]) -> impl Fn(&str) -> Option<String> {
        let map: HashMap<String, String> = pairs
            .iter()
            .map(|(k, v)| ((*k).to_string(), (*v).to_string()))
            .collect();
        move |name| map.get(name).cloned()
    }

    fn required() -> Vec<(&'static str, &'static str)> {
        vec![
            (CAMERA_ID_VAR, "camera-01"),
            (DEVICE_NAME_VAR, "camera-device-01"),
            (
                INPUT_TOPIC_VAR,
                "media/v1/sample-connector/camera-01/snapshots",
            ),
        ]
    }

    fn with(extra: &[(&'static str, &'static str)]) -> Vec<(&'static str, &'static str)> {
        let mut pairs = required();
        pairs.extend_from_slice(extra);
        pairs
    }

    fn error_of(pairs: &[(&str, &str)]) -> String {
        Config::from_lookup(lookup(pairs)).unwrap_err().to_string()
    }

    #[test]
    fn applies_defaults() {
        let config = Config::from_lookup(lookup(&required())).unwrap();
        assert_eq!(
            config.output_topic.as_str(),
            "edge-ai/v1/snapshot-normalizer/camera/camera-01/snapshots"
        );
        assert_eq!(config.event_source, DEFAULT_EVENT_SOURCE);
        assert_eq!(config.data_schema, None);
        assert_eq!(config.limits.max_jpeg_bytes, DEFAULT_MAX_JPEG_BYTES);
        assert_eq!(config.limits.max_envelope_bytes, DEFAULT_MAX_ENVELOPE_BYTES);
        assert_eq!(config.dedup_capacity, DEFAULT_DEDUP_CAPACITY);
        assert_eq!(
            config.dedup_window,
            Duration::from_secs(DEFAULT_DEDUP_WINDOW_SECONDS)
        );
        assert_eq!(config.publish_attempts, DEFAULT_PUBLISH_ATTEMPTS);
    }

    #[test]
    fn default_output_topic_matches_pinned_v1_inference_subscription() {
        let topic = TopicName::new(default_output_topic("camera-01")).unwrap();
        let v1 = TopicFilter::new("edge-ai/v1/+/camera/+/snapshots").unwrap();
        let legacy = TopicFilter::new("edge-ai/+/+/camera/snapshots").unwrap();
        assert!(topic.matches_topic_filter(&v1));
        assert!(!topic.matches_topic_filter(&legacy));
    }

    #[test]
    fn requires_identity_and_input() {
        for missing in [CAMERA_ID_VAR, DEVICE_NAME_VAR, INPUT_TOPIC_VAR] {
            let pairs: Vec<_> = required()
                .into_iter()
                .filter(|(k, _)| *k != missing)
                .collect();
            assert!(error_of(&pairs).contains(missing), "{missing}");
        }
    }

    #[test]
    fn treats_blank_values_as_unset() {
        let pairs = [
            (CAMERA_ID_VAR, "camera-01"),
            (DEVICE_NAME_VAR, "  "),
            (
                INPUT_TOPIC_VAR,
                "media/v1/sample-connector/camera-01/snapshots",
            ),
        ];
        assert!(error_of(&pairs).contains(DEVICE_NAME_VAR));
    }

    #[test]
    fn rejects_camera_ids_that_are_not_topic_segments() {
        let too_long = "a".repeat(MAX_CAMERA_ID_LEN + 1);
        for camera_id in [
            "Camera-01",
            "camera/01",
            "camera+",
            "camera#",
            "camera 01",
            too_long.as_str(),
        ] {
            let pairs = [
                (CAMERA_ID_VAR, camera_id),
                (DEVICE_NAME_VAR, "camera-device-01"),
                (
                    INPUT_TOPIC_VAR,
                    "media/v1/sample-connector/camera-01/snapshots",
                ),
            ];
            assert!(error_of(&pairs).contains(CAMERA_ID_VAR), "{camera_id}");
        }
    }

    #[test]
    fn rejects_output_topic_matching_input_filter() {
        for input_topic in [
            "edge-ai/#",
            "edge-ai/v1/+/camera/+/snapshots",
            "edge-ai/v1/snapshot-normalizer/camera/camera-01/snapshots",
        ] {
            let pairs = [
                (CAMERA_ID_VAR, "camera-01"),
                (DEVICE_NAME_VAR, "camera-device-01"),
                (INPUT_TOPIC_VAR, input_topic),
            ];
            assert!(error_of(&pairs).contains("republish"), "{input_topic}");
        }

        let pairs = with(&[(
            OUTPUT_TOPIC_VAR,
            "media/v1/sample-connector/camera-01/snapshots",
        )]);
        assert!(error_of(&pairs).contains("republish"));
    }

    #[test]
    fn rejects_wildcard_output_topic() {
        let pairs = with(&[(OUTPUT_TOPIC_VAR, "edge-ai/v1/+/camera/camera-01/snapshots")]);
        assert!(error_of(&pairs).contains(OUTPUT_TOPIC_VAR));
    }

    #[test]
    fn rejects_invalid_input_filter() {
        let pairs = [
            (CAMERA_ID_VAR, "camera-01"),
            (DEVICE_NAME_VAR, "camera-device-01"),
            (INPUT_TOPIC_VAR, "media/#/snapshots"),
        ];
        assert!(error_of(&pairs).contains(INPUT_TOPIC_VAR));
    }

    #[test]
    fn rejects_non_positive_numbers() {
        for name in [
            MAX_JPEG_BYTES_VAR,
            MAX_ENVELOPE_BYTES_VAR,
            DEDUP_CAPACITY_VAR,
            DEDUP_WINDOW_SECONDS_VAR,
            PUBLISH_ATTEMPTS_VAR,
            COUNTERS_INTERVAL_SECONDS_VAR,
        ] {
            for raw in ["0", "-1", "ten"] {
                assert!(
                    error_of(&with(&[(name, raw)])).contains(name),
                    "{name}={raw}"
                );
            }
        }
    }

    #[test]
    fn bounds_publish_attempts() {
        let config = Config::from_lookup(lookup(&with(&[(PUBLISH_ATTEMPTS_VAR, "10")]))).unwrap();
        assert_eq!(config.publish_attempts, MAX_PUBLISH_ATTEMPTS);
        assert!(error_of(&with(&[(PUBLISH_ATTEMPTS_VAR, "11")])).contains(PUBLISH_ATTEMPTS_VAR));
    }

    #[test]
    fn receive_packet_size_max_covers_jpeg_bound_and_saturates() {
        let config = Config::from_lookup(lookup(&required())).unwrap();
        assert_eq!(
            config.receive_packet_size_max() as usize,
            DEFAULT_MAX_JPEG_BYTES + RECEIVE_PACKET_HEADROOM_BYTES
        );

        let huge = (u64::from(u32::MAX) + 1).to_string();
        let mut pairs: Vec<(&str, &str)> = required();
        pairs.push((MAX_JPEG_BYTES_VAR, huge.as_str()));
        let config = Config::from_lookup(lookup(&pairs)).unwrap();
        assert_eq!(config.receive_packet_size_max(), u32::MAX);
    }

    #[test]
    fn validates_cloud_event_attributes() {
        let config = Config::from_lookup(lookup(&with(&[
            (EVENT_SOURCE_VAR, "aio://sample/snapshot-normalizer"),
            (
                DATA_SCHEMA_VAR,
                "aio-sr://sample-namespace/image-snapshot:1",
            ),
        ])))
        .unwrap();
        assert_eq!(config.event_source, "aio://sample/snapshot-normalizer");
        assert_eq!(
            config.data_schema.as_deref(),
            Some("aio-sr://sample-namespace/image-snapshot:1")
        );

        assert!(error_of(&with(&[(DATA_SCHEMA_VAR, "not a uri")])).contains(DATA_SCHEMA_VAR));
    }
}
