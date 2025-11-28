use std::{fmt::Write, sync::Arc, time::Duration};

use anyhow::{anyhow, Context, Result};
use azure_iot_operations_mqtt::{
    control_packet::{Publish, QoS},
    interface::{AckToken, ManagedClient, MqttPubSub, PubReceiver},
    session::{Session, SessionManagedClient, SessionOptionsBuilder},
    MqttConnectionSettingsBuilder,
};
use opentelemetry::{
    trace::{Span, Status, Tracer},
    KeyValue,
};
use sha2::{Digest, Sha256};
use tokio::signal;
use tracing::{error, info, info_span, warn};

use crate::{
    config::{AppConfig, MqttConfig},
    correlation::correlation_id_from_payload,
    telemetry,
};

const HEARTBEAT_PAYLOAD: &[u8] = b"alive";

pub async fn run(config: AppConfig) -> Result<()> {
    let shared_config = Arc::new(config);
    let session = Session::new(build_session_options(&shared_config.mqtt)?)
        .map_err(|err| anyhow!("failed to create MQTT session: {err}"))?;

    let managed_client = session.create_managed_client();

    let subscriber_config = shared_config.clone();
    let subscriber_client = managed_client.clone();
    let subscriber_task = tokio::spawn(async move {
        run_subscriptions(subscriber_client, subscriber_config)
            .await
            .context("subscriber task failed")
    });

    let heartbeat_config = shared_config.clone();
    let heartbeat_client = managed_client.clone();
    let heartbeat_task = tokio::spawn(async move {
        run_heartbeat(heartbeat_client, heartbeat_config)
            .await
            .context("heartbeat task failed")
    });

    tokio::select! {
        result = session.run() => result.context("session loop failed")?,
        _ = signal::ctrl_c() => {
            info!("Received Ctrl+C, shutting down MQTT session");
        }
    }

    if let Err(err) = subscriber_task.await.expect("subscriber task panicked") {
        return Err(err);
    }

    if let Err(err) = heartbeat_task.await.expect("heartbeat task panicked") {
        return Err(err);
    }

    Ok(())
}

fn build_session_options(
    config: &MqttConfig,
) -> Result<azure_iot_operations_mqtt::session::SessionOptions> {
    let mut builder = MqttConnectionSettingsBuilder::default();
    builder = builder.client_id(config.client_id.clone());
    builder = builder.hostname(config.broker_host.clone());
    builder = builder.tcp_port(config.broker_port);
    builder = builder.clean_start(false);
    builder = builder.session_expiry(Duration::from_secs(config.session_expiry_secs.into()));
    builder = builder.receive_max(config.receive_max);
    builder = builder.keep_alive(Duration::from_secs(config.keep_alive_secs.into()));
    builder = builder.use_tls(config.use_tls);

    if let Some(ca) = &config.ca_cert_path {
        builder = builder.ca_file(ca.display().to_string());
    }

    if let Some(sat) = &config.sat_token_path {
        builder = builder.sat_file(sat.display().to_string());
    }

    if let (Some(cert), Some(key)) = (&config.x509_cert_path, &config.x509_key_path) {
        builder = builder
            .cert_file(cert.display().to_string())
            .key_file(key.display().to_string());
    }

    let connection_settings = builder
        .build()
        .map_err(|err| anyhow!("failed to build connection settings: {err}"))?;

    SessionOptionsBuilder::default()
        .connection_settings(connection_settings)
        .build()
        .map_err(|err| anyhow!("failed to build session options: {err}"))
}

async fn run_subscriptions(client: SessionManagedClient, config: Arc<AppConfig>) -> Result<()> {
    let mut tasks = Vec::with_capacity(config.mqtt.topic_filters.len());
    for topic in &config.mqtt.topic_filters {
        let topic = topic.clone();
        let client = client.clone();
        let cfg = config.clone();
        tasks.push(tokio::spawn(async move {
            subscribe_topic(client, cfg, topic)
                .await
                .context("subscription task failed")
        }));
    }

    for task in tasks {
        if let Err(err) = task.await.expect("subscription task panicked") {
            return Err(err);
        }
    }

    Ok(())
}

async fn subscribe_topic(
    client: SessionManagedClient,
    config: Arc<AppConfig>,
    topic: String,
) -> Result<()> {
    let subscription = if config.mqtt.shared_subscription_group.trim().is_empty() {
        topic.clone()
    } else {
        format!(
            "$share/{}/{}",
            config.mqtt.shared_subscription_group.trim(),
            topic
        )
    };

    let mut receiver = client
        .create_filtered_pub_receiver(&subscription)
        .map_err(|err| anyhow!("failed to create filtered receiver: {err}"))?;

    client
        .subscribe(subscription.clone(), QoS::AtLeastOnce)
        .await
        .map_err(|err| anyhow!("failed to issue subscribe: {err}"))?
        .await
        .map_err(|err| anyhow!("subscribe acknowledgement failed: {err}"))?;

    info!(filter = %subscription, "Subscribed to MQTT topic");

    while let Some((publish, ack_token)) = receiver.recv_manual_ack().await {
        if let Err(err) = process_publish(&config, publish, ack_token).await {
            error!(target: "mqtt", %subscription, "Failed to process publish: {err:?}");
        }
    }

    Ok(())
}

async fn process_publish(
    config: &AppConfig,
    publish: Publish,
    ack_token: Option<AckToken>,
) -> Result<()> {
    let tracer = telemetry::tracer();
    let mut span = tracer.start("mqtt.receive");

    let topic = String::from_utf8_lossy(publish.topic.as_ref()).to_string();
    let payload_bytes = publish.payload.as_ref();
    let ack_required = ack_token.is_some();

    span.set_attribute(KeyValue::new("messaging.system", "mqtt"));
    span.set_attribute(KeyValue::new("messaging.destination", topic.clone()));
    span.set_attribute(KeyValue::new("messaging.destination_kind", "topic"));
    span.set_attribute(KeyValue::new("messaging.operation", "process"));
    span.set_attribute(KeyValue::new("messaging.mqtt.qos", qos_to_i64(publish.qos)));
    span.set_attribute(KeyValue::new("messaging.mqtt.retain", publish.retain));
    span.set_attribute(KeyValue::new("messaging.mqtt.dup", publish.dup));
    span.set_attribute(KeyValue::new(
        "messaging.message_payload_size_bytes",
        payload_bytes.len() as i64,
    ));
    span.set_attribute(KeyValue::new(
        "messaging.message_payload_sha256",
        payload_digest_hex(payload_bytes),
    ));
    span.set_attribute(KeyValue::new("messaging.ack.required", ack_required));

    let correlation = match correlation_id_from_payload(
        payload_bytes,
        &config.correlation.field_name,
        config.correlation.allow_generated,
    ) {
        Ok(value) => value,
        Err(err) => {
            let message = err.to_string();
            span.record_error(err.as_ref());
            span.set_status(Status::error(message));
            span.end();
            return Err(err);
        }
    };

    span.set_attribute(KeyValue::new("correlation.id", correlation.value.clone()));
    span.set_attribute(KeyValue::new(
        "correlation.generated",
        correlation.is_generated(),
    ));
    if let Some(reason) = correlation.fallback_reason() {
        span.add_event(
            "correlation.generated",
            vec![
                KeyValue::new("reason", reason),
                KeyValue::new("field_name", config.correlation.field_name.clone()),
                KeyValue::new("value", correlation.value.clone()),
            ],
        );
    }

    {
        let log_span = info_span!(
            "mqtt.receive",
            topic = %topic,
            correlation_id = %correlation.value
        );
        let _guard = log_span.enter();
        info!(
            target: "mqtt",
            bytes = payload_bytes.len(),
            ack_required,
            "Processing MQTT publish"
        );
    }

    let acked = match acknowledge_message(ack_token).await {
        Ok(value) => value,
        Err(err) => {
            let message = err.to_string();
            span.record_error(err.as_ref());
            span.set_status(Status::error(message));
            span.end();
            return Err(err);
        }
    };

    span.set_attribute(KeyValue::new("messaging.acknowledged", acked));
    if acked {
        span.add_event("ack", vec![KeyValue::new("status", "success")]);
    }

    info!(
        target: "mqtt",
        topic = %topic,
        acked,
        correlation_id = %correlation.value,
        "Processed MQTT publish"
    );

    span.set_status(Status::Ok);
    span.end();
    Ok(())
}

async fn acknowledge_message(token: Option<AckToken>) -> Result<bool> {
    if let Some(token) = token {
        let completion = token
            .ack()
            .await
            .map_err(|err| anyhow!("failed to send ack: {err}"))?;
        completion
            .await
            .map_err(|err| anyhow!("acknowledgement completion failed: {err}"))?;
        Ok(true)
    } else {
        Ok(false)
    }
}

fn qos_to_i64(qos: QoS) -> i64 {
    match qos {
        QoS::AtMostOnce => 0,
        QoS::AtLeastOnce => 1,
        QoS::ExactlyOnce => 2,
    }
}

fn payload_digest_hex(payload: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(payload);
    let digest = hasher.finalize();

    let mut hex = String::with_capacity(digest.len() * 2);
    for byte in digest {
        write!(&mut hex, "{:02x}", byte).expect("failed to format digest");
    }
    hex
}

async fn run_heartbeat(client: SessionManagedClient, config: Arc<AppConfig>) -> Result<()> {
    let heartbeat_topic = config
        .mqtt
        .topic_filters
        .first()
        .map(|topic| {
            topic
                .trim_end_matches('#')
                .trim_end_matches('/')
                .to_string()
        })
        .filter(|topic| !topic.is_empty())
        .map(|base| format!("{base}/heartbeat"))
        .unwrap_or_else(|| "health/heartbeat".to_string());

    loop {
        match client
            .publish(&heartbeat_topic, QoS::AtLeastOnce, false, HEARTBEAT_PAYLOAD)
            .await
        {
            Ok(token) => {
                if let Err(err) = token.await {
                    warn!(target: "mqtt", topic = %heartbeat_topic, "Heartbeat publish not acknowledged: {err:?}");
                }
            }
            Err(err) => {
                warn!(target: "mqtt", topic = %heartbeat_topic, "Failed to publish heartbeat: {err:?}")
            }
        }

        tokio::time::sleep(Duration::from_secs(config.mqtt.keep_alive_secs.into())).await;
    }
}
