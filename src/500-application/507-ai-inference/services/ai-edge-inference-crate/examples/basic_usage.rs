use ai_edge_inference_crate::{
    InferenceEngine, InferenceConfig, InferenceRequest,
    ModelsConfig, HardwareConfig, SiteContext
};
use base64::{Engine as _, engine::general_purpose};
use std::collections::HashMap;
use std::path::PathBuf;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing for logging
    tracing_subscriber::fmt::init();

    println!("🚀 AI Edge Inference Crate - Basic Example");
    println!("==========================================");

    // Create custom configuration for our use case
    let config = create_industrial_config();

    // Initialize the inference engine
    println!("📦 Initializing inference engine...");
    let mut engine = InferenceEngine::new(config).await?;

    // Initialize and load models
    match engine.initialize().await {
        Ok(_) => println!("✅ Engine initialized successfully"),
        Err(e) => {
            println!("❌ Failed to initialize engine: {}", e);
            println!("💡 This is expected if no models are available in /models directory");
            println!("   In production, you would have ONNX models deployed to the models directory");
            return Ok(());
        }
    }

    // Demonstrate model registry operations
    demonstrate_model_management(&engine).await?;

    // Demonstrate inference with mock data
    demonstrate_inference(&engine).await?;

    // Show performance metrics
    demonstrate_metrics(&engine).await?;

    println!("\n🎯 Example completed successfully!");
    println!("Next steps:");
    println!("  1. Deploy ONNX models to the configured models directory");
    println!("  2. Integrate with MQTT publisher service");
    println!("  3. Set up monitoring and alerting");

    Ok(())
}

fn create_industrial_config() -> InferenceConfig {
    InferenceConfig {
        models: ModelsConfig {
            models_directory: PathBuf::from("./models"), // Local models directory
            global_confidence_threshold: 0.6,
            max_predictions_per_model: 5,
            ..Default::default()
        },
        hardware: HardwareConfig {
            use_gpu: true,
            enable_tensorrt: true,
            gpu_memory_limit_mb: Some(2048),
            fallback_to_cpu: true,
            ..Default::default()
        },
        site_context: SiteContext {
            site_id: "example-facility-001".to_string(),
            facility_name: "Demo Industrial AI Site".to_string(),
            business_unit: Some("Digital Innovation Lab".to_string()),
            region: Some("Demo Region".to_string()),
            environmental_data: {
                let mut env = HashMap::new();
                env.insert("temperature_c".to_string(), serde_json::json!(22.5));
                env.insert("humidity_percent".to_string(), serde_json::json!(45.0));
                env.insert("pressure_kpa".to_string(), serde_json::json!(101.3));
                env
            },
            equipment_mapping: {
                let mut eq = HashMap::new();
                eq.insert("camera-001".to_string(), "Main Entrance Camera".to_string());
                eq.insert("sensor-234".to_string(), "Environmental Monitor".to_string());
                eq.insert("pump-007".to_string(), "Primary Circulation Pump".to_string());
                eq
            },
        },
        ..Default::default()
    }
}

async fn demonstrate_model_management(engine: &InferenceEngine) -> Result<(), Box<dyn std::error::Error>> {
    println!("\n🔧 Model Management Demonstration");
    println!("=================================");

    // List currently loaded models
    let models = engine.get_loaded_models().await;
    println!("📋 Currently loaded models: {}", models.len());

    for model_name in &models {
        println!("  • {}", model_name);
    }

    let model_summaries = engine.get_model_summaries();
    for summary in &model_summaries {
        println!("    Summary: {} ({})", summary.name, summary.model_type);
    }

    if models.is_empty() {
        println!("  ℹ️  No models loaded (models directory may be empty)");
        println!("     In production, models would be deployed via GitOps or container updates");
    }

    Ok(())
}

async fn demonstrate_inference(engine: &InferenceEngine) -> Result<(), Box<dyn std::error::Error>> {
    println!("\n🎯 Inference Demonstration");
    println!("==========================");

    // Create a mock inference request
    let request = create_mock_inference_request();

    println!("📤 Sending inference request:");
    println!("  Request ID: {}", request.request_id);
    println!("  Model: {:?}", request.model_name);
    println!("  Input Type: {}", request.input_type);
    println!("  Data Size: {} bytes", request.input_data.len());

    // Attempt inference
    match engine.infer(request).await {
        Ok(result) => {
            println!("✅ Inference completed successfully!");

            // Display results in a structured way
            println!("📊 Results:");
            println!("  Processing Time: {:.2}ms", result.inference_time_ms);
            println!("  Confidence: {:.3}", result.confidence);

            for (j, prediction) in result.predictions.iter().enumerate() {
                println!("    Prediction {}: {} (confidence: {:.3})",
                    j + 1, prediction.class, prediction.confidence);

                if let Some(bbox) = &prediction.bbox {
                    println!("      Bounding Box: [{:.3}, {:.3}, {:.3}, {:.3}]",
                        bbox[0], bbox[1], bbox[2], bbox[3]);
                }
            }

            // Show JSON serialization for MQTT
            println!("\n📡 JSON for MQTT Publishing:");
            let json_output = serde_json::to_string_pretty(&result)?;
            println!("{}", json_output);
        }
        Err(e) => {
            println!("❌ Inference failed: {}", e);
            println!("💡 This is expected without actual models deployed");

            // Show error handling approach
            match e {
                ai_edge_inference_crate::InferenceError::Model { message } => {
                    println!("🔄 Recovery suggestion: Deploy model or use fallback ({})", message);
                }
                ai_edge_inference_crate::InferenceError::Configuration { message } => {
                    println!("⚙️  Configuration issue: {}", message);
                }
                _ => {
                    println!("🛠️  General error handling would go here");
                }
            }
        }
    }

    Ok(())
}

async fn demonstrate_metrics(engine: &InferenceEngine) -> Result<(), Box<dyn std::error::Error>> {
    println!("\n📈 Performance Metrics");
    println!("======================");

    let metrics = engine.get_metrics().await;

    println!("🔢 Inference Statistics:");
    println!("  Total Inferences: {}", metrics.total_inferences);
    println!("  Successful: {}", metrics.successful_inferences);
    println!("  Failed: {}", metrics.failed_inferences);

    if metrics.total_inferences > 0 {
        let success_rate = metrics.successful_inferences as f64 / metrics.total_inferences as f64 * 100.0;
        println!("  Success Rate: {:.1}%", success_rate);
        println!("  Average Processing Time: {:.2}ms", metrics.average_inference_time_ms);
    }

    println!("\n📊 Model Usage:");
    if metrics.model_usage_count.is_empty() {
        println!("  No model usage recorded yet");
    } else {
        for (model_name, count) in &metrics.model_usage_count {
            println!("  {}: {} inferences", model_name, count);
        }
    }

    println!("\n🚨 Error Analysis:");
    if metrics.error_count_by_type.is_empty() {
        println!("  No errors recorded");
    } else {
        for (error_type, count) in &metrics.error_count_by_type {
            println!("  {}: {} occurrences", error_type, count);
        }
    }

    println!("  Last Reset: {}", metrics.last_reset.format("%Y-%m-%d %H:%M:%S UTC"));

    Ok(())
}

fn create_mock_inference_request() -> InferenceRequest {
    // Create a small mock base64 image (1x1 pixel JPEG)
    let mock_image_bytes = vec![
        255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 1, 0, 72, 0, 72, 0, 0, 255, 219, 0, 67, 0, 8, 6, 6, 7, 6, 5, 8, 7, 7, 7, 9, 9, 8, 10, 12, 20, 13, 12, 11, 11, 12, 25, 18, 19, 15, 20, 29, 26, 31, 30, 29, 26, 28, 28, 32, 36, 46, 39, 32, 34, 44, 35, 28, 28, 40, 55, 41, 44, 48, 49, 52, 52, 52, 31, 39, 57, 61, 56, 50, 60, 46, 51, 52, 50, 255, 192, 0, 17, 8, 0, 1, 0, 1, 1, 1, 17, 0, 2, 17, 1, 3, 17, 1, 255, 196, 0, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 255, 196, 0, 20, 16, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 218, 0, 12, 3, 1, 0, 2, 17, 3, 17, 0, 63, 0, 146, 255, 217
    ];

    let base64_data = general_purpose::STANDARD.encode(&mock_image_bytes);

    InferenceRequest {
        request_id: format!("demo-{}", uuid::Uuid::new_v4()),
        model_name: Some("industrial-safety-vision".to_string()),
        input_data: base64_data,
        input_type: "image/jpeg".to_string(),
        metadata: {
            let mut meta = HashMap::new();
            meta.insert("source".to_string(), serde_json::Value::String("demo_camera_001".to_string()));
            meta.insert("location".to_string(), serde_json::Value::String("main_entrance".to_string()));
            meta.insert("timestamp".to_string(), serde_json::Value::String(
                chrono::Utc::now().to_rfc3339()
            ));
            meta
        },
    }
}
