use ai_edge_inference_crate::backend::{BackendFactory, BackendConfig, BackendType, DeviceType, OptimizationLevel};

#[tokio::main]
async fn main() {
    println!("🧪 Testing no-features scenario...");
    
    let config = BackendConfig {
        backend_type: BackendType::Auto,
        device_type: DeviceType::Cpu,
        model_directory: "/tmp/models".to_string(),
        cache_size_mb: 512,
        enable_optimization: true,
        optimization_level: OptimizationLevel::All,
        parallel_execution: false,
        onnx_config: None,
        candle_config: None,
    };

    let available_backends = BackendFactory::available_backends();
    println!("🔍 Available backends: {:?}", available_backends);

    if available_backends.is_empty() {
        println!("⚠️  No backends available - testing error handling");
        let result = BackendFactory::create_backend(&config).await;
        
        match result {
            Ok(_) => {
                println!("❌ Unexpected success - should have failed!");
                std::process::exit(1);
            }
            Err(error) => {
                println!("✅ Correctly failed with error: {}", error);
                if error.to_string().contains("No suitable backend available") {
                    println!("✅ Error message is correct");
                    println!("🎯 No-features fallback behavior working correctly!");
                } else {
                    println!("❌ Wrong error message: {}", error);
                    std::process::exit(1);
                }
            }
        }
    } else {
        println!("⚠️  Expected no backends, but found: {:?}", available_backends);
        println!("This test is designed for a no-features build");
    }
}