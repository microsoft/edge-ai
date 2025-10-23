use std::env;
use std::path::PathBuf;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use anyhow::{Result, Context};
use ai_edge_inference_crate::{
    InferenceConfig as CrateInferenceConfig, 
    ModelsConfig, HardwareConfig, PerformanceConfig, 
    MonitoringConfig as CrateMonitoringConfig, SiteContext
};

/// Main configuration for the AI Edge MQTT Publisher Service
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComponentConfig {
    pub mqtt: MqttConfig,
    pub inference: InferenceConfig,
    pub monitoring: MonitoringConfig,
    pub site: SiteContext,
}

/// MQTT configuration for publishing inference results
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MqttConfig {
    pub broker_hostname: String,
    pub broker_port: u16,
    pub tls_ca_file: String,
    pub sat_file: String,
    pub topic_prefix: String,
    pub input_topics: Vec<String>,
    pub qos_level: u8,
    pub keep_alive_seconds: u16,
    pub connection_timeout_seconds: u16,
    pub retry_attempts: u8,
    pub retry_delay_ms: u64,
}

/// Inference configuration that maps to ai-edge-inference-crate config
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceConfig {
    pub models_directory: PathBuf,
    pub default_models: Vec<DefaultModel>,
    pub global_confidence_threshold: f32,
    pub max_predictions_per_model: usize,
    pub enable_gpu: bool,
    pub enable_tensorrt: bool,
    pub enable_cuda: bool,
    pub gpu_memory_limit_mb: Option<u32>,
    pub num_threads: Option<usize>,
    pub enable_parallel_processing: bool,
    pub batch_size: usize,
    pub inference_timeout_ms: u64,
    pub enable_model_caching: bool,
}

/// Default model configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DefaultModel {
    pub name: String,
    pub file_path: String,
    pub model_type: String,
    pub version: String,
    pub auto_load: bool,
    pub description: String,
}

/// Monitoring and observability configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonitoringConfig {
    pub enable_metrics: bool,
    pub log_level: String,
    pub enable_timing_metrics: bool,
    pub enable_memory_metrics: bool,
    pub metrics_export_interval_sec: u64,
    pub health_port: u16,
    pub metrics_port: u16,
}

impl ComponentConfig {
    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        Self {
            mqtt: MqttConfig::from_env(),
            inference: InferenceConfig::from_env(),
            monitoring: MonitoringConfig::from_env(),
            site: create_site_context_from_env(),
        }
    }

    /// Validate the configuration
    pub fn validate(&self) -> Result<()> {
        // Validate MQTT configuration
        if self.mqtt.broker_hostname.is_empty() {
            anyhow::bail!("MQTT broker hostname cannot be empty");
        }

        if self.mqtt.broker_port == 0 {
            anyhow::bail!("MQTT broker port must be greater than 0");
        }

        if self.mqtt.topic_prefix.is_empty() {
            anyhow::bail!("MQTT topic prefix cannot be empty");
        }

        // Validate inference configuration
        if !self.inference.models_directory.exists() {
            anyhow::bail!("Models directory does not exist: {:?}", self.inference.models_directory);
        }

        if self.inference.global_confidence_threshold < 0.0 || self.inference.global_confidence_threshold > 1.0 {
            anyhow::bail!("Global confidence threshold must be between 0.0 and 1.0");
        }

        if self.inference.batch_size == 0 {
            anyhow::bail!("Batch size must be greater than 0");
        }

        // Validate site configuration
        if self.site.site_id.is_empty() {
            anyhow::bail!("Site ID cannot be empty");
        }

        Ok(())
    }

    /// Create inference engine configuration from this config
    pub fn create_inference_config(&self) -> CrateInferenceConfig {
        CrateInferenceConfig {
            models: ModelsConfig {
                models_directory: self.inference.models_directory.clone(),
                default_models: Some(self.inference.default_models.iter().map(|dm| {
                    (dm.name.clone(), dm.file_path.clone())
                }).collect()),
                model_configs: HashMap::new(),
                global_confidence_threshold: self.inference.global_confidence_threshold,
                max_predictions_per_model: self.inference.max_predictions_per_model,
            },
            performance: PerformanceConfig {
                num_threads: self.inference.num_threads,
                enable_parallel_processing: self.inference.enable_parallel_processing,
                batch_size: self.inference.batch_size,
                inference_timeout_ms: self.inference.inference_timeout_ms,
                enable_model_caching: self.inference.enable_model_caching,
                memory_pool_size_mb: self.inference.gpu_memory_limit_mb,
            },
            hardware: HardwareConfig {
                use_gpu: self.inference.enable_gpu,
                gpu_device_id: Some(0),
                enable_tensorrt: self.inference.enable_tensorrt,
                enable_cuda: self.inference.enable_cuda,
                gpu_memory_limit_mb: self.inference.gpu_memory_limit_mb,
                fallback_to_cpu: true,
            },
            monitoring: CrateMonitoringConfig {
                enable_metrics: self.monitoring.enable_metrics,
                log_level: self.monitoring.log_level.clone(),
                enable_timing_metrics: self.monitoring.enable_timing_metrics,
                enable_memory_metrics: self.monitoring.enable_memory_metrics,
                metrics_export_interval_sec: self.monitoring.metrics_export_interval_sec,
            },
            site_context: SiteContext {
                site_id: self.site.site_id.clone(),
                facility_name: self.site.facility_name.clone(),
                business_unit: self.site.business_unit.clone(),
                region: self.site.region.clone(),
                environmental_data: self.site.environmental_data.clone(),
                equipment_mapping: self.site.equipment_mapping.clone(),
            },
        }
    }

    /// Parse model type string to enum
    fn parse_model_type(&self, model_type_str: &str) -> ai_edge_inference_crate::ModelType {
        match model_type_str.to_lowercase().as_str() {
            "vision" => ai_edge_inference_crate::ModelType::Vision,
            "audio" => ai_edge_inference_crate::ModelType::Audio,
            "text" => ai_edge_inference_crate::ModelType::Text,
            "multimodal" => ai_edge_inference_crate::ModelType::Multimodal,
            _ => ai_edge_inference_crate::ModelType::Custom,
        }
    }
}

impl MqttConfig {
    fn from_env() -> Self {
        Self {
            broker_hostname: get_env_or_default("AIO_BROKER_HOSTNAME", "aio-broker.azure-iot-operations"),
            broker_port: get_env_or_default("AIO_BROKER_TCP_PORT", "18883").parse().unwrap_or(18883),
            tls_ca_file: get_env_or_default("AIO_TLS_CA_FILE", "/var/run/certs/ca.crt"),
            sat_file: get_env_or_default("AIO_SAT_FILE", "/var/run/secrets/tokens/mq-sat"),
            topic_prefix: get_env_or_default("TOPIC_PREFIX", "edge-ai/business_unit/facility/gateway_id"),
            input_topics: get_env_or_default("MQTT_INPUT_TOPICS", "edge-ai/+/+/+/camera/snapshots,edge-ai/+/+/+/sensors/+")
                .split(',')
                .map(|s| s.trim().to_string())
                .collect(),
            qos_level: get_env_or_default("MQTT_QOS_LEVEL", "1").parse().unwrap_or(1),
            keep_alive_seconds: get_env_or_default("MQTT_KEEP_ALIVE_SECONDS", "60").parse().unwrap_or(60),
            connection_timeout_seconds: get_env_or_default("MQTT_CONNECTION_TIMEOUT_SECONDS", "30").parse().unwrap_or(30),
            retry_attempts: get_env_or_default("MQTT_RETRY_ATTEMPTS", "3").parse().unwrap_or(3),
            retry_delay_ms: get_env_or_default("MQTT_RETRY_DELAY_MS", "1000").parse().unwrap_or(1000),
        }
    }
}

impl InferenceConfig {
    fn from_env() -> Self {
        Self {
            models_directory: PathBuf::from(get_env_or_default("MODELS_DIRECTORY", "/models")),
            default_models: parse_default_models(&get_env_or_default("DEFAULT_MODELS", "")),
            global_confidence_threshold: get_env_or_default("GLOBAL_CONFIDENCE_THRESHOLD", "0.5").parse().unwrap_or(0.5),
            max_predictions_per_model: get_env_or_default("MAX_PREDICTIONS_PER_MODEL", "10").parse().unwrap_or(10),
            enable_gpu: get_env_or_default("ENABLE_GPU", "true").parse().unwrap_or(true),
            enable_tensorrt: get_env_or_default("ENABLE_TENSORRT", "true").parse().unwrap_or(true),
            enable_cuda: get_env_or_default("ENABLE_CUDA", "true").parse().unwrap_or(true),
            gpu_memory_limit_mb: get_env_or_default("GPU_MEMORY_LIMIT_MB", "2048").parse().ok(),
            num_threads: get_env_or_default("NUM_THREADS", "").parse().ok(),
            enable_parallel_processing: get_env_or_default("ENABLE_PARALLEL_PROCESSING", "true").parse().unwrap_or(true),
            batch_size: get_env_or_default("BATCH_SIZE", "1").parse().unwrap_or(1),
            inference_timeout_ms: get_env_or_default("INFERENCE_TIMEOUT_MS", "5000").parse().unwrap_or(5000),
            enable_model_caching: get_env_or_default("ENABLE_MODEL_CACHING", "true").parse().unwrap_or(true),
        }
    }
}

impl MonitoringConfig {
    fn from_env() -> Self {
        Self {
            enable_metrics: get_env_or_default("ENABLE_METRICS", "true").parse().unwrap_or(true),
            log_level: get_env_or_default("RUST_LOG", "info"),
            enable_timing_metrics: get_env_or_default("ENABLE_TIMING_METRICS", "true").parse().unwrap_or(true),
            enable_memory_metrics: get_env_or_default("ENABLE_MEMORY_METRICS", "true").parse().unwrap_or(true),
            metrics_export_interval_sec: get_env_or_default("METRICS_EXPORT_INTERVAL_SEC", "30").parse().unwrap_or(30),
            health_port: get_env_or_default("HEALTH_PORT", "8080").parse().unwrap_or(8080),
            metrics_port: get_env_or_default("METRICS_PORT", "8081").parse().unwrap_or(8081),
        }
    }
}

fn create_site_context_from_env() -> SiteContext {
    SiteContext {
        site_id: get_env_or_default("SITE_ID", "default_site"),
        facility_name: get_env_or_default("FACILITY_NAME", "pilot_facility"),
        business_unit: Some(get_env_or_default("BUSINESS_UNIT", "industrial_ai")),
        region: Some(get_env_or_default("REGION", "north_america")),
        environmental_data: parse_environmental_data(&get_env_or_default("ENVIRONMENTAL_DATA", "{}")),
        equipment_mapping: parse_equipment_mapping(&get_env_or_default("EQUIPMENT_MAPPING", "{}")),
    }
}

/// Helper function to get environment variable or return default
fn get_env_or_default(key: &str, default: &str) -> String {
    env::var(key).unwrap_or_else(|_| {
        tracing::warn!("{} environment variable not set, using default: '{}'", key, default);
        default.to_string()
    })
}

/// Parse default models from environment variable
fn parse_default_models(models_str: &str) -> Vec<DefaultModel> {
    if models_str.is_empty() {
        return vec![
            DefaultModel {
                name: "default".to_string(),
                file_path: "default.onnx".to_string(),
                model_type: "Vision".to_string(),
                version: "1.0.0".to_string(),
                auto_load: true,
                description: "Default ONNX model for inference testing".to_string(),
            },
        ];
    }

    // Parse comma-separated model names and map to actual model files
    let model_names: Vec<&str> = models_str.split(',').map(|s| s.trim()).collect();
    let mut models = Vec::new();
    
    for model_name in model_names {
        match model_name {
            "tiny-yolov2" => {
                models.push(DefaultModel {
                    name: "default".to_string(),
                    file_path: "default.onnx".to_string(),
                    model_type: "Vision".to_string(),
                    version: "1.0.0".to_string(),
                    auto_load: true,
                    description: "Tiny YOLOv2 object detection model".to_string(),
                });
            },
            "mobilenet" => {
                models.push(DefaultModel {
                    name: "mobilenet".to_string(),
                    file_path: "mobilenet.onnx".to_string(),
                    model_type: "Vision".to_string(),
                    version: "1.0.0".to_string(),
                    auto_load: true,
                    description: "MobileNet image classification model".to_string(),
                });
            },
            _ => {
                // For any other model name, assume it's the filename
                models.push(DefaultModel {
                    name: "default".to_string(),
                    file_path: "default.onnx".to_string(),
                    model_type: "Vision".to_string(),
                    version: "1.0.0".to_string(),
                    auto_load: true,
                    description: format!("Model: {}", model_name),
                });
            }
        }
    }
    
    models
}

/// Parse environmental data from JSON string
fn parse_environmental_data(data_str: &str) -> HashMap<String, serde_json::Value> {
    serde_json::from_str(data_str).unwrap_or_else(|_| {
        let mut default_data = HashMap::new();
        default_data.insert("temperature_c".to_string(), serde_json::Value::from(22.5));
        default_data.insert("humidity_percent".to_string(), serde_json::Value::from(45.0));
        default_data
    })
}

/// Parse equipment mapping from JSON string
fn parse_equipment_mapping(mapping_str: &str) -> HashMap<String, String> {
    serde_json::from_str(mapping_str).unwrap_or_else(|_| {
        let mut default_mapping = HashMap::new();
        default_mapping.insert("camera-001".to_string(), "Main Entrance Camera".to_string());
        default_mapping.insert("sensor-234".to_string(), "Environmental Monitor".to_string());
        default_mapping
    })
}

fn parse_shape(shape_str: &str) -> Result<Vec<i64>> {
    shape_str
        .split(',')
        .map(|s| s.trim().parse::<i64>())
        .collect::<Result<Vec<i64>, _>>()
        .context("Failed to parse shape")
}