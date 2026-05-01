# ClusterFuzzLite builder image for edge-ai fuzz harnesses.
#
# Polyglot single-Dockerfile pattern (issue #459): the CFLite GitHub Action
# forwards its `language:` input as the `LANGUAGE` build-arg/env-var, which
# selects the matching `gcr.io/oss-fuzz-base/base-builder-${LANGUAGE}` image.
# A shared `build.sh` dispatches to per-language `build_<lang>.sh` scripts
# (rust, python, javascript).
#
# IMPORTANT: do NOT pin a base-image tag (e.g. :ubuntu-24-04). The
# ClusterFuzzLite GitHub Action runner is Ubuntu 20.04 (glibc 2.31). The
# 24.04-tagged base produces binaries linked against glibc >= 2.32 which fail
# bad_build_check on the runner ("GLIBC_2.32 not found"). The default tag
# tracks the runner's glibc.
ARG LANGUAGE=rust
FROM gcr.io/oss-fuzz-base/base-builder-${LANGUAGE}

ENV DEBIAN_FRONTEND=noninteractive

COPY . $SRC/edge-ai
COPY .clusterfuzzlite/build.sh        $SRC/build.sh
COPY .clusterfuzzlite/build_rust.sh   $SRC/build_rust.sh
COPY .clusterfuzzlite/build_python.sh $SRC/build_python.sh
COPY .clusterfuzzlite/build_js.sh     $SRC/build_js.sh

WORKDIR $SRC/edge-ai
