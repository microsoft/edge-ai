ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM rust:1.90-bullseye@sha256:cfb3f582db21e4b4168bffa96397db118d288f1c55026cf016911e147476184e AS builder

# hadolint ignore=DL3008
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        pkg-config \
        libssl-dev; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY .cargo/ .cargo/
COPY src/ ./src/

RUN cargo build --release

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:9d888a796a79fcb315f4895e39c38a7913f752347395fd63f1f22464630a92a6 AS runtime

WORKDIR /app

COPY --from=builder /app/target/release/mqtt-otel-trace-exporter /app/mqtt-otel-trace-exporter

RUN chmod +x /app/mqtt-otel-trace-exporter

USER nobody

ENTRYPOINT ["/app/mqtt-otel-trace-exporter"]
