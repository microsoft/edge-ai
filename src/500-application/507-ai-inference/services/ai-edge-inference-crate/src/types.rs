use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::collections::HashMap;

/// Request for AI inference processing
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceRequest {
    /// Unique request identifier
    pub request_id: String,
    /// Model name to use (None for default/auto-select)
    pub model_name: Option<String>,
    /// Input data (base64 encoded for images, JSON for sensors)
    pub input_data: String,
    /// Type of input data (image, sensor, time_series)
    pub input_type: String,
    /// Additional metadata
    pub metadata: HashMap<String, serde_json::Value>,
}

/// Types of AI models supported by the inference engine
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ModelType {
    /// Computer vision models for object detection, classification
    Vision,
    /// Audio analysis models for sound pattern recognition
    Audio, 
    /// Text analysis models including BERT and language understanding
    Text,
    /// Multi-modal models that process multiple input types
    Multimodal,
    /// Custom model type for specialized use cases
    Custom,
}

/// Simplified inference result for backend abstraction
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceResult {
    /// Name of the model used
    pub model_name: String,
    /// Type of model
    pub model_type: String,
    /// Predictions from the model
    pub predictions: Vec<Prediction>,
    /// Overall confidence score
    pub confidence: f32,
    /// Processing time in milliseconds
    pub inference_time_ms: f64,
    /// Additional metadata
    pub metadata: serde_json::Value,
}

/// Main inference result structure sent to MQTT topics (backward compatibility)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MqttInferenceResult {
    /// Type of message for downstream processing
    pub message_type: String,
    /// When the inference was completed
    pub timestamp: DateTime<Utc>,
    /// Source device/camera identifier
    pub source_device: String,
    /// Core AI inference output
    pub inference_result: ModelOutput,
    /// Additional contextual data
    pub enrichment: Option<EnrichmentData>,
}

/// Core model output from ONNX inference
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelOutput {
    /// Name of the model used for inference
    pub model_name: String,
    /// Type of model (vision, audio, text, multi-modal)
    pub model_type: ModelType,
    /// Overall confidence score [0.0, 1.0]
    pub confidence: f32,
    /// Specific predictions from the model
    pub predictions: Vec<Prediction>,
    /// Processing time in milliseconds
    pub processing_time_ms: u64,
    /// Model version for tracking and debugging
    pub model_version: String,
}

/// Individual prediction from AI model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Prediction {
    /// Classification label (e.g., "fire", "person", "equipment_failure")
    pub class: String,
    /// Confidence score for this specific prediction [0.0, 1.0]
    pub confidence: f32,
    /// Bounding box coordinates [x, y, width, height] for vision models
    pub bbox: Option<[f32; 4]>,
    /// Additional metadata specific to prediction type
    pub metadata: HashMap<String, serde_json::Value>,
    /// Severity level for operational prioritization
    pub severity: Option<String>,
}

/// Additional contextual information for industrial operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnrichmentData {
    /// Site identifier (e.g., "houston_lab", "pilot_facility")
    pub site: String,
    /// Facility within the site
    pub facility: String,
    /// Business unit or division
    pub business_unit: Option<String>,
    /// Geographic region
    pub region: Option<String>,
    /// Alert priority level for operations team
    pub alert_level: String,
    /// Recommended actions based on detection
    pub recommended_actions: Vec<String>,
    /// Equipment or asset IDs related to the detection
    pub equipment_ids: Vec<String>,
    /// Environmental context (temperature, weather, etc.)
    pub environmental_context: Option<HashMap<String, serde_json::Value>>,
}

/// Performance and processing metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessingMetrics {
    /// Total processing time from input to output
    pub total_time_ms: u64,
    /// Time spent on preprocessing (image resize, audio filtering, etc.)
    pub preprocessing_time_ms: u64,
    /// Core model inference time
    pub inference_time_ms: u64,
    /// Time spent on postprocessing (NMS, filtering, etc.)
    pub postprocessing_time_ms: u64,
    /// Memory usage during processing
    pub memory_usage_mb: Option<f32>,
    /// GPU utilization percentage during inference
    pub gpu_utilization_percent: Option<f32>,
}

/// Input data types for different processing modes
#[derive(Debug, Clone)]
pub enum InputData {
    /// Raw image bytes (JPEG, PNG, etc.)
    Image(Vec<u8>),
    /// Audio samples as f32 array
    Audio(Vec<f32>),
    /// Text string for NLP processing
    Text(String),
    /// Combined inputs for multi-modal processing
    MultiModal {
        image: Option<Vec<u8>>,
        audio: Option<Vec<f32>>,
        text: Option<String>,
    },
}

/// Configuration for specific model types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelConfig {
    /// Path to the ONNX model file
    pub model_path: String,
    /// Model name for identification
    pub name: String,
    /// Model type classification
    pub model_type: ModelType,
    /// Confidence threshold for filtering predictions
    pub confidence_threshold: f32,
    /// Maximum number of predictions to return
    pub max_predictions: usize,
    /// Model-specific parameters
    pub parameters: HashMap<String, serde_json::Value>,
    /// Whether this model requires GPU acceleration
    pub requires_gpu: bool,
    /// Input image/audio size requirements
    pub input_size: Option<(u32, u32)>,
}

impl Default for InferenceResult {
    fn default() -> Self {
        Self {
            model_name: "unknown".to_string(),
            model_type: "unknown".to_string(),
            predictions: Vec::new(),
            confidence: 0.0,
            inference_time_ms: 0.0,
            metadata: serde_json::json!({}),
        }
    }
}

impl Default for MqttInferenceResult {
    fn default() -> Self {
        Self {
            message_type: "ai_inference_result".to_string(),
            timestamp: Utc::now(),
            source_device: "unknown".to_string(),
            inference_result: ModelOutput::default(),
            enrichment: None,
        }
    }
}

impl Default for ModelOutput {
    fn default() -> Self {
        Self {
            model_name: "unknown".to_string(),
            model_type: ModelType::Vision,
            confidence: 0.0,
            predictions: Vec::new(),
            processing_time_ms: 0,
            model_version: "1.0.0".to_string(),
        }
    }
}

impl Default for Prediction {
    fn default() -> Self {
        Self {
            class: "unknown".to_string(),
            confidence: 0.0,
            bbox: None,
            metadata: HashMap::new(),
            severity: None,
        }
    }
}

impl std::fmt::Display for ModelType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ModelType::Vision => write!(f, "vision"),
            ModelType::Audio => write!(f, "audio"),
            ModelType::Text => write!(f, "text"),
            ModelType::Multimodal => write!(f, "multimodal"),
            ModelType::Custom => write!(f, "custom"),
        }
    }
}