use std::sync::Arc;
use tokio::signal;
use tracing::{info, error, span, Level};
use tracing_subscriber::EnvFilter;
use anyhow::Result;

// Import the AI inference crate
use ai_edge_inference_crate::{
    InferenceEngine
};

mod config;
mod mqtt;
mod topic_router;
mod health_simple;

use config::ComponentConfig;
use mqtt::MqttPublisher;
use topic_router::TopicRouter;
use health_simple::HealthService;

/// Main application entry point for AI Edge MQTT Publisher Service
#[tokio::main]
async fn main() -> Result<()> {
    // Initialize structured logging with environment filter
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    // Create application span for tracing context
    let app_span = span!(Level::INFO, "ai_edge_mqtt_publisher");
    let _enter = app_span.enter();

    info!("Starting AI Edge MQTT Publisher Service v{}", env!("CARGO_PKG_VERSION"));

    // Load configuration from environment
    let config = ComponentConfig::from_env();
    info!("Configuration loaded successfully");

    // Validate configuration
    if let Err(e) = config.validate() {
        error!("Configuration validation failed: {}", e);
        return Err(anyhow::anyhow!("Configuration validation failed: {}", e));
    }
    info!("Configuration validated");

    // Initialize AI inference engine using the crate library
    let inference_config = config.create_inference_config();
    let mut inference_engine = InferenceEngine::new(inference_config).await?;
    
    // Initialize the inference engine and load models
    if let Err(e) = inference_engine.initialize().await {
        error!("Failed to initialize inference engine: {}", e);
        return Err(e.into());
    }
    info!("AI inference engine initialized successfully");
    
    // Wrap in Arc after initialization
    let inference_engine = Arc::new(inference_engine);

    // Initialize topic router for intelligent MQTT topic selection
    let topic_router = Arc::new(TopicRouter::new(config.mqtt.topic_prefix.clone()));
    info!("Topic router initialized");

    // Initialize MQTT publisher with inference engine
    let mut mqtt_publisher = MqttPublisher::new(config.mqtt.clone(), Arc::clone(&inference_engine)).await?;
    mqtt_publisher.set_topic_router(Arc::clone(&topic_router));
    let mqtt_publisher = Arc::new(mqtt_publisher);
    info!("MQTT publisher initialized");

    // Initialize health service
    let health_service = Arc::new(
        HealthService::new(
            Arc::clone(&inference_engine),
            Arc::clone(&mqtt_publisher),
            config.monitoring.health_port,
        ).await?
    );
    info!("Health service initialized");

    // Start background services - run directly to avoid Send/Sync issues
    let health_service_clone = Arc::clone(&health_service);

    // Start main MQTT processing - run directly without spawn to avoid Send/Sync issues
    let mqtt_publisher_clone = Arc::clone(&mqtt_publisher);

    info!("AI Edge MQTT Publisher Service started successfully");
    info!("Health endpoint: http://0.0.0.0:{}/health", config.monitoring.health_port);

    // Wait for any task to complete or shutdown signal
    tokio::select! {
        result = health_service_clone.start_server() => {
            if let Err(e) = result {
                error!("Health server error: {}", e);
            }
        }
        result = mqtt_publisher_clone.start_processing() => {
            if let Err(e) = result {
                error!("MQTT processing error: {}", e);
            }
        }
        _ = signal::ctrl_c() => {
            info!("Received shutdown signal (Ctrl+C)");
        }
    }

    info!("AI Edge MQTT Publisher Service shutting down gracefully");
    
    // Perform cleanup
    cleanup_resources().await;
    
    info!("Shutdown complete");
    Ok(())
}

/// Perform cleanup before shutdown
async fn cleanup_resources() {
    info!("Cleaning up resources...");
    
    // Add any necessary cleanup logic here
    // For example:
    // - Flush pending metrics
    // - Close database connections
    // - Save state to disk
    // - Gracefully disconnect from MQTT broker
    
    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
    info!("Resource cleanup completed");
}