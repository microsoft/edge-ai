use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use crate::types::ModelType;

/// Configuration for the AI inference engine
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceConfig {
    /// Models configuration
    pub models: ModelsConfig,
    /// Performance settings
    pub performance: PerformanceConfig,
    /// GPU/Hardware settings
    pub hardware: HardwareConfig,
    /// Logging and monitoring
    pub monitoring: MonitoringConfig,
    /// Industrial site context
    pub site_context: SiteContext,
}

/// Configuration for AI models
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelsConfig {
    /// Directory containing model files
    pub models_directory: PathBuf,
    /// Default models to load on startup (name -> path mapping)
    pub default_models: Option<HashMap<String, String>>,
    /// Model-specific configurations
    pub model_configs: HashMap<String, ModelParameters>,
    /// Global confidence threshold
    pub global_confidence_threshold: f32,
    /// Maximum predictions per inference
    pub max_predictions_per_model: usize,
}

/// Definition of an AI model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelDefinition {
    /// Unique model identifier
    pub name: String,
    /// Path to ONNX model file (relative to models_directory)
    pub file_path: String,
    /// Type of model
    pub model_type: ModelType,
    /// Model version
    pub version: String,
    /// Whether to load this model on startup
    pub auto_load: bool,
    /// Description for documentation
    pub description: String,
}

/// Model-specific parameters
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelParameters {
    /// Input image size for vision models (width, height)
    pub input_size: Option<(u32, u32)>,
    /// Audio sample rate for audio models
    pub sample_rate: Option<u32>,
    /// Maximum text length for text models
    pub max_text_length: Option<usize>,
    /// Model-specific confidence threshold
    pub confidence_threshold: f32,
    /// Preprocessing parameters
    pub preprocessing: HashMap<String, serde_json::Value>,
    /// Postprocessing parameters
    pub postprocessing: HashMap<String, serde_json::Value>,
}

/// Performance and optimization settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    /// Number of worker threads for inference
    pub num_threads: Option<usize>,
    /// Enable parallel processing of multiple inputs
    pub enable_parallel_processing: bool,
    /// Batch size for processing multiple inputs
    pub batch_size: usize,
    /// Timeout for inference operations (milliseconds)
    pub inference_timeout_ms: u64,
    /// Enable model caching to reduce load times
    pub enable_model_caching: bool,
    /// Memory pool size for efficient allocation
    pub memory_pool_size_mb: Option<u32>,
}

/// Hardware and GPU configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HardwareConfig {
    /// Use GPU acceleration if available
    pub use_gpu: bool,
    /// Preferred GPU device ID (for multi-GPU systems)
    pub gpu_device_id: Option<u32>,
    /// Enable TensorRT optimization
    pub enable_tensorrt: bool,
    /// Enable CUDA optimizations
    pub enable_cuda: bool,
    /// Memory limit for GPU operations (MB)
    pub gpu_memory_limit_mb: Option<u32>,
    /// Fallback to CPU if GPU fails
    pub fallback_to_cpu: bool,
}

/// Monitoring and observability settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonitoringConfig {
    /// Enable performance metrics collection
    pub enable_metrics: bool,
    /// Log level for inference operations
    pub log_level: String,
    /// Enable detailed timing information
    pub enable_timing_metrics: bool,
    /// Enable memory usage tracking
    pub enable_memory_metrics: bool,
    /// Metrics export interval (seconds)
    pub metrics_export_interval_sec: u64,
}

/// Industrial site context for enrichment
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SiteContext {
    /// Site identifier
    pub site_id: String,
    /// Facility name
    pub facility_name: String,
    /// Business unit
    pub business_unit: Option<String>,
    /// Geographic region
    pub region: Option<String>,
    /// Environmental context
    pub environmental_data: HashMap<String, serde_json::Value>,
    /// Equipment mapping for alerts
    pub equipment_mapping: HashMap<String, String>,
}

impl Default for InferenceConfig {
    fn default() -> Self {
        Self {
            models: ModelsConfig::default(),
            performance: PerformanceConfig::default(),
            hardware: HardwareConfig::default(),
            monitoring: MonitoringConfig::default(),
            site_context: SiteContext::default(),
        }
    }
}

impl Default for ModelsConfig {
    fn default() -> Self {
        Self {
            models_directory: PathBuf::from("/models"),
            default_models: Some([
                ("industrial-safety-vision".to_string(), "object-detection/yolov8n-safety.onnx".to_string()),
                ("environmental-anomaly-detection".to_string(), "audio/audio-environmental.onnx".to_string()),
                ("bert-facility-monitoring".to_string(), "text/bert-facility-monitoring.onnx".to_string()),
            ].iter().cloned().collect()),
            model_configs: HashMap::new(),
            global_confidence_threshold: 0.5,
            max_predictions_per_model: 10,
        }
    }
}

impl Default for ModelParameters {
    fn default() -> Self {
        Self {
            input_size: Some((640, 640)),
            sample_rate: Some(16000),
            max_text_length: Some(512),
            confidence_threshold: 0.5,
            preprocessing: HashMap::new(),
            postprocessing: HashMap::new(),
        }
    }
}

impl Default for PerformanceConfig {
    fn default() -> Self {
        Self {
            num_threads: None, // Use system default
            enable_parallel_processing: true,
            batch_size: 1,
            inference_timeout_ms: 5000,
            enable_model_caching: true,
            memory_pool_size_mb: Some(512),
        }
    }
}

impl Default for HardwareConfig {
    fn default() -> Self {
        Self {
            use_gpu: true,
            gpu_device_id: Some(0),
            enable_tensorrt: true,
            enable_cuda: true,
            gpu_memory_limit_mb: Some(2048),
            fallback_to_cpu: true,
        }
    }
}

impl Default for MonitoringConfig {
    fn default() -> Self {
        Self {
            enable_metrics: true,
            log_level: "info".to_string(),
            enable_timing_metrics: true,
            enable_memory_metrics: true,
            metrics_export_interval_sec: 30,
        }
    }
}

impl Default for SiteContext {
    fn default() -> Self {
        Self {
            site_id: "default_site".to_string(),
            facility_name: "pilot_facility".to_string(),
            business_unit: Some("industrial_ai".to_string()),
            region: Some("north_america".to_string()),
            environmental_data: HashMap::new(),
            equipment_mapping: HashMap::new(),
        }
    }
}

impl InferenceConfig {
    /// Load configuration from file
    pub fn from_file<P: AsRef<std::path::Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(path)?;
        let config: InferenceConfig = serde_json::from_str(&content)?;
        Ok(config)
    }

    /// Save configuration to file
    pub fn to_file<P: AsRef<std::path::Path>>(&self, path: P) -> Result<(), Box<dyn std::error::Error>> {
        let content = serde_json::to_string_pretty(self)?;
        std::fs::write(path, content)?;
        Ok(())
    }

    /// Validate configuration
    pub fn validate(&self) -> Result<(), String> {
        // Validate models directory exists
        if !self.models.models_directory.exists() {
            return Err(format!(
                "Models directory does not exist: {:?}",
                self.models.models_directory
            ));
        }

        // Validate model files exist if default_models is provided
        if let Some(default_models) = &self.models.default_models {
            for (model_name, model_path) in default_models {
                let full_model_path = self.models.models_directory.join(model_path);
                if !full_model_path.exists() {
                    return Err(format!(
                        "Model file does not exist: {:?} for model {}",
                        full_model_path, model_name
                    ));
                }
            }
        }

        // Validate confidence thresholds
        if self.models.global_confidence_threshold < 0.0 || self.models.global_confidence_threshold > 1.0 {
            return Err("Global confidence threshold must be between 0.0 and 1.0".to_string());
        }

        Ok(())
    }
}