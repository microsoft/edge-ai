# Multi-stage build for ai-edge-inference with configurable backend support
# Build with: docker build --build-arg BACKEND=onnx|candle .
# Cross-compilation support stage (pinned to versioned SHA256 digest for supply chain security)
FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.9.0@sha256:c64defb9ed5a91eacb37f96ccc3d4cd72521c4bd18d5442905b95e2226b0e707 AS xx

# Build stage - using SHA-pinned Azure Linux 3.0 image
# SHA mapping maintained in scripts/security/Update-DockerSHAPinning.ps1
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS build

# Install build dependencies including cross-compilation tools
RUN tdnf install -y \
    openssl-devel \
    gcc \
    make \
    binutils \
    glibc-devel \
    kernel-headers \
    curl \
    ca-certificates \
    clang \
    pkgconf-pkg-config \
    protobuf-devel \
    tar \
    && tdnf clean all

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Rust via rustup-init with sha256 verification (OSSF Pinned-Dependencies)
ARG RUST_TOOLCHAIN=1.90.0
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
    echo "$(awk '{print $1}' "${RUSTUP_HASH}")  ${RUSTUP_INIT}" | sha256sum -c -; \
    chmod +x "${RUSTUP_INIT}"; \
    "${RUSTUP_INIT}" -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN}" --component rustc,cargo,rust-std,rustfmt; \
    rm -rf "${RUSTUP_DIR}" "${RUSTUP_HASH}"

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

COPY --from=xx / /
ARG TARGETPLATFORM
ARG BACKEND=onnx

# Conditionally install ONNX Runtime dependencies (only for ONNX backend)
WORKDIR /tmp
RUN if [ "$BACKEND" = "onnx" ]; then \
        mkdir -p /opt/onnxruntime && \
        # Use amd64 as default, can be enhanced for multi-arch later
        curl -sSfL -o "onnxruntime-linux-x64-1.24.4.tgz" "https://github.com/microsoft/onnxruntime/releases/download/v1.24.4/onnxruntime-linux-x64-1.24.4.tgz" && \
        tar -xzf "onnxruntime-linux-x64-1.24.4.tgz" && \
        cp -r onnxruntime-linux-x64-1.24.4/* /opt/onnxruntime/ && \
        rm -rf onnxruntime-linux-x64-1.24.4.tgz onnxruntime-linux-x64-1.24.4; \
    fi

WORKDIR /app

# Define a build argument to control whether to use replace-with (default to false for local builds)
ARG USE_REPLACE_WITH=false

# Create .cargo directory and config file for Azure IoT Operations SDK access
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
    fi

# Copy the ai-edge-inference-crate dependency to the correct relative path
COPY ./ai-edge-inference-crate ../ai-edge-inference-crate

# Copy source code and configuration
COPY ./ai-edge-inference/src ./src
COPY ./ai-edge-inference/Cargo.toml ./Cargo.toml
COPY ./ai-edge-inference/Cargo.lock ./Cargo.lock
COPY ./ai-edge-inference/.cargo ./.cargo

# Point ort-sys to the pre-downloaded ONNX Runtime (avoids downloading incompatible binaries)
ENV ORT_LIB_LOCATION="/opt/onnxruntime/lib"
ENV ORT_PREFER_DYNAMIC_LINK="1"

# Build the application with backend-specific features
RUN if [ "$BACKEND" = "candle" ]; then \
        cargo build --release --features candle --no-default-features; \
    elif [ "$BACKEND" = "onnx" ]; then \
        cargo build --release --features onnx-runtime --no-default-features; \
    else \
        echo "Invalid BACKEND: $BACKEND. Use 'onnx' or 'candle'" && exit 1; \
    fi

# Create a build info file for runtime verification
RUN echo "backend=${BACKEND}" > /app/build-info.txt && \
    echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/build-info.txt

# Runtime stage - using SHA-pinned Azure Linux 3.0 image
# SHA mapping maintained in scripts/security/Update-DockerSHAPinning.ps1
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS runtime
ARG BACKEND=onnx

# Upgrade all packages to latest versions to fix vulnerabilities
RUN tdnf upgrade -y && tdnf clean all

# Install runtime dependencies and create non-root user
RUN tdnf install -y \
    ca-certificates \
    ncurses-libs \
    shadow-utils \
    tar \
    && tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

# Conditionally copy ONNX Runtime (only for ONNX backend)
RUN if [ "$BACKEND" = "onnx" ]; then \
        mkdir -p /opt/onnxruntime; \
    fi

# Copy ONNX Runtime from build stage if needed
COPY --from=build /opt/onnxruntime /opt/onnxruntime

# Copy application binary and build info
COPY --from=build /app/target/release/ai-edge-mqtt-publisher /usr/local/bin/ai-edge-mqtt-publisher
COPY --from=build /app/build-info.txt /app/build-info.txt

# Set proper ownership and permissions
RUN chown -R appuser:appuser /usr/local/bin/ai-edge-mqtt-publisher /app && \
    chmod +x /usr/local/bin/ai-edge-mqtt-publisher

# Set environment variables
ENV RUST_LOG=info
ENV MODEL_DIRECTORY=/models
ENV METRICS_PORT=8080
ENV HEALTH_PORT=8081

# Set ONNX Runtime environment variables (will be ignored for Candle)
ENV LD_LIBRARY_PATH="/opt/onnxruntime/lib"
ENV ORT_LIB_LOCATION="/opt/onnxruntime/lib"

# Use the non-root user for better security
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["/usr/local/bin/ai-edge-mqtt-publisher", "--health-check"]

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/ai-edge-mqtt-publisher"]

# Labels for build metadata
ARG BACKEND
LABEL ai.edge.inference.backend="${BACKEND}"
LABEL ai.edge.inference.version="0.2.0"
LABEL maintainer="Edge AI Team"
