ARG BUILDPLATFORM=linux/amd64

# =============================================================================
# Build Stage
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY \
    && tdnf -y update \
    && tdnf -y install \
        ca-certificates curl git tar xz gzip which findutils \
        pkgconfig cmake make gcc gcc-c++ \
        glibc-devel kernel-headers binutils libstdc++-devel \
        diffutils file patch perl gawk \
        openssl openssl-devel zlib zlib-devel \
        yasm nasm autoconf automake libtool \
    && tdnf clean all

ENV RUSTUP_HOME=/root/.rustup \
    CARGO_HOME=/root/.cargo \
    PATH=/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin
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
    echo "$(awk '{print $1}' "${RUSTUP_HASH}")  ${RUSTUP_INIT}" | sha256sum -c -; \
    chmod +x "${RUSTUP_INIT}"; \
    "${RUSTUP_INIT}" -y --profile minimal --default-toolchain "${RUST_TOOLCHAIN}" --component rustc,cargo,rust-std; \
    rm -rf "${RUSTUP_DIR}" "${RUSTUP_HASH}"; \
    rustc --version && cargo --version

WORKDIR /app

# Pin x264 to specific commit on `stable` branch with SHA256 verification
ARG X264_COMMIT=b35605ace3ddf7c1a5d67a2eb553f034aef41d55
ARG X264_SHA256=6eeb82934e69fd51e043bd8c5b0d152839638d1ce7aa4eea65a3fedcf83ff224
RUN set -eux; \
    curl -fsSL -o /tmp/x264.tar.bz2 "https://code.videolan.org/videolan/x264/-/archive/${X264_COMMIT}/x264-${X264_COMMIT}.tar.bz2"; \
    echo "${X264_SHA256}  /tmp/x264.tar.bz2" | sha256sum -c -; \
    mkdir -p /tmp/x264 && tar -xjf /tmp/x264.tar.bz2 -C /tmp/x264 --strip-components=1
WORKDIR /tmp/x264
RUN set -eux; \
    ./configure --prefix=/usr/local --enable-shared --disable-cli; \
    make -j"$(nproc)"; \
    make install; \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local-x264.conf; \
    if command -v ldconfig >/dev/null 2>&1; then ldconfig; fi; \
    rm -rf /tmp/x264 /tmp/x264.tar.bz2
WORKDIR /app

ARG FFMPEG_VERSION=7.1.1
ARG FFMPEG_SHA256=733984395e0dbbe5c046abda2dc49a5544e7e0e1e2366bba849222ae9e3a03b1
ENV CC=gcc CXX=g++
ENV FFMPEG_VERSION=${FFMPEG_VERSION}
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig

RUN set -eux; echo 'int main(){return 0;}' > /tmp/t.c; ${CC} /tmp/t.c -o /tmp/t; file /tmp/t; rm -f /tmp/t /tmp/t.c
RUN set -eux; \
    curl -fsSL -o ffmpeg.tar.xz "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz"; \
    echo "${FFMPEG_SHA256}  ffmpeg.tar.xz" | sha256sum -c -; \
    mkdir -p /tmp/ffmpeg && tar -xJf ffmpeg.tar.xz -C /tmp/ffmpeg --strip-components=1
WORKDIR /tmp/ffmpeg
RUN set -eux; \
    ./configure \
        --prefix=/usr/local \
        --enable-gpl \
        --enable-libx264 \
        --disable-debug \
        --disable-doc \
        --enable-shared \
        --enable-pic; \
    make -j"$(nproc)"; \
    make install; \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local-ffmpeg.conf; \
    if command -v ldconfig >/dev/null 2>&1; then ldconfig; fi; \
    rm -rf /tmp/ffmpeg ffmpeg.tar.xz
WORKDIR /app

COPY Cargo.toml ./Cargo.toml
COPY Cargo.lock ./Cargo.lock

RUN mkdir -p src && echo "fn main() {}" > src/main.rs

RUN cargo build --release && rm -rf src

COPY src ./src

RUN cargo build --release

# =============================================================================
# Runtime Stage
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81

RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY && \
    tdnf upgrade -y && \
    tdnf clean all

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

RUN set -eux; \
    rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY; \
    tdnf -y update \
    && tdnf -y install \
        ca-certificates \
        openssl \
        zlib \
    && tdnf clean all \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/local-ffmpeg.conf \
    && echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local-ffmpeg.conf \
    && if command -v ldconfig >/dev/null 2>&1; then ldconfig; fi

COPY --from=build /app/target/release/video-to-gif /usr/local/bin/video-to-gif
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/lib64 /usr/local/lib64
COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=build /usr/local/bin/ffprobe /usr/local/bin/ffprobe

RUN useradd -r -u 65532 nonroot
USER nonroot:nonroot

ENTRYPOINT ["/usr/local/bin/video-to-gif"]
CMD ["--help"]
