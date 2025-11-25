use std::collections::HashMap;
use std::sync::Arc;
use std::time::Instant;
use std::sync::RwLock;
use std::path::PathBuf;
use tracing::{info, warn, debug};
use base64::{Engine as _, engine::general_purpose};
use serde_json;

use crate::types::{InferenceRequest, InferenceResult};
use crate::error::InferenceError;
use crate::config::InferenceConfig;
use crate::backend::{Backend, BackendFactory, BackendConfig, BackendType, DeviceType, OptimizationLevel};
use crate::{InferenceInput, ModelConfig};
use crate::model_config::{ModelConfigManager, ModelConfiguration, ModelSummary};

/// Core AI inference engine that processes requests using pluggable ML backends
pub struct InferenceEngine {
    backend: Backend,
    config: InferenceConfig,
    metrics: Arc<RwLock<InferenceMetrics>>,
    model_config_manager: Option<ModelConfigManager>,
}

/// Performance and usage metrics for the inference engine
#[derive(Debug, Default, Clone)]
pub struct InferenceMetrics {
    pub total_inferences: u64,
    pub successful_inferences: u64,
    pub failed_inferences: u64,
    pub average_inference_time_ms: f64,
    pub total_inference_time_ms: f64,
    pub model_usage_count: HashMap<String, u64>,
    pub error_count_by_type: HashMap<String, u64>,
    pub last_reset: chrono::DateTime<chrono::Utc>,
}

impl InferenceEngine {
    /// Create a new inference engine with automatic backend selection
    pub async fn new(config: InferenceConfig) -> Result<Self, InferenceError> {
        info!("Creating AI inference engine with automatic backend selection");

        // Check what backends are available
        let available_backends = BackendFactory::available_backends();
        info!("Available backends: {:?}", available_backends);

        if available_backends.is_empty() {
            return Err(InferenceError::configuration(
                "No ML backends available. Check that onnx-runtime or candle features are enabled.".to_string()
            ));
        }

        // Create backend configuration with CPU-only settings
        let backend_config = BackendConfig {
            backend_type: BackendType::Auto, // Auto-select
            device_type: DeviceType::Cpu, // Force CPU
            model_directory: config.models.models_directory.to_string_lossy().to_string(),
            cache_size_mb: 512, // Reduced cache
            enable_optimization: false, // Disable optimization for debugging
            optimization_level: OptimizationLevel::None,
            parallel_execution: false, // Disable parallel execution
            onnx_config: Some(crate::backend::OnnxConfig {
                execution_providers: vec!["CPUExecutionProvider".to_string()], // CPU only
                inter_op_num_threads: Some(1),
                intra_op_num_threads: Some(1),
                enable_cpu_mem_arena: true,
                enable_mem_pattern: false, // Disable for debugging
                optimization_level: "basic".to_string(),
            }),
            candle_config: Some(Default::default()),
        };

        // Create backend using factory
        let backend = BackendFactory::create_backend(&backend_config).await
            .map_err(|e| InferenceError::configuration(format!("Failed to create backend: {}", e)))?;

        Ok(Self {
            backend,
            config,
            metrics: Arc::new(RwLock::new(InferenceMetrics::default())),
            model_config_manager: None,
        })
    }

    /// Create a new inference engine with a specific backend type
    pub async fn new_with_backend(config: InferenceConfig, backend_type: BackendType) -> Result<Self, InferenceError> {
        info!("Creating AI inference engine with {} backend", backend_type);

        // Create backend configuration
        let backend_config = BackendConfig {
            backend_type: backend_type.clone(),
            device_type: DeviceType::Auto,
            model_directory: config.models.models_directory.to_string_lossy().to_string(),
            cache_size_mb: 1024,
            enable_optimization: true,
            optimization_level: OptimizationLevel::Basic,
            parallel_execution: true,
            onnx_config: Some(Default::default()),
            candle_config: Some(Default::default()),
        };

        // Create specific backend
        let backend = BackendFactory::create_backend(&backend_config).await
            .map_err(|e| InferenceError::configuration(format!("Failed to create {} backend: {}", backend_type, e)))?;

        Ok(Self {
            backend,
            config,
            metrics: Arc::new(RwLock::new(InferenceMetrics::default())),
            model_config_manager: None,
        })
    }

    /// Initialize the inference engine and load default models
    pub async fn initialize(&mut self) -> Result<(), InferenceError> {
        info!("Initializing AI inference engine...");

        // Validate configuration
        self.config.validate()
            .map_err(|e| InferenceError::configuration(e))?;

        // Initialize backend
        let backend_config = BackendConfig {
            backend_type: BackendType::Auto, // Use detected backend
            device_type: DeviceType::Auto,
            model_directory: self.config.models.models_directory.to_string_lossy().to_string(),
            cache_size_mb: 1024,
            enable_optimization: true,
            optimization_level: OptimizationLevel::Basic,
            parallel_execution: true,
            onnx_config: Some(Default::default()),
            candle_config: Some(Default::default()),
        };

        self.backend.initialize(&backend_config).await
            .map_err(|e| InferenceError::configuration(format!("Backend initialization failed: {}", e)))?;

        // Load default models if specified
        if let Some(default_models) = &self.config.models.default_models {
            for (model_name, model_path) in default_models {
                let model_config = ModelConfig {
                    model_path: model_path.clone(),
                    model_type: "auto".to_string(),
                    confidence_threshold: Some(0.5),
                    preprocessing: None,
                    postprocessing: None,
                };

                if let Err(e) = self.backend.load_model(model_name, &model_config).await {
                    warn!("Failed to load default model '{}': {}", model_name, e);
                } else {
                    info!("Loaded default model: {}", model_name);
                }
            }
        }

        // Initialize metrics
        let mut metrics = self.metrics.write().unwrap();
        metrics.last_reset = chrono::Utc::now();

        info!("AI inference engine initialized successfully with {} backend", self.backend.backend_type());
        Ok(())
    }

    /// Process a single inference request
    pub async fn infer(&self, request: InferenceRequest) -> Result<InferenceResult, InferenceError> {
        let start_time = Instant::now();
        let request_id = request.request_id.clone();

        debug!("Processing inference request: {}", request_id);

        // Validate request
        self.validate_request(&request)?;

        // Convert request to backend input format
        let inference_input = self.convert_request_to_input(&request).await?;

        // Run inference (simplified without timeout for now)
        let result = self.backend.infer(inference_input, request.model_name.as_deref()).await;

        let inference_result = match result {
            Ok(mut result) => {
                // Update result with request metadata
                result.metadata.as_object_mut().unwrap().insert(
                    "request_id".to_string(),
                    serde_json::Value::String(request_id.clone())
                );

                self.update_success_metrics(&result.model_name, start_time).await;
                Ok(result)
            }
            Err(e) => {
                let inference_error = InferenceError::execution(e.to_string());
                self.update_error_metrics(&inference_error).await;
                Err(inference_error)
            }
        };

        debug!("Completed inference request: {} in {:?}", request_id, start_time.elapsed());
        inference_result
    }

    /// Process multiple inference requests in batch
    pub async fn infer_batch(&self, requests: Vec<InferenceRequest>) -> Vec<InferenceResult> {
        if requests.is_empty() {
            return vec![];
        }

        info!("Processing batch of {} inference requests", requests.len());

        if self.config.performance.enable_parallel_processing {
            // Process requests in parallel
            let futures = requests.into_iter().map(|req| self.infer(req));
            let results = futures::future::join_all(futures).await;

            results.into_iter().map(|r| match r {
                Ok(result) => result,
                Err(e) => self.create_error_result(e),
            }).collect()
        } else {
            // Process requests sequentially
            let mut results = Vec::new();
            for request in requests {
                match self.infer(request).await {
                    Ok(result) => results.push(result),
                    Err(e) => results.push(self.create_error_result(e)),
                }
            }
            results
        }
    }

    /// Convert inference request to backend input format
    async fn convert_request_to_input(&self, request: &InferenceRequest) -> Result<InferenceInput, InferenceError> {
        match request.input_type.as_str() {
            "image" => {
                // Decode base64 image data
                let image_data = general_purpose::STANDARD.decode(&request.input_data)
                    .map_err(|e| InferenceError::preprocessing(format!("Failed to decode base64 image: {}", e)))?;

                // Load image
                let image = image::load_from_memory(&image_data)
                    .map_err(|e| InferenceError::preprocessing(format!("Failed to load image: {}", e)))?;

                Ok(InferenceInput::Image {
                    data: image,
                    metadata: crate::ImageMetadata {
                        width: 0, // Will be filled by preprocessing
                        height: 0,
                        channels: 3,
                        format: "RGB".to_string(),
                    },
                })
            }
            "time_series" | "sensor" => {
                // Parse sensor data from JSON
                let sensor_data: serde_json::Value = serde_json::from_str(&request.input_data)
                    .map_err(|e| InferenceError::preprocessing(format!("Failed to parse sensor data: {}", e)))?;

                let values = sensor_data["values"].as_array()
                    .ok_or_else(|| InferenceError::preprocessing("Missing 'values' field in sensor data".to_string()))?
                    .iter()
                    .map(|v| v.as_f64().unwrap_or(0.0) as f32)
                    .collect::<Vec<f32>>();

                let timestamps = sensor_data["timestamps"].as_array()
                    .map(|arr| arr.iter().map(|v| v.as_i64().unwrap_or(0)).collect())
                    .unwrap_or_else(|| (0..values.len() as i64).collect());

                Ok(InferenceInput::TimeSeries {
                    values,
                    timestamps,
                    metadata: crate::SensorMetadata {
                        sensor_type: sensor_data["sensor_type"].as_str().unwrap_or("unknown").to_string(),
                        sampling_rate: sensor_data["sampling_rate"].as_f64().unwrap_or(1.0),
                        units: sensor_data["units"].as_str().unwrap_or("").to_string(),
                    },
                })
            }
            _ => Err(InferenceError::invalid_input(format!("Unsupported input type: {}", request.input_type)))
        }
    }

    /// Load a model into the backend
    pub async fn load_model(&mut self, model_name: &str, model_config: &ModelConfig) -> Result<(), InferenceError> {
        self.backend.load_model(model_name, model_config).await
            .map_err(|e| InferenceError::model(format!("Backend model loading failed: {}", e)))
    }

    /// Unload a model from the backend
    pub async fn unload_model(&mut self, model_name: &str) -> Result<(), InferenceError> {
        self.backend.unload_model(model_name).await
            .map_err(|e| InferenceError::model(format!("Backend model unloading failed: {}", e)))
    }

    /// Get list of loaded models
    pub async fn get_loaded_models(&self) -> Vec<String> {
        self.backend.get_loaded_models().await
    }

    /// Get backend status
    pub async fn get_backend_status(&self) -> crate::backend::BackendStatus {
        self.backend.get_status().await
    }

    /// Create an error result for failed inference
    fn create_error_result(&self, error: InferenceError) -> InferenceResult {
        InferenceResult {
            model_name: "error".to_string(),
            model_type: "error".to_string(),
            predictions: vec![],
            confidence: 0.0,
            inference_time_ms: 0.0,
            metadata: serde_json::json!({
                "error": error.to_string(),
                "error_type": match error {
                    InferenceError::Model { .. } => "model_error",
                    InferenceError::InvalidInput { .. } => "invalid_input",
                    InferenceError::Timeout { .. } => "timeout",
                    InferenceError::Configuration { .. } => "configuration_error",
                    InferenceError::ResourceExhausted { .. } => "resource_exhausted",
                    InferenceError::Gpu { .. } => "gpu_error",
                    InferenceError::Memory { .. } => "memory_error",
                    InferenceError::Audio { .. } => "audio_error",
                    InferenceError::Text { .. } => "text_error",
                    InferenceError::Internal { .. } => "internal_error",
                    InferenceError::Io(_) => "io_error",
                    InferenceError::Image(_) => "image_error",
                    InferenceError::Serialization(_) => "serialization_error",
                    #[cfg(feature = "onnx-runtime")]
                    InferenceError::OnnxRuntime(_) => "onnx_runtime_error",
                }
            }),
        }
    }

    /// Validate inference request
    fn validate_request(&self, request: &InferenceRequest) -> Result<(), InferenceError> {
        if request.request_id.is_empty() {
            return Err(InferenceError::invalid_input("Request ID cannot be empty".to_string()));
        }

        if request.input_data.is_empty() {
            return Err(InferenceError::invalid_input("Input data cannot be empty".to_string()));
        }

        if !["image", "sensor", "time_series"].contains(&request.input_type.as_str()) {
            return Err(InferenceError::invalid_input(format!("Unsupported input type: {}", request.input_type)));
        }

        Ok(())
    }

    /// Update success metrics
    async fn update_success_metrics(&self, model_name: &str, start_time: Instant) {
        let mut metrics = self.metrics.write().unwrap();
        let inference_time = start_time.elapsed().as_millis() as f64;

        metrics.total_inferences += 1;
        metrics.successful_inferences += 1;
        metrics.total_inference_time_ms += inference_time;
        metrics.average_inference_time_ms = metrics.total_inference_time_ms / metrics.total_inferences as f64;

        *metrics.model_usage_count.entry(model_name.to_string()).or_insert(0) += 1;
    }

    /// Update error metrics
    async fn update_error_metrics(&self, error: &InferenceError) {
        let mut metrics = self.metrics.write().unwrap();
        metrics.total_inferences += 1;
        metrics.failed_inferences += 1;

        let error_type = match error {
            InferenceError::Model { .. } => "model_error",
            InferenceError::InvalidInput { .. } => "invalid_input",
            InferenceError::Timeout { .. } => "timeout",
            InferenceError::Configuration { .. } => "configuration_error",
            InferenceError::ResourceExhausted { .. } => "resource_exhausted",
            InferenceError::Gpu { .. } => "gpu_error",
            InferenceError::Memory { .. } => "memory_error",
            InferenceError::Audio { .. } => "audio_error",
            InferenceError::Text { .. } => "text_error",
            InferenceError::Internal { .. } => "internal_error",
            InferenceError::Io(_) => "io_error",
            InferenceError::Image(_) => "image_error",
            InferenceError::Serialization(_) => "serialization_error",
            #[cfg(feature = "onnx-runtime")]
            InferenceError::OnnxRuntime(_) => "onnx_runtime_error",
        };

        *metrics.error_count_by_type.entry(error_type.to_string()).or_insert(0) += 1;
    }

    /// Get current performance metrics
    pub async fn get_metrics(&self) -> InferenceMetrics {
        self.metrics.read().unwrap().clone()
    }

    /// Reset performance metrics
    pub async fn reset_metrics(&self) {
        let mut metrics = self.metrics.write().unwrap();
        *metrics = InferenceMetrics::default();
        metrics.last_reset = chrono::Utc::now();
    }

    // ========= YAML Configuration System Methods =========

    /// Initialize YAML-based model configuration system
    pub fn initialize_yaml_config_system(&mut self, models_base_dir: PathBuf) -> Result<(), InferenceError> {
        let manager = ModelConfigManager::new(models_base_dir.clone());
        self.model_config_manager = Some(manager);
        info!("YAML model configuration system initialized with base directory: {}", models_base_dir.display());
        Ok(())
    }

    /// Load a model from a YAML configuration file (universal approach)
    pub async fn load_model_from_yaml(&mut self, yaml_path: &str) -> Result<String, InferenceError> {
        let manager = self.model_config_manager.as_mut()
            .ok_or_else(|| InferenceError::configuration("YAML config system not initialized. Call initialize_yaml_config_system() first.".to_string()))?;

        let model_name = manager.load_config(yaml_path).await
            .map_err(|e| InferenceError::configuration(format!("Failed to load YAML config: {}", e)))?;

        // Get the loaded configuration (clone it to avoid borrowing issues)
        let yaml_config = manager.get_config(&model_name)
            .ok_or_else(|| InferenceError::configuration("Model config was loaded but not found".to_string()))?
            .clone();

        // Convert YAML config to legacy ModelConfig for backend compatibility
        let model_config = Self::convert_yaml_to_model_config(&yaml_config, &manager.base_dir)?;

        // Load the model using the existing backend system
        self.backend.load_model(&model_name, &model_config).await
            .map_err(|e| InferenceError::model(format!("Backend model loading failed: {}", e)))?;

        info!("Successfully loaded model '{}' from YAML configuration", model_name);
        Ok(model_name)
    }

    /// Load all YAML model configurations from a directory
    pub async fn load_models_from_directory(&mut self, directory_path: &str) -> Result<Vec<String>, InferenceError> {
        let manager = self.model_config_manager.as_mut()
            .ok_or_else(|| InferenceError::configuration("YAML config system not initialized".to_string()))?;

        let loaded_models = manager.load_from_directory(directory_path).await
            .map_err(|e| InferenceError::configuration(format!("Failed to load models from directory: {}", e)))?;

        // Get base directory for conversion
        let base_dir = manager.base_dir.clone();

        // Load each model into the backend
        let mut successfully_loaded = Vec::new();
        for model_name in &loaded_models {
            if let Some(yaml_config) = manager.get_config(model_name) {
                let yaml_config = yaml_config.clone(); // Clone to avoid borrowing issues
                match Self::convert_yaml_to_model_config(&yaml_config, &base_dir) {
                    Ok(model_config) => {
                        match self.backend.load_model(model_name, &model_config).await {
                            Ok(_) => {
                                successfully_loaded.push(model_name.clone());
                                info!("Successfully loaded model '{}' from directory", model_name);
                            }
                            Err(e) => {
                                warn!("Failed to load model '{}': {}", model_name, e);
                            }
                        }
                    }
                    Err(e) => {
                        warn!("Failed to convert YAML config for model '{}': {}", model_name, e);
                    }
                }
            }
        }

        info!("Loaded {}/{} models from directory '{}'", successfully_loaded.len(), loaded_models.len(), directory_path);
        Ok(successfully_loaded)
    }

    /// Get model summary information (for health endpoints and model registry)
    pub fn get_model_summaries(&self) -> Vec<ModelSummary> {
        if let Some(manager) = &self.model_config_manager {
            manager.get_all_summaries()
        } else {
            Vec::new()
        }
    }

    /// Get specific model summary by name
    pub fn get_model_summary(&self, model_name: &str) -> Option<ModelSummary> {
        self.model_config_manager.as_ref()
            .and_then(|manager| manager.get_model_summary(model_name))
    }

    /// List all available YAML-configured models
    pub fn list_yaml_models(&self) -> Vec<String> {
        if let Some(manager) = &self.model_config_manager {
            manager.list_models()
        } else {
            Vec::new()
        }
    }

    /// Helper method to convert YAML ModelConfiguration to legacy ModelConfig
    fn convert_yaml_to_model_config(yaml_config: &ModelConfiguration, base_dir: &PathBuf) -> Result<ModelConfig, InferenceError> {
        let model_path = base_dir.join(&yaml_config.model.path)
            .to_string_lossy()
            .to_string();

        // Convert preprocessing to JSON if available
        let preprocessing = yaml_config.preprocessing.as_ref()
            .map(|p| serde_json::to_value(p))
            .transpose()
            .map_err(|e| InferenceError::configuration(format!("Failed to serialize preprocessing: {}", e)))?;

        // Convert postprocessing to JSON if available
        let postprocessing = yaml_config.postprocessing.as_ref()
            .map(|p| serde_json::to_value(p))
            .transpose()
            .map_err(|e| InferenceError::configuration(format!("Failed to serialize postprocessing: {}", e)))?;

        Ok(ModelConfig {
            model_path,
            model_type: yaml_config.model.model_type.clone(),
            confidence_threshold: yaml_config.output.confidence_threshold,
            preprocessing,
            postprocessing,
        })
    }
}
