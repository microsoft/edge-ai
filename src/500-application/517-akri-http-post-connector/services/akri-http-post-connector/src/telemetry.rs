//! Status and health-event reporting helpers shared across the device endpoint,
//! asset, and dataset lifecycle.
//!
//! The SDK's `report_*_status_if_modified` methods take a `Fn(Option<Result<(), &E>>)
//! -> Option<Result<(), E>>` closure and internally decide whether the candidate
//! status actually differs from what's already reported, skipping the network call
//! when it doesn't. [`report_if_changed`] adapts a single candidate status value
//! into that closure shape.

use azure_iot_operations_connector::AdrConfigError;
use opentelemetry::trace::TracerProvider;
use opentelemetry::KeyValue;
use opentelemetry_otlp::SpanExporter;
use opentelemetry_sdk::propagation::TraceContextPropagator;
use opentelemetry_sdk::trace::SdkTracerProvider;
use opentelemetry_sdk::Resource;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

/// Retains and flushes the connector's OpenTelemetry provider for the process
/// lifetime.
pub struct TelemetryGuard {
    provider: SdkTracerProvider,
}

impl Drop for TelemetryGuard {
    fn drop(&mut self) {
        let _ = self.provider.shutdown();
    }
}

/// Installs console tracing, W3C propagation, and an optional OTLP exporter.
pub fn init(
    service_name: &'static str,
    configured_log_level: Option<&str>,
) -> Result<TelemetryGuard, String> {
    opentelemetry::global::set_text_map_propagator(TraceContextPropagator::new());
    let resource = Resource::builder()
        .with_service_name(service_name)
        .with_attributes([KeyValue::new("service.version", env!("CARGO_PKG_VERSION"))])
        .build();
    let mut provider_builder = SdkTracerProvider::builder().with_resource(resource);
    if std::env::var("OTEL_EXPORTER_OTLP_ENDPOINT").is_ok() {
        let exporter = SpanExporter::builder()
            .with_tonic()
            .build()
            .map_err(|_| "failed to configure OTLP trace exporter".to_string())?;
        provider_builder = provider_builder.with_batch_exporter(exporter);
    }
    let provider = provider_builder.build();
    let tracer = provider.tracer(service_name);
    let env_filter_configured = std::env::var_os(EnvFilter::DEFAULT_ENV).is_some();
    let filter = std::env::var(EnvFilter::DEFAULT_ENV)
        .map_err(|error| error.to_string())
        .and_then(|directive| EnvFilter::try_new(directive).map_err(|error| error.to_string()))
        .or_else(|error| {
            if env_filter_configured {
                Err(error)
            } else {
                EnvFilter::try_new(configured_log_level.unwrap_or("info"))
                    .map_err(|error| error.to_string())
            }
        })
        .map_err(|_| "failed to configure tracing filter".to_string())?;
    tracing_subscriber::registry()
        .with(filter)
        .with(fmt::layer().with_target(true))
        .with(tracing_opentelemetry::layer().with_tracer(tracer))
        .try_init()
        .map_err(|_| "failed to initialize tracing subscriber".to_string())?;
    let filter_source = if env_filter_configured {
        EnvFilter::DEFAULT_ENV
    } else if configured_log_level.is_some() {
        "connector_diagnostics"
    } else {
        "default"
    };
    tracing::info!(filter_source, "tracing initialized");
    Ok(TelemetryGuard { provider })
}

/// Stable, bounded failure reasons that may be published through ADR status and
/// health surfaces.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FailureReason {
    ConfigurationRejected,
    EndpointUnavailable,
    InvalidEndpoint,
    BodyUnavailable,
    RequestFailed,
    ForwardingFailed,
}

impl FailureReason {
    /// Returns the reason code used in status, health, and structured logs.
    pub fn code(self) -> &'static str {
        match self {
            Self::ConfigurationRejected => "ConfigurationRejected",
            Self::EndpointUnavailable => "EndpointUnavailable",
            Self::InvalidEndpoint => "InvalidEndpoint",
            Self::BodyUnavailable => "BodyUnavailable",
            Self::RequestFailed => "RequestFailed",
            Self::ForwardingFailed => "ForwardingFailed",
        }
    }

    /// Returns whether this failure makes the accepted observation plan unusable.
    pub fn invalidates_runtime_configuration(self) -> bool {
        matches!(
            self,
            Self::ConfigurationRejected
                | Self::EndpointUnavailable
                | Self::InvalidEndpoint
                | Self::BodyUnavailable
        )
    }
}

/// Builds a closure suitable for any `report_*_status_if_modified` call that
/// reports `new_status` the first time (`current` is `None`) or whenever it
/// differs from the currently reported status, and otherwise reports nothing.
pub fn report_if_changed(
    new_status: Result<(), AdrConfigError>,
) -> impl Fn(Option<Result<(), &AdrConfigError>>) -> Option<Result<(), AdrConfigError>> {
    move |current| {
        let changed = match (current, &new_status) {
            (None, _) => true,
            (Some(Ok(())), Ok(())) => false,
            (Some(Err(current_err)), Err(new_err)) => current_err != new_err,
            _ => true,
        };
        changed.then(|| new_status.clone())
    }
}

/// A healthy status with no configuration error.
pub fn ok_status() -> Result<(), AdrConfigError> {
    Ok(())
}

/// A configuration-error status carrying a human-readable message.
pub fn error_status(message: impl Into<String>) -> Result<(), AdrConfigError> {
    Err(AdrConfigError {
        message: Some(message.into()),
        ..Default::default()
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_ok_status_the_first_time() {
        let modify = report_if_changed(ok_status());
        assert_eq!(modify(None), Some(Ok(())));
    }

    #[test]
    fn skips_reporting_when_status_unchanged() {
        let modify = report_if_changed(ok_status());
        assert_eq!(modify(Some(Ok(()))), None);
    }

    #[test]
    fn reports_when_transitioning_from_ok_to_error() {
        let modify = report_if_changed(error_status("boom"));
        assert!(modify(Some(Ok(()))).is_some());
    }

    #[test]
    fn skips_reporting_when_error_message_unchanged() {
        let modify = report_if_changed(error_status("boom"));
        let existing = error_status("boom").unwrap_err();
        assert_eq!(modify(Some(Err(&existing))), None);
    }

    #[test]
    fn reports_when_error_message_changes() {
        let modify = report_if_changed(error_status("new failure"));
        let existing = error_status("old failure").unwrap_err();
        assert!(modify(Some(Err(&existing))).is_some());
    }
}
