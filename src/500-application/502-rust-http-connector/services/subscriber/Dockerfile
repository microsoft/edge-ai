# =============================================================================
# MQTT Telemetry Subscriber Dockerfile
#
# This Dockerfile builds a lightweight container for the Rust-based MQTT subscriber application.
# The application subscribes to MQTT messages published by the broker and processes telemetry data.
# The build uses a multi-stage approach:
# 1. A builder stage that compiles the Rust application and caches dependencies
# 2. A minimal runtime container with only the necessary dependencies and a non-root user
#
# The container expects the following environment variables:
# - AIO_MQTT_USE_TLS: Whether to use TLS for MQTT connections
# - AIO_MQTT_CLIENT_ID: MQTT client ID
# - AIO_BROKER_HOSTNAME: MQTT broker hostname
# - AIO_BROKER_TCP_PORT: MQTT broker port
# - MQ_TOPIC: The MQTT topic to subscribe to
# =============================================================================

# STAGE 1: Builder - Compiles the Rust application
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/rust:1.72 AS builder

WORKDIR /usr/src/app

COPY ./Cargo.toml ./Cargo.toml
COPY ./.cargo/config.toml ./.cargo/config.toml

# Install build dependencies for Rust compilation
RUN tdnf update -y && \
    tdnf install -y pkgconfig openssl-devel

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN rustup update stable && \
    rustup component add rustfmt

ARG USE_REPLACE_WITH=false

# Build the Rust application in release mode
COPY ./src ./src
RUN cargo build --release

# STAGE 2: Runtime - Creates the minimal production image
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/core:2.0

# Install runtime dependencies and create non-root user
RUN tdnf update -y && \
    tdnf install -y ca-certificates util-linux wget systemd shadow-utils && \
    tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy compiled binary from builder stage
COPY --from=builder /usr/src/app/target/release/subscriber /app/subscriber

# Set proper ownership and permissions
RUN chown appuser:appuser /app/subscriber && \
    chmod +x /app/subscriber

# Use non-root user for security
USER appuser

# Set entrypoint
ENTRYPOINT ["/app/subscriber"]
