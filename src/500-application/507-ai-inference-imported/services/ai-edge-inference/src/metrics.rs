use std::error::Error;
use std::sync::Arc;
use tokio::net::TcpListener;
use tokio::sync::RwLock;
use warp::{Filter, Reply};
use serde::{Deserialize, Serialize};
use tracing::{info, warn, error};
use crate::inference::InferenceEngine;
use crate::models::ModelManager;

/// Metrics and health monitoring service
pub struct MetricsService {
    inference_engine: Arc<InferenceEngine>,
    model_manager: Arc<ModelManager>,
    metrics_data: Arc<RwLock<MetricsData>>,
    port: u16,
}

/// System metrics data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MetricsData {
    pub system_info: SystemInfo,
    pub inference_metrics: InferenceMetrics,
    pub model_metrics: Vec<ModelMetrics>,
    pub resource_usage: ResourceUsage,
    pub last_updated: i64,
}

/// System information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemInfo {
    pub service_name: String,
    pub version: String,
    pub uptime_seconds: u64,
    pub device_name: String,
    pub location: Option<(f64, f64)>,
}

/// Inference performance metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceMetrics {
    pub total_inferences: u64,
    pub successful_inferences: u64,
    pub failed_inferences: u64,
    pub avg_inference_time_ms: f32,
    pub min_inference_time_ms: f32,
    pub max_inference_time_ms: f32,
    pub last_inference_time: Option<i64>,
    pub throughput_per_minute: f32,
}

/// Per-model metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelMetrics {
    pub model_name: String,
    pub inference_count: u64,
    pub avg_confidence: f32,
    pub high_confidence_rate: f32, // Percentage above 0.8
    pub avg_processing_time_ms: f32,
    pub memory_usage_mb: f32,
}

/// Resource usage metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceUsage {
    pub cpu_usage_percent: f32,
    pub memory_usage_mb: f32,
    pub memory_total_mb: f32,
    pub disk_usage_mb: f32,
    pub disk_total_mb: f32,
    pub gpu_usage_percent: Option<f32>,
    pub gpu_memory_mb: Option<f32>,
}

/// Health check response
#[derive(Debug, Serialize)]
pub struct HealthResponse {
    pub status: HealthStatus,
    pub timestamp: i64,
    pub checks: Vec<HealthCheck>,
    pub uptime_seconds: u64,
}

/// Health status enum
#[derive(Debug, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum HealthStatus {
    Healthy,
    Degraded,
    Unhealthy,
}

/// Individual health check
#[derive(Debug, Serialize)]
pub struct HealthCheck {
    pub name: String,
    pub status: HealthStatus,
    pub message: String,
    pub response_time_ms: Option<u64>,
}

impl MetricsService {
    /// Create new metrics service
    pub async fn new(
        inference_engine: Arc<InferenceEngine>,
        model_manager: Arc<ModelManager>,
        port: u16,
    ) -> Result<Self, Box<dyn Error>> {
        let metrics_data = Arc::new(RwLock::new(MetricsData::default()));

        let service = Self {
            inference_engine,
            model_manager,
            metrics_data,
            port,
        };

        Ok(service)
    }

    /// Start the metrics HTTP server
    pub async fn start_server(&self) -> Result<(), Box<dyn Error>> {
        info!("Starting metrics server on port {}", self.port);

        let metrics_data = Arc::clone(&self.metrics_data);
        let inference_engine = Arc::clone(&self.inference_engine);
        let model_manager = Arc::clone(&self.model_manager);

        // Health endpoint
        let health = warp::path("health")
            .and(warp::get())
            .and(warp::any().map(move || Arc::clone(&inference_engine)))
            .and(warp::any().map(move || Arc::clone(&model_manager)))
            .and_then(handle_health_check);

        // Metrics endpoint
        let metrics = warp::path("metrics")
            .and(warp::get())
            .and(warp::any().map(move || Arc::clone(&metrics_data)))
            .and_then(handle_metrics);

        // Readiness endpoint
        let ready = warp::path("ready")
            .and(warp::get())
            .and(warp::any().map(move || Arc::clone(&inference_engine)))
            .and_then(handle_readiness);

        // Liveness endpoint
        let live = warp::path("live")
            .and(warp::get())
            .map(|| warp::reply::with_status("OK", warp::http::StatusCode::OK));

        let routes = health.or(metrics).or(ready).or(live);

        // Start the server
        let addr = ([0, 0, 0, 0], self.port);
        info!("Metrics server listening on http://{}", format!("{}:{}", "0.0.0.0", self.port));
        
        warp::serve(routes).run(addr).await;
        
        Ok(())
    }

    /// Start metrics collection background task
    pub async fn start_metrics_collection(&self) -> Result<(), Box<dyn Error>> {
        info!("Starting metrics collection background task");

        let metrics_data = Arc::clone(&self.metrics_data);
        let inference_engine = Arc::clone(&self.inference_engine);
        let model_manager = Arc::clone(&self.model_manager);

        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(30));
            
            loop {
                interval.tick().await;
                
                match collect_metrics(&inference_engine, &model_manager).await {
                    Ok(new_metrics) => {
                        let mut data = metrics_data.write().await;
                        *data = new_metrics;
                    }
                    Err(e) => {
                        error!("Failed to collect metrics: {}", e);
                    }
                }
            }
        });

        Ok(())
    }

    /// Get current metrics data
    pub async fn get_metrics(&self) -> MetricsData {
        let data = self.metrics_data.read().await;
        data.clone()
    }

    /// Record inference metrics
    pub async fn record_inference(&self, processing_time_ms: u64, success: bool, confidence: f32, model_name: &str) {
        let mut data = self.metrics_data.write().await;
        
        // Update inference metrics
        data.inference_metrics.total_inferences += 1;
        if success {
            data.inference_metrics.successful_inferences += 1;
        } else {
            data.inference_metrics.failed_inferences += 1;
        }

        // Update timing metrics
        let time_ms = processing_time_ms as f32;
        if data.inference_metrics.total_inferences == 1 {
            data.inference_metrics.avg_inference_time_ms = time_ms;
            data.inference_metrics.min_inference_time_ms = time_ms;
            data.inference_metrics.max_inference_time_ms = time_ms;
        } else {
            data.inference_metrics.avg_inference_time_ms = 
                (data.inference_metrics.avg_inference_time_ms * (data.inference_metrics.total_inferences - 1) as f32 + time_ms) 
                / data.inference_metrics.total_inferences as f32;
            data.inference_metrics.min_inference_time_ms = data.inference_metrics.min_inference_time_ms.min(time_ms);
            data.inference_metrics.max_inference_time_ms = data.inference_metrics.max_inference_time_ms.max(time_ms);
        }

        data.inference_metrics.last_inference_time = Some(chrono::Utc::now().timestamp());

        // Update model-specific metrics
        if let Some(model_metrics) = data.model_metrics.iter_mut().find(|m| m.model_name == model_name) {
            model_metrics.inference_count += 1;
            model_metrics.avg_confidence = 
                (model_metrics.avg_confidence * (model_metrics.inference_count - 1) as f32 + confidence) 
                / model_metrics.inference_count as f32;
            
            if confidence > 0.8 {
                model_metrics.high_confidence_rate = 
                    (model_metrics.high_confidence_rate * (model_metrics.inference_count - 1) as f32 + 1.0) 
                    / model_metrics.inference_count as f32;
            }
            
            model_metrics.avg_processing_time_ms = 
                (model_metrics.avg_processing_time_ms * (model_metrics.inference_count - 1) as f32 + time_ms) 
                / model_metrics.inference_count as f32;
        } else {
            // Add new model metrics
            data.model_metrics.push(ModelMetrics {
                model_name: model_name.to_string(),
                inference_count: 1,
                avg_confidence: confidence,
                high_confidence_rate: if confidence > 0.8 { 1.0 } else { 0.0 },
                avg_processing_time_ms: time_ms,
                memory_usage_mb: 0.0, // TODO: Measure actual memory usage
            });
        }

        data.last_updated = chrono::Utc::now().timestamp();
    }
}

impl Default for MetricsData {
    fn default() -> Self {
        Self {
            system_info: SystemInfo {
                service_name: "ai-edge-inference".to_string(),
                version: env!("CARGO_PKG_VERSION").to_string(),
                uptime_seconds: 0,
                device_name: std::env::var("DEVICE_NAME").unwrap_or_else(|_| "unknown".to_string()),
                location: None,
            },
            inference_metrics: InferenceMetrics {
                total_inferences: 0,
                successful_inferences: 0,
                failed_inferences: 0,
                avg_inference_time_ms: 0.0,
                min_inference_time_ms: 0.0,
                max_inference_time_ms: 0.0,
                last_inference_time: None,
                throughput_per_minute: 0.0,
            },
            model_metrics: Vec::new(),
            resource_usage: ResourceUsage {
                cpu_usage_percent: 0.0,
                memory_usage_mb: 0.0,
                memory_total_mb: 0.0,
                disk_usage_mb: 0.0,
                disk_total_mb: 0.0,
                gpu_usage_percent: None,
                gpu_memory_mb: None,
            },
            last_updated: chrono::Utc::now().timestamp(),
        }
    }
}

/// Collect current system metrics
async fn collect_metrics(
    inference_engine: &Arc<InferenceEngine>,
    model_manager: &Arc<ModelManager>,
) -> Result<MetricsData, Box<dyn Error>> {
    let mut metrics = MetricsData::default();
    
    // Update system info
    metrics.system_info.uptime_seconds = get_system_uptime();
    
    // Update resource usage
    metrics.resource_usage = collect_resource_usage().await?;
    
    // Update model metrics
    let loaded_models = inference_engine.get_loaded_models().await;
    for model_name in loaded_models {
        if !metrics.model_metrics.iter().any(|m| m.model_name == model_name) {
            metrics.model_metrics.push(ModelMetrics {
                model_name: model_name.clone(),
                inference_count: 0,
                avg_confidence: 0.0,
                high_confidence_rate: 0.0,
                avg_processing_time_ms: 0.0,
                memory_usage_mb: 0.0,
            });
        }
    }
    
    metrics.last_updated = chrono::Utc::now().timestamp();
    
    Ok(metrics)
}

/// Collect resource usage metrics
async fn collect_resource_usage() -> Result<ResourceUsage, Box<dyn Error>> {
    // This is a simplified implementation
    // In production, you'd use system monitoring libraries like `sysinfo`
    
    Ok(ResourceUsage {
        cpu_usage_percent: 0.0, // TODO: Implement actual CPU monitoring
        memory_usage_mb: 0.0,   // TODO: Implement actual memory monitoring
        memory_total_mb: 0.0,   // TODO: Get total system memory
        disk_usage_mb: 0.0,     // TODO: Implement disk usage monitoring
        disk_total_mb: 0.0,     // TODO: Get total disk space
        gpu_usage_percent: None, // TODO: Implement GPU monitoring if available
        gpu_memory_mb: None,     // TODO: Implement GPU memory monitoring
    })
}

/// Get system uptime
fn get_system_uptime() -> u64 {
    // Simplified implementation - in production use proper system calls
    // or libraries like `sysinfo`
    0
}

/// Health check handler
async fn handle_health_check(
    inference_engine: Arc<InferenceEngine>,
    model_manager: Arc<ModelManager>,
) -> Result<impl Reply, warp::Rejection> {
    let start_time = std::time::Instant::now();
    
    let mut checks = Vec::new();
    let mut overall_status = HealthStatus::Healthy;

    // Check inference engine
    let loaded_models = inference_engine.get_loaded_models().await;
    let engine_check = if loaded_models.is_empty() {
        overall_status = HealthStatus::Degraded;
        HealthCheck {
            name: "inference_engine".to_string(),
            status: HealthStatus::Degraded,
            message: "No models loaded".to_string(),
            response_time_ms: Some(start_time.elapsed().as_millis() as u64),
        }
    } else {
        HealthCheck {
            name: "inference_engine".to_string(),
            status: HealthStatus::Healthy,
            message: format!("{} models loaded", loaded_models.len()),
            response_time_ms: Some(start_time.elapsed().as_millis() as u64),
        }
    };
    checks.push(engine_check);

    // Check model directory
    let model_dir = model_manager.get_model_directory();
    let dir_check = if std::path::Path::new(model_dir).exists() {
        HealthCheck {
            name: "model_directory".to_string(),
            status: HealthStatus::Healthy,
            message: "Model directory accessible".to_string(),
            response_time_ms: Some(start_time.elapsed().as_millis() as u64),
        }
    } else {
        overall_status = HealthStatus::Unhealthy;
        HealthCheck {
            name: "model_directory".to_string(),
            status: HealthStatus::Unhealthy,
            message: "Model directory not accessible".to_string(),
            response_time_ms: Some(start_time.elapsed().as_millis() as u64),
        }
    };
    checks.push(dir_check);

    let response = HealthResponse {
        status: overall_status,
        timestamp: chrono::Utc::now().timestamp(),
        checks,
        uptime_seconds: get_system_uptime(),
    };

    Ok(warp::reply::json(&response))
}

/// Metrics handler
async fn handle_metrics(metrics_data: Arc<RwLock<MetricsData>>) -> Result<impl Reply, warp::Rejection> {
    let data = metrics_data.read().await;
    Ok(warp::reply::json(&*data))
}

/// Readiness handler
async fn handle_readiness(inference_engine: Arc<InferenceEngine>) -> Result<impl Reply, warp::Rejection> {
    let loaded_models = inference_engine.get_loaded_models().await;
    
    if loaded_models.is_empty() {
        Ok(warp::reply::with_status(
            "Not ready - no models loaded", 
            warp::http::StatusCode::SERVICE_UNAVAILABLE
        ))
    } else {
        Ok(warp::reply::with_status(
            "Ready", 
            warp::http::StatusCode::OK
        ))
    }
}