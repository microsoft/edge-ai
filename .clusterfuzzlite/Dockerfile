# ClusterFuzzLite builder image for edge-ai fuzz harnesses.
# Provides toolchains for Rust (cargo-fuzz/libFuzzer), Python (Atheris), and JS (Jazzer.js).
FROM gcr.io/oss-fuzz-base/base-builder-rust:ubuntu-24-04

ENV DEBIAN_FRONTEND=noninteractive

# Python 3.11 + Atheris for Python harnesses.
# Base image is Ubuntu 24.04 (noble); system python is 3.12 but atheris 3.0.0
# only supports up to 3.11, so install python3.11 from the deadsnakes PPA.
# Tracking move to atheris 3.12+ in issue #454.
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
        python3.11 \
        python3.11-dev \
        python3.11-venv \
        python3-pip \
    && curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3.11 \
    && python3.11 -m pip install --no-cache-dir \
        atheris==3.0.0 \
        coverage==7.6.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 + Jazzer.js for JS harnesses.
# @jazzer.js/fuzzer@2.1.0 ships no napi prebuilts matching this base
# (target=4 runtime=napi arch=x64 platform=linux), so install the source-build
# toolchain (prebuild/cmake-js/node-gyp + build-essential/cmake/python3) first
# so the `npm run prebuild` fallback can compile the native addon.
# hadolint ignore=DL3008,DL4006
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends \
        nodejs \
        build-essential \
        cmake \
        python3 \
    && npm install -g --no-audit --no-fund \
        prebuild \
        cmake-js \
        node-gyp \
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
