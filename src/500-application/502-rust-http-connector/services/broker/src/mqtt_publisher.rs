use std::time::Duration;
use azure_iot_operations_mqtt::interface::MqttPubSub;
use azure_iot_operations_mqtt::control_packet::QoS;
use azure_iot_operations_mqtt::session::{SessionConnectionMonitor, SessionManagedClient};
use tokio::time::timeout;
use tracing::{event, Level};
use tokio_retry::{strategy::ExponentialBackoff, Retry};

pub const DEFAULT_MAX_PUBLISH_ATTEMPTS: usize = 5;
pub const DEFAULT_PUBLISH_RETRY_DELAY: u64 = 2; // in seconds
pub const DEFAULT_TIMEOUT: u64 = 10; // in seconds;

/// Publishes MQTT messages with retry logic and error handling using SessionManagedClient.
pub async fn mqtt_publish_message(
    client: SessionManagedClient,
    monitor: SessionConnectionMonitor,
    topic: String,
    payload: String,
) {
    event!(
        Level::INFO,
        "Publishing message into mqtt topic {} with size {} using SessionManagedClient",
        topic,
        payload.len()
    );

    let retry_strategy = ExponentialBackoff::from_millis(DEFAULT_PUBLISH_RETRY_DELAY * 1000)
        .max_delay(Duration::from_secs(DEFAULT_TIMEOUT))
        .take(DEFAULT_MAX_PUBLISH_ATTEMPTS);

    let topic_for_log = topic.clone();

    let publish_result = Retry::spawn(retry_strategy, {
        let topic = topic.clone();
        let payload = payload.clone();
        let client = client.clone();
        let monitor = monitor.clone();
        move || {
            let topic = topic.clone();
            let payload = payload.clone();
            let client = client.clone();
            let monitor = monitor.clone();
            async move {
                event!(Level::INFO, "Checking connection status...");
                match timeout(Duration::from_secs(DEFAULT_TIMEOUT), monitor.connected()).await {
                    Ok(_) => {
                        event!(Level::INFO, "Connected to MQTT broker.");
                        match client.publish(&topic, QoS::AtLeastOnce, false, payload.clone()).await {
                            Ok(comp_token) => match comp_token.await {
                                Ok(_) => {
                                    event!(
                                        Level::INFO,
                                        "Successfully published message into mqtt topic {} using SessionManagedClient",
                                        topic
                                    );
                                    Ok(())
                                }
                                Err(e) => {
                                    event!(
                                        Level::ERROR,
                                        error_code = "MQTT_PUBLISH_ERROR",
                                        "Failed to complete publishing message into mqtt topic {} using SessionManagedClient: {:?}", topic, e
                                    );
                                    Err(())
                                }
                            },
                            Err(e) => {
                                event!(
                                    Level::ERROR,
                                    error_code = "MQTT_PUBLISH_ERROR",
                                    "Failed to publish message into mqtt topic {} using SessionManagedClient: {:?}", topic, e
                                );
                                Err(())
                            }
                        }
                    }
                    Err(e) => {
                        event!(
                            Level::ERROR,
                            error_code = "MQTT_CONNECTION_TIMEOUT",
                            "Failed to connect to MQTT broker within timeout period using SessionManagedClient: {:?}", e
                        );
                        Err(())
                    }
                }
            }
        }
    })
    .await;

    if publish_result.is_err() {
        event!(
            Level::ERROR,
            error_code = "MQTT_PUBLISH_ERROR",
            "Exceeded maximum retry attempts for publishing message into mqtt topic {} using SessionManagedClient",
            topic_for_log
        );
    }

    event!(Level::INFO, "Disconnected from MQTT broker using SessionManagedClient.");
}
