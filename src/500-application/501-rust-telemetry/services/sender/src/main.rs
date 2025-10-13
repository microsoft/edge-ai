//! # Telemetry Sender Application
//!
//! This application demonstrates how to send telemetry data using Azure IoT Operations MQTT client.
//! It periodically sends JSON telemetry messages with temperature data and timestamps to a specified MQTT topic.
//! The application also includes OpenTelemetry instrumentation for distributed tracing.

mod otel;

// Standard library imports
use std::time::Duration;

// Azure IoT Operations imports
use azure_iot_operations_mqtt::{
    session::{Session, SessionManagedClient, SessionOptionsBuilder},
    MqttConnectionSettingsBuilder,
};
use azure_iot_operations_protocol::{
    application::ApplicationContextBuilder,
    common::payload_serialize::{
        DeserializationError, FormatIndicator, PayloadSerialize, SerializedPayload,
    },
    telemetry,
};

// Third-party imports
use serde_json::Value;
use tokio::time;
use tracing::{info, instrument};

// Local imports
use otel::{inject_current_context, setup_otel_tracing};

// Default configuration values
/// The default MQTT topic where telemetry messages will be published
/// Can be overridden with the TOPIC environment variable
const DEFAULT_TOPIC: &str = "sample/telemetry";

/// The default CloudEvent source URI
/// Can be overridden with the CE_SOURCE environment variable
const DEFAULT_CE_SOURCE: &str = "urn:edge-ai:telemetry:sensor:temperature-001";

/// The default message expiry time in seconds
/// Can be overridden with the MESSAGE_EXPIRY_SECS environment variable
const DEFAULT_MESSAGE_EXPIRY_SECS: u64 = 30;

/// Entry point for the telemetry sender application.
///
/// This function:
/// 1. Sets up OpenTelemetry tracing
/// 2. Configures MQTT connection settings from environment variables
/// 3. Creates an IoT Operations telemetry sender
/// 4. Runs the main telemetry loop in parallel with the MQTT session
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize OpenTelemetry tracing with the service name
    setup_otel_tracing("sender.sample");

    info!("Starting IoT Edge telemetry sender");

    // Get topic name from environment variable or use default
    let topic = std::env::var("TOPIC").unwrap_or_else(|_| DEFAULT_TOPIC.to_string());

    // Get message expiry from environment variable or use default
    let message_expiry_secs = std::env::var("MESSAGE_EXPIRY_SECS")
        .ok()
        .and_then(|s| s.parse::<u64>().ok())
        .unwrap_or(DEFAULT_MESSAGE_EXPIRY_SECS);

    info!("Messaging configuration:");
    info!("  - Topic: {}", topic);
    info!("  - Message expiry: {} seconds", message_expiry_secs);

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

    // Create an ApplicationContext
    let application_context = ApplicationContextBuilder::default().build()?;

    // Configure telemetry sender options with the target topic
    let sender_options = telemetry::sender::OptionsBuilder::default()
        .topic_pattern(&topic)
        .build()?;

    // Create a telemetry Sender with the custom Payload type
    let sender: telemetry::Sender<Payload, _> = telemetry::Sender::new(
        application_context,
        session.create_managed_client(),
        sender_options,
    )?;

    // Run the Session and sender in parallel
    // This ensures both tasks run concurrently and we exit if either completes
    tokio::select! {
        r1 = telemetry_loop(&sender) => r1.map_err(|e| e as Box<dyn std::error::Error>)?,
        r2 = session.run() => r2?,
    }

    Ok(())
}

/// Main telemetry loop that runs continuously
///
/// This function:
/// 1. Sends a telemetry message with the current context
/// 2. Simulates temperature changes following a pattern
/// 3. Waits for 5 seconds before sending the next message
/// 4. Repeats indefinitely
///
/// # Arguments
///
/// * `sender` - The telemetry sender instance used to send messages
async fn telemetry_loop(
    sender: &telemetry::Sender<Payload, SessionManagedClient>,
) -> Result<(), Box<dyn std::error::Error>> {
    info!("Starting telemetry sender loop");

    let ce_source = std::env::var("CE_SOURCE").unwrap_or_else(|_| DEFAULT_CE_SOURCE.to_string());
    loop {
        simulate_and_send(sender, &ce_source).await?;

        // Wait before sending the next message (5 second interval)
        time::sleep(Duration::from_secs(5)).await;
    }
}

#[instrument(skip_all)]
async fn simulate_and_send(
    sender: &telemetry::Sender<Payload, SessionManagedClient>,
    source: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    // Simulate temperature change
    let payload = Payload(serde_json::json!({
        "temperature": 100,
    }));
    // Send telemetry message with the new temperature
    send_telemetry(sender, payload, source).await?;
    Ok(())
}

/// Sends a single telemetry message with OpenTelemetry tracing context
///
/// This function:
/// 1. Creates a sample JSON payload with temperature data
/// 2. Creates a CloudEvent with source information
/// 3. Injects the current tracing context for distributed tracing
/// 4. Builds and sends the telemetry message
///
/// The #[instrument] attribute creates a new span for each function call
/// for better observability in traces
///
/// # Arguments
///
/// * `sender` - The telemetry sender instance used to send messages
#[instrument(name = "send", skip_all, fields(otel.kind = "PRODUCER", messaging.system = "mqtt", messaging.operation = "publish"))]
async fn send_telemetry(
    sender: &telemetry::Sender<Payload, SessionManagedClient>,
    payload: Payload,
    source: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    // Get message expiry time from environment variable or use default
    let message_expiry_secs = std::env::var("MESSAGE_EXPIRY_SECS")
        .ok()
        .and_then(|s| s.parse::<u64>().ok())
        .unwrap_or(DEFAULT_MESSAGE_EXPIRY_SECS);

    let cloud_event = telemetry::sender::CloudEventBuilder::default()
        .source(source)
        .time(chrono::Utc::now()) // Add event occurrence time
        .build()?;

    // Inject current OpenTelemetry span context into the message
    // This allows for distributed tracing across services
    let custom_user_data = inject_current_context();

    // Create the message with all required attributes
    let message = telemetry::sender::MessageBuilder::default()
        .custom_user_data(custom_user_data) // Add trace context
        .payload(payload)? // Add the JSON payload
        .message_expiry(Duration::from_secs(message_expiry_secs)) // Message TTL from env or default
        .cloud_event(cloud_event) // Add CloudEvent metadata
        .build()
        .unwrap();

    // Send the message to the configured topic
    sender.send(message).await?;
    info!("Telemetry message sent successfully");

    Ok(())
}

/// Payload wrapper for telemetry data
///
/// This struct wraps a serde_json::Value to allow for flexible JSON payloads.
/// It implements the PayloadSerialize trait required by the IoT Operations SDK
/// to convert between wire format and application data structures.
#[derive(Clone, Debug)]
pub struct Payload(pub Value);

impl PayloadSerialize for Payload {
    type Error = String;

    /// Serializes the payload into the wire format
    ///
    /// This converts our Payload wrapper into a SerializedPayload that contains:
    /// - The JSON payload as a UTF-8 encoded string
    /// - The content type (application/json)
    /// - The format indicator (UTF-8 encoded character data)
    fn serialize(self) -> Result<SerializedPayload, String> {
        match serde_json::to_string(&self.0) {
            Ok(payload) => Ok(SerializedPayload {
                payload: payload.into(),
                content_type: "application/json".to_string(),
                format_indicator: FormatIndicator::Utf8EncodedCharacterData,
            }),
            Err(e) => Err(format!("Failed to serialize sensor data: {}", e)),
        }
    }

    /// Deserializes the payload from the wire format
    ///
    /// This method is not implemented in the sender because it only sends data.
    /// See the receiver application for the implementation.
    fn deserialize(
        _payload: &[u8],
        _content_type: Option<&String>,
        _format_indicator: &FormatIndicator,
    ) -> Result<Payload, DeserializationError<String>> {
        // Not used in the sender application
        unimplemented!()
    }
}
