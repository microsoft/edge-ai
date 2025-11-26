//! # OpenTelemetry Integration Module
//!
//! This module provides functionality for setting up OpenTelemetry tracing
//! and injecting trace context into outgoing telemetry messages.
//!
//! It enables distributed tracing across services by:
//! 1. Setting up an OpenTelemetry exporter to send traces to an OTLP collector
//! 2. Configuring the W3C Trace Context propagator
//! 3. Providing a function to inject the current span context into messages

use opentelemetry::propagation::Injector;
use opentelemetry::{global, trace::TracerProvider};
use opentelemetry_otlp::SpanExporter;
use tracing::Span;
use tracing_opentelemetry::OpenTelemetrySpanExt;
use tracing_subscriber::EnvFilter;

use opentelemetry_sdk::propagation::TraceContextPropagator;
use opentelemetry_sdk::trace::SdkTracerProvider;
use opentelemetry_sdk::Resource;
use std::env;
use tracing::{info, warn};
use tracing_subscriber::prelude::*;

/// Initialize the OpenTelemetry tracer provider with optional OTLP exporter
///
/// Creates a tracer provider that exports spans to an OpenTelemetry collector
/// using the OTLP protocol with gRPC transport, but only if the OTEL_EXPORTER_OTLP_ENDPOINT
/// environment variable is set.
///
/// When the environment variable is not set, returns a no-op tracer provider that
/// doesn't export spans to an external collector.
fn init_traces() -> SdkTracerProvider {
    // Create a common resource builder for all configurations
    let resource = Resource::builder().build();

    // Start building the tracer provider
    let mut builder = SdkTracerProvider::builder();

    // Check if the OTEL_EXPORTER_OTLP_ENDPOINT environment variable is set
    if let Ok(endpoint) = env::var("OTEL_EXPORTER_OTLP_ENDPOINT") {
        // OTEL_EXPORTER_OTLP_ENDPOINT is set, create an exporter
        info!(
            "OTEL_EXPORTER_OTLP_ENDPOINT is set to {}, enabling OpenTelemetry exporter",
            endpoint
        );

        // Try to create the OTLP exporter
        if let Ok(exporter) = SpanExporter::builder().with_tonic().build() {
            // Add the resource and batch exporter to the builder
            builder = builder
                .with_resource(resource)
                .with_batch_exporter(exporter);
        } else {
            warn!("Failed to create OTLP span exporter, using local-only tracing");
            // Fall back to a no-op tracer provider if the exporter creation fails
            builder = builder.with_resource(resource);
        }
    } else {
        info!("OTEL_EXPORTER_OTLP_ENDPOINT is not set, using local-only tracing");
        builder = builder.with_resource(resource);
    }

    // Build and return the tracer provider
    builder.build()
}

/// Set up OpenTelemetry tracing with the given service name
///
/// This function:
/// 1. Initializes the OpenTelemetry tracer provider (with or without OTLP exporter)
/// 2. Configures the W3C Trace Context propagator for cross-service tracing
/// 3. Sets up the tracing subscriber with appropriate layers
///
/// If OTEL_EXPORTER_OTLP_ENDPOINT is set, full OpenTelemetry tracing will be enabled.
/// Otherwise, only console logging will be used, but the W3C context propagation
/// will still be available for cross-service tracing.
///
/// # Arguments
///
/// * `tracer_name` - The name of the tracer, typically the service name
pub fn setup_otel_tracing(tracer_name: &str) {
    // Set the global propagator for W3C Trace Context
    // This ensures trace context is correctly propagated between services
    // even if we're not exporting traces to a collector
    opentelemetry::global::set_text_map_propagator(TraceContextPropagator::new());

    // Create console output layer with environment-based filtering
    let filter_fmt = EnvFilter::from_default_env();
    let fmt_layer = tracing_subscriber::fmt::layer().with_filter(filter_fmt);

    // Check if we should add the OpenTelemetry layer
    let has_otel_endpoint = env::var("OTEL_EXPORTER_OTLP_ENDPOINT").is_ok();

    if has_otel_endpoint {
        // Initialize the tracer provider
        let tracer_provider = init_traces();
        let tracer = tracer_provider.tracer(tracer_name.to_string());

        // Create the OpenTelemetry layer
        let otel_layer = tracing_opentelemetry::layer()
            .with_tracer(tracer)
            .with_filter(EnvFilter::from_default_env());

        // Compose both layers together and initialize
        tracing_subscriber::registry()
            .with(fmt_layer)
            .with(otel_layer)
            .init();
        info!("OpenTelemetry tracing initialized with OTLP exporter");
    } else {
        // Only use the fmt layer
        tracing_subscriber::registry().with(fmt_layer).init();
        info!("OpenTelemetry tracing initialized without OTLP exporter");
    }
}

/// Custom injector that stores trace context in a vector of key-value pairs
///
/// This injector is used with the OpenTelemetry text map propagator to
/// convert the current trace context into a format that can be sent
/// in message metadata.
struct VecInjector<'a>(&'a mut Vec<(String, String)>);

impl<'a> Injector for VecInjector<'a> {
    /// Add a key-value pair to the vector
    fn set(&mut self, key: &str, value: String) {
        self.0.push((key.to_string(), value));
    }
}

/// Extract the current OpenTelemetry context and inject it into a vector
///
/// This function:
/// 1. Gets the current tracing span context
/// 2. Creates a vector to store the trace context headers
/// 3. Injects the trace context into the vector using the W3C Trace Context format
///
/// The returned vector contains key-value pairs that can be sent with a message
/// to propagate trace context to downstream services.
///
/// # Returns
///
/// A vector of (key, value) pairs containing the trace context
pub fn inject_current_context() -> Vec<(String, String)> {
    // Get the current OpenTelemetry context from the active span
    let ctx = Span::current().context();
    let mut carrier = Vec::new();

    // Use the global text map propagator to inject context
    global::get_text_map_propagator(|propagator| {
        // Create the injector with the carrier
        let mut injector = VecInjector(&mut carrier);
        // Inject the context into the carrier
        // This typically adds keys like "traceparent" with W3C trace context values
        propagator.inject_context(&ctx, &mut injector);
    });

    carrier
}
