use azure_iot_operations_mqtt::control_packet::QoS;
use azure_iot_operations_mqtt::interface::{ManagedClient, MqttPubSub, PubReceiver};
use azure_iot_operations_mqtt::session::{
    Session, SessionManagedClient, SessionOptionsBuilder,
};
use azure_iot_operations_mqtt::MqttConnectionSettingsBuilder;
use std::env;
use tokio::task;
use tracing_subscriber::filter::EnvFilter;
use tracing::{info, Level, event};

// Environment variable names for MQTT configuration
const MQ_DATA_TOPIC_VAR: &str = "MQ_DATA_TOPIC";
const MQ_ERROR_TOPIC_VAR: &str = "MQ_ERROR_TOPIC";

/// Main entry point for the IoT Edge temperature subscriber application.
/// Initializes MQTT session and starts receiving messages from the configured topics.
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing subscriber for logging with environment filter
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    info!("Starting IoT Edge temperature subscriber");

    // Build MQTT connection settings from environment variables
    // See https://github.com/Azure/iot-operations-sdks/blob/5b7c965c9b96492447cd0b1e1ef25a26bfe18802/rust/azure_iot_operations_mqtt/src/connection_settings.rs#L92
    // for details on the expected environment variables
    let connection_settings = MqttConnectionSettingsBuilder::from_environment()
        .unwrap()
        .build()
        .unwrap();

    // Create session options with the connection settings
    let session_options = SessionOptionsBuilder::default()
        .connection_settings(connection_settings)
        .build()?;

    // Create a new MQTT session
    let session = Session::new(session_options)?;

    // Create a managed MQTT client from the session
    let client = session.create_managed_client();

    // Spawn tasks for both data and error topic subscribers
    let data_handle = task::spawn(subscribe_and_receive(client.clone(), MQ_DATA_TOPIC_VAR, "data"));
    let error_handle = task::spawn(subscribe_and_receive(client.clone(), MQ_ERROR_TOPIC_VAR, "error"));

    // Run the MQTT session concurrently (this is required for message processing)
    session.run().await.unwrap();

    // Wait for both tasks to finish (they run indefinitely unless an error occurs)
    let _ = tokio::try_join!(data_handle, error_handle);

    info!("Shutdown complete");
    Ok(())
}

/// Subscribes to a topic and continuously receives MQTT messages.
/// - `client`: The managed MQTT client.
/// - `topic_env_var`: The environment variable name for the topic.
/// - `label`: A label for logging (e.g., "data" or "error").
async fn subscribe_and_receive(
    client: SessionManagedClient,
    topic_env_var: &str,
    label: &str,
) {
    // Retrieve the topic name from environment variables
    let topic = match env::var(topic_env_var) {
        Ok(val) => val,
        Err(_) => {
            event!(Level::ERROR, "Environment variable '{}' not found", topic_env_var);
            return;
        }
    };

    info!("Preparing to subscribe to {} topic '{}'", label, topic);

    // Create a filtered receiver for the specified MQTT topic
    let mut receiver = match client.create_filtered_pub_receiver(&topic) {
        Ok(r) => r,
        Err(e) => {
            event!(Level::ERROR, "Failed to create filtered pub receiver for {}: {:?}", label, e);
            return;
        }
    };

    info!("Created filtered receiver for {} topic '{}'", label, topic);

    // Subscribe to the MQTT topic with QoS level AtLeastOnce
    if let Err(e) = client.subscribe(topic.clone(), QoS::AtLeastOnce).await {
        event!(Level::ERROR, "Failed to subscribe to {} topic {}: {:?}", label, topic, e);
        return;
    }

    info!("Successfully subscribed to {} topic '{}'", label, topic);

    // Continuously receive and process incoming MQTT messages
    while let Some(msg) = receiver.recv().await {
        info!(
            "Received message on {} topic '{}', payload size: {}",
            label,
            topic,
            msg.payload.len()
        );
        println!("Received on {}: {:?}", label, msg.payload);
    }
}
