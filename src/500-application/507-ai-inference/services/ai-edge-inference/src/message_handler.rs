use std::sync::Arc;
use std::collections::HashMap;
use tokio::time::{timeout, Duration};
use tracing::{info, error, warn, debug, instrument};
use serde_json;

use ai_edge_inference_crate::{
    InferenceEngine, InferenceRequest, InferenceResult, InferenceError
};
use crate::topic_router::TopicRouter;
use crate::mqtt::MqttPublisher;

/// Message handler that coordinates AI inference and MQTT publishing
pub struct MessageHandler {
    inference_engine: Arc<InferenceEngine>,
    topic_router: Arc<TopicRouter>,
    mqtt_publisher: Arc<MqttPublisher>,
    request_timeout: Duration,
}

/// Statistics for message handling performance
#[derive(Debug, Clone)]
pub struct MessageStats {
    pub total_requests: u64,
    pub successful_inferences: u64,
    pub failed_inferences: u64,
    pub successful_publishes: u64,
    pub failed_publishes: u64,
    pub average_processing_time_ms: f64,
}

impl MessageHandler {
    /// Create a new message handler
    pub fn new(
        inference_engine: Arc<InferenceEngine>,
        topic_router: Arc<TopicRouter>,
        mqtt_publisher: Arc<MqttPublisher>,
    ) -> Self {
        Self {
            inference_engine,
            topic_router,
            mqtt_publisher,
            request_timeout: Duration::from_secs(30), // 30 second timeout
        }
    }

    /// Process an inference request and publish results to MQTT
    #[instrument(skip(self, request), fields(request_id = %request.request_id, model = %request.model_name))]
    pub async fn process_request(&self, request: InferenceRequest) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let start_time = std::time::Instant::now();
        let request_id = request.request_id.clone();
        
        debug!("Processing inference request: {}", request_id);

        // Step 1: Run AI inference with timeout
        let inference_result = match timeout(self.request_timeout, self.inference_engine.infer(request)).await {
            Ok(Ok(result)) => {
                info!("Inference completed successfully for request: {}", request_id);
                result
            }
            Ok(Err(e)) => {
                error!("Inference failed for request {}: {}", request_id, e);
                
                // Create error result for publishing
                let error_result = self.create_error_result(request_id, e).await;
                self.publish_error_result(error_result).await?;
                
                return Err(format!("Inference failed: {}", e).into());
            }
            Err(_) => {
                error!("Inference timed out for request: {}", request_id);
                
                // Create timeout result for publishing
                let timeout_result = self.create_timeout_result(request_id).await;
                self.publish_error_result(timeout_result).await?;
                
                return Err("Inference timed out".into());
            }
        };

        // Step 2: Route to appropriate MQTT topic
        let topic = self.topic_router.route_result(&inference_result);
        
        // Step 3: Serialize result to JSON
        let json_payload = match serde_json::to_string(&inference_result) {
            Ok(payload) => payload,
            Err(e) => {
                error!("Failed to serialize inference result: {}", e);
                return Err(format!("Serialization failed: {}", e).into());
            }
        };

        // Step 4: Publish to MQTT
        match self.mqtt_publisher.publish(&topic, &json_payload).await {
            Ok(_) => {
                let processing_time = start_time.elapsed();
                info!("Successfully published inference result for request {} to topic {} (processing time: {:?})", 
                    request_id, topic, processing_time);
                
                // Publish processing metrics
                self.publish_metrics(&inference_result, &topic, processing_time.as_millis() as u64).await?;
            }
            Err(e) => {
                error!("Failed to publish inference result for request {}: {}", request_id, e);
                return Err(format!("MQTT publish failed: {}", e).into());
            }
        }

        Ok(())
    }

    /// Process multiple inference requests in batch
    pub async fn process_batch(&self, requests: Vec<InferenceRequest>) -> Vec<Result<(), Box<dyn std::error::Error + Send + Sync>>> {
        info!("Processing batch of {} inference requests", requests.len());
        
        // Process requests in parallel
        let futures = requests.into_iter().map(|req| self.process_request(req));
        futures::future::join_all(futures).await
    }

    /// Handle incoming MQTT message and trigger inference
    #[instrument(skip(self, payload), fields(topic = %topic))]
    pub async fn handle_mqtt_message(&self, topic: &str, payload: &[u8]) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        debug!("Received MQTT message on topic: {}", topic);

        // Parse payload as inference request
        let request: InferenceRequest = match serde_json::from_slice(payload) {
            Ok(req) => req,
            Err(e) => {
                error!("Failed to parse MQTT payload as InferenceRequest: {}", e);
                return Err(format!("Invalid request format: {}", e).into());
            }
        };

        // Process the inference request
        self.process_request(request).await
    }

    /// Create error result for publishing when inference fails
    async fn create_error_result(&self, request_id: String, error: InferenceError) -> InferenceResult {
        InferenceResult {
            request_id,
            model_name: "unknown".to_string(),
            model_type: ai_edge_inference_crate::ModelType::Custom,
            model_version: "unknown".to_string(),
            outputs: vec![],
            confidence_threshold: 0.0,
            processing_time_ms: 0,
            timestamp: chrono::Utc::now(),
            site_context: None,
            metadata: {
                let mut metadata = HashMap::new();
                metadata.insert("error".to_string(), serde_json::Value::String(error.to_string()));
                metadata.insert("error_type".to_string(), serde_json::Value::String(format!("{:?}", error)));
                metadata
            },
        }
    }

    /// Create timeout result for publishing
    async fn create_timeout_result(&self, request_id: String) -> InferenceResult {
        InferenceResult {
            request_id,
            model_name: "unknown".to_string(),
            model_type: ai_edge_inference_crate::ModelType::Custom,
            model_version: "unknown".to_string(),
            outputs: vec![],
            confidence_threshold: 0.0,
            processing_time_ms: 0,
            timestamp: chrono::Utc::now(),
            site_context: None,
            metadata: {
                let mut metadata = HashMap::new();
                metadata.insert("error".to_string(), serde_json::Value::String("Request timed out".to_string()));
                metadata.insert("error_type".to_string(), serde_json::Value::String("Timeout".to_string()));
                metadata
            },
        }
    }

    /// Publish error results to dedicated error topic
    async fn publish_error_result(&self, error_result: InferenceResult) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let error_topic = self.topic_router.route_error("ai-inference", "processing_failed");
        let json_payload = serde_json::to_string(&error_result)?;
        
        self.mqtt_publisher.publish(&error_topic, &json_payload).await?;
        warn!("Published error result to topic: {}", error_topic);
        
        Ok(())
    }

    /// Publish processing metrics
    async fn publish_metrics(&self, result: &InferenceResult, topic: &str, processing_time_ms: u64) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let metrics_topic = self.topic_router.route_metrics("processing");
        
        let metrics = serde_json::json!({
            "request_id": result.request_id,
            "model_name": result.model_name,
            "model_type": format!("{:?}", result.model_type),
            "processing_time_ms": processing_time_ms,
            "inference_time_ms": result.processing_time_ms,
            "prediction_count": result.outputs.iter().map(|o| o.predictions.len()).sum::<usize>(),
            "confidence_max": result.outputs.iter()
                .flat_map(|o| &o.predictions)
                .map(|p| p.confidence)
                .fold(0.0f32, f32::max),
            "published_topic": topic,
            "timestamp": chrono::Utc::now().to_rfc3339(),
        });

        let metrics_payload = serde_json::to_string(&metrics)?;
        self.mqtt_publisher.publish(&metrics_topic, &metrics_payload).await?;
        
        Ok(())
    }

    /// Get current processing statistics
    pub async fn get_stats(&self) -> MessageStats {
        // Get inference engine metrics
        let inference_metrics = self.inference_engine.get_metrics().await;
        
        // Get MQTT publisher stats
        let mqtt_stats = self.mqtt_publisher.get_stats().await;
        
        MessageStats {
            total_requests: inference_metrics.total_inferences,
            successful_inferences: inference_metrics.successful_inferences,
            failed_inferences: inference_metrics.failed_inferences,
            successful_publishes: mqtt_stats.successful_publishes,
            failed_publishes: mqtt_stats.failed_publishes,
            average_processing_time_ms: inference_metrics.average_inference_time_ms,
        }
    }

    /// Set request timeout
    pub fn set_timeout(&mut self, timeout: Duration) {
        self.request_timeout = timeout;
    }

    /// Subscribe to input topics and start processing messages
    pub async fn start_message_processing(&self, input_topics: Vec<String>) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        info!("Starting message processing for topics: {:?}", input_topics);
        
        // Subscribe to input topics and set up message handlers
        for topic in input_topics {
            let handler = Arc::clone(&self);
            let topic_clone = topic.clone();
            
            // Start subscription in background task
            tokio::spawn(async move {
                if let Err(e) = handler.mqtt_publisher.subscribe(&topic_clone, Box::new(move |topic, payload| {
                    let handler = Arc::clone(&handler);
                    let topic = topic.to_string();
                    Box::pin(async move {
                        if let Err(e) = handler.handle_mqtt_message(&topic, payload).await {
                            error!("Failed to handle message from topic {}: {}", topic, e);
                        }
                    })
                })).await {
                    error!("Failed to subscribe to topic {}: {}", topic_clone, e);
                }
            });
        }
        
        Ok(())
    }
}