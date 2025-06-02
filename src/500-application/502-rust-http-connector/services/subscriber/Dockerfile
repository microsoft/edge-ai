# =============================================================================
# MQTT Telemetry Subscriber Dockerfile
#
# This Dockerfile builds a lightweight container for the Rust-based MQTT subscriber application.
# The application subscribes to MQTT messages published by the broker and processes telemetry data.
#
# The build uses a multi-stage approach:
# 1. Builder stage: Compiles the Rust application and caches dependencies for faster builds.
# 2. Runtime stage: Creates a minimal container with only the necessary runtime dependencies and a non-root user.
#
# The container expects the following environment variables:
# - AIO_MQTT_USE_TLS: Whether to use TLS for MQTT connections
# - AIO_MQTT_CLIENT_ID: MQTT client ID
# - AIO_BROKER_HOSTNAME: MQTT broker hostname
# - AIO_BROKER_TCP_PORT: MQTT broker port
# - MQ_TOPIC: The MQTT topic to subscribe to
# =============================================================================

# STAGE 1: Builder - Compiles the Rust application and caches dependencies
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

# Install Rust toolchain (v1.86.0) with minimal profile and required components
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile minimal \
    --default-toolchain 1.86.0 \
    --component rustc,cargo,rust-std

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

# Build argument to control registry source for dependencies
ARG USE_REPLACE_WITH=false

# Now build your Rust app
WORKDIR /usr/src/app
COPY ./src ./src
COPY ./Cargo.toml ./Cargo.toml
COPY ./.cargo ./.cargo
RUN cargo build --release

# =============================================================================
# STAGE 2: Runtime - Minimal production image with non-root user
# =============================================================================
FROM --platform=$BUILDPLATFORM rust:slim-bookworm

# Install runtime dependencies and create a non-root user
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates=20230311 \
    passwd=1:4.13+dfsg1-1+deb12u1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/app/target/release/subscriber /app/subscriber

# Set proper ownership and permissions for the binary
RUN chown appuser:appuser /app/subscriber && \
    chmod +x /app/subscriber

# Use the non-root user for better security
USER appuser

# Set the entrypoint to run the subscriber application
ENTRYPOINT ["/app/subscriber"]
