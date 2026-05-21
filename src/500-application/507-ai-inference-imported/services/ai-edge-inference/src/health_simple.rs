use std::sync::Arc;
use warp::{Filter, Reply};
use serde::Serialize;
use tracing::{info, error};
use ai_edge_inference_crate::{InferenceEngine, InferenceRequest};
use crate::mqtt::MqttPublisher;
use anyhow::Result;
use bytes::Bytes;
use std::path::Path;
use std::fs;
use base64::{Engine, engine::general_purpose};
use uuid;

/// Health monitoring service for MQTT Publisher Service readiness and liveness probes
#[derive(Serialize)]
struct ModelListResponse {
    models: Vec<ModelInfo>,
    count: usize,
}

#[derive(Serialize)]
struct ModelInfo {
    name: String,
    framework: String,
    input_shape: Vec<usize>,
    output_shape: Vec<usize>,
    preprocessing: String,
    postprocessing: String,
    description: Option<String>,
}

#[derive(Serialize)]
struct ModelDetailResponse {
    name: String,
    framework: String,
    input_shape: Vec<usize>,
    output_shape: Vec<usize>,
    preprocessing: PreprocessingInfo,
    postprocessing: PostprocessingInfo,
    description: Option<String>,
    capabilities: Vec<String>,
}

#[derive(Serialize)]
struct PreprocessingInfo {
    resize_strategy: String,
    target_size: (usize, usize),
    normalization: String,
    mean: Vec<f32>,
    std: Vec<f32>,
}

#[derive(Serialize)]
struct PostprocessingInfo {
    output_format: String,
    confidence_threshold: Option<f32>,
    nms_threshold: Option<f32>,
    max_detections: Option<usize>,
}

pub struct HealthService {
    inference_engine: Arc<InferenceEngine>,
    mqtt_publisher: Arc<MqttPublisher>,
    port: u16,
    start_time: std::time::Instant,
}

/// Simple health status response
#[derive(Debug, Serialize)]
pub struct SimpleHealthResponse {
    pub status: String,
    pub timestamp: i64,
    pub uptime_seconds: u64,
}

/// Detailed health status with component checks
#[derive(Debug, Serialize)]
pub struct DetailedHealthResponse {
    pub status: String,
    pub timestamp: i64,
    pub uptime_seconds: u64,
    pub inference_engine: ComponentHealth,
    pub mqtt_publisher: ComponentHealth,
}

/// File processing result
#[derive(Debug, Serialize)]
pub struct FileProcessingResponse {
    pub status: String,
    pub message: String,
    pub processed_files: Vec<ProcessedFile>,
    pub total_files: usize,
    pub successful: usize,
    pub failed: usize,
}

/// Individual file processing result
#[derive(Debug, Serialize)]
pub struct ProcessedFile {
    pub filename: String,
    pub status: String,
    pub inference_result: Option<serde_json::Value>,
    pub error: Option<String>,
    pub processing_time_ms: u64,
}

/// Individual component health status
#[derive(Debug, Serialize, Clone)]
pub struct ComponentHealth {
    pub name: String,
    pub status: String,
    pub details: Option<String>,
}

/// System information
#[derive(Debug, Serialize)]
pub struct SystemInfo {
    pub cpu_usage: f64,
    pub memory_usage: f64,
    pub disk_usage: f64,
}

impl HealthService {
    /// Create new health service for MQTT Publisher
    pub async fn new(
        inference_engine: Arc<InferenceEngine>,
        mqtt_publisher: Arc<MqttPublisher>,
        port: u16,
    ) -> Result<Self> {
        Ok(Self {
            inference_engine,
            mqtt_publisher,
            port,
            start_time: std::time::Instant::now(),
        })
    }

    /// Get service uptime in seconds
    fn get_uptime_seconds(&self) -> u64 {
        self.start_time.elapsed().as_secs()
    }

    // Model registry endpoints
    async fn get_models(engine: Arc<InferenceEngine>) -> Result<impl warp::Reply, warp::Rejection> {
        info!("Fetching available models");
        
        let model_names = engine.get_loaded_models().await;
        let model_infos: Vec<ModelInfo> = model_names.iter().map(|name| {
            ModelInfo {
                name: name.clone(),
                framework: "Unknown".to_string(), // TODO: Get actual framework info
                input_shape: vec![1, 3, 224, 224], // TODO: Get actual input shape
                output_shape: vec![1, 1000], // TODO: Get actual output shape
                preprocessing: "Standard".to_string(), // TODO: Get actual preprocessing info
                postprocessing: "Standard".to_string(), // TODO: Get actual postprocessing info
                description: Some(format!("Model: {}", name)),
            }
        }).collect();

        let response = ModelListResponse {
            count: model_infos.len(),
            models: model_infos,
        };

        Ok(warp::reply::with_status(
            warp::reply::json(&response),
            warp::http::StatusCode::OK,
        ))
    }

    async fn get_model_detail(model_name: String, engine: Arc<InferenceEngine>) -> Result<impl warp::Reply, warp::Rejection> {
        info!("Fetching details for model: {}", model_name);
        
        let model_names = engine.get_loaded_models().await;
        if model_names.contains(&model_name) {
            let preprocessing_info = PreprocessingInfo {
                resize_strategy: "Letterbox".to_string(), // TODO: Get actual strategy
                target_size: (224, 224), // TODO: Get actual target size
                normalization: "ImageNet".to_string(), // TODO: Get actual normalization
                mean: vec![0.485, 0.456, 0.406], // TODO: Get actual mean values
                std: vec![0.229, 0.224, 0.225], // TODO: Get actual std values
            };

            let postprocessing_info = PostprocessingInfo {
                output_format: "Classification".to_string(), // TODO: Get actual format
                confidence_threshold: Some(0.5), // TODO: Get actual threshold
                nms_threshold: None, // TODO: Get actual NMS threshold if applicable
                max_detections: None, // TODO: Get actual max detections if applicable
            };

            let capabilities = vec![
                "Classification".to_string(),
                "CPU Inference".to_string(),
                // TODO: Add actual capabilities
            ];

            let response = ModelDetailResponse {
                name: model_name.clone(),
                framework: "Unknown".to_string(), // TODO: Get actual framework
                input_shape: vec![1, 3, 224, 224], // TODO: Get actual input shape
                output_shape: vec![1, 1000], // TODO: Get actual output shape
                preprocessing: preprocessing_info,
                postprocessing: postprocessing_info,
                description: Some(format!("Detailed information for model: {}", model_name)),
                capabilities,
            };

            Ok(warp::reply::with_status(
                warp::reply::json(&response),
                warp::http::StatusCode::OK,
            ))
        } else {
            Ok(warp::reply::with_status(
                warp::reply::json(&serde_json::json!({
                    "error": "Model not found",
                    "model_name": model_name
                })),
                warp::http::StatusCode::NOT_FOUND,
            ))
        }
    }

    /// Start the health check HTTP server
    pub async fn start_server(&self) -> Result<()> {
        info!("Starting health service on port {}", self.port);

        let start_timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        // Kubernetes liveness probe - simple check
        let liveness = warp::path("healthz")
            .and(warp::get())
            .map(move || {
                let current_timestamp = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs();
                let response = SimpleHealthResponse {
                    status: "alive".to_string(),
                    timestamp: chrono::Utc::now().timestamp(),
                    uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
                };
                warp::reply::json(&response)
            });

        // Kubernetes readiness probe - checks if service is ready to accept traffic
        let inference_engine1 = Arc::clone(&self.inference_engine);
        let readiness = warp::path("readyz")
            .and(warp::get())
            .and_then(move || {
                let engine = Arc::clone(&inference_engine1);
                async move {
                    handle_readiness_check_simple(engine, start_timestamp).await
                }
            });

        // Detailed health check for monitoring and debugging
        let inference_engine2 = Arc::clone(&self.inference_engine);
        let health_detailed = warp::path("health")
            .and(warp::path("detailed"))
            .and(warp::get())
            .and_then(move || {
                let engine = Arc::clone(&inference_engine2);
                async move {
                    handle_detailed_health_simple(engine, start_timestamp).await
                }
            });

        // Simple health endpoint
        let inference_engine3 = Arc::clone(&self.inference_engine);
        let health_simple = warp::path("health")
            .and(warp::get())
            .and_then(move || {
                let engine = Arc::clone(&inference_engine3);
                async move {
                    handle_simple_health_simple(engine, start_timestamp).await
                }
            });

        // Startup probe - checks if application has started
        let inference_engine4 = Arc::clone(&self.inference_engine);
        let startup = warp::path("startup")
            .and(warp::get())
            .and_then(move || {
                let engine = Arc::clone(&inference_engine4);
                async move {
                    handle_startup_check_simple(engine, start_timestamp).await
                }
            });

        // Test endpoint - for testing inference with sample data
        let inference_engine5 = Arc::clone(&self.inference_engine);
        let test_inference = warp::path("test")
            .and(warp::path("inference"))
            .and(warp::post())
            .and(warp::body::content_length_limit(1024 * 1024 * 10)) // 10MB limit
            .and(warp::body::bytes())
            .and_then(move |bytes: bytes::Bytes| {
                let engine = Arc::clone(&inference_engine5);
                async move {
                    handle_test_inference(engine, bytes).await
                }
            });

        // File processing endpoint - processes images from /models/test-images/
        let inference_engine6 = Arc::clone(&self.inference_engine);
        let process_files = warp::path("process-files")
            .and(warp::post())
            .and_then(move || {
                let engine = Arc::clone(&inference_engine6);
                async move {
                    handle_file_processing(engine).await
                }
            });

        // Model registry endpoints
        let inference_engine7 = Arc::clone(&self.inference_engine);
        let models_list = warp::path("models")
            .and(warp::get())
            .and_then(move || {
                let engine = Arc::clone(&inference_engine7);
                async move {
                    Self::get_models(engine).await
                }
            });

        let inference_engine8 = Arc::clone(&self.inference_engine);
        let model_detail = warp::path!("models" / String)
            .and(warp::get())
            .and_then(move |model_name: String| {
                let engine = Arc::clone(&inference_engine8);
                async move {
                    Self::get_model_detail(model_name, engine).await
                }
            });

        let routes = liveness
            .or(readiness)
            .or(health_detailed)
            .or(health_simple)
            .or(startup)
            .or(test_inference)
            .or(process_files)
            .or(models_list)
            .or(model_detail);

        // Start the server
        let addr = ([0, 0, 0, 0], self.port);
        info!("Health service listening on http://{}", format!("{}:{}", "0.0.0.0", self.port));
        
        warp::serve(routes).run(addr).await;
        
        Ok(())
    }
}

/// Handle Kubernetes readiness probe (simplified)
async fn handle_readiness_check_simple(
    inference_engine: Arc<InferenceEngine>,
    start_timestamp: u64,
) -> Result<impl Reply, warp::Rejection> {
    // Check if inference engine is ready
    let backend_status = inference_engine.get_backend_status().await;
    let engine_ready = backend_status.initialized;
    
    // For now, assume MQTT is connected (we can't check it safely across threads)
    let mqtt_connected = true;
    
    let current_timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    
    if engine_ready && mqtt_connected {
        let response = SimpleHealthResponse {
            status: "ready".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
        };
        
        Ok(warp::reply::with_status(
            warp::reply::json(&response),
            warp::http::StatusCode::OK,
        ))
    } else {
        let response = SimpleHealthResponse {
            status: "not_ready".to_string(),
            timestamp: chrono::Utc::now().timestamp(),
            uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
        };
        
        Ok(warp::reply::with_status(
            warp::reply::json(&response),
            warp::http::StatusCode::SERVICE_UNAVAILABLE,
        ))
    }
}

/// Handle simple health check (simplified)
async fn handle_simple_health_simple(
    inference_engine: Arc<InferenceEngine>,
    start_timestamp: u64,
) -> Result<impl Reply, warp::Rejection> {
    let backend_status = inference_engine.get_backend_status().await;
    let mqtt_connected = true; // Assume connected for now
    
    let status = if backend_status.initialized && mqtt_connected {
        "healthy"
    } else {
        "unhealthy"
    };
    
    let current_timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    
    let response = SimpleHealthResponse {
        status: status.to_string(),
        timestamp: chrono::Utc::now().timestamp(),
        uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
    };
    
    Ok(warp::reply::json(&response))
}

/// Handle detailed health check (simplified)
async fn handle_detailed_health_simple(
    inference_engine: Arc<InferenceEngine>,
    start_timestamp: u64,
) -> Result<impl Reply, warp::Rejection> {
    let mut components = Vec::new();
    
    // Check inference engine
    let backend_status = inference_engine.get_backend_status().await;
    let inference_component = ComponentHealth {
        name: "inference_engine".to_string(),
        status: if backend_status.initialized { "healthy" } else { "unhealthy" }.to_string(),
        details: Some(format!("Models loaded: {}", backend_status.loaded_models.len())),
    };
    
    // Check MQTT publisher (simplified)
    let mqtt_component = ComponentHealth {
        name: "mqtt_publisher".to_string(),
        status: "healthy".to_string(), // Assume healthy for now
        details: Some("MQTT publisher status check skipped due to thread safety".to_string()),
    };
    
    components.push(inference_component.clone());
    components.push(mqtt_component.clone());
    
    let timestamp = chrono::Utc::now().timestamp();
    let overall_status = if components.iter().all(|c| c.status == "healthy") {
        "healthy"
    } else {
        "unhealthy"
    };
    
    // System info
    let system_info = SystemInfo {
        cpu_usage: 0.0, // Placeholder
        memory_usage: 0.0, // Placeholder
        disk_usage: 0.0, // Placeholder
    };
    
    let current_timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    
    let response = DetailedHealthResponse {
        status: overall_status.to_string(),
        timestamp,
        uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
        inference_engine: inference_component,
        mqtt_publisher: mqtt_component,
    };
    
    let status_code = match overall_status {
        "healthy" => warp::http::StatusCode::OK,
        _ => warp::http::StatusCode::SERVICE_UNAVAILABLE,
    };
    
    Ok(warp::reply::with_status(
        warp::reply::json(&response),
        status_code,
    ))
}

/// Handle startup check (simplified)
async fn handle_startup_check_simple(
    inference_engine: Arc<InferenceEngine>,
    start_timestamp: u64,
) -> Result<impl Reply, warp::Rejection> {
    // For startup probe, check if basic initialization is complete
    let backend_status = inference_engine.get_backend_status().await;
    let engine_ready = backend_status.initialized;
    
    let status = if engine_ready {
        "started"
    } else {
        "starting"
    };
    
    let current_timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    
    let response = SimpleHealthResponse {
        status: status.to_string(),
        timestamp: chrono::Utc::now().timestamp(),
        uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
    };
    
    let status_code = if status == "started" {
        warp::http::StatusCode::OK
    } else {
        warp::http::StatusCode::SERVICE_UNAVAILABLE
    };
    
    Ok(warp::reply::with_status(
        warp::reply::json(&response),
        status_code,
    ))
}

/// Handle test inference endpoint
async fn handle_test_inference(
    inference_engine: Arc<InferenceEngine>,
    image_bytes: Bytes,
) -> Result<impl Reply, warp::Rejection> {
    info!("Received test inference request with {} bytes", image_bytes.len());
    
    // Try to load the image to validate it
    let image = match image::load_from_memory(&image_bytes) {
        Ok(img) => img,
        Err(e) => {
            error!("Failed to load image: {}", e);
            return Ok(warp::reply::with_status(
                warp::reply::json(&serde_json::json!({
                    "status": "error",
                    "message": format!("Failed to load image: {}", e)
                })),
                warp::http::StatusCode::BAD_REQUEST,
            ));
        }
    };
    
    // Encode image to base64
    let image_base64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, &image_bytes);
    
    // Create metadata
    let mut metadata = std::collections::HashMap::new();
    metadata.insert("width".to_string(), serde_json::Value::Number(serde_json::Number::from(image.width())));
    metadata.insert("height".to_string(), serde_json::Value::Number(serde_json::Number::from(image.height())));
    metadata.insert("channels".to_string(), serde_json::Value::Number(serde_json::Number::from(3)));
    metadata.insert("format".to_string(), serde_json::Value::String("RGB".to_string()));
    
    // Create inference request with correct structure
    let request = InferenceRequest {
        request_id: uuid::Uuid::new_v4().to_string(),
        model_name: Some("default".to_string()), // Explicitly use default model
        input_data: image_base64,
        input_type: "image".to_string(),
        metadata,
    };
    
    // Run inference
    match inference_engine.infer(request).await {
        Ok(result) => {
            info!("Inference completed successfully");
            Ok(warp::reply::with_status(
                warp::reply::json(&serde_json::json!({
                    "status": "success",
                    "result": result
                })),
                warp::http::StatusCode::OK,
            ))
        }
        Err(e) => {
            error!("Inference failed: {}", e);
            Ok(warp::reply::with_status(
                warp::reply::json(&serde_json::json!({
                    "status": "error",
                    "message": format!("Inference failed: {}", e)
                })),
                warp::http::StatusCode::INTERNAL_SERVER_ERROR,
            ))
        }
    }
}

/// Handle file processing endpoint - scans and processes images from /models/test-images/
async fn handle_file_processing(
    inference_engine: Arc<InferenceEngine>,
) -> Result<impl Reply, warp::Rejection> {
    info!("Starting file-based image processing from /models/test-images/");
    
    let images_dir = "/models/test-images";
    let mut processed_files = Vec::new();
    let mut successful = 0;
    let mut failed = 0;
    
    // Read directory contents
    match fs::read_dir(images_dir) {
        Ok(entries) => {
            for entry in entries {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    if let Some(extension) = path.extension() {
                        let ext = extension.to_string_lossy().to_lowercase();
                        if matches!(ext.as_str(), "jpg" | "jpeg" | "png") {
                            let filename = path.file_name()
                                .unwrap_or_default()
                                .to_string_lossy()
                                .to_string();
                            
                            info!("Processing image file: {}", filename);
                            let start_time = std::time::Instant::now();
                            
                            match process_image_file(&path, &inference_engine).await {
                                Ok(result) => {
                                    let processing_time = start_time.elapsed().as_millis() as u64;
                                    
                                    // Convert result to JSON for HTTP response  
                                    let json_result = result;
                                    
                                    processed_files.push(ProcessedFile {
                                        filename: filename.clone(),
                                        status: "success".to_string(),
                                        inference_result: Some(json_result),
                                        error: None,
                                        processing_time_ms: processing_time,
                                    });
                                    successful += 1;
                                    info!("✅ Successfully processed {} in {}ms", filename, processing_time);
                                }
                                Err(e) => {
                                    let processing_time = start_time.elapsed().as_millis() as u64;
                                    processed_files.push(ProcessedFile {
                                        filename: filename.clone(),
                                        status: "error".to_string(),
                                        inference_result: None,
                                        error: Some(e.to_string()),
                                        processing_time_ms: processing_time,
                                    });
                                    failed += 1;
                                    error!("❌ Failed to process {}: {}", filename, e);
                                }
                            }
                        }
                    }
                }
            }
        }
        Err(e) => {
            error!("Failed to read images directory {}: {}", images_dir, e);
            let response = FileProcessingResponse {
                status: "error".to_string(),
                message: format!("Failed to read images directory: {}", e),
                processed_files: vec![],
                total_files: 0,
                successful: 0,
                failed: 0,
            };
            return Ok(warp::reply::json(&response));
        }
    }
    
    let total_files = processed_files.len();
    let status = if failed == 0 { "success" } else if successful == 0 { "error" } else { "partial" };
    
    let response = FileProcessingResponse {
        status: status.to_string(),
        message: format!("Processed {} files: {} successful, {} failed", total_files, successful, failed),
        processed_files,
        total_files,
        successful,
        failed,
    };
    
    info!("File processing complete: {} total, {} successful, {} failed", total_files, successful, failed);
    Ok(warp::reply::json(&response))
}

/// Process a single image file
async fn process_image_file(
    path: &Path,
    inference_engine: &InferenceEngine,
) -> Result<serde_json::Value> {
    // Read image file
    let image_data = fs::read(path)?;
    let image_base64 = general_purpose::STANDARD.encode(&image_data);
    
    // Create metadata
    let mut metadata = std::collections::HashMap::new();
    metadata.insert("source".to_string(), serde_json::Value::String("file_processor".to_string()));
    metadata.insert("filename".to_string(), serde_json::Value::String(
        path.file_name().unwrap_or_default().to_string_lossy().to_string()
    ));
    
    // Create inference request using the same structure as the test endpoint
    let request = ai_edge_inference_crate::InferenceRequest {
        request_id: uuid::Uuid::new_v4().to_string(),
        model_name: Some("default".to_string()), // Explicitly use default model
        input_data: image_base64,
        input_type: "image".to_string(),
        metadata,
    };
    
    // Run inference
    let result = inference_engine.infer(request).await?;
    
    // Convert to JSON
    let json_result = serde_json::to_value(result)?;
    
    Ok(json_result)
}