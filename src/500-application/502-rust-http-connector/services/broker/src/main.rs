use azure_iot_operations_mqtt::session::{
    Session, SessionConnectionMonitor, SessionManagedClient, SessionOptionsBuilder,
};
use azure_iot_operations_mqtt::MqttConnectionSettingsBuilder;
use std::str;
use std::time::Duration;

use reqwest::get;
use serde_json::Value;
use std::env;
mod error;
mod error_handler;
mod json_validator;
mod mqtt_publisher;
mod uptime_monitor;
use crate::error::{parse_json_schema, validate_json};
use crate::error_handler::ErrorAlert;
use crate::mqtt_publisher::mqtt_publish_message;
use tokio::time;
use tracing::{event, info, span, Level};
use tracing_subscriber::filter::EnvFilter;
use uptime_monitor::uptime_monitor;

const HTTP_DEVICE_ENDPOINT_VAR: &str = "HTTP_DEVICE_ENDPOINT";
const MQ_DATA_TOPIC_VAR: &str = "MQ_DATA_TOPIC";
const MQ_ERROR_TOPIC_VAR: &str = "MQ_ERROR_TOPIC";
const DEVICE_ID_VAR: &str = "DEVICE_ID";
const POLLING_INTERVAL_VAR: &str = "POLLING_INTERVAL";
const JSON_SCHEMA_VAR: &str = "JSON_SCHEMA";

const ERROR_PARSING_JSON: &str = "002";
const ERROR_GETTING_DATA: &str = "003";
const ERROR_VALIDATING_JSON: &str = "004";

/// Reads sensor data from an HTTP endpoint, validates it against a JSON schema,
/// and publishes the data or error alerts to MQTT topics accordingly.
async fn read_sensor(
    device_url: &str,
    mq_error_topic: &str,
    mq_data_topic: &str,
    json_schema: Value,
    device_id: &str,
    client: SessionManagedClient,
    monitor: SessionConnectionMonitor,
) {
    info!("Reading sensor data");

    // Fetch data from the sensor HTTP endpoint
    info!("Getting data from: {}", device_url);
    match get(device_url).await {
        Ok(resp) => {
            // Extract response body as text
            let mut body = resp
                .text()
                .await
                .unwrap()
                .trim_end_matches('\n')
                .to_string();

            info!("Receiving: {}", &body);

            // Extract content between <html></html> tags if present
            if let Some(start) = body.find("<html>") {
                if let Some(end) = body.find("</html>") {
                    let content_start = start + "<html>".len();
                    let content_end = end;
                    body = body[content_start..content_end].to_string();
                }
            }

            info!("Parsing: {} as json", &body);

            // Parse the extracted content as JSON
            match serde_json::from_str::<Value>(&body) {
                Ok(json) => {
                    info!(
                        "Successfully parsed JSON from sensor, now validating with schema: {:?}",
                        json
                    );
                    // Validate JSON against provided schema
                    match validate_json(json_schema, json, device_id) {
                        Ok(_) => {
                            // Publish validated data to MQTT data topic
                            mqtt_publish_message(
                                client.clone(),
                                monitor.clone(),
                                mq_data_topic.to_string(),
                                body.clone(),
                            )
                            .await;
                        }
                        Err(alert) => {
                            // Publish validation error alert to MQTT error topic
                            event!(
                                Level::ERROR,
                                error_code = ERROR_VALIDATING_JSON,
                                "Generating json schema validation error alert: {}",
                                alert
                            );
                            mqtt_publish_message(
                                client.clone(),
                                monitor.clone(),
                                mq_error_topic.to_string(),
                                alert.clone(),
                            )
                            .await;
                        }
                    }
                }
                Err(err) => {
                    // Handle JSON parsing errors
                    let error_message = format!("Failed to parse JSON from sensor: {:?}", err);
                    let error_alert = ErrorAlert::generate_alert(
                        device_id.to_string(),
                        ERROR_PARSING_JSON.to_string(),
                        error_message.to_string(),
                    );
                    event!(
                        Level::ERROR,
                        error_code = ERROR_PARSING_JSON,
                        "Generating Data Not Available error alert: {}",
                        error_alert
                    );
                    mqtt_publish_message(
                        client.clone(),
                        monitor.clone(),
                        mq_error_topic.to_string(),
                        error_alert.clone(),
                    )
                    .await;
                }
            }
        }
        Err(_) => {
            // Handle HTTP request errors
            let error_message = "Failed to get data from sensor";
            let error_alert = ErrorAlert::generate_alert(
                device_id.to_string(),
                ERROR_GETTING_DATA.to_string(),
                error_message.to_string(),
            );
            event!(
                Level::ERROR,
                error_code = ERROR_GETTING_DATA,
                "Generating Device Not Responding error alert: {}",
                error_alert
            );
            mqtt_publish_message(
                client.clone(),
                monitor.clone(),
                mq_error_topic.to_string(),
                error_alert.clone(),
            )
            .await;
        }
    }
}

/// Main entry point of the application.
/// Initializes configuration, MQTT session, and starts sensor reading loop.
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    info!("Starting up application");

    // Retrieve required environment variables
    let device_url = env::vars()
        .find(|(key, _)| key.starts_with(HTTP_DEVICE_ENDPOINT_VAR))
        .map(|(_, value)| value)
        .expect("No HTTP_DEVICE_ENDPOINT environment variable found");

    let device_id = env::vars()
        .find(|(key, _)| key.starts_with(DEVICE_ID_VAR))
        .map(|(_, value)| value)
        .expect("No DEVICE_ID environment variable found");

    let json_schema = env::vars()
        .find(|(key, _)| key.starts_with(JSON_SCHEMA_VAR))
        .map(|(_, value)| value)
        .expect("No JSON_SCHEMA environment variable found");

    let mq_data_topic = env::vars()
        .find(|(key, _)| key.starts_with(MQ_DATA_TOPIC_VAR))
        .map(|(_, value)| value)
        .expect("No MQ_DATA_TOPIC environment variable found");

    let mq_error_topic =
        env::var(MQ_ERROR_TOPIC_VAR).expect("No MQ_ERROR_TOPIC environment variable found");

    let polling_interval = env::var(POLLING_INTERVAL_VAR)
        .unwrap_or_else(|_| "10".to_string())
        .parse::<u64>()
        .expect("POLLING_INTERVAL must be a valid u64 number");

    info!(
        device_url = %device_url,
        device_id = %device_id,
        mq_data_topic = %mq_data_topic,
        mq_error_topic = %mq_error_topic,
        polling_interval = %polling_interval,
        "Starting HTTP Broker with the following configuration:"
    );

    let mut tasks = Vec::new();
    let device_url_clone = device_url.clone();
    let mq_data_topic_clone = mq_data_topic.clone();
    let device_id_clone = device_id.clone();
    let mq_error_topic_clone = mq_error_topic.clone();

    // Build MQTT connection settings from environment variables
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
    let monitor = session.create_connection_monitor();
    let client = session.create_managed_client();

    // Spawn tasks for sending and receiving messages using managed clients
    tokio::spawn(uptime_monitor(monitor.clone()));

    let json_parsing_span = span!(Level::INFO, "json_schema_parsing");
    let _enter = json_parsing_span.enter();
    match parse_json_schema(&json_schema) {
        Ok(schema) => {
            info!("Successfully parsed JSON schema");
            tasks.push(tokio::spawn(async move {
                info!("Starting sensor reading loop");
                loop {
                    let read_sensor_span = span!(Level::INFO, "read_sensor");
                    let _enter = read_sensor_span.enter();
                    read_sensor(
                        &device_url_clone[..],
                        &mq_error_topic_clone[..],
                        &mq_data_topic_clone[..],
                        schema.clone(),
                        &device_id_clone[..],
                        client.clone(),
                        monitor.clone(),
                    )
                    .await;
                    info!("Sleeping for {} seconds", polling_interval);
                    time::sleep(Duration::from_secs(polling_interval)).await;
                }
            }));
        }
        Err(e) => {
            event!(Level::ERROR, "Failed to parse JSON schema: {}", e);
            drop(_enter);
            return Err(e.into());
        }
    }
    // Run the session. This blocks until the session is exited.
    session.run().await.unwrap();
    futures::future::join_all(tasks).await;
    Ok(())
}
