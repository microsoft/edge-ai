use std::error::Error;
use std::fmt;
use serde::{Deserialize, Serialize};
use async_trait::async_trait;
use crate::{InferenceInput, InferenceResult, ModelConfig};

/// Specific backend implementations
#[derive(Debug)]
pub enum Backend {
    #[cfg(feature = "onnx-runtime")]
    OnnxRuntime(crate::backends::onnx::OnnxRuntimeBackend),
    #[cfg(feature = "candle")]
    Candle(crate::backends::candle::CandleBackend),
}

impl Backend {
    /// Initialize the backend with configuration
    pub async fn initialize(&mut self, config: &BackendConfig) -> Result<(), BackendError> {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(backend) => backend.initialize(config).await,
            #[cfg(feature = "candle")]
            Backend::Candle(backend) => backend.initialize(config).await,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => Err(BackendError::ConfigurationError(
                "No backend features enabled. Enable 'onnx-runtime' or 'candle' feature.".to_string()
            )),
        }
    }
    
    /// Load a model from file or URL
    pub async fn load_model(&mut self, model_name: &str, model_config: &ModelConfig) -> Result<(), BackendError> {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(backend) => backend.load_model(model_name, model_config).await,
            #[cfg(feature = "candle")]
            Backend::Candle(backend) => backend.load_model(model_name, model_config).await,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => Err(BackendError::ConfigurationError(
                "No backend features enabled. Enable 'onnx-runtime' or 'candle' feature.".to_string()
            )),
        }
    }
    
    /// Unload a model
    pub async fn unload_model(&mut self, model_name: &str) -> Result<(), BackendError> {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(backend) => backend.unload_model(model_name).await,
            #[cfg(feature = "candle")]
            Backend::Candle(backend) => backend.unload_model(model_name).await,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => Err(BackendError::ConfigurationError(
                "No backend features enabled. Enable 'onnx-runtime' or 'candle' feature.".to_string()
            )),
        }
    }
    
    /// Run inference on input data
    pub async fn infer(&self, input: InferenceInput, model_name: Option<&str>) -> Result<InferenceResult, BackendError> {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(backend) => backend.infer(input, model_name).await,
            #[cfg(feature = "candle")]
            Backend::Candle(backend) => backend.infer(input, model_name).await,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => Err(BackendError::ConfigurationError(
                "No backend features enabled. Enable 'onnx-runtime' or 'candle' feature.".to_string()
            )),
        }
    }
    
    /// Get list of loaded models
    pub async fn get_loaded_models(&self) -> Vec<String> {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(backend) => backend.get_loaded_models().await,
            #[cfg(feature = "candle")]
            Backend::Candle(backend) => backend.get_loaded_models().await,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => Vec::new(),
        }
    }
    
    /// Get backend status
    pub async fn get_status(&self) -> BackendStatus {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(backend) => backend.get_status().await,
            #[cfg(feature = "candle")]
            Backend::Candle(backend) => backend.get_status().await,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => BackendStatus {
                backend_type: BackendType::Auto,
                device_type: DeviceType::Cpu,
                initialized: false,
                loaded_models: Vec::new(),
                memory_usage_mb: 0.0,
                last_inference_time_ms: None,
                total_inferences: 0,
                errors: vec!["No backend features enabled".to_string()],
            },
        }
    }
    
    /// Get backend type identifier
    pub fn backend_type(&self) -> BackendType {
        match self {
            #[cfg(feature = "onnx-runtime")]
            Backend::OnnxRuntime(_) => BackendType::OnnxRuntime,
            #[cfg(feature = "candle")]
            Backend::Candle(_) => BackendType::Candle,
            #[cfg(not(any(feature = "onnx-runtime", feature = "candle")))]
            _ => BackendType::Auto,
        }
    }
}

/// Inference backend trait that allows multiple ML frameworks
#[async_trait]
pub trait InferenceBackend: Send + Sync {
    /// Initialize the backend with configuration
    async fn initialize(&mut self, config: &BackendConfig) -> Result<(), BackendError>;
    
    /// Load a model from file or URL
    async fn load_model(&mut self, model_name: &str, model_config: &ModelConfig) -> Result<(), BackendError>;
    
    /// Unload a model
    async fn unload_model(&mut self, model_name: &str) -> Result<(), BackendError>;
    
    /// Run inference on input data
    async fn infer(&self, input: InferenceInput, model_name: Option<&str>) -> Result<InferenceResult, BackendError>;
    
    /// Get list of loaded models
    async fn get_loaded_models(&self) -> Vec<String>;
    
    /// Get backend status
    async fn get_status(&self) -> BackendStatus;
    
    /// Get backend type identifier
    fn backend_type(&self) -> BackendType;
}

/// Backend configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendConfig {
    pub backend_type: BackendType,
    pub device_type: DeviceType,
    pub model_directory: String,
    pub cache_size_mb: usize,
    pub enable_optimization: bool,
    pub optimization_level: OptimizationLevel,
    pub parallel_execution: bool,
    pub onnx_config: Option<OnnxConfig>,
    pub candle_config: Option<CandleConfig>,
}

/// ONNX Runtime specific configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OnnxConfig {
    pub execution_providers: Vec<String>,
    pub inter_op_num_threads: Option<usize>,
    pub intra_op_num_threads: Option<usize>,
    pub enable_cpu_mem_arena: bool,
    pub enable_mem_pattern: bool,
    pub optimization_level: String,
}

/// Candle specific configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CandleConfig {
    pub dtype: CandleDType,
    pub use_flash_attention: bool,
    pub enable_quantization: bool,
    pub quantization_bits: Option<u8>,
}

/// Candle data types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CandleDType {
    F16,
    F32,
    F64,
    U8,
    I64,
}

/// Backend types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum BackendType {
    OnnxRuntime,
    Candle,
    Auto, // Automatically choose best available
}

impl fmt::Display for BackendType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BackendType::OnnxRuntime => write!(f, "ONNX Runtime"),
            BackendType::Candle => write!(f, "Candle"),
            BackendType::Auto => write!(f, "Auto"),
        }
    }
}

/// Optimization levels for model inference
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OptimizationLevel {
    None,
    Basic,
    Extended,
    All,
}

/// Device types for inference
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DeviceType {
    Cpu,
    Cuda(usize), // GPU index
    Metal,
    Auto,
}

/// Backend status information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackendStatus {
    pub backend_type: BackendType,
    pub device_type: DeviceType,
    pub initialized: bool,
    pub loaded_models: Vec<String>,
    pub memory_usage_mb: f64,
    pub last_inference_time_ms: Option<f64>,
    pub total_inferences: u64,
    pub errors: Vec<String>,
}

/// Backend-specific errors
#[derive(Debug)]
pub enum BackendError {
    InitializationFailed(String),
    ModelLoadFailed(String),
    ModelUnloadFailed(String),
    InferenceFailed(String),
    InvalidInput(String),
    DeviceError(String),
    ConfigurationError(String),
    BackendUnavailable(String),
    BackendNotInitialized(String),
    PreprocessingFailed(String),
    PostprocessingFailed(String),
    OnnxError(String),
    CandleError(String),
}

impl fmt::Display for BackendError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BackendError::InitializationFailed(msg) => write!(f, "Backend initialization failed: {}", msg),
            BackendError::ModelLoadFailed(msg) => write!(f, "Model load failed: {}", msg),
            BackendError::ModelUnloadFailed(msg) => write!(f, "Model unload failed: {}", msg),
            BackendError::InferenceFailed(msg) => write!(f, "Inference failed: {}", msg),
            BackendError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
            BackendError::DeviceError(msg) => write!(f, "Device error: {}", msg),
            BackendError::ConfigurationError(msg) => write!(f, "Configuration error: {}", msg),
            BackendError::BackendUnavailable(msg) => write!(f, "Backend unavailable: {}", msg),
            BackendError::BackendNotInitialized(msg) => write!(f, "Backend not initialized: {}", msg),
            BackendError::PreprocessingFailed(msg) => write!(f, "Preprocessing failed: {}", msg),
            BackendError::PostprocessingFailed(msg) => write!(f, "Postprocessing failed: {}", msg),
            BackendError::OnnxError(msg) => write!(f, "ONNX Runtime error: {}", msg),
            BackendError::CandleError(msg) => write!(f, "Candle error: {}", msg),
        }
    }
}

impl Error for BackendError {}

#[cfg(feature = "candle")]
impl From<candle_core::Error> for BackendError {
    fn from(error: candle_core::Error) -> Self {
        BackendError::CandleError(error.to_string())
    }
}

/// Factory for creating inference backends
pub struct BackendFactory;

impl BackendFactory {
    /// Create a backend based on configuration and availability
    /// Create a new backend instance based on configuration
    pub async fn create_backend(config: &BackendConfig) -> Result<Backend, BackendError> {
        match config.backend_type {
            BackendType::OnnxRuntime => {
                #[cfg(feature = "onnx-runtime")]
                {
                    let mut backend = crate::backends::onnx::OnnxRuntimeBackend::new();
                    backend.initialize(config).await?;
                    Ok(Backend::OnnxRuntime(backend))
                }
                #[cfg(not(feature = "onnx-runtime"))]
                {
                    Err(BackendError::BackendUnavailable("ONNX Runtime backend not compiled".to_string()))
                }
            }
            BackendType::Candle => {
                #[cfg(feature = "candle")]
                {
                    let mut backend = crate::backends::candle::CandleBackend::new();
                    backend.initialize(config).await?;
                    Ok(Backend::Candle(backend))
                }
                #[cfg(not(feature = "candle"))]
                {
                    Err(BackendError::BackendUnavailable("Candle backend not compiled".to_string()))
                }
            }
            BackendType::Auto => {
                // Try ONNX Runtime first, fallback to Candle
                #[cfg(feature = "onnx-runtime")]
                {
                    let mut onnx_config = config.clone();
                    onnx_config.backend_type = BackendType::OnnxRuntime;
                    
                    let mut backend = crate::backends::onnx::OnnxRuntimeBackend::new();
                    if backend.initialize(&onnx_config).await.is_ok() {
                        tracing::info!("Using ONNX Runtime backend (preferred)");
                        return Ok(Backend::OnnxRuntime(backend));
                    }
                }
                
                #[cfg(feature = "candle")]
                {
                    let mut candle_config = config.clone();
                    candle_config.backend_type = BackendType::Candle;
                    
                    let mut backend = crate::backends::candle::CandleBackend::new();
                    if backend.initialize(&candle_config).await.is_ok() {
                        tracing::info!("Using Candle backend (fallback)");
                        return Ok(Backend::Candle(backend));
                    }
                }
                
                Err(BackendError::BackendUnavailable("No suitable backend available".to_string()))
            }
        }
    }
    
    /// Check which backends are available at compile time
    pub fn available_backends() -> Vec<BackendType> {
        let mut backends = Vec::new();
        
        #[cfg(feature = "onnx-runtime")]
        backends.push(BackendType::OnnxRuntime);
        
        #[cfg(feature = "candle")]
        backends.push(BackendType::Candle);
        
        backends
    }
}

impl Default for BackendConfig {
    fn default() -> Self {
        Self {
            backend_type: BackendType::Auto,
            device_type: DeviceType::Auto,
            model_directory: "./models".to_string(),
            cache_size_mb: 512,
            enable_optimization: true,
            optimization_level: OptimizationLevel::Basic,
            parallel_execution: true,
            onnx_config: Some(OnnxConfig::default()),
            candle_config: Some(CandleConfig::default()),
        }
    }
}

impl Default for OnnxConfig {
    fn default() -> Self {
        Self {
            execution_providers: vec![
                "CUDAExecutionProvider".to_string(),
                "CPUExecutionProvider".to_string(),
            ],
            inter_op_num_threads: None,
            intra_op_num_threads: None,
            enable_cpu_mem_arena: true,
            enable_mem_pattern: true,
            optimization_level: "all".to_string(),
        }
    }
}

impl Default for CandleConfig {
    fn default() -> Self {
        Self {
            dtype: CandleDType::F32,
            use_flash_attention: false,
            enable_quantization: false,
            quantization_bits: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_backend_factory_available_backends() {
        let backends = BackendFactory::available_backends();
        
        // At least one backend should be available
        assert!(!backends.is_empty(), "No backends compiled in");
        
        #[cfg(feature = "onnx-runtime")]
        assert!(backends.contains(&BackendType::OnnxRuntime));
        
        #[cfg(feature = "candle")]
        assert!(backends.contains(&BackendType::Candle));
    }
    
    #[test]
    fn test_backend_config_default() {
        let config = BackendConfig::default();
        assert_eq!(config.backend_type, BackendType::Auto);
        assert_eq!(config.model_directory, "./models");
        assert!(config.enable_optimization);
    }
}