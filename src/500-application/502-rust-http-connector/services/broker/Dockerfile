# =============================================================================
# Sensor Data Broker Dockerfile
#
# This Dockerfile builds a lightweight container for the HTTP/REST connector application,
# which relays sensor data from an HTTP endpoint and publishes MQTT messages
# The build uses a multi-stage approach:
# 1. A builder stage that compiles the Rust application and caches dependencies
# 2. A minimal runtime container with only the necessary dependencies and a non-root user
#
# The container expects the following environment variables:
# - AIO_MQTT_USE_TLS: Whether to use TLS for MQTT connections
# - AIO_MQTT_CLIENT_ID: MQTT client ID
# - AIO_BROKER_HOSTNAME: MQTT broker hostname
# - AIO_BROKER_TCP_PORT: MQTT broker port
# - MQ_TOPIC: The MQTT topic to publish to
# - MQ_ERROR_TOPIC: The MQTT topic for error messages
# - HTTP_DEVICE_ENDPOINT: The HTTP endpoint for the device
# - DEVICE_ID: The device ID
# - POLLING_INTERVAL: The interval for polling the sensor data
# - JSON_SCHEMA: The JSON schema used to validate sensor data
# =============================================================================

# STAGE 1: Builder - Compiles the Rust application
FROM --platform=$BUILDPLATFORM tonistiigi/xx:master AS xx
FROM --platform=$BUILDPLATFORM rust:slim-bookworm AS builder
RUN rustup update stable && \
    rustup component add rustfmt

COPY --from=xx / /

# Install OpenSSL development libraries, C compiler, curl, CA certificates, kernel headers, and other build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl-dev=3.0.16-1~deb12u1 \
    pkg-config=1.8.1-1 \
    gcc=4:12.2.0-3 \
    make=4.3-4.1 \
    binutils=2.40-2 \
    libc6-dev=2.36-9+deb12u10 \
    curl=7.88.1-10+deb12u12 \
    ca-certificates=20230311 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile minimal \
    --default-toolchain 1.86.0 \
    --component rustc,cargo,rust-std

# Add Rust binaries to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

ARG USE_REPLACE_WITH=false

# Now build your Rust app
WORKDIR /usr/src/app
COPY ./src ./src
COPY ./Cargo.toml ./Cargo.toml
COPY ./.cargo ./.cargo
RUN cargo build --release

# STAGE 2: Runtime - Creates the minimal production image
FROM --platform=$BUILDPLATFORM rust:slim-bookworm

# Install runtime dependencies and create a non-root user
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates=20230311 \
    passwd=1:4.13+dfsg1-1+deb12u1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy compiled binary from builder stage
COPY --from=builder /usr/src/app/target/release/http-connector /app/http-connector

# Set proper ownership and permissions
RUN chown appuser:appuser /app/http-connector && \
    chmod +x /app/http-connector

# Use non-root user
USER appuser

# Set entrypoint
ENTRYPOINT ["/app/http-connector"]
