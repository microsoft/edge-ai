use ai_edge_inference_crate::backend::{BackendFactory, BackendConfig, BackendType, DeviceType, OptimizationLevel};

#[tokio::test]
async fn test_auto_backend_selection() {
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
    println!("🔍 Available backends at compile time: {:?}", available_backends);

    if available_backends.is_empty() {
        println!("⚠️  No backends available - testing error handling");
        let result = BackendFactory::create_backend(&config).await;
        assert!(result.is_err());
        let error = result.unwrap_err();
        assert!(error.to_string().contains("No suitable backend available"));
        println!("✅ Correctly handled no-backend scenario: {}", error);
        return;
    }

    println!("🚀 Testing backend creation with auto-selection...");
    let result = BackendFactory::create_backend(&config).await;
    assert!(result.is_ok());
    
    println!("✅ Successfully created backend using auto-selection");
    println!("🎯 Backend abstraction system is working correctly!");
}

#[tokio::test] 
async fn test_specific_backend_types() {
    // Test ONNX Runtime backend specifically if available
    #[cfg(feature = "onnx-runtime")]
    {
        println!("🧪 Testing ONNX Runtime backend...");
        let config = BackendConfig {
            backend_type: BackendType::OnnxRuntime,
            device_type: DeviceType::Cpu,
            model_directory: "/tmp/models".to_string(),
            cache_size_mb: 512,
            enable_optimization: true,
            optimization_level: OptimizationLevel::All,
            parallel_execution: false,
            onnx_config: Some(ai_edge_inference_crate::backend::OnnxConfig {
                optimization_level: "all".to_string(),
                inter_op_num_threads: Some(4),
                intra_op_num_threads: Some(4),
                enable_mem_pattern: true,
                enable_cpu_mem_arena: true,
                execution_providers: vec!["CPUExecutionProvider".to_string()],
            }),
            candle_config: None,
        };

        let result = BackendFactory::create_backend(&config).await;
        assert!(result.is_ok());
        println!("✅ ONNX Runtime backend created successfully");
    }

    // Test Candle backend specifically if available
    #[cfg(feature = "candle")]
    {
        println!("🧪 Testing Candle backend...");
        let config = BackendConfig {
            backend_type: BackendType::Candle,
            device_type: DeviceType::Cpu,
            model_directory: "/tmp/models".to_string(),
            cache_size_mb: 512,
            enable_optimization: true,
            optimization_level: OptimizationLevel::All,
            parallel_execution: false,
            onnx_config: None,
            candle_config: Some(ai_edge_inference_crate::backend::CandleConfig {
                device_type: ai_edge_inference_crate::backend::DeviceType::Cpu,
                enable_mkl: false,
                enable_cuda: false,
                enable_opengl: false,
            }),
        };

        let result = BackendFactory::create_backend(&config).await;
        assert!(result.is_ok());
        println!("✅ Candle backend created successfully");
    }

    // Test requesting unavailable backend
    #[cfg(not(feature = "onnx-runtime"))]
    {
        println!("🧪 Testing unavailable ONNX Runtime backend request...");
        let config = BackendConfig {
            backend_type: BackendType::OnnxRuntime,
            device_type: DeviceType::Cpu,
            model_directory: "/tmp/models".to_string(),
            cache_size_mb: 512,
            enable_optimization: true,
            optimization_level: OptimizationLevel::All,
            parallel_execution: false,
            onnx_config: None,
            candle_config: None,
        };

        let result = BackendFactory::create_backend(&config).await;
        assert!(result.is_err());
        let error = result.unwrap_err();
        assert!(error.to_string().contains("ONNX Runtime backend not compiled"));
        println!("✅ Correctly handled unavailable ONNX Runtime request: {}", error);
    }

    #[cfg(not(feature = "candle"))]
    {
        println!("🧪 Testing unavailable Candle backend request...");
        let config = BackendConfig {
            backend_type: BackendType::Candle,
            device_type: DeviceType::Cpu,
            model_directory: "/tmp/models".to_string(),
            cache_size_mb: 512,
            enable_optimization: true,
            optimization_level: OptimizationLevel::All,
            parallel_execution: false,
            onnx_config: None,
            candle_config: None,
        };

        let result = BackendFactory::create_backend(&config).await;
        assert!(result.is_err());
        let error = result.unwrap_err();
        assert!(error.to_string().contains("Candle backend not compiled"));
        println!("✅ Correctly handled unavailable Candle request: {}", error);
    }

    println!("🎯 All backend-specific tests completed successfully!");
}