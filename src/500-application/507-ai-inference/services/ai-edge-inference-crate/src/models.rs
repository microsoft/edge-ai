use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::RwLock;
use serde::{Deserialize, Serialize};

use crate::types::ModelType;
use crate::error::InferenceError;
use crate::config::InferenceConfig;

/// Metadata for a loaded model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelMetadata {
    pub name: String,
    pub model_type: ModelType,
    pub version: String,
    pub input_shape: Vec<i64>,
    pub output_shape: Vec<i64>,
    pub loaded_at: chrono::DateTime<chrono::Utc>,
    pub file_path: PathBuf,
    pub file_size_bytes: u64,
    pub description: String,
}

/// Container for a loaded model (generic placeholder without ort)
pub struct LoadedModel {
    pub metadata: ModelMetadata,
    pub preprocessing_config: HashMap<String, serde_json::Value>,
    pub postprocessing_config: HashMap<String, serde_json::Value>,
    pub confidence_threshold: f32,
}

/// Model registry for managing multiple ONNX models
pub struct ModelRegistry {
    models: Arc<RwLock<HashMap<String, LoadedModel>>>,
    config: InferenceConfig,
}

impl ModelRegistry {
    /// Create a new model registry
    pub fn new(config: InferenceConfig) -> Self {
        Self {
            models: Arc::new(RwLock::new(HashMap::new())),
            config,
        }
    }

    /// Load a model from file (placeholder implementation when no backend features enabled)
    pub async fn load_model(&self, model_name: &str, model_path: &PathBuf) -> Result<(), InferenceError> {
        // Get model-specific configuration
        let _model_params = self.config.models.model_configs
            .get(model_name)
            .cloned()
            .unwrap_or_default();

        // Get file metadata
        let file_metadata = std::fs::metadata(model_path)
            .map_err(|e| InferenceError::model(format!("Failed to read file metadata: {}", e)))?;

        let metadata = ModelMetadata {
            name: model_name.to_string(),
            model_type: ModelType::Vision, // Default placeholder
            version: "1.0.0".to_string(),
            input_shape: vec![1, 3, 224, 224], // Default image input shape
            output_shape: vec![1, 1000], // Default classification output
            loaded_at: chrono::Utc::now(),
            file_path: model_path.clone(),
            file_size_bytes: file_metadata.len(),
            description: format!("Loaded model: {}", model_name),
        };

        let loaded_model = LoadedModel {
            metadata,
            preprocessing_config: HashMap::new(),
            postprocessing_config: HashMap::new(),
            confidence_threshold: self.config.models.global_confidence_threshold,
        };

        // Store in registry
        let mut models = self.models.write().unwrap();
        models.insert(model_name.to_string(), loaded_model);

        tracing::info!("Model '{}' loaded successfully", model_name);
        Ok(())
    }

    /// Get list of loaded models
    pub async fn list_models(&self) -> Vec<ModelMetadata> {
        let models = self.models.read().unwrap();
        models.values().map(|m| m.metadata.clone()).collect()
    }

    /// Check if a model is loaded
    pub async fn is_model_loaded(&self, model_name: &str) -> bool {
        let models = self.models.read().unwrap();
        models.contains_key(model_name)
    }

    /// Unload a model
    pub async fn unload_model(&self, model_name: &str) -> Result<(), InferenceError> {
        let mut models = self.models.write().unwrap();
        models.remove(model_name)
            .ok_or_else(|| InferenceError::model(format!("Model not found: {}", model_name)))?;
        
        tracing::info!("Unloaded model: {}", model_name);
        Ok(())
    }

    /// Get model metadata
    pub async fn get_model_metadata(&self, model_name: &str) -> Result<ModelMetadata, InferenceError> {
        let models = self.models.read().unwrap();
        let model = models.get(model_name)
            .ok_or_else(|| InferenceError::model(format!("Model not found: {}", model_name)))?;
        Ok(model.metadata.clone())
    }

    /// Load all default models specified in configuration
    pub async fn load_default_models(&self) -> Result<(), InferenceError> {
        if let Some(default_models) = &self.config.models.default_models {
            for (model_name, model_path_str) in default_models {
                let model_path = self.config.models.models_directory.join(model_path_str);
                
                match self.load_model(model_name, &model_path).await {
                    Ok(_) => {
                        tracing::info!("Auto-loaded model: {}", model_name);
                    }
                    Err(e) => {
                        tracing::error!("Failed to auto-load model {}: {}", model_name, e);
                        if !self.config.hardware.fallback_to_cpu {
                            return Err(e);
                        }
                    }
                }
            }
        }

        Ok(())
    }

    /// Get access to a loaded model for inference
    pub async fn get_model(&self, model_name: &str) -> Result<Arc<RwLock<HashMap<String, LoadedModel>>>, InferenceError> {
        if !self.is_model_loaded(model_name).await {
            return Err(InferenceError::model(format!("Model not found: {}", model_name)));
        }
        Ok(Arc::clone(&self.models))
    }

    /// Get model statistics
    pub async fn get_model_stats(&self) -> HashMap<String, serde_json::Value> {
        let models = self.models.read().unwrap();
        let mut stats = HashMap::new();
        
        stats.insert("total_models".to_string(), serde_json::Value::Number(models.len().into()));
        
        let mut model_types = HashMap::new();
        let mut total_memory_mb = 0.0;
        
        for model in models.values() {
            // Count by type
            let type_str = format!("{:?}", model.metadata.model_type);
            let count: i64 = model_types.get(&type_str).unwrap_or(&0) + 1;
            model_types.insert(type_str, count);
            
            // Estimate memory usage (rough approximation)
            total_memory_mb += model.metadata.file_size_bytes as f64 / (1024.0 * 1024.0);
        }
        
        stats.insert("models_by_type".to_string(), serde_json::to_value(model_types).unwrap_or_default());
        stats.insert("estimated_memory_mb".to_string(), serde_json::Value::Number(
            serde_json::Number::from_f64(total_memory_mb).unwrap_or_else(|| serde_json::Number::from(0))
        ));
        
        stats
    }
}