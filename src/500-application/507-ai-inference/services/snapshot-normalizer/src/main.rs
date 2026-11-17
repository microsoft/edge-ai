//! MQTT adapter that republishes binary JPEG snapshots as `image_snapshot` v1
//! requests for the component 507 inference service.

mod config;
mod pipeline;

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use azure_iot_operations_mqtt::aio::connection_settings::MqttConnectionSettingsBuilder;
use azure_iot_operations_mqtt::control_packet::{
    QoS, RetainHandling, RetainOptions, SubAck, SubscribeProperties,
};
use azure_iot_operations_mqtt::session::{
    Session, SessionManagedClient, SessionMonitor, SessionOptionsBuilder,
};
use chrono::Utc;
use snapshot_normalizer_core::Counters;
use tracing::{info, warn};
use tracing_subscriber::EnvFilter;

use crate::config::{Config, RECEIVE_MAX};
use crate::pipeline::{prepare, KeyedDedup, Outcome, Prepared};

const INITIAL_RETRY_DELAY: Duration = Duration::from_millis(500);
const MAX_RETRY_DELAY: Duration = Duration::from_secs(30);

/// Counters the adapter adds to the core set.
#[derive(Debug, Default)]
struct AdapterCounters {
    published: AtomicU64,
    unkeyed: AtomicU64,
    publish_failed: AtomicU64,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let config = Config::from_env()?;
    // A small receive maximum bounds buffered inputs, because inputs are handled
    // and acknowledged one at a time; the packet bound drops oversize inputs.
    let connection_settings = MqttConnectionSettingsBuilder::from_environment()
        .map_err(|error| anyhow::anyhow!("failed to read MQTT connection settings: {error}"))?
        .receive_max(RECEIVE_MAX)
        .receive_packet_size_max(Some(config.receive_packet_size_max()))
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
    let exit = session.create_exit_handle();
    let counters = Arc::new(Counters::default());
    let adapter_counters = Arc::new(AdapterCounters::default());

    info!(
        input_topic = config.input_filter.as_str(),
        output_topic = config.output_topic.as_str(),
        client_id = client.client_id(),
        "snapshot normalizer starting"
    );

    let result = tokio::select! {
        result = session.run() => result.map_err(|error| anyhow::anyhow!("MQTT session stopped: {error}")),
        result = process_messages(client, monitor, &config, counters.clone(), adapter_counters.clone()) => result,
        () = log_counters(config.counters_interval, counters.clone(), adapter_counters.clone()) => Ok(()),
        result = shutdown_signal() => result,
    };

    if exit.try_exit().is_err() {
        exit.force_exit();
    }
    report(&counters, &adapter_counters, "snapshot normalizer stopped");
    result
}

async fn process_messages(
    client: SessionManagedClient,
    monitor: SessionMonitor,
    config: &Config,
    counters: Arc<Counters>,
    adapter_counters: Arc<AdapterCounters>,
) -> Result<()> {
    // Create the receiver before subscribing so no delivery is dropped.
    let mut receiver = client.create_filtered_pub_receiver(config.input_filter.clone());
    let mut dedup = KeyedDedup::new(config.dedup_capacity, config.dedup_window);

    monitor.connected().await;
    let suback = client
        .subscribe(
            config.input_filter.clone(),
            QoS::AtLeastOnce,
            true,
            input_retain_options(),
            SubscribeProperties::default(),
        )
        .await
        .context("failed to queue INPUT_TOPIC subscription")?
        .await
        .context("INPUT_TOPIC subscription was not acknowledged")?;
    check_suback(&suback)?;
    info!(
        input_topic = config.input_filter.as_str(),
        "subscribed to snapshots"
    );

    while let Some((message, ack)) = receiver.recv_manual_ack().await {
        counters.received.fetch_add(1, Ordering::Relaxed);
        let outcome = prepare(
            config,
            &mut dedup,
            message.topic_name.as_str(),
            &message.payload,
            &message.properties,
            Instant::now(),
            Utc::now(),
        )?;

        match outcome {
            Outcome::Rejected(reason) => {
                counters.record_reject(reason);
                warn!(
                    reason = reason.as_str(),
                    payload_bytes = message.payload.len(),
                    "snapshot rejected"
                );
            }
            Outcome::Duplicate => {
                counters.duplicate.fetch_add(1, Ordering::Relaxed);
            }
            Outcome::Publish(prepared) => {
                counters.accepted.fetch_add(1, Ordering::Relaxed);
                if prepared.dedup_key.is_none() {
                    adapter_counters.unkeyed.fetch_add(1, Ordering::Relaxed);
                }
                let Prepared {
                    payload,
                    properties,
                    dedup_key,
                } = *prepared;
                if publish(&client, config, payload, properties).await {
                    adapter_counters.published.fetch_add(1, Ordering::Relaxed);
                    if let Some(key) = dedup_key {
                        dedup.record(key, Instant::now());
                    }
                } else {
                    adapter_counters
                        .publish_failed
                        .fetch_add(1, Ordering::Relaxed);
                }
            }
        }

        // Acknowledgements are delivered in receive order, so every message is
        // acknowledged once handling ends, including failed publishes.
        if let Some(ack) = ack {
            ack.ack()
                .await
                .context("failed to queue input acknowledgement")?
                .await
                .context("input acknowledgement failed")?;
        }
    }

    Ok(())
}

/// Skips retained snapshots on subscribe, so a stale frame isn't replayed as
/// a new request after every restart.
fn input_retain_options() -> RetainOptions {
    RetainOptions {
        retain_as_published: false,
        retain_handling: RetainHandling::DoNotSend,
    }
}

/// Fails when the broker refused the subscription, so the pod exits and the
/// failure is visible as a restart rather than a silent idle adapter.
fn check_suback(suback: &SubAck) -> Result<()> {
    suback
        .as_result()
        .map_err(|failure| anyhow::anyhow!("INPUT_TOPIC subscription was rejected: {failure}"))
}

/// Delay before the retry that follows `delay`, doubling up to [`MAX_RETRY_DELAY`].
fn next_retry_delay(delay: Duration) -> Duration {
    delay.saturating_mul(2).min(MAX_RETRY_DELAY)
}

/// Publishes a request at QoS 1 with bounded retries.
///
/// Returns false when every attempt failed or the broker rejected the request.
async fn publish(
    client: &SessionManagedClient,
    config: &Config,
    payload: String,
    properties: azure_iot_operations_mqtt::control_packet::PublishProperties,
) -> bool {
    let mut delay = INITIAL_RETRY_DELAY;
    for attempt in 1..=config.publish_attempts {
        let result = match client
            .publish_qos1(
                config.output_topic.clone(),
                false,
                payload.clone(),
                properties.clone(),
            )
            .await
        {
            Ok(completion) => completion.await.map_err(|error| error.to_string()),
            Err(error) => Err(error.to_string()),
        };
        match result {
            Ok(puback) if puback.is_success() => return true,
            Ok(puback) => {
                warn!(reason = ?puback.reason, "broker rejected normalized snapshot");
                return false;
            }
            Err(error) => {
                warn!(attempt, attempts = config.publish_attempts, %error, "normalized snapshot publish failed");
            }
        }
        if attempt < config.publish_attempts {
            tokio::time::sleep(delay).await;
            delay = next_retry_delay(delay);
        }
    }
    false
}

async fn log_counters(
    interval: Duration,
    counters: Arc<Counters>,
    adapter_counters: Arc<AdapterCounters>,
) {
    let mut ticker = tokio::time::interval(interval);
    ticker.tick().await;
    loop {
        ticker.tick().await;
        report(&counters, &adapter_counters, "snapshot normalizer counters");
    }
}

fn report(counters: &Counters, adapter_counters: &AdapterCounters, message: &str) {
    let core = counters.snapshot();
    info!(
        received = core.received,
        accepted = core.accepted,
        published = adapter_counters.published.load(Ordering::Relaxed),
        duplicate = core.duplicate,
        unkeyed = adapter_counters.unkeyed.load(Ordering::Relaxed),
        rejected_empty = core.rejected_empty,
        rejected_not_jpeg = core.rejected_not_jpeg,
        rejected_oversize = core.rejected_oversize,
        publish_failed = adapter_counters.publish_failed.load(Ordering::Relaxed),
        "{message}"
    );
}

async fn shutdown_signal() -> Result<()> {
    let mut terminate = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
        .context("failed to listen for SIGTERM")?;
    tokio::select! {
        result = tokio::signal::ctrl_c() => result.context("failed to listen for SIGINT"),
        _ = terminate.recv() => Ok(()),
    }
}

#[cfg(test)]
mod tests {
    use azure_iot_operations_mqtt::control_packet::{
        PacketIdentifier, SubAckProperties, SubAckReason,
    };

    use super::*;

    fn suback(reasons: Vec<SubAckReason>) -> SubAck {
        SubAck {
            packet_identifier: PacketIdentifier::new(1).unwrap(),
            reasons,
            properties: SubAckProperties::default(),
        }
    }

    #[test]
    fn granted_suback_is_accepted() {
        assert!(check_suback(&suback(vec![SubAckReason::GrantedQoS1])).is_ok());
        assert!(check_suback(&suback(vec![SubAckReason::GrantedQoS0])).is_ok());
    }

    #[test]
    fn rejected_suback_fails_with_reason() {
        let error = check_suback(&suback(vec![SubAckReason::NotAuthorized]))
            .unwrap_err()
            .to_string();
        assert!(error.contains("rejected"), "{error}");
        assert!(error.contains("NotAuthorized"), "{error}");
    }

    #[test]
    fn retained_snapshots_are_not_replayed_on_subscribe() {
        let options = input_retain_options();
        assert!(matches!(options.retain_handling, RetainHandling::DoNotSend));
    }

    #[test]
    fn retry_delay_doubles_and_is_capped() {
        let mut delay = INITIAL_RETRY_DELAY;
        let mut delays = Vec::new();
        for _ in 0..config::MAX_PUBLISH_ATTEMPTS {
            delays.push(delay);
            delay = next_retry_delay(delay);
        }
        assert_eq!(delays[1], Duration::from_secs(1));
        assert_eq!(delays.iter().max(), Some(&MAX_RETRY_DELAY));
        assert_eq!(next_retry_delay(MAX_RETRY_DELAY), MAX_RETRY_DELAY);
    }
}
