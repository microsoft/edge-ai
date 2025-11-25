//! Model configuration management
//! Based on Universal Computer Vision Runtime approach
//!
//! This module provides a YAML-based configuration system that allows
//! operations teams to deploy new models by simply providing a model file
//! and configuration YAML, without code changes.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use thiserror::Error;

/// Errors related to model configuration
#[derive(Error, Debug)]
pub enum ModelConfigError {
    #[error("YAML parsing error: {0}")]
    YamlError(#[from] serde_yaml::Error),
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),
    #[error("Model not found: {0}")]
    ModelNotFound(String),
}

/// Top-level model configuration loaded from YAML
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelConfiguration {
    /// Model metadata
    pub model: ModelMetadata,
    /// Input configuration
    pub input: InputConfiguration,
    /// Output configuration
    pub output: OutputConfiguration,
    /// Optional preprocessing configuration
    pub preprocessing: Option<PreprocessingConfiguration>,
    /// Optional postprocessing configuration
    pub postprocessing: Option<PostprocessingConfiguration>,
    /// Optional model-specific parameters
    pub parameters: Option<HashMap<String, serde_yaml::Value>>,
}

/// Model metadata and identification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelMetadata {
    /// Model name/identifier
    pub name: String,
    /// Model version
    pub version: String,
    /// Model type (e.g., "object_detection", "image_classification")
    pub model_type: String,
    /// Model description
    pub description: String,
    /// Path to the ONNX model file (relative to config file)
    pub path: PathBuf,
    /// Optional model size information
    pub size_mb: Option<f32>,
    /// Supported backends (e.g., ["onnx", "candle"])
    pub backends: Vec<String>,
    /// Model performance characteristics
    pub performance: Option<PerformanceMetrics>,
}

/// Performance metrics for the model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceMetrics {
    /// Average inference time in milliseconds
    pub avg_inference_ms: Option<f32>,
    /// Memory usage in MB
    pub memory_usage_mb: Option<f32>,
    /// Accuracy metrics
    pub accuracy: Option<f32>,
    /// Target hardware (e.g., "cpu", "gpu", "npu")
    pub target_hardware: Option<String>,
}

/// Input configuration for the model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InputConfiguration {
    /// Input tensor shape (e.g., [1, 3, 640, 640])
    pub shape: Vec<i64>,
    /// Data type (e.g., "float32", "uint8")
    pub dtype: String,
    /// Input format (e.g., "NCHW", "NHWC")
    pub format: String,
    /// Value range (e.g., [0.0, 1.0] for normalized, [0, 255] for uint8)
    pub value_range: Vec<f32>,
    /// Color space (e.g., "RGB", "BGR")
    pub color_space: Option<String>,
    /// Expected input type ("image", "tensor", "audio", "text")
    pub input_type: String,
}

/// Output configuration for the model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputConfiguration {
    /// Output tensor specifications
    pub tensors: Vec<OutputTensorSpec>,
    /// Post-processing type (e.g., "yolo", "classification", "detection")
    pub postprocess_type: String,
    /// Confidence threshold for predictions
    pub confidence_threshold: Option<f32>,
    /// NMS threshold for object detection
    pub nms_threshold: Option<f32>,
    /// Maximum number of detections
    pub max_detections: Option<usize>,
    /// Class labels
    pub class_labels: Option<Vec<String>>,
}

/// Specification for an output tensor
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputTensorSpec {
    /// Tensor name
    pub name: String,
    /// Tensor shape (may contain dynamic dimensions as -1)
    pub shape: Vec<i64>,
    /// Data type
    pub dtype: String,
    /// Semantic meaning (e.g., "boxes", "scores", "classes")
    pub semantic: String,
}

/// Preprocessing configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreprocessingConfiguration {
    /// Resize strategy ("letterbox", "crop", "stretch")
    pub resize_strategy: String,
    /// Target size for resize
    pub target_size: Option<[i64; 2]>,
    /// Normalization parameters
    pub normalization: Option<NormalizationConfig>,
    /// Additional preprocessing steps
    pub steps: Option<Vec<PreprocessingStep>>,
}

/// Normalization configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NormalizationConfig {
    /// Mean values for normalization (per channel)
    pub mean: Vec<f32>,
    /// Standard deviation values (per channel)
    pub std: Vec<f32>,
    /// Whether to scale to [0,1] before normalization
    pub scale_to_unit: bool,
}

/// Individual preprocessing step
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreprocessingStep {
    /// Step type (e.g., "crop", "flip", "blur")
    pub step_type: String,
    /// Step parameters
    pub parameters: HashMap<String, serde_yaml::Value>,
}

/// Postprocessing configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PostprocessingConfiguration {
    /// Postprocessing type
    pub postprocess_type: String,
    /// Type-specific parameters
    pub parameters: Option<HashMap<String, serde_yaml::Value>>,
    /// Output format ("detection", "classification", "segmentation")
    pub output_format: String,
}

/// Model configuration manager
pub struct ModelConfigManager {
    /// Base directory for model files
    pub base_dir: PathBuf,
    /// Loaded configurations
    configurations: HashMap<String, ModelConfiguration>,
}

impl ModelConfigManager {
    /// Create a new model configuration manager
    pub fn new(base_dir: PathBuf) -> Self {
        Self {
            base_dir,
            configurations: HashMap::new(),
        }
    }

    /// Load a model configuration from a YAML file
    pub async fn load_config(&mut self, config_path: &str) -> Result<String, ModelConfigError> {
        let full_path = self.base_dir.join(config_path);
        let yaml_content = tokio::fs::read_to_string(&full_path).await?;
        let config: ModelConfiguration = serde_yaml::from_str(&yaml_content)?;

        // Validate the configuration
        self.validate_config(&config)?;

        let model_name = config.model.name.clone();
        self.configurations.insert(model_name.clone(), config);

        Ok(model_name)
    }

    /// Get a loaded configuration by model name
    pub fn get_config(&self, model_name: &str) -> Option<&ModelConfiguration> {
        self.configurations.get(model_name)
    }

    /// List all loaded model names
    pub fn list_models(&self) -> Vec<String> {
        self.configurations.keys().cloned().collect()
    }

    /// Load all YAML configurations from a directory
    pub async fn load_from_directory(&mut self, dir_path: &str) -> Result<Vec<String>, ModelConfigError> {
        let full_dir = self.base_dir.join(dir_path);
        let mut loaded_models = Vec::new();

        let mut entries = tokio::fs::read_dir(full_dir).await?;
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.extension().map_or(false, |ext| ext == "yaml" || ext == "yml") {
                if let Some(relative_path) = path.strip_prefix(&self.base_dir).ok() {
                    match self.load_config(relative_path.to_string_lossy().as_ref()).await {
                        Ok(model_name) => {
                            loaded_models.push(model_name);
                            tracing::info!("Loaded model config: {}", relative_path.display());
                        },
                        Err(e) => {
                            tracing::warn!("Failed to load config {}: {}", relative_path.display(), e);
                        }
                    }
                }
            }
        }

        Ok(loaded_models)
    }

    /// Validate a model configuration
    fn validate_config(&self, config: &ModelConfiguration) -> Result<(), ModelConfigError> {
        // Basic validation
        if config.model.name.is_empty() {
            return Err(ModelConfigError::InvalidConfig("Model name cannot be empty".to_string()));
        }

        if config.model.model_type.is_empty() {
            return Err(ModelConfigError::InvalidConfig("Model type cannot be empty".to_string()));
        }

        if config.input.shape.is_empty() {
            return Err(ModelConfigError::InvalidConfig("Input shape cannot be empty".to_string()));
        }

        if config.output.tensors.is_empty() {
            return Err(ModelConfigError::InvalidConfig("Output tensors cannot be empty".to_string()));
        }

        // Check if model file exists
        let model_path = self.base_dir.join(&config.model.path);
        if !model_path.exists() {
            return Err(ModelConfigError::InvalidConfig(
                format!("Model file not found: {}", model_path.display())
            ));
        }

        Ok(())
    }

    /// Get model configuration as a summary for health endpoints
    pub fn get_model_summary(&self, model_name: &str) -> Option<ModelSummary> {
        self.get_config(model_name).map(|config| ModelSummary {
            name: config.model.name.clone(),
            version: config.model.version.clone(),
            model_type: config.model.model_type.clone(),
            description: config.model.description.clone(),
            input_shape: config.input.shape.clone(),
            output_count: config.output.tensors.len(),
            backends: config.model.backends.clone(),
            performance: config.model.performance.clone(),
        })
    }

    /// Get all model summaries
    pub fn get_all_summaries(&self) -> Vec<ModelSummary> {
        self.configurations.keys()
            .filter_map(|name| self.get_model_summary(name))
            .collect()
    }
}

/// Simplified model summary for API responses
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelSummary {
    pub name: String,
    pub version: String,
    pub model_type: String,
    pub description: String,
    pub input_shape: Vec<i64>,
    pub output_count: usize,
    pub backends: Vec<String>,
    pub performance: Option<PerformanceMetrics>,
}

/// Helper function to create default configurations for common model types
pub mod defaults {
    use super::*;

    /// Create a default YOLOv8n configuration
    pub fn yolov8n_config(model_path: PathBuf) -> ModelConfiguration {
        ModelConfiguration {
            model: ModelMetadata {
                name: "yolov8n".to_string(),
                version: "1.0.0".to_string(),
                model_type: "object_detection".to_string(),
                description: "YOLOv8 Nano object detection model".to_string(),
                path: model_path,
                size_mb: Some(6.2),
                backends: vec!["onnx".to_string(), "candle".to_string()],
                performance: Some(PerformanceMetrics {
                    avg_inference_ms: Some(45.0),
                    memory_usage_mb: Some(30.0),
                    accuracy: Some(0.37),
                    target_hardware: Some("cpu".to_string()),
                }),
            },
            input: InputConfiguration {
                shape: vec![1, 3, 640, 640],
                dtype: "float32".to_string(),
                format: "NCHW".to_string(),
                value_range: vec![0.0, 1.0],
                color_space: Some("RGB".to_string()),
                input_type: "image".to_string(),
            },
            output: OutputConfiguration {
                tensors: vec![OutputTensorSpec {
                    name: "output0".to_string(),
                    shape: vec![1, 84, 8400],
                    dtype: "float32".to_string(),
                    semantic: "detections".to_string(),
                }],
                postprocess_type: "yolov8".to_string(),
                confidence_threshold: Some(0.5),
                nms_threshold: Some(0.4),
                max_detections: Some(100),
                class_labels: Some(vec![
                    "person".to_string(), "bicycle".to_string(), "car".to_string(),
                    "motorcycle".to_string(), "airplane".to_string(), "bus".to_string(),
                    "train".to_string(), "truck".to_string(), "boat".to_string(),
                    "traffic light".to_string(),
                    // Add more COCO classes as needed...
                ]),
            },
            preprocessing: Some(PreprocessingConfiguration {
                resize_strategy: "letterbox".to_string(),
                target_size: Some([640, 640]),
                normalization: Some(NormalizationConfig {
                    mean: vec![0.0, 0.0, 0.0],
                    std: vec![1.0, 1.0, 1.0],
                    scale_to_unit: true,
                }),
                steps: None,
            }),
            postprocessing: Some(PostprocessingConfiguration {
                postprocess_type: "yolov8".to_string(),
                parameters: None,
                output_format: "detection".to_string(),
            }),
            parameters: None,
        }
    }

    /// Create a default MobileNetV2 classification configuration
    pub fn mobilenetv2_config(model_path: PathBuf) -> ModelConfiguration {
        ModelConfiguration {
            model: ModelMetadata {
                name: "mobilenetv2".to_string(),
                version: "1.0.0".to_string(),
                model_type: "image_classification".to_string(),
                description: "MobileNetV2 image classification model".to_string(),
                path: model_path,
                size_mb: Some(9.2),
                backends: vec!["onnx".to_string(), "candle".to_string()],
                performance: Some(PerformanceMetrics {
                    avg_inference_ms: Some(25.0),
                    memory_usage_mb: Some(15.0),
                    accuracy: Some(0.72),
                    target_hardware: Some("cpu".to_string()),
                }),
            },
            input: InputConfiguration {
                shape: vec![1, 3, 224, 224],
                dtype: "float32".to_string(),
                format: "NCHW".to_string(),
                value_range: vec![-1.0, 1.0],
                color_space: Some("RGB".to_string()),
                input_type: "image".to_string(),
            },
            output: OutputConfiguration {
                tensors: vec![OutputTensorSpec {
                    name: "output".to_string(),
                    shape: vec![1, 1000],
                    dtype: "float32".to_string(),
                    semantic: "classification".to_string(),
                }],
                postprocess_type: "classification".to_string(),
                confidence_threshold: Some(0.1),
                nms_threshold: None,
                max_detections: Some(5),
                class_labels: None, // Would load ImageNet labels
            },
            preprocessing: Some(PreprocessingConfiguration {
                resize_strategy: "crop".to_string(),
                target_size: Some([224, 224]),
                normalization: Some(NormalizationConfig {
                    mean: vec![0.485, 0.456, 0.406],
                    std: vec![0.229, 0.224, 0.225],
                    scale_to_unit: true,
                }),
                steps: None,
            }),
            postprocessing: Some(PostprocessingConfiguration {
                postprocess_type: "classification".to_string(),
                parameters: None,
                output_format: "classification".to_string(),
            }),
            parameters: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_model_config_loading() {
        let temp_dir = TempDir::new().unwrap();
        let base_path = temp_dir.path().to_path_buf();

        // Create a sample YAML config
        let config_yaml = r#"
model:
  name: "test-model"
  version: "1.0.0"
  model_type: "object_detection"
  description: "Test model"
  path: "test-model.onnx"
  backends: ["onnx"]

input:
  shape: [1, 3, 640, 640]
  dtype: "float32"
  format: "NCHW"
  value_range: [0.0, 1.0]
  input_type: "image"

output:
  tensors:
    - name: "output0"
      shape: [1, 84, 8400]
      dtype: "float32"
      semantic: "detections"
  postprocess_type: "yolo"
  confidence_threshold: 0.5

preprocessing:
  resize_strategy: "letterbox"
  target_size: [640, 640]

postprocessing:
  postprocess_type: "yolo"
  output_format: "detection"
"#;

        // Create mock model file
        let model_path = base_path.join("test-model.onnx");
        tokio::fs::write(&model_path, b"mock onnx data").await.unwrap();

        // Create config file
        let config_path = base_path.join("test-config.yaml");
        tokio::fs::write(&config_path, config_yaml).await.unwrap();

        // Test loading
        let mut manager = ModelConfigManager::new(base_path);
        let model_name = manager.load_config("test-config.yaml").await.unwrap();

        assert_eq!(model_name, "test-model");
        assert!(manager.get_config("test-model").is_some());
    }
}
