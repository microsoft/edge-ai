use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use ai_edge_inference_crate::InferenceResult;
use tracing::debug;

/// Topic router for intelligent MQTT topic selection based on inference results
pub struct TopicRouter {
    topic_prefix: String,
    custom_routes: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TopicMapping {
    pub base_topic: String,
    pub site_id: Option<String>,
    pub model_type: Option<String>,
    pub model_name: Option<String>,
    pub priority: Option<String>,
}

impl TopicRouter {
    /// Create a new topic router with base prefix
    pub fn new(topic_prefix: String) -> Self {
        Self {
            topic_prefix,
            custom_routes: HashMap::new(),
        }
    }

    /// Add custom routing rule for specific models or scenarios
    pub fn add_custom_route(&mut self, model_name: String, topic_pattern: String) {
        self.custom_routes.insert(model_name, topic_pattern);
    }

    /// Generate MQTT topic for inference result
    pub fn route_result(&self, result: &InferenceResult) -> String {
        // Check for custom routing first
        if let Some(custom_topic) = self.custom_routes.get(&result.model_name) {
            return self.apply_template(custom_topic, result);
        }

        // Generate standard topic based on result context
        let mut topic_parts = Vec::new();
        
        // Add base prefix
        topic_parts.push(self.topic_prefix.trim_end_matches('/').to_string());
        
        // Add inference and model type
        topic_parts.push("inference".to_string());
        topic_parts.push(self.model_type_to_topic(&result.model_type));
        
        // Add model name
        topic_parts.push(result.model_name.replace("-", "_"));
        
        // Add priority based on predictions
        let priority = self.determine_priority(result);
        if !priority.is_empty() {
            topic_parts.push(priority);
        }
        
        let topic = topic_parts.join("/");
        debug!("Generated topic for model {}: {}", result.model_name, topic);
        topic
    }

    /// Generate topic for status/health messages
    pub fn route_status(&self, component: &str, status_type: &str) -> String {
        format!("{}/status/{}/{}", 
            self.topic_prefix.trim_end_matches('/'), 
            component, 
            status_type
        )
    }

    /// Generate topic for metrics
    pub fn route_metrics(&self, metric_type: &str) -> String {
        format!("{}/metrics/{}", 
            self.topic_prefix.trim_end_matches('/'), 
            metric_type
        )
    }

    /// Generate topic for errors
    pub fn route_error(&self, component: &str, error_type: &str) -> String {
        format!("{}/errors/{}/{}", 
            self.topic_prefix.trim_end_matches('/'), 
            component, 
            error_type
        )
    }

    /// Convert model type to topic segment
    fn model_type_to_topic(&self, model_type: &str) -> String {
        model_type.to_lowercase()
    }

    /// Determine priority level based on inference results
    fn determine_priority(&self, result: &InferenceResult) -> String {
        let mut max_confidence = result.confidence;
        let prediction_count = result.predictions.len();
        
        for prediction in &result.predictions {
            if prediction.confidence > max_confidence {
                max_confidence = prediction.confidence;
            }
        }
        
        // Determine priority based on confidence and prediction count
        if max_confidence >= 0.9 && prediction_count > 0 {
            "high".to_string()
        } else if max_confidence >= 0.7 && prediction_count > 0 {
            "medium".to_string()
        } else if prediction_count > 0 {
            "low".to_string()
        } else {
            "".to_string() // No priority for results without predictions
        }
    }

    /// Apply template variables to custom topic patterns
    fn apply_template(&self, template: &str, result: &InferenceResult) -> String {
        let mut topic = template.to_string();
        
        // Replace template variables
        topic = topic.replace("{prefix}", &self.topic_prefix);
        topic = topic.replace("{model_name}", &result.model_name);
        topic = topic.replace("{model_type}", &self.model_type_to_topic(&result.model_type));
        
        // Replace priority
        let priority = self.determine_priority(result);
        topic = topic.replace("{priority}", &priority);
        
        topic
    }

    /// Get topic mapping information for monitoring and debugging
    pub fn get_topic_mapping(&self, result: &InferenceResult) -> TopicMapping {
        let topic = self.route_result(result);
        
        TopicMapping {
            base_topic: topic,
            site_id: None, // Site context not available in InferenceResult
            model_type: Some(self.model_type_to_topic(&result.model_type)),
            model_name: Some(result.model_name.clone()),
            priority: {
                let priority = self.determine_priority(result);
                if priority.is_empty() { None } else { Some(priority) }
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ai_edge_inference_crate::{ModelOutput, Prediction, SiteContext};
    use std::collections::HashMap;

    fn create_test_result() -> InferenceResult {
        InferenceResult {
            request_id: "test-001".to_string(),
            model_name: "industrial-safety-vision".to_string(),
            model_type: ModelType::Vision,
            model_version: "1.0.0".to_string(),
            outputs: vec![
                ModelOutput {
                    output_type: "predictions".to_string(),
                    predictions: vec![
                        Prediction {
                            class_id: 1,
                            class_name: "safety_helmet".to_string(),
                            confidence: 0.95,
                            bounding_box: Some([0.1, 0.1, 0.3, 0.4]),
                            attributes: HashMap::new(),
                        }
                    ],
                    raw_output: None,
                }
            ],
            confidence_threshold: 0.5,
            processing_time_ms: 45,
            timestamp: chrono::Utc::now(),
            site_context: Some(SiteContext {
                site_id: "pilot-facility-001".to_string(),
                facility_name: "Pilot Industrial AI Site".to_string(),
                business_unit: Some("Digital Innovation".to_string()),
                region: Some("North America".to_string()),
                environmental_data: HashMap::new(),
                equipment_mapping: HashMap::new(),
            }),
            metadata: HashMap::new(),
        }
    }

    #[test]
    fn test_basic_topic_routing() {
        let router = TopicRouter::new("edge-ai/downstream/facility_01/gateway_001".to_string());
        let result = create_test_result();
        
        let topic = router.route_result(&result);
        
        assert!(topic.contains("edge-ai/downstream/facility_01/gateway_001"));
        assert!(topic.contains("site/pilot-facility-001"));
        assert!(topic.contains("inference/vision"));
        assert!(topic.contains("industrial_safety_vision"));
        assert!(topic.contains("high")); // High confidence prediction
    }

    #[test]
    fn test_custom_routing() {
        let mut router = TopicRouter::new("edge-ai".to_string());
        router.add_custom_route(
            "industrial-safety-vision".to_string(),
            "{prefix}/safety/{site_id}/alerts/{priority}".to_string()
        );
        
        let result = create_test_result();
        let topic = router.route_result(&result);
        
        assert_eq!(topic, "edge-ai/safety/pilot-facility-001/alerts/high");
    }

    #[test]
    fn test_status_routing() {
        let router = TopicRouter::new("edge-ai/test".to_string());
        
        let status_topic = router.route_status("ai-inference", "health");
        assert_eq!(status_topic, "edge-ai/test/status/ai-inference/health");
        
        let metrics_topic = router.route_metrics("performance");
        assert_eq!(metrics_topic, "edge-ai/test/metrics/performance");
        
        let error_topic = router.route_error("ai-inference", "model_load_failed");
        assert_eq!(error_topic, "edge-ai/test/errors/ai-inference/model_load_failed");
    }
}