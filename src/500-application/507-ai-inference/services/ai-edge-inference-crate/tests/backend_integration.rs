use ai_edge_inference_crate::backend::{BackendFactory, BackendConfig, BackendType, DeviceType, OptimizationLevel};

#[tokio::test]
async fn test_backend_factory_creation() {
    let config = BackendConfig {
        backend_type: BackendType::Auto,
        device_type: DeviceType::Cpu,
        model_directory: "/tmp/models".to_string(),
        cache_size_mb: 512,
        enable_optimization: true,
        optimization_level: OptimizationLevel::All,
        parallel_execution: false,
        #[cfg(feature = "onnx-runtime")]
        onnx_config: Some(ai_edge_inference_crate::backend::OnnxConfig {
            optimization_level: "all".to_string(),
            inter_op_num_threads: Some(4),
            intra_op_num_threads: Some(4),
            enable_mem_pattern: true,
            enable_cpu_mem_arena: true,
            execution_providers: vec!["CPUExecutionProvider".to_string()],
        }),
        #[cfg(not(feature = "onnx-runtime"))]
        onnx_config: None,
        #[cfg(feature = "candle")]
        candle_config: Some(ai_edge_inference_crate::backend::CandleConfig {
            device_type: ai_edge_inference_crate::backend::DeviceType::Cpu,
            enable_mkl: false,
            enable_cuda: false,
            enable_opengl: false,
        }),
        #[cfg(not(feature = "candle"))]
        candle_config: None,
    };

    let available_backends = BackendFactory::available_backends();
    println!("Available backends: {:?}", available_backends);

    // Test that we can create a backend (will fallback gracefully if no features enabled)
    let result = BackendFactory::create_backend(&config).await;
    
    if available_backends.is_empty() {
        // No backends available, should return an error
        assert!(result.is_err());
        let error = result.unwrap_err();
        assert!(error.to_string().contains("No suitable backend available"));
        println!("✅ Correctly failed when no backends available: {}", error);
    } else {
        // At least one backend available, should succeed
        assert!(result.is_ok());
        println!("✅ Successfully created backend");
    }
}

#[test]
fn test_backend_types() {
    use ai_edge_inference_crate::backend::BackendType;
    
    // Test Display implementation
    assert_eq!(BackendType::OnnxRuntime.to_string(), "ONNX Runtime");
    assert_eq!(BackendType::Candle.to_string(), "Candle");
    assert_eq!(BackendType::Auto.to_string(), "Auto");
    
    println!("✅ BackendType Display implementation works correctly");
}

#[test]
fn test_error_constructors() {
    use ai_edge_inference_crate::error::InferenceError;
    
    let execution_error = InferenceError::execution("Test execution error".to_string());
    let preprocessing_error = InferenceError::preprocessing("Test preprocessing error".to_string());
    let postprocessing_error = InferenceError::postprocessing("Test postprocessing error".to_string());
    
    // Verify error types are created correctly
    assert!(execution_error.to_string().contains("Test execution error"));
    assert!(preprocessing_error.to_string().contains("Test preprocessing error"));
    assert!(postprocessing_error.to_string().contains("Test postprocessing error"));
    
    println!("✅ Error constructor functions work correctly");
}