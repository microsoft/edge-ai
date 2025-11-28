# Build stage - using SHA-pinned Azure Linux image
# SHA mapping maintained in scripts/security/Update-DockerSHAPinning.ps1
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:3ea2978438516bea837ebcf2140d487c1305317c2acea100393b775365b0d7f5 AS build

# Install build dependencies including Rust and ONNX Runtime dependencies
RUN tdnf install -y \
    openssl-devel-1.1.1k-36.cm2 \
    gcc-11.2.0-8.cm2 \
    make-4.3-3.cm2 \
    binutils-2.37-16.cm2 \
    glibc-devel-2.35-7.cm2 \
    curl-8.8.0-6.cm2 \
    ca-certificates-2.0.0-22.cm2 \
    clang-12.0.1-4.cm2 \
    pkgconf-pkg-config-1.8.0-3.cm2 \
    protobuf-devel-3.17.3-4.cm2 \
    wget-1.21.2-4.cm2 \
    tar-1.34-3.cm2 \
    && tdnf clean all

# Set shell options for better error handling with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN wget -q https://sh.rustup.rs -O /tmp/rustup.sh && \
    bash /tmp/rustup.sh -y --profile minimal --default-toolchain 1.86.0 --component rustc,cargo,rust-std,rustfmt && \
    rm /tmp/rustup.sh

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# Copy the entire services directory
COPY . .

# Build the application from ai-edge-inference directory
WORKDIR /app/ai-edge-inference

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

# Download and install ONNX Runtime in build stage
# hadolint ignore=DL4001
RUN mkdir -p /opt/onnxruntime
WORKDIR /tmp
# Using wget for large binary downloads (curl used for rustup script installation)
RUN wget -q https://github.com/microsoft/onnxruntime/releases/download/v1.17.0/onnxruntime-linux-x64-1.17.0.tgz && \
    tar -xzf onnxruntime-linux-x64-1.17.0.tgz && \
    cp -r onnxruntime-linux-x64-1.17.0/* /opt/onnxruntime/ && \
    rm -rf onnxruntime-linux-x64-1.17.0.tgz onnxruntime-linux-x64-1.17.0

# Let ort crate handle ONNX Runtime automatically
# Force rebuild by adding timestamp: 2025-09-25 02:26
WORKDIR /app
RUN cargo build --release

# Runtime stage - using SHA-pinned Azure Linux image
# SHA mapping maintained in scripts/security/Update-DockerSHAPinning.ps1
FROM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:3ea2978438516bea837ebcf2140d487c1305317c2acea100393b775365b0d7f5

# Install runtime dependencies and ONNX Runtime
RUN tdnf install -y \
    wget-1.21.2-4.cm2 \
    ca-certificates-2.0.0-22.cm2 \
    openssl-1.1.1k-36.cm2 \
    shadow-utils-4.9-14.cm2 \
    tar-1.34-3.cm2 \
    && tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

# Download and install ONNX Runtime
RUN mkdir -p /opt/onnxruntime && \
    wget -q https://github.com/microsoft/onnxruntime/releases/download/v1.17.0/onnxruntime-linux-x64-1.17.0.tgz && \
    tar -xzf onnxruntime-linux-x64-1.17.0.tgz -C /opt/onnxruntime --strip-components=1 && \
    rm onnxruntime-linux-x64-1.17.0.tgz

# Set library path for ONNX Runtime and debug info
ENV LD_LIBRARY_PATH="/opt/onnxruntime/lib"
ENV ORT_LIB_LOCATION="/opt/onnxruntime/lib"

# Copy ONNX Runtime libraries from build stage to runtime
COPY --from=build /opt/onnxruntime/lib/ /opt/onnxruntime/lib/

# Debug: List what's actually in the ONNX Runtime directory
RUN ls -la /opt/onnxruntime/ || echo "ONNX Runtime directory not found" && \
    ls -la /opt/onnxruntime/lib/ || echo "ONNX Runtime lib directory not found" && \
    echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH" && \
    echo "Testing library loading:" && \
    ldd --help > /dev/null 2>&1 && ldd /opt/onnxruntime/lib/libonnxruntime.so || echo "ldd failed"

# Copy application binary
COPY --from=build /app/ai-edge-inference/target/release/ai-edge-mqtt-publisher /usr/local/bin/ai-edge-mqtt-publisher

# Set proper ownership and permissions
RUN chown appuser:appuser /usr/local/bin/ai-edge-mqtt-publisher && \
    chmod +x /usr/local/bin/ai-edge-mqtt-publisher

# Set environment variables
ENV RUST_LOG=info
ENV MODEL_DIRECTORY=/models
ENV METRICS_PORT=8080
ENV HEALTH_PORT=8081

# Use the non-root user for better security
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["/usr/local/bin/ai-edge-mqtt-publisher", "--health-check"]

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/ai-edge-mqtt-publisher"]
