// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

/// # Telemetry Receiver Application
/// It subscribes to a specified MQTT topic and processes incoming JSON telemetry messages.
/// The application also maintains distributed tracing context from the sender for end-to-end observability.
///
/// Key features:
/// - Subscribes to configurable MQTT topics
/// - Deserializes JSON payloads
/// - Maintains OpenTelemetry trace context across services

mod otel;

// Azure IoT Operations imports
use azure_iot_operations_mqtt::{
    interface::AckToken,
    MqttConnectionSettingsBuilder,
    session::{Session, SessionManagedClient, SessionOptionsBuilder},
};
use azure_iot_operations_protocol::{
    application::ApplicationContextBuilder,
    common::{
        aio_protocol_error::AIOProtocolError,
        payload_serialize::{DeserializationError, FormatIndicator, PayloadSerialize, SerializedPayload},
    },
    telemetry,
};

// Third-party imports
use serde_json::Value;
use tracing::{debug, error, info, instrument, warn};

// Local imports
use otel::{set_cloud_event_attributes, handle_receive_trace, setup_otel_tracing};

/// The default MQTT topic to subscribe to for receiving telemetry messages
/// Can be overridden with the TOPIC environment variable
const DEFAULT_TOPIC: &str = "sample/telemetry";


/// Entry point for the telemetry receiver application
///
/// This function:
/// 1. Sets up OpenTelemetry tracing
/// 2. Configures MQTT connection settings from environment variables
/// 3. Creates an IoT Operations telemetry receiver that subscribes to a topic
/// 4. Runs the main processing loop in parallel with the MQTT session
#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize OpenTelemetry tracing with the service name
    setup_otel_tracing("receiver.sample");

    info!("Starting IoT Edge telemetry receiver");

    // Get topic name from environment variable or use default
    let topic = std::env::var("TOPIC").unwrap_or_else(|_| DEFAULT_TOPIC.to_string());

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
    let exit_handle = session.create_exit_handle();

    // Create an ApplicationContext which provides common functionality
    let application_context = ApplicationContextBuilder::default().build()?;

    // Configure telemetry receiver options with the subscription topic
    // and auto-acknowledgment enabled
    let receiver_options = telemetry::receiver::OptionsBuilder::default()
        .topic_pattern(&topic)
        .auto_ack(true) // Auto-acknowledge messages to keep things simple
        .build()?;

    // Create a telemetry Receiver with our custom Payload type
    let mut receiver: telemetry::Receiver<Payload, _> = telemetry::Receiver::new(
        application_context.clone(),
        session.create_managed_client(),
        receiver_options,
    )?;

    // Run the Session and the processing loop concurrently using tokio::select
    // This ensures both tasks run concurrently and we exit if either completes
    tokio::select! {
        r1 = telemetry_processing_loop(&mut receiver) => r1.map_err(|e| e as Box<dyn std::error::Error>)?,
        r2 = session.run() => r2?,
    }

    info!("Shutting down");
    receiver.shutdown().await?;
    exit_handle.try_exit().await?;
    info!("Shutdown complete");
    Ok(())
}

/// Process a single received telemetry message
///
/// This function:
/// 1. Extracts the message and acknowledgment token from the result
/// 2. Handles the trace context propagation from the sender
/// 3. Logs the received message content
///
/// The #[instrument] attribute creates a new span for each function call
///
/// # Arguments
///
/// * `msg_result` - The result containing the received message and optional acknowledgment token
#[instrument(name = "receive", skip_all, fields(otel.kind = "CLIENT", messaging.system = "mqtt", messaging.operation = "receive"))]
async fn receive(
    msg_result: Result<(telemetry::receiver::Message<Payload>, Option<AckToken>), AIOProtocolError>,
) -> Result<(), Box<dyn std::error::Error>> {
    // Extract message from result, propagating any errors
    let (message, _ack_token) = msg_result?;

    // Extract and continue the trace context from the sender
    // This maintains the distributed trace across services
    handle_receive_trace(&message.custom_user_data);

    info!("Received telemetry message: {:?}", message);

    match telemetry::receiver::CloudEvent::from_telemetry(&message) {
        Ok(cloud_event) => {
            info!("{cloud_event}");
            set_cloud_event_attributes(&cloud_event);
        }
        Err(e) => {
            // If a cloud event is not present, this error is expected
            warn!("Error parsing cloud event: {e}");
        }
    }

    Ok(())
}

/// Main processing loop that continuously receives and processes telemetry messages
///
/// This function:
/// 1. Waits for incoming messages on the subscribed topic
/// 2. Processes each received message
/// 3. Continues until no more messages are available or an error occurs
///
/// # Arguments
///
/// * `receiver` - The telemetry receiver instance used to receive messages
async fn telemetry_processing_loop(
    receiver: &mut telemetry::Receiver<Payload, SessionManagedClient>,
) -> Result<(), Box<dyn std::error::Error>> {
    info!("Telemetry processing loop started");

    // Continue processing messages until the receiver is closed
    while let Some(msg_result) = receiver.recv().await {
        if let Err(e) = receive(msg_result).await {
            error!("Error processing telemetry message: {:?}", e);
            // Continue processing subsequent messages on error
        }
    }

    // Clean shutdown when the loop exits
    info!("Shutting down telemetry processor");
    receiver.shutdown().await?;

    Ok(())
}



/// Payload wrapper for telemetry data
///
/// This struct wraps a serde_json::Value to allow for flexible JSON payloads.
/// It implements the PayloadSerialize trait required by the IoT Operations SDK
/// to convert between wire format and application data structures.
#[derive(Clone, Debug)]
pub struct Payload(pub Value);


// Implement serialization/deserialization for the original telemetry message
impl PayloadSerialize for Payload {
    type Error = String;

    /// Serializes the payload into the wire format
    ///
    /// This method is not implemented in the receiver because it only receives data.
    /// See the sender application for the implementation.
    fn serialize(self) -> Result<SerializedPayload, String> {
        // Not used in this example, see sender application for implementation
        unimplemented!()
    }

    /// Deserializes the payload from the wire format
    ///
    /// This function:
    /// 1. Verifies the content type is application/json
    /// 2. Converts the payload bytes to a UTF-8 string
    /// 3. Parses the string as JSON
    ///
    /// # Arguments
    ///
    /// * `payload` - The raw payload bytes received from the wire
    /// * `content_type` - The content type header, if present
    /// * `_format_indicator` - The format indicator from the message
    ///
    /// # Returns
    ///
    /// A Result containing either the parsed Payload or a DeserializationError
    fn deserialize(
        payload: &[u8],
        content_type: Option<&String>,
        _format_indicator: &FormatIndicator,
    ) -> Result<Payload, DeserializationError<String>> {
        // Verify content type is application/json if provided
        if let Some(content_type) = content_type {
            if content_type != "application/json" {
                return Err(DeserializationError::UnsupportedContentType(format!(
                    "Invalid content type: '{content_type:?}'. Must be 'application/json'"
                )));
            }
        }

        // Convert payload bytes to UTF-8 string
        let payload_str = match String::from_utf8(payload.to_vec()) {
            Ok(p) => p,
            Err(e) => {
                return Err(DeserializationError::InvalidPayload(format!(
                    "Error while deserializing telemetry: {e}"
                )));
            }
        };

        // Parse the string as JSON
        let payload: Value = match serde_json::from_str(&payload_str) {
            Ok(json) => {
                debug!("Payload successfully parsed as JSON: {:?}", json);
                json
            },
            Err(e) => {
                error!("Failed to parse payload as JSON: {:?}", e);
                return Err(DeserializationError::InvalidPayload(format!(
                    "Error while parsing payload as JSON: {e}"
                )));
            }
        };

        // Return the wrapped JSON value
        Ok(Payload(payload))
    }
}

