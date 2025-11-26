use std::error::Error;
use std::sync::Arc;
use ort::{Environment, ExecutionProvider, Session, SessionBuilder, Value};
use tokio::sync::RwLock;
use tracing::{info, warn, error, instrument};
use serde::{Deserialize, Serialize};
use image::{DynamicImage, ImageBuffer, Rgb};
use crate::config::{ModelConfig, InferenceConfig};

/// Inference engine for running ONNX models at the edge
pub struct InferenceEngine {
    models: Arc<RwLock<Vec<LoadedModel>>>,
    config: InferenceConfig,
    environment: Arc<Environment>,
}

/// A loaded ONNX model with metadata
#[derive(Debug)]
pub struct LoadedModel {
    pub name: String,
    pub model_type: ModelType,
    pub session: Session,
    pub input_shape: Vec<i64>,
    pub output_shape: Vec<i64>,
    pub confidence_threshold: f32,
}

/// Supported model types for different inference tasks
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModelType {
    ImageClassification,
    ObjectDetection,
    TimeSeriesAnomaly,
    MultiModalFusion,
}

/// Inference input data variants
#[derive(Debug)]
pub enum InferenceInput {
    Image {
        data: DynamicImage,
        metadata: ImageMetadata,
    },
    TimeSeries {
        values: Vec<f32>,
        timestamps: Vec<i64>,
        metadata: SensorMetadata,
    },
    MultiModal {
        image: DynamicImage,
        sensor_data: Vec<f32>,
        metadata: MultiModalMetadata,
    },
}

/// Inference output with confidence and metadata
#[derive(Debug, Serialize)]
pub struct InferenceResult {
    pub model_name: String,
    pub model_type: ModelType,
    pub confidence: f32,
    pub predictions: Vec<Prediction>,
    pub processing_time_ms: u64,
    pub metadata: ResultMetadata,
}

/// Individual prediction result
#[derive(Debug, Serialize)]
pub struct Prediction {
    pub label: String,
    pub confidence: f32,
    pub bounding_box: Option<BoundingBox>,
    pub anomaly_score: Option<f32>,
}

/// Bounding box for object detection
#[derive(Debug, Serialize)]
pub struct BoundingBox {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

/// Image metadata for tracking
#[derive(Debug, Clone)]
pub struct ImageMetadata {
    pub camera_id: String,
    pub timestamp: i64,
    pub location: Option<(f64, f64)>, // lat, lon
    pub device_name: String,
}

/// Sensor metadata for tracking
#[derive(Debug, Clone)]
pub struct SensorMetadata {
    pub sensor_id: String,
    pub sensor_type: String,
    pub unit: String,
    pub device_name: String,
}

/// Multi-modal metadata combining image and sensor
#[derive(Debug, Clone)]
pub struct MultiModalMetadata {
    pub image_meta: ImageMetadata,
    pub sensor_meta: Vec<SensorMetadata>,
}

/// Result metadata for audit trail
#[derive(Debug, Serialize)]
pub struct ResultMetadata {
    pub input_id: String,
    pub timestamp: i64,
    pub model_version: String,
    pub edge_device: String,
}

impl InferenceEngine {
    /// Create new inference engine with configuration
    pub async fn new(config: InferenceConfig) -> Result<Self, Box<dyn Error>> {
        info!("Initializing ONNX Runtime inference engine");
        
        // Initialize ONNX Runtime environment with optimization
        let environment = Arc::new(
            Environment::builder()
                .with_name("EdgeAI_Inference")
                .with_log_level(ort::LoggingLevel::Warning)
                .build()?
        );

        let engine = Self {
            models: Arc::new(RwLock::new(Vec::new())),
            config,
            environment,
        };

        info!("ONNX Runtime inference engine initialized successfully");
        Ok(engine)
    }

    /// Load a model from file system
    #[instrument(skip(self))]
    pub async fn load_model(&self, model_config: &ModelConfig) -> Result<(), Box<dyn Error>> {
        info!("Loading model: {} from {}", model_config.name, model_config.path);

        // Configure execution providers based on available hardware
        let mut session_builder = SessionBuilder::new(&self.environment)?;
        
        // Prefer GPU acceleration if available, fallback to CPU
        if self.config.enable_gpu {
            session_builder = session_builder.with_execution_providers([
                ExecutionProvider::CUDA(Default::default()),
                ExecutionProvider::TensorRT(Default::default()),
                ExecutionProvider::CPU(Default::default()),
            ])?;
        } else {
            session_builder = session_builder.with_execution_providers([
                ExecutionProvider::CPU(Default::default()),
            ])?;
        }

        // Configure optimization level
        session_builder = session_builder
            .with_optimization_level(ort::GraphOptimizationLevel::Level3)?
            .with_intra_threads(self.config.cpu_threads as i16)?;

        // Load the model
        let session = session_builder.commit_from_file(&model_config.path)?;

        // Extract input and output shapes for validation
        let input_shape = session.inputs[0].dimensions().map(|d| d.unwrap_or(1)).collect();
        let output_shape = session.outputs[0].dimensions().map(|d| d.unwrap_or(1)).collect();

        let loaded_model = LoadedModel {
            name: model_config.name.clone(),
            model_type: model_config.model_type.clone(),
            session,
            input_shape,
            output_shape,
            confidence_threshold: model_config.confidence_threshold,
        };

        // Add to loaded models
        let mut models = self.models.write().await;
        
        // Remove existing model with same name if present
        models.retain(|m| m.name != model_config.name);
        models.push(loaded_model);

        info!("Model {} loaded successfully", model_config.name);
        Ok(())
    }

    /// Perform inference on input data
    #[instrument(skip(self, input))]
    pub async fn infer(&self, input: InferenceInput, model_name: Option<&str>) -> Result<InferenceResult, Box<dyn Error>> {
        let start_time = std::time::Instant::now();
        
        // Select appropriate model
        let models = self.models.read().await;
        let model = if let Some(name) = model_name {
            models.iter().find(|m| m.name == name)
                .ok_or_else(|| format!("Model {} not found", name))?
        } else {
            // Auto-select model based on input type
            let target_type = match &input {
                InferenceInput::Image { .. } => ModelType::ImageClassification,
                InferenceInput::TimeSeries { .. } => ModelType::TimeSeriesAnomaly,
                InferenceInput::MultiModal { .. } => ModelType::MultiModalFusion,
            };
            
            models.iter().find(|m| std::mem::discriminant(&m.model_type) == std::mem::discriminant(&target_type))
                .ok_or_else(|| format!("No model found for input type: {:?}", target_type))?
        };

        // Prepare input tensor based on input type
        let input_tensor = self.prepare_input_tensor(&input, model).await?;
        
        // Run inference
        let outputs = model.session.run(vec![input_tensor])?;
        
        // Process outputs based on model type
        let predictions = self.process_outputs(&outputs, model, &input).await?;
        
        // Calculate overall confidence
        let confidence = if predictions.is_empty() {
            0.0
        } else {
            predictions.iter().map(|p| p.confidence).sum::<f32>() / predictions.len() as f32
        };

        let processing_time = start_time.elapsed();
        
        let result = InferenceResult {
            model_name: model.name.clone(),
            model_type: model.model_type.clone(),
            confidence,
            predictions,
            processing_time_ms: processing_time.as_millis() as u64,
            metadata: self.create_result_metadata(&input).await,
        };

        info!(
            "Inference completed for model {} in {}ms with confidence {:.3}",
            model.name, processing_time.as_millis(), confidence
        );

        Ok(result)
    }

    /// Prepare input tensor from various input types
    async fn prepare_input_tensor(&self, input: &InferenceInput, model: &LoadedModel) -> Result<Value, Box<dyn Error>> {
        match input {
            InferenceInput::Image { data, .. } => {
                // Resize and normalize image to model input shape
                let (height, width, channels) = (
                    model.input_shape[2] as u32,
                    model.input_shape[3] as u32,
                    model.input_shape[1] as usize,
                );

                let resized = data.resize(width, height, image::imageops::FilterType::Lanczos3);
                let rgb_image = resized.to_rgb8();
                
                // Convert to CHW format and normalize to [0,1]
                let mut input_data = Vec::with_capacity((channels * height as usize * width as usize) as usize);
                
                for c in 0..channels {
                    for y in 0..height {
                        for x in 0..width {
                            let pixel = rgb_image.get_pixel(x, y);
                            let normalized = pixel[c] as f32 / 255.0;
                            input_data.push(normalized);
                        }
                    }
                }

                let tensor = Value::from_array(
                    ([1i64, channels as i64, height as i64, width as i64], input_data)
                )?;
                
                Ok(tensor)
            },
            InferenceInput::TimeSeries { values, .. } => {
                // Prepare time series data - may need windowing/normalization
                let sequence_length = model.input_shape[1] as usize;
                let feature_count = model.input_shape[2] as usize;
                
                let mut input_data = vec![0.0f32; sequence_length * feature_count];
                
                // Take the last sequence_length values, pad if necessary
                let start_idx = if values.len() > sequence_length { 
                    values.len() - sequence_length 
                } else { 
                    0 
                };
                
                for (i, &value) in values[start_idx..].iter().enumerate() {
                    if i < sequence_length {
                        input_data[i * feature_count] = value; // Assuming single feature for now
                    }
                }

                let tensor = Value::from_array(
                    ([1i64, sequence_length as i64, feature_count as i64], input_data)
                )?;
                
                Ok(tensor)
            },
            InferenceInput::MultiModal { image, sensor_data, .. } => {
                // For multi-modal, we'll need to prepare concatenated features
                // This is a simplified implementation - real implementation would depend on model architecture
                warn!("Multi-modal inference not fully implemented - using image only");
                
                let image_input = InferenceInput::Image { 
                    data: image.clone(), 
                    metadata: ImageMetadata {
                        camera_id: "multi_modal".to_string(),
                        timestamp: chrono::Utc::now().timestamp(),
                        location: None,
                        device_name: "edge_device".to_string(),
                    }
                };
                
                self.prepare_input_tensor(&image_input, model).await
            }
        }
    }

    /// Process model outputs to predictions
    async fn process_outputs(&self, outputs: &[Value], model: &LoadedModel, _input: &InferenceInput) -> Result<Vec<Prediction>, Box<dyn Error>> {
        let mut predictions = Vec::new();
        
        if outputs.is_empty() {
            return Ok(predictions);
        }

        match model.model_type {
            ModelType::ImageClassification => {
                // Extract classification scores
                let output_data: Vec<f32> = outputs[0].try_extract_tensor()?.view().iter().copied().collect();
                
                // Apply softmax and filter by confidence threshold
                let exp_sum: f32 = output_data.iter().map(|x| x.exp()).sum();
                
                for (idx, &score) in output_data.iter().enumerate() {
                    let confidence = score.exp() / exp_sum;
                    
                    if confidence >= model.confidence_threshold {
                        predictions.push(Prediction {
                            label: format!("class_{}", idx),
                            confidence,
                            bounding_box: None,
                            anomaly_score: None,
                        });
                    }
                }
            },
            ModelType::ObjectDetection => {
                // Simplified object detection output processing
                // Real implementation would handle YOLO/SSD/etc. specific formats
                let output_data: Vec<f32> = outputs[0].try_extract_tensor()?.view().iter().copied().collect();
                
                // Assuming output format: [batch, detections, (x, y, w, h, confidence, class_probs...)]
                let detection_size = 6; // x, y, w, h, confidence, class
                let num_detections = output_data.len() / detection_size;
                
                for i in 0..num_detections {
                    let base_idx = i * detection_size;
                    if base_idx + 5 < output_data.len() {
                        let confidence = output_data[base_idx + 4];
                        
                        if confidence >= model.confidence_threshold {
                            predictions.push(Prediction {
                                label: "leak_detection".to_string(),
                                confidence,
                                bounding_box: Some(BoundingBox {
                                    x: output_data[base_idx],
                                    y: output_data[base_idx + 1],
                                    width: output_data[base_idx + 2],
                                    height: output_data[base_idx + 3],
                                }),
                                anomaly_score: None,
                            });
                        }
                    }
                }
            },
            ModelType::TimeSeriesAnomaly => {
                // Extract anomaly scores
                let output_data: Vec<f32> = outputs[0].try_extract_tensor()?.view().iter().copied().collect();
                
                for (idx, &anomaly_score) in output_data.iter().enumerate() {
                    if anomaly_score >= model.confidence_threshold {
                        predictions.push(Prediction {
                            label: format!("anomaly_{}", idx),
                            confidence: anomaly_score,
                            bounding_box: None,
                            anomaly_score: Some(anomaly_score),
                        });
                    }
                }
            },
            ModelType::MultiModalFusion => {
                // Multi-modal fusion output processing
                let output_data: Vec<f32> = outputs[0].try_extract_tensor()?.view().iter().copied().collect();
                
                if !output_data.is_empty() {
                    let confidence = output_data[0]; // Assuming single output score
                    
                    if confidence >= model.confidence_threshold {
                        predictions.push(Prediction {
                            label: "multi_modal_leak".to_string(),
                            confidence,
                            bounding_box: None,
                            anomaly_score: Some(confidence),
                        });
                    }
                }
            }
        }

        // Sort by confidence descending
        predictions.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap_or(std::cmp::Ordering::Equal));
        
        Ok(predictions)
    }

    /// Create result metadata for audit trail
    async fn create_result_metadata(&self, input: &InferenceInput) -> ResultMetadata {
        let input_id = match input {
            InferenceInput::Image { metadata, .. } => format!("img_{}_{}", metadata.camera_id, metadata.timestamp),
            InferenceInput::TimeSeries { metadata, .. } => format!("ts_{}_{}", metadata.sensor_id, chrono::Utc::now().timestamp()),
            InferenceInput::MultiModal { metadata, .. } => format!("mm_{}_{}", metadata.image_meta.camera_id, metadata.image_meta.timestamp),
        };

        ResultMetadata {
            input_id,
            timestamp: chrono::Utc::now().timestamp(),
            model_version: "1.0.0".to_string(), // TODO: Get from model metadata
            edge_device: std::env::var("DEVICE_NAME").unwrap_or_else(|_| "unknown_device".to_string()),
        }
    }

    /// Get loaded model information
    pub async fn get_loaded_models(&self) -> Vec<String> {
        let models = self.models.read().await;
        models.iter().map(|m| m.name.clone()).collect()
    }

    /// Remove a loaded model
    pub async fn unload_model(&self, name: &str) -> Result<(), Box<dyn Error>> {
        let mut models = self.models.write().await;
        let initial_len = models.len();
        models.retain(|m| m.name != name);
        
        if models.len() < initial_len {
            info!("Model {} unloaded successfully", name);
            Ok(())
        } else {
            Err(format!("Model {} not found", name).into())
        }
    }
}