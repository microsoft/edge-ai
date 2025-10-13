//! # OpenTelemetry Integration Module for Receiver
//!
//! This module provides functionality for setting up OpenTelemetry tracing
//! and extracting trace context from incoming telemetry messages.
//!
//! It enables distributed tracing across services by:
//! 1. Setting up an OpenTelemetry exporter to send traces to an OTLP collector
//! 2. Configuring the W3C Trace Context propagator
//! 3. Providing a function to extract the sender's span context from message metadata
//! 4. Setting the parent context to maintain the trace across services

use opentelemetry::propagation::Extractor;
use opentelemetry::Context;
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

/// Custom extractor that reads trace context from a vector of key-value pairs
///
/// This extractor implements the OpenTelemetry Extractor trait to allow
/// reading trace context information from message metadata.
struct CustomUserDataExtractor<'a>(&'a Vec<(String, String)>);

impl<'a> Extractor for CustomUserDataExtractor<'a> {
    /// Get the value associated with a key from the Vec
    ///
    /// Used by the propagator to extract values like 'traceparent' header
    fn get(&self, key: &str) -> Option<&str> {
        self.0
            .iter()
            .find(|(k, _)| k == key)
            .map(|(_, v)| v.as_str())
    }

    /// Get all keys in the Vec
    ///
    /// Used by the propagator to know which keys are available
    fn keys(&self) -> Vec<&str> {
        self.0.iter().map(|(k, _)| k.as_str()).collect()
    }
}

/// Extract an OpenTelemetry context from custom user data
///
/// This uses the global text map propagator (W3C Trace Context)
/// to extract trace information from the message metadata.
///
/// # Arguments
///
/// * `custom_user_data` - The vector of key-value pairs from the message
///
/// # Returns
///
/// An OpenTelemetry Context object containing the extracted trace information
fn extract_trace_context(custom_user_data: &Vec<(String, String)>) -> Context {
    let extractor = CustomUserDataExtractor(custom_user_data);
    global::get_text_map_propagator(|propagator| propagator.extract(&extractor))
}

/// Set CloudEvent attributes to the current span
///
/// This function follows the OpenTelemetry semantic conventions for CloudEvents:
/// https://github.com/open-telemetry/semantic-conventions/blob/main/docs/cloudevents/README.md
///
/// NOTE: The semantic conventions for CloudEvents are development and may change.
///
/// It extracts key attributes from the CloudEvent and adds them to the current span
/// to improve observability and correlation between spans and events.
///
/// # Arguments
///
/// * `cloud_event` - The CloudEvent data from the received message
pub fn set_cloud_event_attributes(
    cloud_event: &azure_iot_operations_protocol::telemetry::receiver::CloudEvent,
) {
    // Get the current span
    let span = Span::current();

    // Required CloudEvent attributes (as defined in the CloudEvents spec v1.0.2)
    span.set_attribute("cloudevents.id", cloud_event.id.to_string());
    span.set_attribute("cloudevents.source", cloud_event.source.to_string());
    span.set_attribute(
        "cloudevents.specversion",
        cloud_event.spec_version.to_string(),
    );
    span.set_attribute("cloudevents.type", cloud_event.event_type.to_string());

    // Optional CloudEvent attributes
    if let Some(subject) = &cloud_event.subject {
        span.set_attribute("cloudevents.subject", subject.to_string());
    }

    if let Some(time) = cloud_event.time {
        span.set_attribute("cloudevents.time", time.to_rfc3339());
    }

    if let Some(dataschema) = &cloud_event.data_schema {
        span.set_attribute("cloudevents.dataschema", dataschema.to_string());
    }

    if let Some(data_content_type) = &cloud_event.data_content_type {
        span.set_attribute("cloudevents.datacontenttype", data_content_type.to_string());
    }
}

/// Handle the trace context from a received message
///
/// This function:
/// 1. Logs the received context headers
/// 2. Extracts the OpenTelemetry context from the message metadata
/// 3. Sets the current span's parent to maintain the distributed trace
/// 4. Adds messaging attributes for better observability
///
/// # Arguments
///
/// * `custom_user_data` - The vector of key-value pairs from the message metadata
pub fn handle_receive_trace(custom_user_data: &Vec<(String, String)>) {
    // Extract the OpenTelemetry context from the message metadata
    let cx = extract_trace_context(custom_user_data);

    // Get the current span
    let span = Span::current();

    // Set the parent context to link this span to the sender's trace
    // This creates a continuous trace across services
    span.set_parent(cx);
}
