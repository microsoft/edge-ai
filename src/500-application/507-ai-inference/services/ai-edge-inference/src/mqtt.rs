use std::error::Error;
use std::sync::Arc;
use std::collections::HashMap;
use azure_iot_operations_mqtt::aio::connection_settings::MqttConnectionSettingsBuilder;
use azure_iot_operations_mqtt::control_packet::{
    PublishProperties, QoS, RetainOptions, SubAckReason, SubscribeProperties, TopicFilter,
    TopicName,
};
use azure_iot_operations_mqtt::session::{
    Session, SessionManagedClient, SessionMonitor, SessionOptionsBuilder, SessionPubReceiver,
};
use tokio::time::{timeout, Duration};
use tokio::sync::RwLock;
use tracing::{error, info, debug, warn, instrument};
use serde::{Deserialize, Serialize};
use base64::Engine;
use crate::config::MqttConfig;
use ai_edge_inference_crate::{InferenceEngine, InferenceInput, InferenceResult, InferenceRequest, ImageMetadata, SensorMetadata};
use anyhow::Result;


/// MQTT publisher for AI Edge Inference service - using Azure IoT Operations SDK pattern
pub struct MqttPublisher {
    client: SessionManagedClient,
    monitor: SessionMonitor,
    session: Option<Session>,
    config: MqttConfig,
    inference_engine: Arc<InferenceEngine>,
    stats: Arc<RwLock<MqttStats>>,
    topic_router: Option<Arc<crate::topic_router::TopicRouter>>,
}

/// Processing context for handling MQTT messages in parallel tasks
#[derive(Clone)]
pub struct MqttProcessingContext {
    pub inference_engine: Arc<InferenceEngine>,
    pub stats: Arc<RwLock<MqttStats>>,
    pub topic_router: Option<Arc<crate::topic_router::TopicRouter>>,
    pub config: MqttConfig,
    pub client: SessionManagedClient,
    pub monitor: SessionMonitor,
}

/// MQTT publishing statistics
#[derive(Debug, Clone, Default, Serialize)]
pub struct MqttStats {
    pub successful_publishes: u64,
    pub failed_publishes: u64,
    pub total_messages: u64,
    pub connection_errors: u64,
    pub last_publish_time: Option<chrono::DateTime<chrono::Utc>>,
    pub is_connected: bool,
}

/// Incoming message types from MQTT broker
#[derive(Debug, Deserialize)]
#[serde(tag = "message_type")]
pub enum IncomingMessage {
    #[serde(rename = "image_snapshot")]
    ImageSnapshot {
        camera_id: String,
        timestamp: i64,
        image_data: String, // Base64 encoded image
        device_name: String,
        location: Option<(f64, f64)>,
        // Optional in the image_snapshot v1 schema; producers omit it when empty.
        #[allow(dead_code)]
        #[serde(default)]
        metadata: serde_json::Value,
    },
    #[serde(rename = "sensor_data")]
    SensorData {
        sensor_id: String,
        sensor_type: String,
        values: Vec<f32>,
        timestamps: Vec<i64>,
        unit: String,
        device_name: String,
        #[allow(dead_code)]
        metadata: serde_json::Value,
    },
    #[serde(rename = "alert_trigger")]
    AlertTrigger {
        trigger_id: String,
        camera_id: Option<String>,
        sensor_id: Option<String>,
        timestamp: i64,
        priority: String,
        #[allow(dead_code)]
        metadata: serde_json::Value,
    },
    #[serde(rename = "model_command")]
    ModelCommand {
        command: ModelCommandType,
        model_name: String,
        parameters: serde_json::Value,
    },
}

/// Model management command types
#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ModelCommandType {
    Load,
    Unload,
    Reload,
    SetConfidence,
    GetStatus,
}

/// Output message for inference results
#[derive(Debug, Serialize)]
pub struct InferenceResultMessage {
    pub message_type: String,
    pub timestamp: i64,
    pub source_device: String,
    pub inference_result: InferenceResult,
    pub enrichment: EnrichmentData,
}

/// Additional enrichment data for downstream processing
#[derive(Debug, Serialize)]
pub struct EnrichmentData {
    pub site: String,
    pub facility: String,
    pub region: String,
    pub business_unit: String,
    pub alert_level: AlertLevel,
    pub recommended_actions: Vec<String>,
}

/// Alert severity levels
#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum AlertLevel {
    Low,
    Medium,
    High,
    Critical,
}

impl MqttPublisher {
    /// Create new MQTT publisher with inference engine using Azure IoT Operations SDK
    pub async fn new(config: MqttConfig, inference_engine: Arc<InferenceEngine>) -> anyhow::Result<Self> {
        info!("Initializing MQTT connection using Azure IoT Operations SDK");

        let connection_settings = MqttConnectionSettingsBuilder::from_environment()
            .map_err(|e| anyhow::anyhow!("Failed to build connection settings: {}", e))?
            .build()?;

        let session_options = SessionOptionsBuilder::default()
            .connection_settings(connection_settings)
            .build()?;

        let session = Session::new(session_options)
            .map_err(|e| anyhow::anyhow!("Failed to create session: {}", e))?;

        let monitor = session.create_session_monitor();
        let client = session.create_managed_client();
        let _exit_handle = session.create_exit_handle();

        info!("Successfully created MQTT session with Azure IoT Operations SDK");

        Ok(Self {
            client,
            monitor,
            session: Some(session),
            config,
            inference_engine,
            stats: Arc::new(RwLock::new(MqttStats::default())),
            topic_router: None,
        })
    }

    /// Set topic router for intelligent topic routing
    pub fn set_topic_router(&mut self, topic_router: Arc<crate::topic_router::TopicRouter>) {
        self.topic_router = Some(topic_router);
    }

    /// Take the MQTT session for running its event loop concurrently
    pub fn take_session(&mut self) -> Option<Session> {
        self.session.take()
    }

    /// Start processing MQTT messages using Azure IoT Operations SDK
    #[instrument(skip(self))]
    pub async fn start_processing(&self) -> anyhow::Result<()> {
        info!("Starting MQTT message processing using Azure IoT Operations SDK");

        // Wait for connection with retry mechanism instead of timeout exit
        info!("Waiting for MQTT broker connection...");

        // Spawn connection monitoring task like http-connector
        let monitor_clone = self.monitor.clone();
        tokio::spawn(async move {
            loop {
                info!("Monitoring MQTT broker connection...");
                monitor_clone.connected().await;
                info!("✅ MQTT broker connected successfully");
                monitor_clone.disconnected().await;
                info!("⚠️  MQTT broker disconnected, monitoring for reconnection...");
            }
        });

        // Don't exit on connection timeout - just continue with subscription attempts

        // Update connection status
        {
            let mut stats = self.stats.write().await;
            stats.is_connected = true;
        }

        // Subscribe to every configured input filter, retrying each independently
        let patterns = input_patterns(&self.config.input_topics);
        info!("Attempting subscription to patterns: {}", patterns.join(", "));

        for pattern in &patterns {
            let client_clone = self.client.clone();
            let pattern_for_sub = pattern.clone();
            tokio::spawn(async move {
                let topic_filter = match TopicFilter::new(&pattern_for_sub) {
                    Ok(tf) => tf,
                    Err(e) => {
                        error!("Invalid subscription pattern {}: {}", pattern_for_sub, e);
                        return;
                    }
                };
                loop {
                    let outcome = match client_clone
                        .subscribe(
                            topic_filter.clone(),
                            QoS::AtLeastOnce,
                            false,
                            RetainOptions::default(),
                            SubscribeProperties::default(),
                        )
                        .await
                    {
                        Ok(token) => match token.await {
                            Ok(suback) => match rejected_suback_reasons(&suback.reasons) {
                                None => Ok(()),
                                Some(reasons) => {
                                    Err(format!("broker rejected subscription: {reasons}"))
                                }
                            },
                            Err(e) => Err(format!("SUBACK not received: {e}")),
                        },
                        Err(e) => Err(format!("SUBSCRIBE not issued: {e}")),
                    };
                    match outcome {
                        Ok(()) => {
                            info!("✅ Subscribed to pattern: {}", pattern_for_sub);
                            break;
                        }
                        Err(reason) => {
                            error!(
                                "Subscription to {} failed (retrying in 10s): {}",
                                pattern_for_sub, reason
                            );
                            tokio::time::sleep(Duration::from_secs(10)).await;
                        }
                    }
                }
            });
        }

        // Start message processing using proper Azure IoT Operations SDK receiver
        let context = self.clone_for_processing().await;

        tokio::spawn(async move {
            info!("Starting Azure IoT Operations message processing for patterns: {}", patterns.join(", "));
            if let Err(e) = context.process_aio_messages(&patterns).await {
                error!("❌ Error in AIO message processing: {}", e);
            }
        });

        // Keep the service running with periodic heartbeats
        info!("✅ MQTT message processing active");
        loop {
            tokio::time::sleep(tokio::time::Duration::from_secs(30)).await;
            debug!("MQTT processing heartbeat - subscription active");

            // Update stats to show we're operational
            let mut stats = self.stats.write().await;
            stats.is_connected = true;
        }
    }

    /// Create a processing context for handling messages in parallel tasks
    async fn clone_for_processing(&self) -> MqttProcessingContext {
        MqttProcessingContext {
            inference_engine: Arc::clone(&self.inference_engine),
            stats: Arc::clone(&self.stats),
            topic_router: self.topic_router.clone(),
            config: self.config.clone(),
            client: self.client.clone(),
            monitor: self.monitor.clone(),
        }
    }

    /// Handle image inference using the crate library
    #[allow(dead_code)]
    async fn handle_image_inference(
        &self,
        camera_id: String,
        timestamp: i64,
        image_data: String,
        device_name: String,
        location: Option<(f64, f64)>
    ) -> Result<(), Box<dyn Error>> {
        // Decode base64 image
                let image_bytes = base64::engine::general_purpose::STANDARD.decode(&image_data)?;
        let image = image::load_from_memory(&image_bytes)?;

        let metadata = ImageMetadata {
            width: image.width(),
            height: image.height(),
            channels: 3, // Assume RGB
            format: "RGB".to_string(),
        };

        let _inference_input = InferenceInput::Image {
            data: image,
            metadata,
        };

        // Create inference request
        let mut request_metadata = HashMap::new();
        request_metadata.insert("camera_id".to_string(), serde_json::Value::String(camera_id.clone()));
        request_metadata.insert("timestamp".to_string(), serde_json::Value::Number(timestamp.into()));
        if let Some(loc) = location {
            request_metadata.insert("location".to_string(), serde_json::json!(loc));
        }
        request_metadata.insert("device_name".to_string(), serde_json::Value::String(device_name.clone()));

        let request = InferenceRequest {
            request_id: uuid::Uuid::new_v4().to_string(),
            model_name: None, // Use default model
            input_data: image_data, // Base64 encoded image
            input_type: "image".to_string(),
            metadata: request_metadata,
        };

        // Run inference using the crate
        let result = self.inference_engine.infer(request).await?;

        // Use topic router to determine output topic
        if let Some(topic_router) = &self.topic_router {
            let output_topic = topic_router.route_result(&result);
            self.publish_inference_result(result, &output_topic).await?;
        } else {
            // Fallback to simple topic construction
            let output_topic = format!("{}ai/results/{}", self.config.topic_prefix, camera_id);
            self.publish_inference_result(result, &output_topic).await?;
        }

        Ok(())
    }

    /// Handle sensor inference using the crate library
    #[expect(dead_code)]
    async fn handle_sensor_inference(
        &self,
        sensor_id: String,
        sensor_type: String,
        values: Vec<f32>,
        timestamps: Vec<i64>,
        unit: String,
        device_name: String
    ) -> Result<(), Box<dyn Error>> {
        let metadata = SensorMetadata {
            sensor_type,
            sampling_rate: 1.0, // Default sampling rate
            units: unit,
        };

        // Clone values for serialization since we use them in the request
        let values_for_serialization = values.clone();

        let _inference_input = InferenceInput::TimeSeries {
            values,
            timestamps,
            metadata,
        };

        // Create inference request
        let mut request_metadata = HashMap::new();
        request_metadata.insert("sensor_id".to_string(), serde_json::Value::String(sensor_id.clone()));
        request_metadata.insert("device_name".to_string(), serde_json::Value::String(device_name.clone()));

        let request = InferenceRequest {
            request_id: uuid::Uuid::new_v4().to_string(),
            model_name: None, // Use default model
            input_data: serde_json::to_string(&values_for_serialization)?, // Serialize sensor values
            input_type: "time_series".to_string(),
            metadata: request_metadata,
        };

        // Run inference using the crate
        let result = self.inference_engine.infer(request).await?;

        // Use topic router to determine output topic
        if let Some(topic_router) = &self.topic_router {
            let output_topic = topic_router.route_result(&result);
            self.publish_inference_result(result, &output_topic).await?;
        } else {
            // Fallback to simple topic construction
            let output_topic = format!("{}ai/results/{}", self.config.topic_prefix, sensor_id);
            self.publish_inference_result(result, &output_topic).await?;
        }

        Ok(())
    }

    /// Handle alert triggers
    #[expect(dead_code)]
    async fn handle_alert_trigger(
        &self,
        trigger_id: String,
        camera_id: Option<String>,
        sensor_id: Option<String>,
        timestamp: i64,
        priority: String
    ) -> Result<(), Box<dyn Error>> {
        info!("Processing alert trigger: {} (priority: {})", trigger_id, priority);

        // Create alert message
        let alert_message = serde_json::json!({
            "message_type": "alert_trigger",
            "trigger_id": trigger_id,
            "camera_id": camera_id,
            "sensor_id": sensor_id,
            "timestamp": timestamp,
            "priority": priority,
            "acknowledged": false
        });

        let topic = format!("{}alerts/triggers", self.config.topic_prefix);
        let payload = serde_json::to_string(&alert_message)?;

        self.publish_with_retry(&topic, &payload).await?;
        info!("Published alert trigger to topic: {}", topic);

        Ok(())
    }

    /// Handle model management commands
    #[expect(dead_code)]
    async fn handle_model_command(
        &self,
        command: ModelCommandType,
        model_name: String,
        _parameters: serde_json::Value
    ) -> Result<(), Box<dyn Error>> {
        match command {
            ModelCommandType::Load => {
                info!("Loading model: {}", model_name);
                // Model loading would be handled by the inference engine
                // Implementation depends on the crate's model management capabilities
            }
            ModelCommandType::Unload => {
                info!("Unloading model: {}", model_name);
                // Use inference engine's unload capabilities
            }
            ModelCommandType::GetStatus => {
                info!("Getting model status for: {}", model_name);
                // Publish status response
                let status_message = serde_json::json!({
                    "message_type": "model_status",
                    "model_name": model_name,
                    "status": "loaded", // This would come from the inference engine
                    "timestamp": chrono::Utc::now().to_rfc3339()
                });

                let topic = format!("{}ai/status/models", self.config.topic_prefix);
                let payload = serde_json::to_string(&status_message)?;
                self.publish_with_retry(&topic, &payload).await?;
            }
            _ => {
                warn!("Unhandled command type: {:?}", command);
            }
        }

        Ok(())
    }

    /// Publish inference result to output topic
    async fn publish_inference_result(&self, result: InferenceResult, topic: &str) -> Result<(), Box<dyn Error>> {
        let enrichment = self.create_enrichment_data(&result).await;

        let message = InferenceResultMessage {
            message_type: "ai_inference_result".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            source_device: std::env::var("DEVICE_NAME").unwrap_or_else(|_| "unknown_device".to_string()),
            inference_result: result,
            enrichment,
        };

        let payload = serde_json::to_string(&message)?;

        self.publish_with_retry(topic, &payload).await?;

        info!("Published inference result to topic: {}", topic);

        // Update statistics
        let mut stats = self.stats.write().await;
        stats.successful_publishes += 1;
        stats.last_publish_time = Some(chrono::Utc::now());

        Ok(())
    }

    /// Create enrichment data for results
    async fn create_enrichment_data(&self, result: &InferenceResult) -> EnrichmentData {
        // Determine alert level based on confidence and predictions
        let alert_level = if result.confidence >= 0.9 {
            AlertLevel::Critical
        } else if result.confidence >= 0.7 {
            AlertLevel::High
        } else if result.confidence >= 0.5 {
            AlertLevel::Medium
        } else {
            AlertLevel::Low
        };

        // Generate recommended actions based on alert level
        let recommended_actions = match alert_level {
            AlertLevel::Critical => vec![
                "Immediate manual inspection required".to_string(),
                "Alert operations team".to_string(),
                "Consider shutting down affected equipment".to_string(),
            ],
            AlertLevel::High => vec![
                "Schedule inspection within 1 hour".to_string(),
                "Notify maintenance team".to_string(),
            ],
            AlertLevel::Medium => vec![
                "Schedule inspection within 4 hours".to_string(),
                "Log for trending analysis".to_string(),
            ],
            AlertLevel::Low => vec![
                "Continue monitoring".to_string(),
                "Log for trending analysis".to_string(),
            ],
        };

        EnrichmentData {
            site: std::env::var("SITE").unwrap_or_else(|_| "unknown_site".to_string()),
            facility: std::env::var("FACILITY").unwrap_or_else(|_| "unknown_facility".to_string()),
            region: std::env::var("REGION").unwrap_or_else(|_| "unknown_region".to_string()),
            business_unit: std::env::var("BUSINESS_UNIT").unwrap_or_else(|_| "unknown_bu".to_string()),
            alert_level,
            recommended_actions,
        }
    }

    /// Publish message with retry logic
    async fn publish_with_retry(&self, topic: &str, payload: &str) -> Result<(), Box<dyn Error>> {
        const MAX_RETRIES: usize = 3;
        const RETRY_DELAY: Duration = Duration::from_secs(2);

        let topic_name = TopicName::new(topic)?;

        for attempt in 1..=MAX_RETRIES {
            match timeout(
                Duration::from_secs(10),
                self.client.publish_qos1(
                    topic_name.clone(),
                    false,
                    payload.to_string(),
                    PublishProperties::default(),
                ),
            )
            .await
            {
                Ok(Ok(_)) => {
                    debug!("Successfully published to topic: {} (attempt {})", topic, attempt);
                    return Ok(());
                }
                Ok(Err(e)) => {
                    error!("Publish attempt {} failed: {}", attempt, e);
                }
                Err(_) => {
                    error!("Publish attempt {} timed out", attempt);
                }
            }

            if attempt < MAX_RETRIES {
                tokio::time::sleep(RETRY_DELAY).await;
            }
        }

        Err(Box::new(std::io::Error::other("Failed to publish after all retry attempts")))
    }

    /// Publish inference result to specified topic (public method for external use)
    #[expect(dead_code)]
    pub async fn publish_result(&self, result: InferenceResult, topic: &str) -> Result<(), Box<dyn Error>> {
        let enrichment = self.create_enrichment_data(&result).await;

        let message = InferenceResultMessage {
            message_type: "ai_inference_result".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            source_device: std::env::var("DEVICE_NAME").unwrap_or_else(|_| "file_processor".to_string()),
            inference_result: result,
            enrichment,
        };

        let payload = serde_json::to_string(&message)?;

        self.publish_with_retry(topic, &payload).await?;

        info!("📤 Published inference result to topic: {}", topic);

        Ok(())
    }

    /// Get current MQTT statistics
    #[expect(dead_code)]
    pub async fn get_stats(&self) -> MqttStats {
        self.stats.read().await.clone()
    }

    /// Check if MQTT client is connected
    #[expect(dead_code)]
    pub async fn is_connected(&self) -> bool {
        self.stats.read().await.is_connected
    }

    /// Gracefully disconnect from MQTT broker
    #[expect(dead_code)]
    pub async fn disconnect(&self) -> Result<(), Box<dyn Error>> {
        // Note: AIO MQTT client doesn't have a direct disconnect method
        // We'll use the exit handle to signal shutdown
        info!("Disconnecting from MQTT broker");
        Ok(())
    }

}

/// Implementation for MQTT processing context
#[allow(dead_code)]
impl MqttProcessingContext {
    /// Process messages from a specific topic
    #[instrument(skip(self, receiver))]
    pub async fn process_topic_messages(&self, topic: &str, mut receiver: SessionPubReceiver) -> anyhow::Result<()> {
        info!("Starting message processing for topic: {}", topic);

        loop {
            info!("Calling receiver.recv().await for topic: {}", topic);

            // Try with a timeout to see if recv() is blocking indefinitely
            match tokio::time::timeout(Duration::from_secs(10), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = message.topic_name.to_string();
                    self.process_payload(&topic_str, &message.payload).await;
                }
                Ok(None) => {
                    error!("Receiver returned None for topic: {}", topic);
                    break;
                }
                Err(_) => {
                    // Timeout occurred - continue silently to avoid log spam
                    continue;
                }
            }
        }

        warn!("Message processing stopped for topic: {}", topic);
        Ok(())
    }

    /// Process messages using direct polling approach (bypassing receivers)
    #[instrument(skip(self))]
    /// Process messages using Azure IoT Operations SDK receiver
    pub async fn process_aio_messages(&self, patterns: &[String]) -> anyhow::Result<()> {
        info!("Starting Azure IoT Operations message processing for patterns: {}", patterns.join(", "));

        // Create unfiltered receiver (we'll filter manually)
        let mut receiver = self.client.create_unfiltered_pub_receiver();
        let filters = topic_filters(patterns);

        let mut heartbeat_counter = 0;

        loop {
            heartbeat_counter += 1;

            // Log heartbeat every 60 iterations (about 1 minute at 1 second intervals)
            if heartbeat_counter % 60 == 0 {
                debug!("AIO message processing heartbeat - patterns: {}", patterns.join(", "));
            }

            // Wait for connection if needed
            if heartbeat_counter % 300 == 0 { // Every 5 minutes
                match timeout(Duration::from_secs(5), self.monitor.connected()).await {
                    Ok(_) => debug!("Connection verified"),
                    Err(_) => {
                        warn!("Connection check timed out, but continuing...");
                        continue;
                    }
                }
            }

            // Try to receive message with reasonable timeout
            match timeout(Duration::from_secs(1), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = message.topic_name.to_string();
                    debug!(
                        "AIO message received on topic: {} (payload: {} bytes)",
                        topic_str,
                        message.payload.len()
                    );

                    if matches_any_filter(&message.topic_name, &filters) {
                        self.process_payload(&topic_str, &message.payload).await;
                    } else {
                        debug!("Ignoring message from non-matching topic: {}", topic_str);
                    }
                }
                Ok(None) => {
                    debug!("AIO receiver returned None, continuing...");
                    tokio::time::sleep(Duration::from_millis(500)).await;
                }
                Err(_) => {
                    // Timeout - continue polling
                    tokio::time::sleep(Duration::from_millis(100)).await;
                }
            }
        }
    }




    /// Process messages from filtered receiver (Microsoft examples pattern)
    #[instrument(skip(self, receiver))]
    pub async fn process_filtered_messages(&self, pattern: &str, mut receiver: SessionPubReceiver) -> anyhow::Result<()> {
        info!("Starting filtered message processing for pattern: {}", pattern);

        loop {
            info!("Calling filtered receiver.recv().await for pattern: {}", pattern);

            // Use same timeout approach but with filtered receiver
            match tokio::time::timeout(Duration::from_secs(10), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = message.topic_name.to_string();
                    self.process_payload(&topic_str, &message.payload).await;
                }
                Ok(None) => {
                    error!("Filtered receiver returned None for pattern: {}", pattern);
                    break;
                }
                Err(_) => {
                    // Timeout occurred - continue silently to avoid log spam
                    continue;
                }
            }
        }

        warn!("Filtered message processing stopped for pattern: {}", pattern);
        Ok(())
    }

    /// Process messages from unfiltered receiver (receives all messages)
    #[instrument(skip(self, receiver))]
    pub async fn process_unfiltered_messages(&self, pattern: &str, mut receiver: SessionPubReceiver) -> anyhow::Result<()> {
        info!("Starting unfiltered message processing for pattern: {}", pattern);
        let filters = topic_filters(&[pattern.to_string()]);

        loop {
            info!("Calling unfiltered receiver.recv().await for pattern: {}", pattern);

            // Try with a timeout to see if recv() is blocking indefinitely
            match tokio::time::timeout(Duration::from_secs(10), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = message.topic_name.to_string();

                    if matches_any_filter(&message.topic_name, &filters) {
                        self.process_payload(&topic_str, &message.payload).await;
                    } else {
                        debug!("Ignoring message from non-matching topic: {}", topic_str);
                    }
                }
                Ok(None) => {
                    error!("Unfiltered receiver returned None for pattern: {}", pattern);
                    break;
                }
                Err(_) => {
                    // Timeout occurred - continue silently to avoid log spam
                    continue;
                }
            }
        }

        warn!("Unfiltered message processing stopped for pattern: {}", pattern);
        Ok(())
    }

    /// Handle incoming message and perform inference + publishing
    async fn handle_incoming_message(&self, payload: &str, topic: &str) -> anyhow::Result<()> {
        debug!("Processing message from topic: {} (payload size: {} bytes)", topic, payload.len());

        let json_value: serde_json::Value = match serde_json::from_str(payload) {
            Ok(value) => value,
            Err(_) => {
                warn!(
                    "Dropping payload from topic {} ({} bytes): not valid JSON",
                    topic,
                    payload.len()
                );
                return Ok(());
            }
        };
        check_schema_version(&json_value)
            .map_err(|rejection| anyhow::anyhow!(rejection.as_str()))?;

        match IncomingMessage::deserialize(&json_value) {
            Ok(message) => {
                match message {
                    IncomingMessage::ImageSnapshot { camera_id, timestamp, image_data, device_name, location, .. } => {
                        self.handle_image_inference(camera_id, timestamp, image_data, device_name, location).await?;
                    }
                    IncomingMessage::SensorData { sensor_id, sensor_type, values, timestamps, unit, device_name, .. } => {
                        self.handle_sensor_inference(sensor_id, sensor_type, values, timestamps, unit, device_name).await?;
                    }
                    IncomingMessage::AlertTrigger { trigger_id, camera_id, sensor_id, timestamp, priority, .. } => {
                        self.handle_alert_trigger(trigger_id, camera_id, sensor_id, timestamp, priority).await?;
                    }
                    IncomingMessage::ModelCommand { command, model_name, parameters } => {
                        self.handle_model_command(command, model_name, parameters).await?;
                    }
                }
            }
            Err(_) => {
                debug!(
                    "Payload from topic {} is not a structured message, trying simplified format",
                    topic
                );
                self.handle_simplified_message(&json_value, topic).await?;
            }
        }

        Ok(())
    }

    /// Validates, dispatches, and counts one received payload. Logs only the topic,
    /// the payload length, and bounded reasons, never payload content.
    async fn process_payload(&self, topic: &str, payload: &[u8]) {
        let payload_str = match decode_payload(payload) {
            Ok(payload_str) => payload_str,
            Err(rejection) => {
                warn!(
                    "Dropping payload from topic {} ({} bytes): {}",
                    topic,
                    payload.len(),
                    rejection.as_str()
                );
                let mut stats = self.stats.write().await;
                stats.failed_publishes += 1;
                return;
            }
        };

        info!(
            "Processing message from topic: {} ({} bytes)",
            topic,
            payload.len()
        );
        match self.handle_incoming_message(payload_str, topic).await {
            Ok(_) => {
                debug!("Processed message from topic: {}", topic);
                let mut stats = self.stats.write().await;
                stats.total_messages += 1;
            }
            Err(e) => {
                error!("Failed to process message from topic {}: {}", topic, e);
                let mut stats = self.stats.write().await;
                stats.failed_publishes += 1;
            }
        }
    }

    /// Handle simplified message format (for direct image data or simple payloads)
    async fn handle_simplified_message(
        &self,
        json_value: &serde_json::Value,
        topic: &str,
    ) -> anyhow::Result<()> {
        info!("Processing simplified message from topic: {}", topic);

        if let Some(image_data_str) = json_value.get("image_data").and_then(|v| v.as_str()) {
            info!("Found image_data in simplified message, processing as image inference");

            // Extract basic fields with defaults
            let camera_id = json_value
                .get("camera_id")
                .and_then(|v| v.as_str())
                .unwrap_or("unknown_camera")
                .to_string();

            let device_name = json_value
                .get("device_name")
                .and_then(|v| v.as_str())
                .unwrap_or("unknown_device")
                .to_string();

            let timestamp = json_value
                .get("timestamp")
                .and_then(|v| v.as_i64())
                .unwrap_or_else(|| chrono::Utc::now().timestamp());

            self.handle_image_inference(
                camera_id,
                timestamp,
                image_data_str.to_string(),
                device_name,
                None,
            )
            .await?;
            return Ok(());
        }

        warn!("Unable to process simplified message format for topic: {}", topic);
        Ok(())
    }

    /// Handle image inference (same logic as in MqttPublisher)
    async fn handle_image_inference(
        &self,
        camera_id: String,
        timestamp: i64,
        image_data: String,
        device_name: String,
        _location: Option<(f64, f64)>
    ) -> anyhow::Result<()> {
        info!("Processing image inference for camera: {} from device: {}", camera_id, device_name);

        // Decode base64 image
        let image_bytes = base64::engine::general_purpose::STANDARD.decode(&image_data)?;
        let image = image::load_from_memory(&image_bytes)?;

        let metadata = ImageMetadata {
            width: image.width(),
            height: image.height(),
            channels: 3, // Assume RGB
            format: "RGB".to_string(),
        };

        let _inference_input = InferenceInput::Image {
            data: image,
            metadata,
        };

        // Create inference request
        let request = InferenceRequest {
            request_id: uuid::Uuid::new_v4().to_string(),
            input_data: image_data,
            input_type: "image".to_string(),
            model_name: None, // Use default model
            metadata: {
                let mut map = std::collections::HashMap::new();
                map.insert("camera_id".to_string(), serde_json::Value::String(camera_id.clone()));
                map.insert("device_name".to_string(), serde_json::Value::String(device_name.clone()));
                map.insert("timestamp".to_string(), serde_json::Value::Number(serde_json::Number::from(timestamp)));
                map
            },
        };

        // Run inference
        match self.inference_engine.infer(request).await {
            Ok(result) => {
                info!("Image inference completed successfully for camera: {}", camera_id);
                info!("Inference result: model={}, confidence={:.2}, predictions={}",
                      result.model_name, result.confidence, result.predictions.len());

                // Publish the result back to MQTT
                match self.publish_inference_result(result, &camera_id).await {
                    Ok(_) => {
                        info!("Published inference result for camera: {}", camera_id);
                        let mut stats = self.stats.write().await;
                        stats.successful_publishes += 1;
                        stats.last_publish_time = Some(chrono::Utc::now());
                    }
                    Err(e) => {
                        error!("Failed to publish inference result for camera {}: {}", camera_id, e);
                        let mut stats = self.stats.write().await;
                        stats.failed_publishes += 1;
                    }
                }
            }
            Err(e) => {
                error!("Image inference failed for camera {}: {}", camera_id, e);
                let mut stats = self.stats.write().await;
                stats.failed_publishes += 1;
            }
        }

        Ok(())
    }

    /// Placeholder implementations for other message types
    async fn handle_sensor_inference(&self, _sensor_id: String, _sensor_type: String, _values: Vec<f32>, _timestamps: Vec<i64>, _unit: String, _device_name: String) -> anyhow::Result<()> {
        info!("Sensor inference not yet implemented");
        Ok(())
    }

    async fn handle_alert_trigger(&self, _trigger_id: String, _camera_id: Option<String>, _sensor_id: Option<String>, _timestamp: i64, _priority: String) -> anyhow::Result<()> {
        info!("Alert trigger handling not yet implemented");
        Ok(())
    }

    async fn handle_model_command(&self, _command: ModelCommandType, _model_name: String, _parameters: serde_json::Value) -> anyhow::Result<()> {
        info!("Model command handling not yet implemented");
        Ok(())
    }

    /// Publish inference result to MQTT
    async fn publish_inference_result(&self, result: InferenceResult, camera_id: &str) -> anyhow::Result<()> {
        // Create enrichment data
        let enrichment = self.create_enrichment_data(&result).await;

        // Create result message
        let result_message = InferenceResultMessage {
            message_type: "inference_result".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            source_device: camera_id.to_string(),
            inference_result: result,
            enrichment,
        };

        // Determine output topic
        let output_topic = if let Some(topic_router) = &self.topic_router {
            topic_router.route_result(&result_message.inference_result)
        } else {
            format!("{}ai/results/{}", self.config.topic_prefix, camera_id)
        };

        // Serialize and publish
        let payload = serde_json::to_string(&result_message)?;

        // Publish to MQTT using the client
        info!("Publishing inference result to topic: {} (payload size: {} bytes)", output_topic, payload.len());
        debug!("Inference result payload: {}", payload);

        let output_topic_name = TopicName::new(&output_topic)?;
        match timeout(Duration::from_secs(10),
                     self.client.publish_qos1(output_topic_name, false, payload, PublishProperties::default())).await {
            Ok(Ok(_)) => {
                info!("Successfully published inference result to topic: {}", output_topic);
                Ok(())
            }
            Ok(Err(e)) => {
                error!("Failed to publish to topic {}: {}", output_topic, e);
                Err(anyhow::anyhow!("Publish failed: {}", e))
            }
            Err(_) => {
                error!("Publish to topic {} timed out", output_topic);
                Err(anyhow::anyhow!("Publish operation timed out"))
            }
        }
    }

    /// Create enrichment data for results (same as in MqttPublisher)
    async fn create_enrichment_data(&self, result: &InferenceResult) -> EnrichmentData {
        // Determine alert level based on confidence and predictions
        let alert_level = if result.confidence >= 0.9 {
            AlertLevel::Critical
        } else if result.confidence >= 0.7 {
            AlertLevel::High
        } else if result.confidence >= 0.5 {
            AlertLevel::Medium
        } else {
            AlertLevel::Low
        };

        // Generate recommended actions based on alert level
        let recommended_actions = match alert_level {
            AlertLevel::Critical => vec![
                "Immediate manual inspection required".to_string(),
                "Alert operations team".to_string(),
                "Consider shutting down affected equipment".to_string(),
            ],
            AlertLevel::High => vec![
                "Schedule inspection within 1 hour".to_string(),
                "Notify maintenance team".to_string(),
            ],
            AlertLevel::Medium => vec![
                "Schedule inspection within 4 hours".to_string(),
                "Log for trending analysis".to_string(),
            ],
            AlertLevel::Low => vec![
                "Continue monitoring".to_string(),
                "Log for trending analysis".to_string(),
            ],
        };

        EnrichmentData {
            site: std::env::var("SITE").unwrap_or_else(|_| "unknown_site".to_string()),
            facility: std::env::var("FACILITY").unwrap_or_else(|_| "unknown_facility".to_string()),
            region: std::env::var("REGION").unwrap_or_else(|_| "unknown_region".to_string()),
            business_unit: std::env::var("BUSINESS_UNIT").unwrap_or_else(|_| "unknown_bu".to_string()),
            alert_level,
            recommended_actions,
        }
    }
}

/// Envelope `schema_version` major this consumer accepts.
const SUPPORTED_SCHEMA_MAJOR: &str = "1";

/// Returns the non-empty configured input filters, or the default filters.
fn input_patterns(input_topics: &[String]) -> Vec<String> {
    let patterns = non_empty_topics(input_topics.iter().map(String::as_str));
    if patterns.is_empty() {
        non_empty_topics(crate::config::DEFAULT_INPUT_TOPICS.split(','))
    } else {
        patterns
    }
}

fn non_empty_topics<'a>(topics: impl Iterator<Item = &'a str>) -> Vec<String> {
    topics
        .map(str::trim)
        .filter(|topic| !topic.is_empty())
        .map(str::to_string)
        .collect()
}

/// Parses filters with the SDK, skipping (and logging) invalid ones.
fn topic_filters(patterns: &[String]) -> Vec<TopicFilter> {
    patterns
        .iter()
        .filter_map(|pattern| match TopicFilter::new(pattern) {
            Ok(filter) => Some(filter),
            Err(e) => {
                error!("Invalid topic filter {}: {}", pattern, e);
                None
            }
        })
        .collect()
}

fn matches_any_filter(topic: &TopicName, filters: &[TopicFilter]) -> bool {
    filters
        .iter()
        .any(|filter| topic.matches_topic_filter(filter))
}

/// Returns the non-granted SUBACK reason codes, or `None` when every filter was granted.
fn rejected_suback_reasons(reasons: &[SubAckReason]) -> Option<String> {
    if reasons.is_empty() {
        return Some("no reason codes".to_string());
    }
    let rejected: Vec<String> = reasons
        .iter()
        .filter(|reason| {
            !matches!(
                reason,
                SubAckReason::GrantedQoS0 | SubAckReason::GrantedQoS1 | SubAckReason::GrantedQoS2
            )
        })
        .map(|reason| format!("{reason:?}"))
        .collect();
    if rejected.is_empty() {
        None
    } else {
        Some(rejected.join(", "))
    }
}

/// Bounded reasons a received payload is dropped before inference.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum PayloadRejection {
    NotUtf8,
    UnsupportedSchemaVersion,
}

impl PayloadRejection {
    fn as_str(self) -> &'static str {
        match self {
            Self::NotUtf8 => "payload is not valid UTF-8",
            Self::UnsupportedSchemaVersion => "unsupported schema_version major",
        }
    }
}

fn decode_payload(payload: &[u8]) -> Result<&str, PayloadRejection> {
    std::str::from_utf8(payload).map_err(|_| PayloadRejection::NotUtf8)
}

/// Accepts envelopes without `schema_version` (legacy producers) or with a
/// string whose major component is 1; rejects any other value.
fn check_schema_version(message: &serde_json::Value) -> Result<(), PayloadRejection> {
    match message.get("schema_version") {
        None => Ok(()),
        Some(serde_json::Value::String(version))
            if version.split('.').next() == Some(SUPPORTED_SCHEMA_MAJOR) =>
        {
            Ok(())
        }
        Some(_) => Err(PayloadRejection::UnsupportedSchemaVersion),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn image_snapshot_v1_without_metadata_deserializes() {
        let schema: serde_json::Value = serde_json::from_str(include_str!(
            "../../../resources/schemas/image-snapshot-v1.schema.json"
        ))
        .unwrap();
        let examples = schema["examples"].as_array().unwrap();
        assert!(examples
            .iter()
            .any(|example| example.get("metadata").is_none()));
        // Field order and omissions match snapshot-normalizer-core serialize_envelope output.
        let normalizer_output = r#"{"message_type":"image_snapshot","schema_version":"1.0","camera_id":"camera-01","timestamp":1700000000,"image_data":"/9j/4AAQSkZJRgABAQAAAQABAAD/2Q==","device_name":"device-01","correlation_id":"00000000-0000-4000-8000-000000000001"}"#;

        for payload in examples
            .iter()
            .map(serde_json::Value::to_string)
            .chain([normalizer_output.to_string()])
        {
            match serde_json::from_str::<IncomingMessage>(&payload) {
                Ok(IncomingMessage::ImageSnapshot { camera_id, .. }) => {
                    assert_eq!(camera_id, "camera-01");
                }
                other => panic!("expected image_snapshot, got {other:?}"),
            }
        }
    }

    #[tokio::test]
    async fn test_mqtt_publisher_creation() {
        // This test would require a running MQTT broker and inference engine
        // Placeholder for actual integration tests
    }

    #[test]
    fn test_message_deserialization() {
        let image_message = r#"{
            "message_type": "image_snapshot",
            "camera_id": "cam001",
            "timestamp": 1635724800,
            "image_data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==",
            "device_name": "test_device",
            "location": [37.7749, -122.4194],
            "metadata": {}
        }"#;

        let result: Result<IncomingMessage, _> = serde_json::from_str(image_message);
        assert!(result.is_ok());
    }

    #[test]
    fn input_patterns_keep_every_filter_and_default_when_empty() {
        let configured = vec![
            "edge-ai/+/+/camera/snapshots".to_string(),
            " edge-ai/v1/+/camera/+/snapshots ".to_string(),
            String::new(),
        ];
        assert_eq!(
            input_patterns(&configured),
            vec![
                "edge-ai/+/+/camera/snapshots",
                "edge-ai/v1/+/camera/+/snapshots"
            ]
        );
        assert_eq!(
            input_patterns(&[String::new()]),
            vec![
                "edge-ai/+/+/camera/snapshots",
                "edge-ai/v1/+/camera/+/snapshots"
            ]
        );
    }

    fn matches_defaults(topic: &str) -> bool {
        let filters = topic_filters(&input_patterns(&[]));
        matches_any_filter(&TopicName::new(topic).unwrap(), &filters)
    }

    #[test]
    fn default_filters_match_legacy_and_pinned_v1_snapshot_topics() {
        assert!(matches_defaults("edge-ai/site/gateway/camera/snapshots"));
        assert!(matches_defaults(
            "edge-ai/v1/snapshot-normalizer/camera/camera-01/snapshots"
        ));
        assert!(!matches_defaults(
            "edge-ai/v2/snapshot-normalizer/camera/camera-01/snapshots"
        ));
        assert!(!matches_defaults(
            "edge-ai/v1/snapshot-normalizer/camera-01/camera/snapshots"
        ));
        assert!(!matches_defaults("edge-ai/a/b/c/d/camera/snapshots"));
        assert!(!matches_defaults("edge-ai/site/gateway/camera/results"));
    }

    #[test]
    fn topic_filters_support_trailing_multi_level_wildcard_and_skip_invalid() {
        let filters = topic_filters(&["edge-ai/#".to_string(), "edge-ai/#/a".to_string()]);
        assert_eq!(filters.len(), 1);
        assert!(matches_any_filter(
            &TopicName::new("edge-ai/a/b").unwrap(),
            &filters
        ));
        assert!(matches_any_filter(
            &TopicName::new("edge-ai/a").unwrap(),
            &filters
        ));
        assert!(!matches_any_filter(
            &TopicName::new("other/a").unwrap(),
            &filters
        ));
    }

    #[test]
    fn suback_with_any_failure_reason_is_rejected() {
        assert_eq!(rejected_suback_reasons(&[SubAckReason::GrantedQoS1]), None);
        assert_eq!(
            rejected_suback_reasons(&[SubAckReason::GrantedQoS1, SubAckReason::NotAuthorized]),
            Some("NotAuthorized".to_string())
        );
        assert!(rejected_suback_reasons(&[]).is_some());
    }

    #[test]
    fn non_utf8_payload_straddling_byte_100_is_rejected_without_panicking() {
        let mut payload = vec![b'a'; 99];
        payload.extend_from_slice(&[0xE2, 0x82]);
        payload.extend_from_slice(b"rest");
        // from_utf8_lossy places a 3-byte replacement char across byte 100.
        assert!(!String::from_utf8_lossy(&payload).is_char_boundary(100));
        assert_eq!(decode_payload(&payload), Err(PayloadRejection::NotUtf8));
    }

    #[test]
    fn utf8_payload_with_multibyte_char_at_byte_100_is_accepted() {
        let mut payload = "a".repeat(99);
        payload.push('€');
        assert_eq!(decode_payload(payload.as_bytes()), Ok(payload.as_str()));
    }

    #[test]
    fn schema_version_major_must_be_one_when_present() {
        let check = |value: serde_json::Value| check_schema_version(&value);
        assert_eq!(
            check(serde_json::json!({"message_type": "image_snapshot"})),
            Ok(())
        );
        assert_eq!(check(serde_json::json!({"schema_version": "1.0"})), Ok(()));
        assert_eq!(check(serde_json::json!({"schema_version": "1.7"})), Ok(()));
        assert_eq!(check(serde_json::json!({"schema_version": "1"})), Ok(()));
        for rejected in [
            serde_json::json!({"schema_version": "2.0"}),
            serde_json::json!({"schema_version": "10.0"}),
            serde_json::json!({"schema_version": ""}),
            serde_json::json!({"schema_version": 1}),
            serde_json::json!({"schema_version": null}),
        ] {
            assert_eq!(
                check(rejected),
                Err(PayloadRejection::UnsupportedSchemaVersion)
            );
        }
    }
}
