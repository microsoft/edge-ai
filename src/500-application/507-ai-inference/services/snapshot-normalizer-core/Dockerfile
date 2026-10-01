FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN tdnf install -y \
    ca-certificates \
    curl \
    gcc \
    glibc-devel \
    kernel-headers \
    make \
    openssl-devel \
    pkgconf-pkg-config \
    && tdnf clean all

ARG RUST_TOOLCHAIN=1.90.0
RUN set -eux; \
    case "$(uname -m)" in \
        x86_64) RUSTUP_ARCH="x86_64-unknown-linux-gnu" ;; \
        aarch64) RUSTUP_ARCH="aarch64-unknown-linux-gnu" ;; \
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    RUSTUP_DIR="$(mktemp -d)"; \
    RUSTUP_INIT="${RUSTUP_DIR}/rustup-init"; \
    RUSTUP_HASH="$(mktemp)"; \
    RUSTUP_URL="https://static.rust-lang.org/rustup/dist/${RUSTUP_ARCH}/rustup-init"; \
    curl --proto '=https' --tlsv1.2 -sSf "${RUSTUP_URL}" -o "${RUSTUP_INIT}"; \
    curl --proto '=https' --tlsv1.2 -sSf "${RUSTUP_URL}.sha256" -o "${RUSTUP_HASH}"; \
    echo "$(cut -d ' ' -f 1 "${RUSTUP_HASH}")  ${RUSTUP_INIT}" | sha256sum --check --strict; \
    chmod +x "${RUSTUP_INIT}"; \
    "${RUSTUP_INIT}" -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN}"; \
    rm -rf "${RUSTUP_DIR}" "${RUSTUP_HASH}"

ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release --locked

FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS runtime

RUN tdnf upgrade -y \
    && tdnf install -y ca-certificates openssl-libs shadow-utils \
    && tdnf clean all \
    && groupadd --system appuser \
    && useradd --system --gid appuser appuser

COPY --from=build /app/target/release/snapshot-normalizer-core /usr/local/bin/snapshot-normalizer

RUN chown appuser:appuser /usr/local/bin/snapshot-normalizer \
    && chmod 0555 /usr/local/bin/snapshot-normalizer

USER appuser
ENTRYPOINT ["/usr/local/bin/snapshot-normalizer"]

LABEL maintainer="Edge AI Team"
LABEL org.opencontainers.image.source="https://github.com/microsoft/edge-ai"
LABEL org.opencontainers.image.title="Snapshot Normalizer"