ARG BUILDPLATFORM=linux/amd64

# =============================================================================
# Build Stage
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81 AS build

# Ensure robust shell behavior and pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install build dependencies and multimedia/computer-vision headers
RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY \
    && tdnf -y update \
    && tdnf -y install \
        ca-certificates curl git tar xz gzip which findutils \
    pkgconfig cmake make gcc gcc-c++ clang clang-devel \
    glibc-devel kernel-headers binutils libstdc++-devel \
    diffutils file patch perl gawk \
        openssl openssl-devel zlib zlib-devel \
        yasm nasm autoconf automake libtool \
    && tdnf clean all

# Install Rust via rustup (stable)
ENV RUSTUP_HOME=/root/.rustup \
    CARGO_HOME=/root/.cargo \
    PATH=/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && rustc --version && cargo --version

WORKDIR /app

# Build and install x264 (software H.264 encoder) for FFmpeg
RUN set -eux; \
    git clone --depth 1 https://code.videolan.org/videolan/x264.git /tmp/x264
WORKDIR /tmp/x264
RUN set -eux; \
    ./configure --prefix=/usr/local --enable-shared --disable-cli; \
    make -j"$(nproc)"; \
    make install; \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local-x264.conf; \
    if command -v ldconfig >/dev/null 2>&1; then ldconfig; fi; \
    rm -rf /tmp/x264
WORKDIR /app
# Build and install FFmpeg from source (Mariner repos may not include ffmpeg libs)
ARG FFMPEG_VERSION=7.1.1
ENV CC=gcc CXX=g++
ENV FFMPEG_VERSION=${FFMPEG_VERSION}
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig

# Sanity check toolchain can produce executables
RUN set -eux; echo 'int main(){return 0;}' > /tmp/t.c; ${CC} /tmp/t.c -o /tmp/t; file /tmp/t; rm -f /tmp/t /tmp/t.c
RUN set -eux; \
    curl -fsSL -o ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz; \
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

# Build and install OpenCV from source (Mariner repos do not provide it)
ARG OPENCV_VERSION=4.10.0
ENV OPENCV_VERSION=${OPENCV_VERSION}
RUN set -eux; \
    curl -fsSL -o opencv.tar.gz https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.tar.gz; \
    mkdir -p /tmp/opencv && tar -xzf opencv.tar.gz -C /tmp/opencv --strip-components=1; \
    mkdir -p /tmp/opencv/build
WORKDIR /tmp/opencv/build
RUN set -eux; \
    cmake -G "Unix Makefiles" .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DWITH_FFMPEG=ON \
        -DWITH_GSTREAMER=OFF \
        -DWITH_OPENCL=OFF \
        -DWITH_QT=OFF \
        -DWITH_IPP=OFF \
        -DBUILD_LIST=core,videoio,imgproc,imgcodecs \
        -DBUILD_JPEG=OFF \
        -DBUILD_PNG=OFF \
        -DBUILD_TIFF=OFF \
        -DBUILD_ZLIB=OFF \
        -DOPENCV_GENERATE_PKGCONFIG=ON \
        -DBUILD_opencv_python=OFF \
        -DBUILD_opencv_python2=OFF \
        -DBUILD_opencv_python3=OFF; \
    make -j"$(nproc)"; \
    make install; \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local-opencv.conf; \
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local-opencv.conf || true; \
    if command -v ldconfig >/dev/null 2>&1; then ldconfig; fi; \
    rm -rf /tmp/opencv opencv.tar.gz

WORKDIR /app

# Copy dependency files first for better Docker layer caching
COPY ./services/media-capture-service/Cargo.toml ./Cargo.toml
COPY ./services/media-capture-service/Cargo.lock ./Cargo.lock
COPY ./services/media-capture-service/.cargo ./.cargo

# Create a dummy multi_trigger_binary.rs to build dependencies only
RUN mkdir -p src && echo "fn main() {}" > src/multi_trigger_binary.rs

# Build dependencies (this layer will be cached unless Cargo.toml changes)
RUN cargo build --release && rm -rf src

# Now copy the actual source code
COPY ./services/media-capture-service/src ./src

# Build the final application (only application code recompiles)
RUN cargo build --release

# =============================================================================
# Runtime Stage
# =============================================================================
FROM mcr.microsoft.com/azurelinux/base/core:3.0.20250910@sha256:919cfecd0ffe136adff3bea7030f3e6abc6633a4069a6de44b2070bb86c40c81
# Upgrade all packages to latest versions to fix vulnerabilities
RUN rpm --import /etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY && \
    tdnf upgrade -y && \
    tdnf clean all

# Ensure robust shell behavior and pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

# Install only the required runtime libraries
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

COPY --from=build /app/target/release/multi_trigger /multi_trigger
# Copy FFmpeg shared libs and optional binaries
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/lib64 /usr/local/lib64
COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=build /usr/local/bin/ffprobe /usr/local/bin/ffprobe
COPY ./services/media-capture-service/run.sh /
RUN chmod +x /run.sh

CMD ["/run.sh"]
