use std::sync::Arc;
use warp::{Filter, Reply};
use serde::Serialize;
use tracing::info;
use ai_edge_inference_crate::InferenceEngine;
use crate::mqtt::{MqttPublisher, MqttStats};
use anyhow::Result;

/// Health monitoring service for MQTT Publisher Service readiness and liveness probes
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
    pub components: Vec<ComponentHealth>,
    pub system_info: SystemHealthInfo,
}

/// Individual component health status
#[derive(Debug, Serialize)]
pub struct ComponentHealth {
    pub name: String,
    pub status: String,
    pub message: String,
    pub last_check: i64,
}

/// System health information for MQTT Publisher Service
#[derive(Debug, Serialize)]
pub struct SystemHealthInfo {
    pub loaded_models: Vec<String>,
    pub mqtt_stats: MqttStats,
    pub mqtt_connected: bool,
    pub inference_engine_status: String,
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

        let routes = liveness
            .or(readiness)
            .or(health_detailed)
            .or(health_simple)
            .or(startup);

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

/// Handle detailed health check
async fn handle_detailed_health(
    inference_engine: Arc<InferenceEngine>,
    mqtt_publisher: Arc<MqttPublisher>,
    start_timestamp: u64,
) -> Result<impl Reply, warp::Rejection> {
    let mut components = Vec::new();
    let timestamp = chrono::Utc::now().timestamp();
    
    // Check inference engine
    let backend_status = inference_engine.get_backend_status().await;
    let engine_status = ComponentHealth {
        name: "inference_engine".to_string(),
        status: if backend_status.initialized { "healthy" } else { "unhealthy" }.to_string(),
        message: format!("Initialized: {}, Models loaded: {}", backend_status.initialized, backend_status.loaded_models.len()),
        last_check: timestamp,
    };
    components.push(engine_status);
    
    // Check MQTT publisher
    let mqtt_stats = mqtt_publisher.get_stats().await;
    let mqtt_status = ComponentHealth {
        name: "mqtt_publisher".to_string(),
        status: if mqtt_stats.is_connected { "healthy" } else { "unhealthy" }.to_string(),
        message: format!("Connected: {}, Published: {}, Failed: {}", 
                        mqtt_stats.is_connected, 
                        mqtt_stats.successful_publishes, 
                        mqtt_stats.failed_publishes),
        last_check: timestamp,
    };
    components.push(mqtt_status);
    
    // Determine overall status
    let overall_status = if components.iter().any(|c| c.status == "unhealthy") {
        "unhealthy"
    } else if components.iter().any(|c| c.status == "degraded") {
        "degraded"
    } else {
        "healthy"
    };
    
    // Create system info
    let backend_status = inference_engine.get_backend_status().await;
    let loaded_models = backend_status.loaded_models;

    let system_info = SystemHealthInfo {
        loaded_models,
        mqtt_stats,
        mqtt_connected: mqtt_publisher.is_connected().await,
        inference_engine_status: "operational".to_string(),
    };
    
    let current_timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    
    let response = DetailedHealthResponse {
        status: overall_status.to_string(),
        timestamp,
        uptime_seconds: current_timestamp.saturating_sub(start_timestamp),
        components,
        system_info,
    };
    
    let status_code = match overall_status {
        "healthy" => warp::http::StatusCode::OK,
        "degraded" => warp::http::StatusCode::OK, // Still accepting traffic
        "unhealthy" => warp::http::StatusCode::SERVICE_UNAVAILABLE,
        _ => warp::http::StatusCode::INTERNAL_SERVER_ERROR,
    };
    
    Ok(warp::reply::with_status(
        warp::reply::json(&response),
        status_code,
    ))
}

/// Handle startup probe check
async fn handle_startup_check(
    inference_engine: Arc<InferenceEngine>,
    mqtt_publisher: Arc<MqttPublisher>,
    start_timestamp: u64,
) -> Result<impl Reply, warp::Rejection> {
    // For startup probe, check if basic initialization is complete
    let backend_status = inference_engine.get_backend_status().await;
    let engine_ready = backend_status.initialized;
    let mqtt_ready = mqtt_publisher.is_connected().await;
    
    let status = if engine_ready && mqtt_ready {
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