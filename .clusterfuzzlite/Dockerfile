# ClusterFuzzLite builder image for edge-ai fuzz harnesses.
#
# Single-Dockerfile, single-base-image pattern (issue #459): the CFLite GitHub
# Action does NOT forward its `language:` input as a Docker build-arg, so a
# `LANGUAGE`-parameterized base image cannot be selected at build time. Instead
# we build on top of `base-builder-rust` (which contains the OSS-Fuzz tooling
# plus a working python3) and dispatch to per-language `build_<lang>.sh`
# scripts via the shared `build.sh`. The OSS-Fuzz `compile` step uses the
# runtime `FUZZING_LANGUAGE` env var (set by CFLite from `language:`) to know
# how to wrap each harness.
#
# IMPORTANT: do NOT pin a base-image tag (e.g. :ubuntu-24-04). The
# ClusterFuzzLite GitHub Action runner is Ubuntu 20.04 (glibc 2.31). The
# 24.04-tagged base produces binaries linked against glibc >= 2.32 which fail
# bad_build_check on the runner ("GLIBC_2.32 not found"). The default tag
# tracks the runner's glibc.
FROM gcr.io/oss-fuzz-base/base-builder-rust

ENV DEBIAN_FRONTEND=noninteractive

# Node.js (and npm) are required by build_js.sh to run `npm ci` and `npx jazzer`
# for JavaScript fuzz harnesses. The base-builder-rust image does not include
# Node. Install Node 20.x from the official prebuilt linux-x64 tarball on
# nodejs.org instead of apt: the CFLite build container cannot reliably reach
# Ubuntu's archive/security mirrors (port 80 to archive.ubuntu.com and
# security.ubuntu.com regularly times out from the runner), but HTTPS to
# nodejs.org works. curl + ca-certificates are already present in the base
# image.
ARG NODE_VERSION=20.18.1
# hadolint ignore=DL3003
RUN curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
  && tar -xJf "node-v${NODE_VERSION}-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v${NODE_VERSION}-linux-x64.tar.xz" \
  && node --version \
  && npm --version

# atheris must be present in the image before the OSS-Fuzz `compile` step runs
# (compile imports the Python fuzz targets to wrap them, which fails if atheris
# is not yet installed). Install unconditionally: the ClusterFuzzLite GitHub
# Action does not forward its `language:` input as a Docker build-arg, so the
# `LANGUAGE` ARG above is always the default at image-build time and a
# conditional install would never fire for python harnesses.
# hadolint ignore=DL3013
RUN python3 -m pip install --no-cache-dir atheris pyinstaller

COPY . $SRC/edge-ai
COPY .clusterfuzzlite/build.sh        $SRC/build.sh
COPY .clusterfuzzlite/build_rust.sh   $SRC/build_rust.sh
COPY .clusterfuzzlite/build_python.sh $SRC/build_python.sh
COPY .clusterfuzzlite/build_js.sh     $SRC/build_js.sh

WORKDIR $SRC/edge-ai
