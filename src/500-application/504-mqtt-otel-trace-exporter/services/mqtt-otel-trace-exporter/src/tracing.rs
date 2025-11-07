use std::time::Duration;

use anyhow::{anyhow, Result};
use opentelemetry::{global, KeyValue};
use opentelemetry_otlp::{SpanExporter, WithExportConfig};
use opentelemetry_sdk::{
    propagation::TraceContextPropagator,
    resource::Resource,
    trace::{BatchConfigBuilder, BatchSpanProcessor, Sampler, SdkTracerProvider},
};
use tracing::{info, warn};

use crate::config::TelemetryConfig;

pub const TRACER_NAME: &str = "mqtt-otel-trace-exporter";

pub struct TelemetryGuard {
    provider: SdkTracerProvider,
}

pub async fn init(config: &TelemetryConfig) -> Result<TelemetryGuard> {
    global::set_text_map_propagator(TraceContextPropagator::new());

    let collector_configured = config.collector_endpoint.is_some();
    let collector_endpoint = config
        .collector_endpoint
        .as_deref()
        .unwrap_or("<unset>");

    info!(
        target: "telemetry",
        service_name = %config.service_name,
        service_namespace = %config.service_namespace,
        service_instance_id = %config.service_instance_id,
        sampling_ratio = config.sampling_ratio,
        collector_configured = collector_configured,
        collector_endpoint = %collector_endpoint,
        max_queue_size = config.max_queue_size,
        max_export_batch_size = config.max_export_batch_size,
        scheduled_delay_millis = config.scheduled_delay_millis,
        export_timeout_millis = config.export_timeout_millis,
        "telemetry configuration applied"
    );

    let resource = Resource::builder()
        .with_attributes([
            KeyValue::new("service.name", config.service_name.clone()),
            KeyValue::new("service.namespace", config.service_namespace.clone()),
            KeyValue::new("service.instance.id", config.service_instance_id.clone()),
        ])
        .build();

    let mut builder = SdkTracerProvider::builder()
        .with_resource(resource)
        .with_sampler(sampler_from_ratio(config.sampling_ratio));

    if let Some(endpoint) = &config.collector_endpoint {
        let exporter = SpanExporter::builder()
            .with_tonic()
            .with_endpoint(endpoint.clone())
            .build()
            .map_err(|err| anyhow!("failed to configure OTLP exporter: {err}"))?;

        let batch_config_builder = BatchConfigBuilder::default()
            .with_max_queue_size(config.max_queue_size)
            .with_max_export_batch_size(config.max_export_batch_size)
            .with_scheduled_delay(Duration::from_millis(config.scheduled_delay_millis));

        #[cfg(feature = "experimental_trace_batch_span_processor_with_async_runtime")]
        let batch_config_builder = batch_config_builder
            .with_max_export_timeout(Duration::from_millis(config.export_timeout_millis));

        let batch_config = batch_config_builder.build();

        let batch_processor = BatchSpanProcessor::builder(exporter)
            .with_batch_config(batch_config)
            .build();

        builder = builder.with_span_processor(batch_processor);
    } else {
        warn!("OTEL_EXPORTER_OTLP_ENDPOINT not set; spans will not be exported");
    }

    let provider = builder.build();
    let cloned_provider = provider.clone();
    global::set_tracer_provider(provider);

    Ok(TelemetryGuard {
        provider: cloned_provider,
    })
}

impl TelemetryGuard {
    pub async fn shutdown(self) -> Result<()> {
        self.provider.shutdown()?;
        Ok(())
    }
}

pub fn tracer() -> opentelemetry::global::BoxedTracer {
    global::tracer(TRACER_NAME)
}

fn sampler_from_ratio(ratio: f64) -> Sampler {
    match ratio {
        r if r <= 0.0 => Sampler::AlwaysOff,
        r if r >= 1.0 => Sampler::AlwaysOn,
        r => Sampler::TraceIdRatioBased(r),
    }
}
