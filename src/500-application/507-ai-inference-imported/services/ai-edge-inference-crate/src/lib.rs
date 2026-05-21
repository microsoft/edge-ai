//! # AI Edge Inference Crate
//! 
//! A high-performance Rust library for running AI inference at the edge using multiple ML backends.
//! Designed for industrial IoT applications with focus on reliability, performance, and 
//! easy integration with messaging systems like MQTT.
//!
//! ## Features
//!
//! - Multiple ML backend support (ONNX Runtime, Hugging Face Candle)
//! - Automatic backend selection with graceful fallback
//! - GPU acceleration support (CUDA, Metal)
//! - Async/await support for non-blocking operations
//! - Comprehensive error handling with recovery suggestions
//! - Structured data types optimized for JSON serialization
//! - Performance metrics and monitoring
//! - Support for multiple model types (Vision, Sensor data)
//! - Industrial site context enrichment
//! - Dynamic model loading/unloading
//! - Batch processing and parallel inference
//! - Configurable preprocessing and postprocessing pipelines
//!
//! ## Example Usage
//!
//! ```rust
//! use ai_edge_inference_crate::{InferenceEngine, InferenceConfig, InferenceRequest, ModelConfig};
//!
//! #[tokio::main]
//! async fn main() -> Result<(), Box<dyn std::error::Error>> {
//!     // Load configuration
//!     let config = InferenceConfig::default();
//!     
//!     // Create and initialize engine (auto-selects best backend)
//!     let mut engine = InferenceEngine::new(config).await?;
//!     engine.initialize().await?;
//!     
//!     // Load a model
//!     let model_config = ModelConfig {
//!         model_path: "/path/to/model.onnx".to_string(),
//!         model_type: "image_classification".to_string(),
//!         confidence_threshold: Some(0.7),
//!         preprocessing: None,
//!         postprocessing: None,
//!     };
//!     engine.load_model("safety-detector", &model_config).await?;
//!     
//!     // Create inference request
//!     let request = InferenceRequest {
//!         request_id: "test-001".to_string(),
//!         model_name: Some("safety-detector".to_string()),
//!         input_data: base64_encoded_image_data,
//!         input_type: "image".to_string(),
//!         metadata: std::collections::HashMap::new(),
//!     };
//!     
//!     // Run inference
//!     let result = engine.infer(request).await?;
//!     
//!     // Serialize result to JSON for MQTT publishing
//!     let json_result = serde_json::to_string(&result)?;
//!     println!("Inference result: {}", json_result);
//!     
//!     Ok(())
//! }
//! ```
//! }
//! ```
//!
//! ## Microservices Architecture
//!
//! This crate is designed to be used in a microservices architecture where:
//! 1. **AI Inference Service**: Uses this crate for pure AI processing
//! 2. **MQTT Publisher Service**: Consumes inference results and publishes to topics
//! 3. **Model Management Service**: Handles model lifecycle and updates
//!
//! The crate produces JSON-serializable results that can be easily published
//! to MQTT topics for consumption by other edge or cloud services.

pub mod types;
pub mod error;
pub mod config;
pub mod models;
pub mod engine;
pub mod backend;
pub mod backends;
pub mod model_config;
pub mod preprocessing;
pub mod postprocessing;

// Re-export main types for easy access
pub use types::{
    InferenceRequest, InferenceResult, MqttInferenceResult, Prediction, ModelType
};
pub use error::InferenceError;
pub use config::{
    InferenceConfig, ModelsConfig, PerformanceConfig, HardwareConfig, 
    MonitoringConfig, SiteContext, ModelDefinition, ModelParameters
};
pub use models::{ModelRegistry, ModelMetadata, LoadedModel};
pub use engine::{InferenceEngine, InferenceMetrics};
pub use model_config::{
    ModelConfiguration, ModelConfigManager, ModelConfigError, 
    ModelMetadata as YamlModelMetadata, ModelSummary
};

// Re-export universal processing types
pub use preprocessing::{
    UniversalImagePreprocessor, PreprocessedImage, PreprocessingError,
    ResizeStrategy, NormalizationConfig, InputFormat
};
pub use postprocessing::{
    UniversalPostprocessor, PostprocessingError, DetectionBox
};

// Re-export backend types
pub use backend::{
    InferenceBackend, BackendFactory, BackendConfig, BackendError, 
    BackendStatus, BackendType, DeviceType
};

// New unified input/output types for backend abstraction
#[derive(Debug, Clone)]
pub enum InferenceInput {
    Image {
        data: image::DynamicImage,
        metadata: ImageMetadata,
    },
    TimeSeries {
        values: Vec<f32>,
        timestamps: Vec<i64>,
        metadata: SensorMetadata,
    },
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ImageMetadata {
    pub width: u32,
    pub height: u32,
    pub channels: u32,
    pub format: String,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SensorMetadata {
    pub sensor_type: String,
    pub sampling_rate: f64,
    pub units: String,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ModelConfig {
    pub model_path: String,
    pub model_type: String,
    pub confidence_threshold: Option<f32>,
    pub preprocessing: Option<serde_json::Value>,
    pub postprocessing: Option<serde_json::Value>,
}

/// Library version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Supported model types for industrial AI applications
pub const SUPPORTED_MODEL_TYPES: &[&str] = &[
    "industrial-safety-vision",
    "environmental-anomaly-detection", 
    "wildlife-detection",
    "facility-operations-monitoring",
    "ppe-compliance-detection",
    "audio-environmental-analysis",
    "bert-facility-monitoring"
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }

    #[test] 
    fn test_supported_models() {
        assert!(!SUPPORTED_MODEL_TYPES.is_empty());
        assert!(SUPPORTED_MODEL_TYPES.contains(&"industrial-safety-vision"));
    }
}