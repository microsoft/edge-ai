use std::error::Error;
use std::path::Path;
use std::sync::Arc;
use tokio::fs;
use tokio::sync::RwLock;
use tracing::{info, warn, error, instrument};
use serde::{Deserialize, Serialize};
use crate::config::ModelConfig;
use crate::inference::{ModelType, InferenceEngine};

/// Model manager for loading and managing ONNX models
pub struct ModelManager {
    inference_engine: Arc<InferenceEngine>,
    model_configs: Arc<RwLock<Vec<ModelConfig>>>,
    model_directory: String,
}

/// Model metadata for tracking
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelMetadata {
    pub name: String,
    pub version: String,
    pub model_type: ModelType,
    pub file_path: String,
    pub file_size: u64,
    pub created_at: i64,
    pub last_modified: i64,
    pub checksum: Option<String>,
    pub performance_metrics: Option<PerformanceMetrics>,
}

/// Performance tracking for models
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceMetrics {
    pub avg_inference_time_ms: f32,
    pub total_inferences: u64,
    pub accuracy_score: Option<f32>,
    pub last_performance_check: i64,
}

/// Model loading status
#[derive(Debug, Serialize)]
pub enum ModelStatus {
    NotLoaded,
    Loading,
    Loaded,
    Failed(String),
}

impl ModelManager {
    /// Create new model manager
    pub async fn new(inference_engine: Arc<InferenceEngine>, model_directory: String) -> Result<Self, Box<dyn Error>> {
        info!("Initializing model manager with directory: {}", model_directory);

        // Ensure model directory exists
        if !Path::new(&model_directory).exists() {
            fs::create_dir_all(&model_directory).await?;
            info!("Created model directory: {}", model_directory);
        }

        let manager = Self {
            inference_engine,
            model_configs: Arc::new(RwLock::new(Vec::new())),
            model_directory,
        };

        Ok(manager)
    }

    /// Discover and load all models from the model directory
    #[instrument(skip(self))]
    pub async fn discover_and_load_models(&self) -> Result<(), Box<dyn Error>> {
        info!("Discovering models in directory: {}", self.model_directory);

        let mut dir_entries = fs::read_dir(&self.model_directory).await?;
        let mut discovered_models = Vec::new();

        while let Some(entry) = dir_entries.next_entry().await? {
            let path = entry.path();
            
            if path.is_file() {
                if let Some(extension) = path.extension() {
                    if extension == "onnx" {
                        match self.create_model_config_from_file(&path).await {
                            Ok(config) => {
                                discovered_models.push(config);
                            }
                            Err(e) => {
                                error!("Failed to create config for model {:?}: {}", path, e);
                            }
                        }
                    }
                }
            }
        }

        info!("Discovered {} ONNX models", discovered_models.len());

        // Load the discovered models
        for config in discovered_models {
            match self.load_model(config.clone()).await {
                Ok(_) => {
                    info!("Successfully loaded model: {}", config.name);
                }
                Err(e) => {
                    error!("Failed to load model {}: {}", config.name, e);
                }
            }
        }

        Ok(())
    }

    /// Load a specific model
    #[instrument(skip(self))]
    pub async fn load_model(&self, config: ModelConfig) -> Result<(), Box<dyn Error>> {
        info!("Loading model: {} from {}", config.name, config.path);

        // Validate model file exists
        if !Path::new(&config.path).exists() {
            return Err(format!("Model file not found: {}", config.path).into());
        }

        // Load model in inference engine
        self.inference_engine.load_model(&config).await?;

        // Store configuration
        let mut configs = self.model_configs.write().await;
        configs.retain(|c| c.name != config.name); // Remove existing config
        configs.push(config);

        info!("Model loaded successfully");
        Ok(())
    }

    /// Unload a specific model
    pub async fn unload_model(&self, model_name: &str) -> Result<(), Box<dyn Error>> {
        info!("Unloading model: {}", model_name);

        // Unload from inference engine
        self.inference_engine.unload_model(model_name).await?;

        // Remove from configurations
        let mut configs = self.model_configs.write().await;
        configs.retain(|c| c.name != model_name);

        info!("Model {} unloaded successfully", model_name);
        Ok(())
    }

    /// Reload a model (unload then load)
    pub async fn reload_model(&self, model_name: &str) -> Result<(), Box<dyn Error>> {
        info!("Reloading model: {}", model_name);

        // Find existing configuration
        let config = {
            let configs = self.model_configs.read().await;
            configs.iter().find(|c| c.name == model_name).cloned()
        };

        if let Some(config) = config {
            // Unload then reload
            self.unload_model(model_name).await?;
            self.load_model(config).await?;
            
            info!("Model {} reloaded successfully", model_name);
            Ok(())
        } else {
            Err(format!("Model configuration not found: {}", model_name).into())
        }
    }

    /// Get status of all models
    pub async fn get_model_status(&self) -> Vec<(String, ModelStatus)> {
        let configs = self.model_configs.read().await;
        let loaded_models = self.inference_engine.get_loaded_models().await;
        
        let mut status_list = Vec::new();
        
        for config in configs.iter() {
            let status = if loaded_models.contains(&config.name) {
                ModelStatus::Loaded
            } else {
                ModelStatus::NotLoaded
            };
            
            status_list.push((config.name.clone(), status));
        }
        
        status_list
    }

    /// Update model confidence threshold
    pub async fn update_confidence_threshold(&self, model_name: &str, new_threshold: f32) -> Result<(), Box<dyn Error>> {
        if new_threshold < 0.0 || new_threshold > 1.0 {
            return Err("Confidence threshold must be between 0.0 and 1.0".into());
        }

        let mut configs = self.model_configs.write().await;
        
        if let Some(config) = configs.iter_mut().find(|c| c.name == model_name) {
            config.confidence_threshold = new_threshold;
            info!("Updated confidence threshold for {} to {}", model_name, new_threshold);
            
            // Reload the model to apply new threshold
            drop(configs); // Release the lock before reloading
            self.reload_model(model_name).await?;
            
            Ok(())
        } else {
            Err(format!("Model not found: {}", model_name).into())
        }
    }

    /// Get model metadata
    pub async fn get_model_metadata(&self, model_name: &str) -> Result<ModelMetadata, Box<dyn Error>> {
        let configs = self.model_configs.read().await;
        
        if let Some(config) = configs.iter().find(|c| c.name == model_name) {
            let metadata = self.create_metadata_from_config(config).await?;
            Ok(metadata)
        } else {
            Err(format!("Model not found: {}", model_name).into())
        }
    }

    /// Watch for model file changes and auto-reload
    pub async fn start_file_watcher(&self) -> Result<(), Box<dyn Error>> {
        info!("Starting model file watcher for directory: {}", self.model_directory);
        
        // This is a placeholder for file system watching
        // In a real implementation, you'd use a library like `notify` to watch for file changes
        // and automatically reload models when their files are updated
        
        tokio::spawn({
            let model_dir = self.model_directory.clone();
            async move {
                loop {
                    // Check for file changes every 30 seconds
                    tokio::time::sleep(tokio::time::Duration::from_secs(30)).await;
                    info!("Checking for model file changes in {}", model_dir);
                    // TODO: Implement actual file watching logic
                }
            }
        });

        Ok(())
    }

    /// Create model configuration from file
    async fn create_model_config_from_file(&self, path: &Path) -> Result<ModelConfig, Box<dyn Error>> {
        let file_name = path.file_stem()
            .and_then(|s| s.to_str())
            .ok_or("Invalid file name")?;

        // Try to extract model type from filename or use default
        let model_type = if file_name.contains("classification") {
            ModelType::ImageClassification
        } else if file_name.contains("detection") {
            ModelType::ObjectDetection
        } else if file_name.contains("timeseries") || file_name.contains("anomaly") {
            ModelType::TimeSeriesAnomaly
        } else if file_name.contains("multimodal") || file_name.contains("fusion") {
            ModelType::MultiModalFusion
        } else {
            // Default to image classification
            ModelType::ImageClassification
        };

        let config = ModelConfig {
            name: file_name.to_string(),
            path: path.to_string_lossy().to_string(),
            model_type,
            confidence_threshold: 0.5, // Default threshold
            enabled: true,
        };

        Ok(config)
    }

    /// Create metadata from model configuration
    async fn create_metadata_from_config(&self, config: &ModelConfig) -> Result<ModelMetadata, Box<dyn Error>> {
        let path = Path::new(&config.path);
        let file_metadata = fs::metadata(path).await?;
        
        let metadata = ModelMetadata {
            name: config.name.clone(),
            version: "1.0.0".to_string(), // TODO: Extract from model metadata
            model_type: config.model_type.clone(),
            file_path: config.path.clone(),
            file_size: file_metadata.len(),
            created_at: file_metadata.created()?.duration_since(std::time::UNIX_EPOCH)?.as_secs() as i64,
            last_modified: file_metadata.modified()?.duration_since(std::time::UNIX_EPOCH)?.as_secs() as i64,
            checksum: None, // TODO: Calculate file checksum
            performance_metrics: None, // TODO: Track performance over time
        };

        Ok(metadata)
    }

    /// Export model configurations to file
    pub async fn export_configurations(&self, export_path: &str) -> Result<(), Box<dyn Error>> {
        let configs = self.model_configs.read().await;
        let json_data = serde_json::to_string_pretty(&*configs)?;
        
        fs::write(export_path, json_data).await?;
        info!("Model configurations exported to: {}", export_path);
        
        Ok(())
    }

    /// Import model configurations from file
    pub async fn import_configurations(&self, import_path: &str) -> Result<(), Box<dyn Error>> {
        let json_data = fs::read_to_string(import_path).await?;
        let imported_configs: Vec<ModelConfig> = serde_json::from_str(&json_data)?;
        
        info!("Importing {} model configurations", imported_configs.len());
        
        for config in imported_configs {
            match self.load_model(config.clone()).await {
                Ok(_) => {
                    info!("Successfully imported model: {}", config.name);
                }
                Err(e) => {
                    error!("Failed to import model {}: {}", config.name, e);
                }
            }
        }
        
        Ok(())
    }

    /// Get model directory
    pub fn get_model_directory(&self) -> &str {
        &self.model_directory
    }

    /// List all available models (loaded and unloaded)
    pub async fn list_available_models(&self) -> Vec<String> {
        let configs = self.model_configs.read().await;
        configs.iter().map(|c| c.name.clone()).collect()
    }

    /// Check model health
    pub async fn check_model_health(&self, model_name: &str) -> Result<bool, Box<dyn Error>> {
        let configs = self.model_configs.read().await;
        
        if let Some(config) = configs.iter().find(|c| c.name == model_name) {
            // Check if model file still exists
            let path_exists = Path::new(&config.path).exists();
            
            // Check if model is loaded in inference engine
            let loaded_models = self.inference_engine.get_loaded_models().await;
            let is_loaded = loaded_models.contains(&config.name);
            
            Ok(path_exists && is_loaded)
        } else {
            Err(format!("Model not found: {}", model_name).into())
        }
    }
}