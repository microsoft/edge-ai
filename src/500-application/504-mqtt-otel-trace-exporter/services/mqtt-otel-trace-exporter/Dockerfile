# =============================================================================
# MQTT OTel Trace Exporter Dockerfile
#
# Multi-stage build for the MQTT OpenTelemetry trace exporter application,
# which exports MQTT messages with OpenTelemetry trace context.
# 1. A builder stage that compiles the Rust application
# 2. A minimal runtime container with only the necessary dependencies
# =============================================================================

ARG BUILDPLATFORM=linux/amd64

# =============================================================================
# STAGE 1: Builder - Compiles the Rust application
# =============================================================================
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS builder

# Install build dependencies
RUN tdnf install -y openssl-devel gcc make binutils glibc-devel curl ca-certificates && \
    tdnf clean all

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Rust via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    --profile minimal \
    --default-toolchain 1.90.0 \
    --component rustc,cargo,rust-std

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY .cargo/ .cargo/
COPY src/ ./src/

RUN cargo build --release

# =============================================================================
# STAGE 2: Runtime - Creates the minimal production image
# =============================================================================
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81

# Upgrade all packages to latest versions to fix vulnerabilities
RUN tdnf upgrade -y && tdnf clean all

# Install CA certificates and shadow-utils for creating users
RUN tdnf install -y ca-certificates shadow-utils && \
    tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/target/release/mqtt-otel-trace-exporter /app/mqtt-otel-trace-exporter

# Set proper ownership for the application binary
RUN chown appuser:appuser /app/mqtt-otel-trace-exporter && \
    chmod +x /app/mqtt-otel-trace-exporter

# Use the non-root user for better security
USER appuser

ENTRYPOINT ["/app/mqtt-otel-trace-exporter"]
