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

# =============================================================================
# STAGE 1: Builder - Compiles the Rust application
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/rust:1.86.0-6-azl3.0.20250910@sha256:c02d008ae63540df5dd366d92247736a5a20948c8543f33b15f6b7ba7cd412f0 AS builder

WORKDIR /usr/src/app

COPY ./services/broker/Cargo.toml ./Cargo.toml
COPY ./services/broker/Cargo.lock ./Cargo.lock
COPY ./services/broker/.cargo/config.toml ./.cargo/config.toml

# Install build dependencies for Rust compilation
RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY && \
    tdnf update -y && \
    tdnf install -y pkgconfig openssl-devel

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN rustup update stable && \
    rustup component add rustfmt

ARG USE_REPLACE_WITH=false

# Build the Rust application in release mode
COPY ./services/broker/src ./src
RUN cargo build --release

# =============================================================================
# STAGE 2: Runtime - Creates the minimal production image
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81
# Upgrade all packages to latest versions to fix vulnerabilities
RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY && \
    tdnf upgrade -y && \
    tdnf clean all

# Install runtime dependencies and create non-root user
RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY && \
    tdnf update -y && \
    tdnf install -y ca-certificates util-linux wget systemd shadow-utils && \
    tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy compiled binary from builder stage
COPY --from=builder /usr/src/app/target/release/http-connector /app/http-connector

# Set proper ownership and permissions
RUN chown appuser:appuser /app/http-connector && \
    chmod +x /app/http-connector

# Use non-root user for security
USER appuser

# Set entrypoint
ENTRYPOINT ["/app/http-connector"]
