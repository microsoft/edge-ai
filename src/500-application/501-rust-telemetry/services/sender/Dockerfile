# =============================================================================
# Telemetry Sender Dockerfile
#
# This Dockerfile builds a lightweight container for the telemetry sender application,
# which publishes MQTT messages with OpenTelemetry trace context.
# The build uses a multi-stage approach:
# 1. A builder stage that compiles the Rust application
# 2. A slim runtime container with only the necessary dependencies
#
# The container expects the following environment variables:
# - AIO_MQTT_USE_TLS: Whether to use TLS for MQTT connections
# - AIO_MQTT_CLIENT_ID: MQTT client ID
# - AIO_BROKER_HOSTNAME: MQTT broker hostname
# - AIO_BROKER_TCP_PORT: MQTT broker port
# - TOPIC: The MQTT topic to publish messages to
# - OTEL_SERVICE_NAME: The service name for OpenTelemetry
# - OTEL_EXPORTER_OTLP_ENDPOINT: OpenTelemetry collector endpoint
# =============================================================================
# STAGE 1: Builder - Compiles the Rust application
# =============================================================================
FROM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:b462b8e95dfa12b3fefc95025a627306a527de61db17b8519a59b8e25f1663c7 AS builder

# Install OpenSSL development libraries, C compiler, curl, CA certificates, and other build dependencies
RUN tdnf install -y openssl-devel-1.1.1k-36.cm2 gcc-11.2.0-8.cm2 make-4.3-2.cm2 binutils-2.37-14.cm2 glibc-devel-2.35-7.cm2 curl-8.8.0-5.cm2 ca-certificates-2.0.0-19.cm2 && \
    tdnf clean all

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# NOTE: The rust install should be removed when v1.85 is available
# See Open Issue: https://github.com/microsoft/azurelinux/issues/12837
# A rust version that supports edition 2024 is needed to use Azure IoT Operations crates
# Install Rust and immediately source the environment in the same RUN command
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile minimal \
    --default-toolchain 1.86.0 \
    --component rustc,cargo,rust-std

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

# Copy only the files needed for dependency resolution
# This leverages Docker's layer caching for faster rebuilds
COPY ./Cargo.toml ./Cargo.toml

# Define a build argument to control whether to use replace-with (default to false for local builds)
ARG USE_REPLACE_WITH=false

# Create .cargo directory, config file, and dummy main.rs for dependency caching
RUN mkdir -p .cargo && \
    echo '[registries]' > .cargo/config.toml && \
    echo 'aio-sdks = { index = "sparse+https://pkgs.dev.azure.com/azure-iot-sdks/iot-operations/_packaging/preview/Cargo/index/" }' >> .cargo/config.toml && \
    echo '' >> .cargo/config.toml && \
    if [ "$USE_REPLACE_WITH" = "true" ]; then \
      echo '[source.crates-io]' >> .cargo/config.toml && \
      echo 'replace-with = "aio-sdks"' >> .cargo/config.toml && \
      echo '' >> .cargo/config.toml && \
      echo '# Note: This requires authentication to the Azure Artifacts feed' >> .cargo/config.toml && \
      echo '# The pipeline should provide credentials to access both Azure packages and mirrored crates.io packages' >> .cargo/config.toml; \
    else \
      echo '# For local development: not using replace-with to avoid authentication issues' >> .cargo/config.toml; \
    fi && \
    mkdir -p src && \
    echo 'fn main() { println!("dependency build"); }' > src/main.rs

# First build step - compile and cache dependencies only
RUN cargo build --release

# Now copy the actual application source code and rebuild with real code
COPY ./src ./src
# Touch main.rs to ensure it's recompiled with the real code
RUN touch src/main.rs && cargo build --release

# =============================================================================
# STAGE 2: Runtime - Creates the minimal production image
# =============================================================================
FROM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:b462b8e95dfa12b3fefc95025a627306a527de61db17b8519a59b8e25f1663c7 AS runtime

# Install only the necessary runtime dependencies and create a non-root user
RUN tdnf install -y ca-certificates-2.0.0-19.cm2 shadow-utils-4.9-13.cm2 && \
    tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

# Set up application directory
WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /usr/src/app/target/release/sender /app/sender

# Set proper ownership for the application binary
RUN chown appuser:appuser /app/sender && \
    chmod +x /app/sender

# Use the non-root user for better security
USER appuser

# Set the entrypoint
ENTRYPOINT ["/app/sender"]
