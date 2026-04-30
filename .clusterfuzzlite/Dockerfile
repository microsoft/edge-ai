# ClusterFuzzLite builder image for edge-ai fuzz harnesses.
# Provides toolchains for Rust (cargo-fuzz/libFuzzer), Python (Atheris), and JS (Jazzer.js).
FROM gcr.io/oss-fuzz-base/base-builder-rust:v1

ENV DEBIAN_FRONTEND=noninteractive

# Python 3.12 + Atheris for Python harnesses.
# Base image is Ubuntu 20.04 (focal); python3.12 is unavailable from default apt
# repositories, so install via the deadsnakes PPA.
# hadolint ignore=DL3008,DL3013
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
    && curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3.12 \
    && python3.12 -m pip install --no-cache-dir \
        atheris==3.0.0 \
        coverage==7.6.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 + Jazzer.js for JS harnesses.
# hadolint ignore=DL3008,DL4006
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g --no-audit --no-fund \
        @jazzer.js/core@2.1.0 \
        c8@10.1.2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . $SRC/edge-ai
COPY .clusterfuzzlite/build.sh $SRC/build.sh
COPY .clusterfuzzlite/build_rust.sh $SRC/build_rust.sh
COPY .clusterfuzzlite/build_python.sh $SRC/build_python.sh
COPY .clusterfuzzlite/build_js.sh $SRC/build_js.sh

WORKDIR $SRC/edge-ai
