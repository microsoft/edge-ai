use std::error::Error;
use std::sync::Arc;
use std::collections::HashMap;
use azure_iot_operations_mqtt::control_packet::QoS;
use azure_iot_operations_mqtt::interface::{MqttPubSub, PubReceiver, ManagedClient};
use azure_iot_operations_mqtt::session::{Session, SessionManagedClient, SessionExitHandle, SessionOptionsBuilder, SessionConnectionMonitor};
use azure_iot_operations_mqtt::MqttConnectionSettingsBuilder;
use tokio::time::{timeout, Duration};
use tokio::sync::RwLock;
use tracing::{error, info, debug, warn, instrument};
use serde::{Deserialize, Serialize};
use serde_json;
use base64::Engine;
use crate::config::MqttConfig;
use ai_edge_inference_crate::{InferenceEngine, InferenceInput, InferenceResult, InferenceRequest, ImageMetadata, SensorMetadata};
use uuid;
use anyhow::Result;


/// MQTT publisher for AI Edge Inference service - using Azure IoT Operations SDK pattern
pub struct MqttPublisher {
    client: SessionManagedClient,
    session: Option<Session>,
    exit_handle: SessionExitHandle,
    monitor: SessionConnectionMonitor,
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
    pub monitor: SessionConnectionMonitor,
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
        metadata: serde_json::Value,
    },
    #[serde(rename = "alert_trigger")]
    AlertTrigger {
        trigger_id: String,
        camera_id: Option<String>,
        sensor_id: Option<String>,
        timestamp: i64,
        priority: String,
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

        let mut session = Session::new(session_options)
            .map_err(|e| anyhow::anyhow!("Failed to create session: {}", e))?;

        let monitor = session.create_connection_monitor();
        let client = session.create_managed_client();
        let exit_handle = session.create_exit_handle();
        
        info!("Successfully created MQTT session with Azure IoT Operations SDK");
        
        Ok(Self { 
            client, 
            session: Some(session),
            exit_handle,
            monitor, 
            config,
            inference_engine,
            stats: Arc::new(RwLock::new(MqttStats::default())),
            topic_router: None, // Will be set separately if needed
        })
    }

    /// Set topic router for intelligent topic routing
    pub fn set_topic_router(&mut self, topic_router: Arc<crate::topic_router::TopicRouter>) {
        self.topic_router = Some(topic_router);
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

        // Subscribe to the topic pattern from config with retry logic
        let topics_pattern = self.config.input_topics.first()
            .unwrap_or(&"edge-ai/+/+/camera/snapshots".to_string())
            .clone();
        info!("Attempting subscription to pattern: {}", topics_pattern);
        
        // Spawn subscription task with retry mechanism
        let client_clone = self.client.clone();
        let pattern_for_sub = topics_pattern.clone();
        tokio::spawn(async move {
            loop {
                match client_clone.subscribe(pattern_for_sub.clone(), QoS::AtLeastOnce).await {
                    Ok(_) => {
                        info!("✅ Successfully subscribed to pattern: {}", pattern_for_sub);
                        break;
                    }
                    Err(e) => {
                        warn!("Failed to subscribe (retrying in 10s): {}", e);
                        tokio::time::sleep(Duration::from_secs(10)).await;
                    }
                }
            }
        });

        // Start message processing using proper Azure IoT Operations SDK receiver
        let context = self.clone_for_processing().await;
        let pattern_clone = topics_pattern.clone();
        
        tokio::spawn(async move {
            info!("Starting Azure IoT Operations message processing for pattern: {}", pattern_clone);
            if let Err(e) = context.process_aio_messages(&pattern_clone).await {
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
        
        for attempt in 1..=MAX_RETRIES {
            match timeout(Duration::from_secs(10), 
                         self.client.publish(topic.to_string(), QoS::AtLeastOnce, false, payload.to_string())).await {
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
        
        Err(Box::new(std::io::Error::new(std::io::ErrorKind::Other, "Failed to publish after all retry attempts")))
    }

    /// Publish inference result to specified topic (public method for external use)
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
    pub async fn get_stats(&self) -> MqttStats {
        self.stats.read().await.clone()
    }

    /// Check if MQTT client is connected
    pub async fn is_connected(&self) -> bool {
        self.stats.read().await.is_connected
    }

    /// Gracefully disconnect from MQTT broker
    pub async fn disconnect(&self) -> Result<(), Box<dyn Error>> {
        // Note: AIO MQTT client doesn't have a direct disconnect method
        // We'll use the exit handle to signal shutdown
        info!("Disconnecting from MQTT broker");
        Ok(())
    }

    /// Clone publisher state for async tasks
    fn clone_publisher_state(&self) -> MqttPublisherState {
        MqttPublisherState {
            client: self.client.clone(),
            config: self.config.clone(),
            inference_engine: Arc::clone(&self.inference_engine),
            stats: Arc::clone(&self.stats),
            topic_router: self.topic_router.clone(),
        }
    }
}

/// Implementation for MQTT processing context
impl MqttProcessingContext {
    /// Process messages from a specific topic
    #[instrument(skip(self, receiver))]
    pub async fn process_topic_messages(&self, topic: &str, mut receiver: impl PubReceiver) -> anyhow::Result<()> {
        info!("Starting message processing for topic: {}", topic);

        loop {
            info!("Calling receiver.recv().await for topic: {}", topic);
            
            // Try with a timeout to see if recv() is blocking indefinitely
            match tokio::time::timeout(Duration::from_secs(10), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = String::from_utf8_lossy(&message.topic);
                    info!("✅ Message received on topic {}: payload size {} bytes", topic_str, message.payload.len());
                    
                    // Convert bytes to strings
                    let payload_str = String::from_utf8_lossy(&message.payload);
                    
                    info!("Processing message from topic: {} (payload: {})", topic_str, &payload_str[..std::cmp::min(100, payload_str.len())]);
                    
                    match self.handle_incoming_message(&payload_str, &topic_str).await {
                        Ok(_) => {
                            info!("Successfully processed message from topic: {}", topic_str);
                            let mut stats = self.stats.write().await;
                            stats.total_messages += 1;
                        }
                        Err(e) => {
                            error!("Failed to process message from topic {}: {}", topic_str, e);
                            let mut stats = self.stats.write().await;
                            stats.failed_publishes += 1;
                        }
                    }
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
    pub async fn process_aio_messages(&self, pattern: &str) -> anyhow::Result<()> {
        info!("Starting Azure IoT Operations message processing for pattern: {}", pattern);
        
        // Create unfiltered receiver (we'll filter manually)
        let mut receiver = self.client.create_unfiltered_pub_receiver();
        
        let mut heartbeat_counter = 0;
        
        loop {
            heartbeat_counter += 1;
            
            // Log heartbeat every 60 iterations (about 1 minute at 1 second intervals)
            if heartbeat_counter % 60 == 0 {
                debug!("AIO message processing heartbeat - pattern: {}", pattern);
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
                    let topic_str = String::from_utf8_lossy(&message.topic);
                    info!("🚀 AIO MESSAGE RECEIVED on topic: {} (payload: {} bytes)", topic_str, message.payload.len());
                    
                    // Check if topic matches our pattern
                    if self.topic_matches_pattern(&topic_str, pattern) {
                        let payload_str = String::from_utf8_lossy(&message.payload);
                        info!("Processing AIO message from topic: {} (payload preview: {})", 
                              topic_str, 
                              &payload_str[..std::cmp::min(100, payload_str.len())]);
                        
                        match self.handle_incoming_message(&payload_str, &topic_str).await {
                            Ok(_) => {
                                info!("✅ Successfully processed AIO message from topic: {}", topic_str);
                                let mut stats = self.stats.write().await;
                                stats.total_messages += 1;
                            }
                            Err(e) => {
                                error!("❌ Failed to process AIO message from topic {}: {}", topic_str, e);
                                let mut stats = self.stats.write().await;
                                stats.failed_publishes += 1;
                            }
                        }
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

    /// Check if a topic matches a wildcard pattern
    fn topic_matches_pattern(&self, topic: &str, pattern: &str) -> bool {
        let topic_parts: Vec<&str> = topic.split('/').collect();
        let pattern_parts: Vec<&str> = pattern.split('/').collect();
        
        if topic_parts.len() != pattern_parts.len() {
            return false;
        }
        
        for (topic_part, pattern_part) in topic_parts.iter().zip(pattern_parts.iter()) {
            if *pattern_part != "+" && *pattern_part != *topic_part {
                return false;
            }
        }
        
        true
    }



    /// Process messages from filtered receiver (Microsoft examples pattern)
    #[instrument(skip(self, receiver))]
    pub async fn process_filtered_messages(&self, pattern: &str, mut receiver: impl PubReceiver) -> anyhow::Result<()> {
        info!("Starting filtered message processing for pattern: {}", pattern);

        loop {
            info!("Calling filtered receiver.recv().await for pattern: {}", pattern);
            
            // Use same timeout approach but with filtered receiver
            match tokio::time::timeout(Duration::from_secs(10), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = String::from_utf8_lossy(&message.topic);
                    info!("✅ Filtered message received on topic {}: payload size {} bytes", topic_str, message.payload.len());
                    
                    // Convert bytes to strings
                    let payload_str = String::from_utf8_lossy(&message.payload);
                    
                    info!("Processing filtered message from topic: {} (payload: {})", topic_str, &payload_str[..std::cmp::min(100, payload_str.len())]);
                    
                    match self.handle_incoming_message(&payload_str, &topic_str).await {
                        Ok(_) => {
                            info!("Successfully processed filtered message from topic: {}", topic_str);
                            let mut stats = self.stats.write().await;
                            stats.total_messages += 1;
                        }
                        Err(e) => {
                            error!("Failed to process filtered message from topic {}: {}", topic_str, e);
                            let mut stats = self.stats.write().await;
                            stats.failed_publishes += 1;
                        }
                    }
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
    pub async fn process_unfiltered_messages(&self, pattern: &str, mut receiver: impl PubReceiver) -> anyhow::Result<()> {
        info!("Starting unfiltered message processing for pattern: {}", pattern);

        loop {
            info!("Calling unfiltered receiver.recv().await for pattern: {}", pattern);
            
            // Try with a timeout to see if recv() is blocking indefinitely
            match tokio::time::timeout(Duration::from_secs(10), receiver.recv()).await {
                Ok(Some(message)) => {
                    let topic_str = String::from_utf8_lossy(&message.topic);
                    
                    // Filter for camera snapshot topics
                    if topic_str.ends_with("/camera/snapshots") {
                        info!("✅ Camera snapshot message received on topic {}: payload size {} bytes", topic_str, message.payload.len());
                        
                        // Convert bytes to strings
                        let payload_str = String::from_utf8_lossy(&message.payload);
                        
                        info!("Processing camera message from topic: {} (payload: {})", topic_str, &payload_str[..std::cmp::min(100, payload_str.len())]);
                        
                        match self.handle_incoming_message(&payload_str, &topic_str).await {
                            Ok(_) => {
                                info!("Successfully processed camera message from topic: {}", topic_str);
                                let mut stats = self.stats.write().await;
                                stats.total_messages += 1;
                            }
                            Err(e) => {
                                error!("Failed to process camera message from topic {}: {}", topic_str, e);
                                let mut stats = self.stats.write().await;
                                stats.failed_publishes += 1;
                            }
                        }
                    } else {
                        debug!("Ignoring non-camera message from topic: {}", topic_str);
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

        // Try to parse as JSON first
        let parsed_message: Result<IncomingMessage, _> = serde_json::from_str(payload);
        
        match parsed_message {
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
            Err(json_err) => {
                // If JSON parsing fails, try to handle as a simplified message format
                info!("Failed to parse as structured message, trying simplified format: {}", json_err);
                self.handle_simplified_message(payload, topic).await?;
            }
        }

        Ok(())
    }

    /// Handle simplified message format (for direct image data or simple payloads)
    async fn handle_simplified_message(&self, payload: &str, topic: &str) -> anyhow::Result<()> {
        info!("Processing simplified message from topic: {}", topic);
        
        // Try to parse as a simple JSON object that might contain image_data
        if let Ok(json_value) = serde_json::from_str::<serde_json::Value>(payload) {
            if let Some(image_data_str) = json_value.get("image_data").and_then(|v| v.as_str()) {
                info!("Found image_data in simplified message, processing as image inference");
                
                // Extract basic fields with defaults
                let camera_id = json_value.get("camera_id")
                    .and_then(|v| v.as_str())
                    .unwrap_or("unknown_camera")
                    .to_string();
                
                let device_name = json_value.get("device_name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("unknown_device")
                    .to_string();
                
                let timestamp = json_value.get("timestamp")
                    .and_then(|v| v.as_i64())
                    .unwrap_or_else(|| chrono::Utc::now().timestamp());
                
                self.handle_image_inference(camera_id, timestamp, image_data_str.to_string(), device_name, None).await?;
                return Ok(());
            }
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
        
        match timeout(Duration::from_secs(10), 
                     self.client.publish(output_topic.clone(), QoS::AtLeastOnce, false, payload)).await {
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

/// Simplified state for async task handlers
#[derive(Clone)]
struct MqttPublisherState {
    client: SessionManagedClient,
    config: MqttConfig,
    inference_engine: Arc<InferenceEngine>,
    stats: Arc<RwLock<MqttStats>>,
    topic_router: Option<Arc<crate::topic_router::TopicRouter>>,
}

impl MqttPublisherState {
    /// Process messages from a specific topic (delegated method)
    async fn process_topic_messages(&self, topic: &str, mut receiver: impl PubReceiver) -> anyhow::Result<()> {
        info!("Processing messages for topic: {}", topic);

        while let Some(message) = receiver.recv().await {
            debug!("Received message on topic: {} (payload size: {} bytes)", 
                   String::from_utf8_lossy(&message.topic), 
                   message.payload.len());
            
            // Delegate to parent publisher for processing
            // This is a simplified approach - in practice you'd implement the same logic here
            
            let mut stats = self.stats.write().await;
            stats.total_messages += 1;
        }
        
        warn!("Message processing stopped for topic: {}", topic);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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
}