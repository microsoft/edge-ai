use thiserror::Error;

/// Result type for inference operations
pub type Result<T> = std::result::Result<T, InferenceError>;

/// Comprehensive error types for AI inference operations
#[derive(Error, Debug)]
pub enum InferenceError {
    /// ONNX Runtime related errors (conditional compilation)
    #[cfg(feature = "onnx-runtime")]
    #[error("ONNX Runtime error: {0}")]
    OnnxRuntime(String),

    /// Model loading and management errors
    #[error("Model error: {message}")]
    Model { message: String },

    /// Input data validation errors
    #[error("Invalid input: {message}")]
    InvalidInput { message: String },

    /// Configuration errors
    #[error("Configuration error: {message}")]
    Configuration { message: String },

    /// GPU/CUDA related errors
    #[error("GPU error: {message}")]
    Gpu { message: String },

    /// Memory allocation errors
    #[error("Memory error: {message}")]
    Memory { message: String },

    /// File I/O errors
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// Image processing errors
    #[error("Image processing error: {0}")]
    Image(#[from] image::ImageError),

    /// Audio processing errors
    #[error("Audio processing error: {message}")]
    Audio { message: String },

    /// Text processing errors
    #[error("Text processing error: {message}")]
    Text { message: String },

    /// Serialization/deserialization errors
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    /// Timeout errors for long-running operations
    #[error("Operation timed out after {timeout_ms}ms")]
    Timeout { timeout_ms: u64 },

    /// Resource exhaustion errors
    #[error("Resource exhausted: {resource_type}")]
    ResourceExhausted { resource_type: String },

    /// Generic internal errors
    #[error("Internal error: {message}")]
    Internal { message: String },
}

impl InferenceError {
    /// Create a new model error
    pub fn model<S: Into<String>>(message: S) -> Self {
        Self::Model {
            message: message.into(),
        }
    }

    /// Create a new invalid input error
    pub fn invalid_input<S: Into<String>>(message: S) -> Self {
        Self::InvalidInput {
            message: message.into(),
        }
    }

    /// Create a new configuration error
    pub fn configuration<S: Into<String>>(message: S) -> Self {
        Self::Configuration {
            message: message.into(),
        }
    }

    /// Create a new GPU error
    pub fn gpu<S: Into<String>>(message: S) -> Self {
        Self::Gpu {
            message: message.into(),
        }
    }

    /// Create a new memory error
    pub fn memory<S: Into<String>>(message: S) -> Self {
        Self::Memory {
            message: message.into(),
        }
    }

    /// Create a new audio error
    pub fn audio<S: Into<String>>(message: S) -> Self {
        Self::Audio {
            message: message.into(),
        }
    }

    /// Create a new text error
    pub fn text<S: Into<String>>(message: S) -> Self {
        Self::Text {
            message: message.into(),
        }
    }

    /// Create a new timeout error
    pub fn timeout(timeout_ms: u64) -> Self {
        Self::Timeout { timeout_ms }
    }

    /// Create a new resource exhausted error
    pub fn resource_exhausted<S: Into<String>>(resource_type: S) -> Self {
        Self::ResourceExhausted {
            resource_type: resource_type.into(),
        }
    }

    /// Create a new internal error
    pub fn internal<S: Into<String>>(message: S) -> Self {
        Self::Internal {
            message: message.into(),
        }
    }

    /// Create a new preprocessing error (maps to InvalidInput)
    pub fn preprocessing<S: Into<String>>(message: S) -> Self {
        Self::InvalidInput {
            message: format!("Preprocessing error: {}", message.into()),
        }
    }

    /// Create a new execution error (maps to Internal)
    pub fn execution<S: Into<String>>(message: S) -> Self {
        Self::Internal {
            message: format!("Execution error: {}", message.into()),
        }
    }

    /// Create a new postprocessing error (maps to Internal)
    pub fn postprocessing<S: Into<String>>(message: S) -> Self {
        Self::Internal {
            message: format!("Postprocessing error: {}", message.into()),
        }
    }

    /// Check if this error is recoverable
    pub fn is_recoverable(&self) -> bool {
        match self {
            // Permanent errors that won't resolve with retry
            InferenceError::Configuration { .. } 
            | InferenceError::Model { .. }
            | InferenceError::InvalidInput { .. } => false,
            
            // Temporary errors that might resolve
            InferenceError::Gpu { .. }
            | InferenceError::Memory { .. }
            | InferenceError::Timeout { .. }
            | InferenceError::ResourceExhausted { .. }
            | InferenceError::Io(_) => true,
            
            // Runtime errors depend on underlying cause
            #[cfg(feature = "onnx-runtime")]
            InferenceError::OnnxRuntime(_) => true,
            
            // Processing errors might be recoverable
            InferenceError::Image(_)
            | InferenceError::Audio { .. }
            | InferenceError::Text { .. } => true,
            
            // Serialization errors typically not recoverable
            InferenceError::Serialization(_) => false,
            
            // Internal errors depend on context
            InferenceError::Internal { .. } => false,
        }
    }

    /// Get error category for monitoring and alerting
    pub fn category(&self) -> &'static str {
        match self {
            #[cfg(feature = "onnx-runtime")]
            InferenceError::OnnxRuntime(_) => "runtime",
            InferenceError::Model { .. } => "model",
            InferenceError::InvalidInput { .. } => "input",
            InferenceError::Configuration { .. } => "configuration", 
            InferenceError::Gpu { .. } => "gpu",
            InferenceError::Memory { .. } => "memory",
            InferenceError::Io(_) => "io",
            InferenceError::Image(_) => "image_processing",
            InferenceError::Audio { .. } => "audio_processing",
            InferenceError::Text { .. } => "text_processing",
            InferenceError::Serialization(_) => "serialization",
            InferenceError::Timeout { .. } => "timeout",
            InferenceError::ResourceExhausted { .. } => "resource",
            InferenceError::Internal { .. } => "internal",
        }
    }
}

// Manual conversion implementations for conditional features
#[cfg(feature = "onnx-runtime")]
impl From<ort::Error> for InferenceError {
    fn from(error: ort::Error) -> Self {
        InferenceError::OnnxRuntime(format!("{:?}", error))
    }
}