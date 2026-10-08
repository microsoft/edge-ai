# =============================================================================
# Telemetry Receiver Dockerfile
#
# This Dockerfile builds a lightweight container for the telemetry receiver application,
# which subscribes to MQTT messages and maintains OpenTelemetry trace context.
# The build uses a multi-stage approach:
# 1. A builder stage that compiles the Rust application
# 2. A slim runtime container with only the necessary dependencies
#
# The container expects the following environment variables:
# - AIO_MQTT_USE_TLS: Whether to use TLS for MQTT connections
# - AIO_MQTT_CLIENT_ID: MQTT client ID
# - AIO_BROKER_HOSTNAME: MQTT broker hostname
# - AIO_BROKER_TCP_PORT: MQTT broker port
# - TOPIC: The MQTT topic to subscribe to
# - OTEL_SERVICE_NAME: The service name for OpenTelemetry
# - OTEL_EXPORTER_OTLP_ENDPOINT: OpenTelemetry collector endpoint
# =============================================================================
# STAGE 1: Builder - Compiles the Rust application
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS builder

# Install OpenSSL development libraries, C compiler, curl, CA certificates, and other build dependencies
RUN tdnf install -y openssl-devel gcc make binutils glibc-devel curl ca-certificates && \
    tdnf clean all

# NOTE: The rust install should be removed when v1.85 is available for mcr.microsoft.com/cbl-mariner/base/rust:1
# See Open Issue: https://github.com/microsoft/azurelinux/issues/12837
# A rust version that supports edition 2024 is needed to use Azure IoT Operations crates

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Rust via rustup-init with sha256 verification (OSSF Pinned-Dependencies)
ARG RUST_TOOLCHAIN=1.86.0
RUN set -eux; \
    case "$(uname -m)" in \
        x86_64)  RUSTUP_ARCH="x86_64-unknown-linux-gnu" ;; \
        aarch64) RUSTUP_ARCH="aarch64-unknown-linux-gnu" ;; \
        *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    RUSTUP_DIR="$(mktemp -d)"; \
    RUSTUP_INIT="${RUSTUP_DIR}/rustup-init"; \
    RUSTUP_HASH="$(mktemp)"; \
    RUSTUP_URL="https://static.rust-lang.org/rustup/dist/${RUSTUP_ARCH}/rustup-init"; \
    curl --proto '=https' --tlsv1.2 -sSf "${RUSTUP_URL}"        -o "${RUSTUP_INIT}"; \
    curl --proto '=https' --tlsv1.2 -sSf "${RUSTUP_URL}.sha256" -o "${RUSTUP_HASH}"; \
    echo "$(cut -d ' ' -f 1 "${RUSTUP_HASH}")  ${RUSTUP_INIT}" | sha256sum -c -; \
    chmod +x "${RUSTUP_INIT}"; \
    "${RUSTUP_INIT}" -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN}" --component rustc,cargo,rust-std; \
    rm -rf "${RUSTUP_DIR}" "${RUSTUP_HASH}"

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

ARG CARGO_PROFILE_RELEASE_DEBUG=line-tables-only
ARG CARGO_PROFILE_RELEASE_STRIP=none
ENV CARGO_PROFILE_RELEASE_DEBUG=$CARGO_PROFILE_RELEASE_DEBUG
ENV CARGO_PROFILE_RELEASE_STRIP=$CARGO_PROFILE_RELEASE_STRIP

WORKDIR /usr/src/app

# Copy only the files needed for dependency resolution
# This leverages Docker's layer caching for faster rebuilds
COPY ./Cargo.toml ./Cargo.toml
COPY ./Cargo.lock ./Cargo.lock

# Create dummy main.rs for dependency caching
RUN mkdir -p .cargo src && \
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
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81
# Upgrade all packages to latest versions to fix vulnerabilities
RUN tdnf upgrade -y && tdnf clean all

# Install only the necessary runtime dependencies and create a non-root user
RUN tdnf install -y ca-certificates shadow-utils && \
    tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

# Set up application directory
WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /usr/src/app/target/release/receiver /app/receiver

# Set proper ownership for the application binary
RUN chown appuser:appuser /app/receiver && \
    chmod +x /app/receiver

# Use the non-root user for better security
USER appuser

# Set the entrypoint
ENTRYPOINT ["/app/receiver"]
