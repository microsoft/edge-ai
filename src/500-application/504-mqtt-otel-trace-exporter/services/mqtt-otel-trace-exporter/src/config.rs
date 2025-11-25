use std::{env, net::SocketAddr, num::NonZeroU32, path::PathBuf};

use anyhow::{anyhow, Result};
use uuid::Uuid;

const DEFAULT_LOG_LEVEL: &str = "info";
const DEFAULT_SERVICE_NAME: &str = "mqtt-otel-trace-exporter";
const DEFAULT_SERVICE_NAMESPACE: &str = "edge-ai";
const DEFAULT_SAMPLING_RATIO: f64 = 1.0;
const DEFAULT_BSP_MAX_EXPORT_BATCH_SIZE: usize = 512;
const DEFAULT_BSP_MAX_QUEUE_SIZE: usize = 2048;
const DEFAULT_BSP_SCHEDULE_DELAY_MILLIS: u64 = 5_000;
const DEFAULT_BSP_EXPORT_TIMEOUT_MILLIS: u64 = 30_000;
const DEFAULT_MQTT_BROKER_HOST: &str = "localhost";
const DEFAULT_MQTT_BROKER_PORT: u16 = 1883;
const DEFAULT_MQTT_TOPIC_FILTERS: &str = "telemetry/#";
const DEFAULT_MQTT_SHARED_SUBSCRIPTION: &str = "edge-ai";
const DEFAULT_MQTT_SESSION_EXPIRY_SECS: u32 = 86_400;
const DEFAULT_MQTT_RECEIVE_MAX: u16 = 128;
const DEFAULT_MQTT_KEEP_ALIVE_SECS: u16 = 30;
const DEFAULT_MQTT_RETRY_MIN_BACKOFF_SECS: u64 = 5;
const DEFAULT_MQTT_RETRY_MAX_BACKOFF_SECS: u64 = 60;
const DEFAULT_CORRELATION_FIELD: &str = "correlationId";
const DEFAULT_HEALTH_BIND_ADDR: &str = "0.0.0.0:8080";
const DEFAULT_HEALTH_LIVENESS_PATH: &str = "/healthz";
const DEFAULT_HEALTH_READINESS_PATH: &str = "/readyz";

#[derive(Clone, Debug)]
pub struct AppConfig {
    pub logging: LoggingConfig,
    pub telemetry: TelemetryConfig,
    pub mqtt: MqttConfig,
    pub correlation: CorrelationConfig,
    pub health: HealthConfig,
}

#[derive(Clone, Debug)]
pub struct LoggingConfig {
    pub level: String,
}

#[derive(Clone, Debug)]
pub struct TelemetryConfig {
    pub collector_endpoint: Option<String>,
    pub service_name: String,
    pub service_namespace: String,
    pub service_instance_id: String,
    pub sampling_ratio: f64,
    pub max_export_batch_size: usize,
    pub max_queue_size: usize,
    pub scheduled_delay_millis: u64,
    pub export_timeout_millis: u64,
}

#[derive(Clone, Debug)]
pub struct MqttConfig {
    pub broker_host: String,
    pub broker_port: u16,
    pub client_id: String,
    pub topic_filters: Vec<String>,
    pub shared_subscription_group: String,
    pub session_expiry_secs: u32,
    pub receive_max: u16,
    pub keep_alive_secs: u16,
    pub retry_min_backoff_secs: u64,
    pub retry_max_backoff_secs: u64,
    pub use_tls: bool,
    pub tls_auto_enabled: bool,
    pub sat_token_path: Option<PathBuf>,
    pub ca_cert_path: Option<PathBuf>,
    pub x509_cert_path: Option<PathBuf>,
    pub x509_key_path: Option<PathBuf>,
}

#[derive(Clone, Debug)]
pub struct CorrelationConfig {
    pub field_name: String,
    pub allow_generated: bool,
}

#[derive(Clone, Debug)]
pub struct HealthConfig {
    pub bind_addr: SocketAddr,
    pub liveness_path: String,
    pub readiness_path: String,
}

impl AppConfig {
    pub fn load() -> Result<Self> {
        Ok(Self {
            logging: LoggingConfig {
                level: env::var("APP_LOG_LEVEL").unwrap_or_else(|_| DEFAULT_LOG_LEVEL.to_string()),
            },
            telemetry: TelemetryConfig::from_env()?,
            mqtt: MqttConfig::from_env()?,
            correlation: CorrelationConfig::from_env()?,
            health: HealthConfig::from_env()?,
        })
    }
}

impl TelemetryConfig {
    fn from_env() -> Result<Self> {
        let max_export_batch_size = parse_env(
            "OTEL_BSP_MAX_EXPORT_BATCH_SIZE",
            DEFAULT_BSP_MAX_EXPORT_BATCH_SIZE,
        )?;
        let max_queue_size = parse_env("OTEL_BSP_MAX_QUEUE_SIZE", DEFAULT_BSP_MAX_QUEUE_SIZE)?;
        if max_export_batch_size == 0 {
            return Err(anyhow!(
                "OTEL_BSP_MAX_EXPORT_BATCH_SIZE must be greater than zero"
            ));
        }
        if max_queue_size == 0 {
            return Err(anyhow!("OTEL_BSP_MAX_QUEUE_SIZE must be greater than zero"));
        }
        if max_export_batch_size > max_queue_size {
            return Err(anyhow!(
                "OTEL_BSP_MAX_EXPORT_BATCH_SIZE cannot exceed OTEL_BSP_MAX_QUEUE_SIZE"
            ));
        }

        let scheduled_delay_millis =
            parse_env("OTEL_BSP_SCHEDULE_DELAY", DEFAULT_BSP_SCHEDULE_DELAY_MILLIS)?;
        if scheduled_delay_millis == 0 {
            return Err(anyhow!("OTEL_BSP_SCHEDULE_DELAY must be greater than zero"));
        }

        let export_timeout_millis =
            parse_env("OTEL_BSP_EXPORT_TIMEOUT", DEFAULT_BSP_EXPORT_TIMEOUT_MILLIS)?;
        if export_timeout_millis == 0 {
            return Err(anyhow!("OTEL_BSP_EXPORT_TIMEOUT must be greater than zero"));
        }

        Ok(Self {
            collector_endpoint: optional_env("OTEL_EXPORTER_OTLP_ENDPOINT"),
            service_name: env::var("OTEL_SERVICE_NAME")
                .unwrap_or_else(|_| DEFAULT_SERVICE_NAME.to_string()),
            service_namespace: env::var("OTEL_SERVICE_NAMESPACE")
                .unwrap_or_else(|_| DEFAULT_SERVICE_NAMESPACE.to_string()),
            service_instance_id: env::var("OTEL_SERVICE_INSTANCE_ID")
                .unwrap_or_else(|_| default_instance_id()),
            sampling_ratio: parse_env("OTEL_TRACES_SAMPLER_ARG", DEFAULT_SAMPLING_RATIO)?,
            max_export_batch_size,
            max_queue_size,
            scheduled_delay_millis,
            export_timeout_millis,
        })
    }
}

impl MqttConfig {
    fn from_env() -> Result<Self> {
        let broker_host =
            env::var("MQTT_BROKER_HOST").unwrap_or_else(|_| DEFAULT_MQTT_BROKER_HOST.to_string());
        let broker_port_raw = parse_env("MQTT_BROKER_PORT", u32::from(DEFAULT_MQTT_BROKER_PORT))?;
        if !(1..=u32::from(u16::MAX)).contains(&broker_port_raw) {
            return Err(anyhow!("MQTT_BROKER_PORT must be between 1 and 65535"));
        }
        let broker_port = broker_port_raw as u16;
        let raw_topics = env::var("MQTT_TOPIC_FILTERS")
            .unwrap_or_else(|_| DEFAULT_MQTT_TOPIC_FILTERS.to_string());
        let topic_filters = raw_topics
            .split(',')
            .map(|topic| topic.trim().to_string())
            .filter(|topic| !topic.is_empty())
            .collect::<Vec<_>>();

        if topic_filters.is_empty() {
            return Err(anyhow!(
                "MQTT_TOPIC_FILTERS must contain at least one topic filter"
            ));
        }

        let session_expiry_secs =
            parse_env("MQTT_SESSION_EXPIRY_SECS", DEFAULT_MQTT_SESSION_EXPIRY_SECS)?;
        if NonZeroU32::new(session_expiry_secs).is_none() {
            return Err(anyhow!(
                "MQTT_SESSION_EXPIRY_SECS must be greater than zero"
            ));
        }

        let retry_min_backoff_secs = parse_env(
            "MQTT_RETRY_MIN_BACKOFF_SECS",
            DEFAULT_MQTT_RETRY_MIN_BACKOFF_SECS,
        )?;
        let retry_max_backoff_secs = parse_env(
            "MQTT_RETRY_MAX_BACKOFF_SECS",
            DEFAULT_MQTT_RETRY_MAX_BACKOFF_SECS,
        )?;
        if retry_min_backoff_secs == 0 || retry_max_backoff_secs == 0 {
            return Err(anyhow!("MQTT backoff values must be greater than zero"));
        }
        if retry_min_backoff_secs > retry_max_backoff_secs {
            return Err(anyhow!(
                "MQTT_RETRY_MIN_BACKOFF_SECS cannot exceed MQTT_RETRY_MAX_BACKOFF_SECS"
            ));
        }

        let sat_token_path = optional_path("MQTT_SAT_TOKEN_PATH");
        let ca_cert_path = optional_path("MQTT_CA_CERT_PATH");
        let x509_cert_path = optional_path("MQTT_X509_CERT_PATH");
        let x509_key_path = optional_path("MQTT_X509_KEY_PATH");

        let has_tls_material = sat_token_path.is_some()
            || ca_cert_path.is_some()
            || (x509_cert_path.is_some() && x509_key_path.is_some());

        let mut use_tls = match optional_env("MQTT_USE_TLS") {
            Some(value) => value
                .parse::<bool>()
                .map_err(|err| anyhow!("failed to parse MQTT_USE_TLS='{}': {}", value, err))?,
            None => has_tls_material,
        };

        let mut tls_auto_enabled = false;
        if has_tls_material && !use_tls {
            use_tls = true;
            tls_auto_enabled = true;
        }

        Ok(Self {
            broker_host,
            broker_port,
            client_id: env::var("MQTT_CLIENT_ID")
                .unwrap_or_else(|_| format!("mqtt-otel-{}", Uuid::new_v4())),
            topic_filters,
            shared_subscription_group: env::var("MQTT_SHARED_SUBSCRIPTION")
                .unwrap_or_else(|_| DEFAULT_MQTT_SHARED_SUBSCRIPTION.to_string()),
            session_expiry_secs,
            receive_max: parse_env("MQTT_RECEIVE_MAX", DEFAULT_MQTT_RECEIVE_MAX)?,
            keep_alive_secs: parse_env("MQTT_KEEP_ALIVE_SECS", DEFAULT_MQTT_KEEP_ALIVE_SECS)?,
            retry_min_backoff_secs,
            retry_max_backoff_secs,
            use_tls,
            tls_auto_enabled,
            sat_token_path,
            ca_cert_path,
            x509_cert_path,
            x509_key_path,
        })
    }
}

impl CorrelationConfig {
    fn from_env() -> Result<Self> {
        Ok(Self {
            field_name: env::var("CORRELATION_ID_FIELD")
                .unwrap_or_else(|_| DEFAULT_CORRELATION_FIELD.to_string()),
            allow_generated: parse_env("CORRELATION_ALLOW_GENERATED", true)?,
        })
    }
}

impl HealthConfig {
    fn from_env() -> Result<Self> {
        let bind_addr = optional_env("HTTP_HEALTH_ADDR")
            .map(|value| {
                value
                    .parse::<SocketAddr>()
                    .map_err(|err| anyhow!("failed to parse HTTP_HEALTH_ADDR='{}': {}", value, err))
            })
            .transpose()?
            .unwrap_or_else(|| {
                DEFAULT_HEALTH_BIND_ADDR
                    .parse::<SocketAddr>()
                    .expect("invalid default HTTP health bind address")
            });

        let liveness_path = normalize_health_path(
            optional_env("HTTP_HEALTH_LIVENESS_PATH"),
            DEFAULT_HEALTH_LIVENESS_PATH,
        );
        let readiness_path = normalize_health_path(
            optional_env("HTTP_HEALTH_READINESS_PATH"),
            DEFAULT_HEALTH_READINESS_PATH,
        );

        Ok(Self {
            bind_addr,
            liveness_path,
            readiness_path,
        })
    }
}

fn parse_env<T>(key: &str, default: T) -> Result<T>
where
    T: std::str::FromStr,
    T::Err: std::error::Error + Send + Sync + 'static,
{
    match env::var(key) {
        Ok(value) => value
            .parse::<T>()
            .map_err(|err| anyhow!("failed to parse {}='{}': {}", key, value, err)),
        Err(env::VarError::NotPresent) => Ok(default),
        Err(err) => Err(anyhow!("failed to read {}: {}", key, err)),
    }
}

fn optional_env(key: &str) -> Option<String> {
    env::var(key).ok().filter(|value| !value.trim().is_empty())
}

fn optional_path(key: &str) -> Option<PathBuf> {
    optional_env(key).map(PathBuf::from)
}

fn normalize_health_path(value: Option<String>, default: &str) -> String {
    value
        .and_then(|raw| {
            let trimmed = raw.trim();
            if trimmed.is_empty() {
                None
            } else if trimmed.starts_with('/') {
                Some(trimmed.to_string())
            } else {
                Some(format!("/{}", trimmed))
            }
        })
        .unwrap_or_else(|| default.to_string())
}

fn default_instance_id() -> String {
    env::var("HOSTNAME").unwrap_or_else(|_| Uuid::new_v4().to_string())
}
