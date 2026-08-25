# =============================================================================
# Akri HTTP POST Connector Dockerfile
#
# Multi-stage build for the Akri HTTP POST Connector observation spike:
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

# Install Rust via rustup-init with architecture-specific immutable checksums
ARG RUST_TOOLCHAIN=1.90.0
ARG RUSTUP_INIT_SHA256_X86_64=4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10
ARG RUSTUP_INIT_SHA256_AARCH64=9732d6c5e2a098d3521fca8145d826ae0aaa067ef2385ead08e6feac88fa5792
RUN --mount=type=secret,id=build_root_ca \
    set -eux; \
    if [[ -f /run/secrets/build_root_ca ]]; then \
        cp /run/secrets/build_root_ca /etc/pki/ca-trust/source/anchors/build-root-ca.crt; \
        update-ca-trust; \
    fi; \
    case "$(uname -m)" in \
        x86_64)  RUSTUP_ARCH="x86_64-unknown-linux-gnu"; RUSTUP_INIT_SHA256="${RUSTUP_INIT_SHA256_X86_64}" ;; \
        aarch64) RUSTUP_ARCH="aarch64-unknown-linux-gnu"; RUSTUP_INIT_SHA256="${RUSTUP_INIT_SHA256_AARCH64}" ;; \
        *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    RUSTUP_DIR="$(mktemp -d)"; \
    RUSTUP_INIT="${RUSTUP_DIR}/rustup-init"; \
    RUSTUP_URL="https://static.rust-lang.org/rustup/dist/${RUSTUP_ARCH}/rustup-init"; \
    curl --proto '=https' --tlsv1.2 -sSf "${RUSTUP_URL}" -o "${RUSTUP_INIT}"; \
    echo "${RUSTUP_INIT_SHA256}  ${RUSTUP_INIT}" | sha256sum -c -; \
    chmod +x "${RUSTUP_INIT}"; \
    "${RUSTUP_INIT}" -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN}" --component rustc,cargo,rust-std; \
    rm -rf "${RUSTUP_DIR}"; \
    if [[ -f /etc/pki/ca-trust/source/anchors/build-root-ca.crt ]]; then \
        rm -f /etc/pki/ca-trust/source/anchors/build-root-ca.crt; \
        update-ca-trust; \
    fi

# Add Rust binaries to PATH for subsequent RUN commands
ENV PATH="/root/.cargo/bin:${PATH}"

ARG CARGO_PROFILE_RELEASE_DEBUG=line-tables-only
ARG CARGO_PROFILE_RELEASE_STRIP=none
ENV CARGO_PROFILE_RELEASE_DEBUG=$CARGO_PROFILE_RELEASE_DEBUG
ENV CARGO_PROFILE_RELEASE_STRIP=$CARGO_PROFILE_RELEASE_STRIP

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY .cargo/ .cargo/
COPY src/ ./src/

RUN --mount=type=secret,id=build_root_ca \
    set -eux; \
    if [[ -f /run/secrets/build_root_ca ]]; then \
        cp /run/secrets/build_root_ca /etc/pki/ca-trust/source/anchors/build-root-ca.crt; \
        update-ca-trust; \
    fi; \
    cargo build --locked --release; \
    if [[ -f /etc/pki/ca-trust/source/anchors/build-root-ca.crt ]]; then \
        rm -f /etc/pki/ca-trust/source/anchors/build-root-ca.crt; \
        update-ca-trust; \
    fi

# =============================================================================
# STAGE 2: Runtime - Creates the minimal production image
# =============================================================================
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81

# Install CA certificates and shadow-utils for creating users
RUN tdnf install -y ca-certificates shadow-utils && \
    tdnf clean all && \
    groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/target/release/akri-http-post-connector /app/akri-http-post-connector

# Set proper ownership for the application binary
RUN chown appuser:appuser /app/akri-http-post-connector && \
    chmod +x /app/akri-http-post-connector

# Use the non-root user for better security
USER appuser

ENTRYPOINT ["/app/akri-http-post-connector"]
