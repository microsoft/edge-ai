use std::env;
use std::sync::atomic::Ordering;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use azure_iot_operations_mqtt::aio::connection_settings::MqttConnectionSettingsBuilder;
use azure_iot_operations_mqtt::control_packet::{
    PublishProperties, QoS, RetainOptions, SubscribeProperties, TopicFilter, TopicName,
};
use azure_iot_operations_mqtt::session::{
    Session, SessionManagedClient, SessionMonitor, SessionOptionsBuilder,
};
use snapshot_normalizer_core::{
    build_envelope, is_jpeg, payload_hash, serialize_envelope, BoundedDedup, Counters,
    EnvelopeInput, RejectReason, SizeLimits,
};
use tracing::{info, warn};
use tracing_subscriber::EnvFilter;

const CAMERA_ID_VAR: &str = "CAMERA_ID";
const DEVICE_NAME_VAR: &str = "DEVICE_NAME";
const INPUT_TOPIC_VAR: &str = "INPUT_TOPIC";
const OUTPUT_TOPIC_VAR: &str = "OUTPUT_TOPIC";
const MAX_JPEG_BYTES_VAR: &str = "MAX_JPEG_BYTES";
const MAX_ENVELOPE_BYTES_VAR: &str = "MAX_ENVELOPE_BYTES";
const DEDUP_CAPACITY_VAR: &str = "DEDUP_CAPACITY";
const DEFAULT_INPUT_TOPIC: &str = "edge-ai/cameras/snapshots/raw";
const DEFAULT_OUTPUT_TOPIC: &str = "edge-ai/inference/requests";
const DEFAULT_MAX_JPEG_BYTES: usize = 4 * 1024 * 1024;
const DEFAULT_MAX_ENVELOPE_BYTES: usize = 8 * 1024 * 1024;
const DEFAULT_DEDUP_CAPACITY: usize = 1024;

struct Config {
    camera_id: String,
    device_name: String,
    input_topic: String,
    output_topic: String,
    limits: SizeLimits,
    dedup_capacity: usize,
}

impl Config {
    fn from_env() -> Result<Self> {
        Ok(Self {
            camera_id: required_env(CAMERA_ID_VAR)?,
            device_name: required_env(DEVICE_NAME_VAR)?,
            input_topic: env::var(INPUT_TOPIC_VAR)
                .unwrap_or_else(|_| DEFAULT_INPUT_TOPIC.to_string()),
            output_topic: env::var(OUTPUT_TOPIC_VAR)
                .unwrap_or_else(|_| DEFAULT_OUTPUT_TOPIC.to_string()),
            limits: SizeLimits {
                max_jpeg_bytes: usize_env(MAX_JPEG_BYTES_VAR, DEFAULT_MAX_JPEG_BYTES)?,
                max_envelope_bytes: usize_env(
                    MAX_ENVELOPE_BYTES_VAR,
                    DEFAULT_MAX_ENVELOPE_BYTES,
                )?,
            },
            dedup_capacity: usize_env(DEDUP_CAPACITY_VAR, DEFAULT_DEDUP_CAPACITY)?,
        })
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let config = Config::from_env()?;
    let connection_settings = MqttConnectionSettingsBuilder::from_environment()
        .map_err(|error| anyhow::anyhow!("failed to read MQTT connection settings: {error}"))?
        .build()
        .context("failed to build MQTT connection settings")?;
    let session_options = SessionOptionsBuilder::default()
        .connection_settings(connection_settings)
        .build()
        .context("failed to build MQTT session options")?;
    let session = Session::new(session_options)
        .map_err(|error| anyhow::anyhow!("failed to create MQTT session: {error}"))?;
    let client = session.create_managed_client();
    let monitor = session.create_session_monitor();
    let counters = Arc::new(Counters::default());

    info!(
        input_topic = %config.input_topic,
        output_topic = %config.output_topic,
        camera_id = %config.camera_id,
        device_name = %config.device_name,
        "snapshot normalizer starting"
    );

    tokio::select! {
        result = session.run() => {
            result.map_err(|error| anyhow::anyhow!("MQTT session stopped: {error}"))?
        },
        result = process_messages(client, monitor, counters.clone(), &config) => result?,
        result = tokio::signal::ctrl_c() => result.context("failed to listen for shutdown signal")?,
    }

    info!(counters = ?counters.snapshot(), "snapshot normalizer stopped");
    Ok(())
}

async fn process_messages(
    client: SessionManagedClient,
    monitor: SessionMonitor,
    counters: Arc<Counters>,
    config: &Config,
) -> Result<()> {
    let input_filter = TopicFilter::new(&config.input_topic).context("INPUT_TOPIC is invalid")?;
    let output_topic = TopicName::new(&config.output_topic).context("OUTPUT_TOPIC is invalid")?;
    let mut receiver = client.create_filtered_pub_receiver(input_filter.clone());
    let mut dedup = BoundedDedup::new(config.dedup_capacity);

    monitor.connected().await;
    client
        .subscribe(
            input_filter,
            QoS::AtLeastOnce,
            false,
            RetainOptions::default(),
            SubscribeProperties::default(),
        )
        .await
        .context("failed to subscribe to INPUT_TOPIC")?;
    info!(input_topic = %config.input_topic, "subscribed to snapshots");

    while let Some(message) = receiver.recv().await {
        counters.received.fetch_add(1, Ordering::Relaxed);
        let payload = message.payload.as_ref();

        if let Some(reason) = reject_reason(payload, config.limits) {
            counters.record_reject(reason);
            warn!(reason = reason.as_str(), payload_bytes = payload.len(), "snapshot rejected");
            continue;
        }

        let source_topic = message.topic_name.to_string();
        if dedup.observe(payload_hash(&source_topic, payload)) {
            counters.duplicate.fetch_add(1, Ordering::Relaxed);
            continue;
        }

        let envelope = build_envelope(EnvelopeInput {
            camera_id: &config.camera_id,
            device_name: &config.device_name,
            jpeg: payload,
            timestamp: epoch_seconds()?,
            metadata: serde_json::Map::new(),
            correlation_id: None,
        });
        let serialized = serialize_envelope(&envelope).context("failed to serialize envelope")?;
        if let Err(reason) = config.limits.check_envelope(serialized.len()) {
            counters.record_reject(reason);
            warn!(reason = reason.as_str(), envelope_bytes = serialized.len(), "snapshot rejected");
            continue;
        }

        counters.accepted.fetch_add(1, Ordering::Relaxed);
        let completion = client
            .publish_qos1(
                output_topic.clone(),
                false,
                serialized,
                PublishProperties::default(),
            )
            .await
            .context("failed to publish normalized snapshot")?;
        completion
            .await
            .context("normalized snapshot publish was not acknowledged")?;
    }

    Ok(())
}

fn reject_reason(payload: &[u8], limits: SizeLimits) -> Option<RejectReason> {
    if payload.is_empty() {
        return Some(RejectReason::Empty);
    }
    if !is_jpeg(payload) {
        return Some(RejectReason::NotJpeg);
    }
    limits.check_jpeg(payload.len()).err()
}

fn required_env(name: &str) -> Result<String> {
    env::var(name)
        .with_context(|| format!("{name} must be set"))
        .and_then(|value| {
            if value.trim().is_empty() {
                anyhow::bail!("{name} must not be empty");
            }
            Ok(value)
        })
}

fn usize_env(name: &str, default: usize) -> Result<usize> {
    env::var(name)
        .unwrap_or_else(|_| default.to_string())
        .parse::<usize>()
        .with_context(|| format!("{name} must be a non-negative integer"))
}

fn epoch_seconds() -> Result<i64> {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .context("system clock is before the Unix epoch")?
        .as_secs();
    i64::try_from(seconds).context("system clock exceeds the supported timestamp range")
}