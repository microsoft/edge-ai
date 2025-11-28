# AI Edge Inference Crate

A high-performance Rust library for running AI inference at the edge using both ONNX Runtime and Candle backends. Designed for industrial IoT applications with focus on reliability, performance optimization, and easy integration with messaging systems like MQTT. Features comprehensive backend comparison and performance analysis capabilities.

## Features

- **Dual Backend Architecture**: ONNX Runtime and Candle backends with performance comparison
- **Backend Optimization**: Candle backend achieves 29.5% faster inference (155ms vs 220ms) with reduced memory usage
- **GPU Acceleration**: CUDA and TensorRT support for high-performance inference
- **Multi-Modal AI**: Support for Vision, Audio, Text, and Multimodal models
- **Async/Await**: Non-blocking operations for edge applications
- **Performance Analysis**: Built-in backend comparison and optimization recommendations
- **JSON Serialization**: Results optimized for MQTT publishing and microservices
- **Industrial Context**: Site-specific enrichment and metadata
- **Performance Monitoring**: Built-in metrics and observability with dual backend telemetry
- **Error Recovery**: Comprehensive error handling with recovery suggestions
- **Model Management**: Dynamic loading, unloading, and registry
- **Batch Processing**: Parallel inference for multiple inputs

## Architecture

This crate implements a microservices-friendly architecture:

```text
┌─────────────────────────────────────────────────────────────────┐
│                    AI Edge Inference Crate                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ Vision      │  │ Audio       │  │ Text        │            │
│  │ Processing  │  │ Processing  │  │ Processing  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                           │                                    │
│  ┌─────────────────────────▼─────────────────────────┐         │
│  │          Dual Backend Architecture                │         │
│  │  ┌─────────────────┐    ┌─────────────────┐      │         │
│  │  │ ONNX Runtime    │    │ Candle Backend  │      │         │
│  │  │ (220ms avg)     │    │ (155ms avg)     │      │         │
│  │  └─────────────────┘    └─────────────────┘      │         │
│  │            Performance Comparator                │         │
│  └─────────────────────────────────────────────────┘         │
│                           │                                    │
│  ┌─────────────────────────▼─────────────────────────┐         │
│  │        Model Registry & Configuration             │         │
│  └─────────────────────────────────────────────────┘         │
└─────────────────────────┬───────────────────────────────────────┘
                          │
        JSON Serializable Results + Performance Metrics
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              Enhanced MQTT Publisher Service                   │
│      (Azure IoT Operations SDK + Connection Monitoring)       │
└─────────────────────────────────────────────────────────────────┘
```

## Installation and Setup

### As Part of Edge AI Project

This crate is integrated into the 507-ai-inference application. To use it:

1. **Set up the edge-ai repository** (see [main README](../../../../../README.md))
2. **Navigate to the application**: `cd src/500-application/507-ai-inference`
3. **Build and run**: `docker-compose up --build`

### For External Rust Projects

If using this crate in external projects, add to your `Cargo.toml`:

```toml
[dependencies]
ai-edge-inference-crate = { path = "path/to/edge-ai/src/500-application/507-ai-inference/services/ai-edge-inference-crate" }
tokio = { version = "1.0", features = ["full"] }
serde_json = "1.0"
```

### Directory Structure

```text
507-ai-inference/
├── docker-compose.yaml              # Local development environment
├── services/
│   ├── ai-edge-inference/           # Main Rust service using this crate
│   └── ai-edge-inference-crate/     # This crate ← You are here
├── charts/                          # Kubernetes deployment
└── resources/                       # Models and configuration
```

## Quick Start

### Basic Usage

```rust
use ai_edge_inference_crate::{
    InferenceEngine, InferenceConfig, InferenceRequest
};
use std::collections::HashMap;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Create configuration
    let config = InferenceConfig::default();

    // Initialize inference engine
    let engine = InferenceEngine::new(config);
    engine.initialize().await?;

    // Prepare input data (base64 encoded image)
    let image_data = std::fs::read("safety_inspection.jpg")?;
    let base64_data = base64::encode(&image_data);

    // Create inference request
    let request = InferenceRequest {
        request_id: "inspection-001".to_string(),
        model_name: "industrial-safety-vision".to_string(),
        input_data: base64_data,
        input_type: "image/jpeg".to_string(),
        metadata: HashMap::new(),
    };

    // Run inference
    let result = engine.infer(request).await?;

    // Results are JSON-serializable for MQTT publishing
    let json_output = serde_json::to_string_pretty(&result)?;
    println!("Inference Result:\n{}", json_output);

    // Extract predictions
    for output in &result.outputs {
        for prediction in &output.predictions {
            println!("Detected: {} (confidence: {:.2})",
                prediction.class_name, prediction.confidence);
        }
    }

    Ok(())
}
```

### Batch Processing

```rust
use ai_edge_inference_crate::{InferenceEngine, InferenceRequest};

async fn process_batch(engine: &InferenceEngine) -> Result<(), Box<dyn std::error::Error>> {
    let requests = vec![
        InferenceRequest {
            request_id: "batch-001".to_string(),
            model_name: "industrial-safety-vision".to_string(),
            input_data: base64_image_1,
            input_type: "image/jpeg".to_string(),
            metadata: HashMap::new(),
        },
        InferenceRequest {
            request_id: "batch-002".to_string(),
            model_name: "industrial-safety-vision".to_string(),
            input_data: base64_image_2,
            input_type: "image/jpeg".to_string(),
            metadata: HashMap::new(),
        },
    ];

    // Process all requests in parallel
    let results = engine.infer_batch(requests).await;

    for result in results {
        println!("Request {}: {} predictions",
            result.request_id,
            result.outputs.iter().map(|o| o.predictions.len()).sum::<usize>()
        );
    }

    Ok(())
}
```

### Custom Configuration

```rust
use ai_edge_inference_crate::{
    InferenceConfig, ModelsConfig, HardwareConfig, SiteContext
};
use std::path::PathBuf;
use std::collections::HashMap;

fn create_custom_config() -> InferenceConfig {
    InferenceConfig {
        models: ModelsConfig {
            models_directory: PathBuf::from("/opt/models"),
            global_confidence_threshold: 0.7,
            max_predictions_per_model: 5,
            ..Default::default()
        },
        hardware: HardwareConfig {
            use_gpu: true,
            enable_tensorrt: true,
            gpu_memory_limit_mb: Some(4096),
            fallback_to_cpu: true,
            ..Default::default()
        },
        site_context: SiteContext {
            site_id: "refinery-001".to_string(),
            facility_name: "Main Processing Unit".to_string(),
            business_unit: Some("Downstream Operations".to_string()),
            region: Some("Gulf Coast".to_string()),
            environmental_data: {
                let mut env = HashMap::new();
                env.insert("temperature_c".to_string(),
                    serde_json::Value::Number(25.5.into()));
                env.insert("humidity_percent".to_string(),
                    serde_json::Value::Number(65.0.into()));
                env
            },
            equipment_mapping: {
                let mut eq = HashMap::new();
                eq.insert("pump-001".to_string(), "Main Feed Pump".to_string());
                eq.insert("valve-234".to_string(), "Emergency Shutoff".to_string());
                eq
            },
        },
        ..Default::default()
    }
}
```

## Configuration

### Configuration File Example

```json
{
  "models": {
    "models_directory": "/opt/models",
    "default_models": [
      {
        "name": "industrial-safety-vision",
        "file_path": "object-detection/yolov8n-safety.onnx",
        "model_type": "Vision",
        "version": "1.0.0",
        "auto_load": true,
        "description": "Industrial safety monitoring and PPE compliance detection"
      },
      {
        "name": "environmental-anomaly-detection",
        "file_path": "audio/audio-environmental.onnx",
        "model_type": "Audio",
        "version": "1.0.0",
        "auto_load": true,
        "description": "Environmental sound anomaly detection for facility monitoring"
      }
    ],
    "global_confidence_threshold": 0.5,
    "max_predictions_per_model": 10
  },
  "performance": {
    "enable_parallel_processing": true,
    "batch_size": 4,
    "inference_timeout_ms": 5000,
    "enable_model_caching": true
  },
  "hardware": {
    "use_gpu": true,
    "enable_tensorrt": true,
    "enable_cuda": true,
    "gpu_memory_limit_mb": 2048,
    "fallback_to_cpu": true
  },
  "site_context": {
    "site_id": "pilot-facility-001",
    "facility_name": "Pilot Industrial AI Site",
    "business_unit": "Digital Innovation",
    "region": "North America"
  }
}
```

## Data Types

### InferenceResult Structure

The crate produces JSON-serializable results optimized for MQTT publishing:

```json
{
  "request_id": "inspection-001",
  "model_name": "industrial-safety-vision",
  "model_type": "Vision",
  "model_version": "1.0.0",
  "outputs": [
    {
      "output_type": "predictions",
      "predictions": [
        {
          "class_id": 1,
          "class_name": "safety_helmet",
          "confidence": 0.95,
          "bounding_box": [0.1, 0.1, 0.3, 0.4],
          "attributes": {
            "color": "yellow",
            "compliance_status": "compliant"
          }
        }
      ]
    }
  ],
  "confidence_threshold": 0.5,
  "processing_time_ms": 45,
  "timestamp": "2025-09-15T10:30:00Z",
  "site_context": {
    "site_id": "pilot-facility-001",
    "facility_name": "Pilot Industrial AI Site"
  }
}
```

### Error Handling

Comprehensive error types with recovery suggestions:

```rust
use ai_edge_inference_crate::InferenceError;

match engine.infer(request).await {
    Ok(result) => {
        // Process successful result
        publish_to_mqtt(&result).await?;
    }
    Err(InferenceError::ModelNotFound(model_name)) => {
        // Attempt to load model or fallback to default
        eprintln!("Model {} not found, trying fallback", model_name);
    }
    Err(InferenceError::InferenceTimeout(details)) => {
        // Log timeout and potentially retry with simpler model
        eprintln!("Inference timed out: {}", details);
    }
    Err(InferenceError::GpuMemoryError(details)) => {
        // Switch to CPU or reduce batch size
        eprintln!("GPU memory issue: {}", details);
    }
    Err(e) => {
        eprintln!("Inference error: {}", e);
    }
}
```

## Performance Monitoring

Built-in metrics collection and monitoring:

```rust
// Get current performance metrics
let metrics = engine.get_metrics().await;

println!("Total inferences: {}", metrics.total_inferences);
println!("Success rate: {:.2}%",
    metrics.successful_inferences as f64 / metrics.total_inferences as f64 * 100.0);
println!("Average inference time: {:.2}ms", metrics.average_inference_time_ms);

// Model usage statistics
for (model_name, count) in &metrics.model_usage_count {
    println!("Model {}: {} inferences", model_name, count);
}

// Error analysis
for (error_type, count) in &metrics.error_count_by_type {
    println!("Error {}: {} occurrences", error_type, count);
}
```

## Model Management

Dynamic model loading and management:

```rust
// Get model registry
let registry = engine.get_model_registry();

// List currently loaded models
let models = registry.list_models().await;
for model in models {
    println!("Loaded: {} v{} ({})",
        model.name, model.version, model.model_type);
}

// Load a new model
registry.load_model(
    "custom-detector",
    &PathBuf::from("/models/custom/detector.onnx")
).await?;

// Unload a model to free memory
registry.unload_model("old-model").await?;

// Get model statistics
let stats = registry.get_model_stats().await;
println!("Model memory usage: {:.2} MB",
    stats["estimated_memory_mb"].as_f64().unwrap_or(0.0));
```

## Integration with AI Inference Service

This crate is the core library powering the [507-ai-inference application](../../README.md). The main service (`../ai-edge-inference/`) uses this crate to:

- Process MQTT messages from Azure IoT Operations
- Serve HTTP endpoints for health checks and file processing
- Manage dual backend (ONNX Runtime + Candle) inference
- Provide comprehensive monitoring and observability

### Service Integration Example

```rust
// From the main ai-edge-inference service
use ai_edge_inference_crate::{InferenceEngine, InferenceResult};
use azure_iot_operations::{MqttClient, Topic};

async fn process_mqtt_message(
    engine: &InferenceEngine,
    mqtt_client: &MqttClient,
    message: &[u8]
) -> Result<(), Box<dyn std::error::Error>> {
    // Parse incoming MQTT message
    let request: InferenceRequest = serde_json::from_slice(message)?;

    // Run inference using this crate
    let result = engine.infer(request).await?;

    // Publish results back via MQTT
    let topic = format!("ai-inference/results/{}/{}",
        result.model_name, result.request_id);
    let payload = serde_json::to_string(&result)?;

    mqtt_client.publish(&topic, payload.as_bytes()).await?;
    Ok(())
}
```

### Deployment Integration

The application provides complete deployment automation:

```bash
# Deploy to Kubernetes with monitoring
./services/ai-edge-inference/scripts/deploy.sh

# Test end-to-end functionality
./services/ai-edge-inference/tests/test-mqtt-inference.sh
```

## Supported Model Types

- **Vision Models**: Object detection, classification, segmentation
  - YOLOv8, YOLOv5, ResNet, EfficientNet
  - Industrial safety monitoring, PPE compliance
  - Equipment condition assessment

- **Audio Models**: Environmental sound analysis
  - Anomaly detection in industrial environments
  - Equipment health monitoring via acoustic signatures
  - Safety alert classification

- **Text Models**: Document and alert processing
  - BERT-based models for maintenance logs
  - Alert classification and prioritization
  - Operational procedure compliance

- **Multimodal Models**: Combined input processing
  - Vision + Audio for comprehensive monitoring
  - Text + Image for document analysis

## Hardware Requirements

### Minimum Requirements

- CPU: x86_64 or ARM64
- RAM: 2GB available
- Storage: 1GB for models

### Recommended for GPU Acceleration

- NVIDIA GPU with CUDA Compute Capability 6.1+
- CUDA 11.8+
- TensorRT 8.5+
- GPU Memory: 4GB+

## Prerequisites

This crate is part of the **Microsoft Edge AI Accelerator** project. Before using this crate:

1. **Set up the edge-ai repository** following the [main project README](../../../../../README.md)
2. **Configure your development environment** with the required tools (Docker, Rust, etc.)
3. **Ensure you have the necessary models** in the `/models` directory

## Getting Started

### Quick Local Development

The 507-ai-inference application includes scripts to help you get started quickly:

```bash
# Navigate to the AI inference application
cd src/500-application/507-ai-inference

# Start the complete development environment (includes MQTT broker)
docker-compose up --build

# In another terminal, run deployment script for Kubernetes testing
./services/ai-edge-inference/scripts/deploy.sh

# Test the inference service with MQTT
./services/ai-edge-inference/tests/test-mqtt-inference.sh
```

### Development Workflow

```bash
# From the edge-ai repository root
cd src/500-application/507-ai-inference/services/ai-edge-inference-crate

# Build the crate
cargo build --release

# Run unit tests
cargo test

# Run with GPU features (if CUDA available)
cargo build --release --features="gpu"

# Format and lint
cargo fmt
cargo clippy -- -D warnings
```

### Available Scripts and Testing

The parent application provides several testing and deployment scripts:

#### Local Testing

```bash
# Navigate to application root
cd src/500-application/507-ai-inference

# Test with Docker Compose (local development)
docker-compose up --build
# Then test inference via HTTP or MQTT

# Test specific model inference via MQTT
./services/ai-edge-inference/tests/test-mqtt-inference.sh

# Test dual backend performance (MobileNet)
./services/ai-edge-inference/tests/test-mobilenet-dual-backend.sh

# Test YOLOv2 object detection
./services/ai-edge-inference/tests/test-yolov2-dual-backend.sh
```

#### Kubernetes Deployment Testing

```bash
# Deploy to Kubernetes cluster
./services/ai-edge-inference/scripts/deploy.sh

# Monitor deployment
kubectl get pods -n azure-iot-operations -l app=ai-edge-inference
kubectl logs -f -n azure-iot-operations -l app=ai-edge-inference
```

#### Crate-Specific Testing

```bash
# From the crate directory
cd services/ai-edge-inference-crate

# Unit tests
cargo test

# Integration tests with mock models
cargo test --test integration_tests

# Benchmark tests
cargo bench

# Performance profiling
cargo test --release -- --bench
```
