# ClusterFuzzLite builder image for edge-ai fuzz harnesses.
#
# Scoped to Rust (cargo-fuzz/libFuzzer) only.
#
# IMPORTANT: do NOT pin a base-image tag (e.g. :ubuntu-24-04). The
# ClusterFuzzLite GitHub Action runner is Ubuntu 20.04 (glibc 2.31). The
# 24.04-tagged base produces binaries linked against glibc >= 2.32 which fail
# bad_build_check on the runner ("GLIBC_2.32 not found"). The default tag
# tracks the runner's glibc.
#
# Python (Atheris) and JavaScript (Jazzer.js) harnesses are deferred: their
# toolchains will live in dedicated per-language builder containers tracked
# in a follow-up issue split from #150. The fuzz-python / fuzz-js jobs in
# .github/workflows/fuzz-pr.yml are disabled until those containers land.
FROM gcr.io/oss-fuzz-base/base-builder-rust

ENV DEBIAN_FRONTEND=noninteractive

COPY . $SRC/edge-ai
COPY .clusterfuzzlite/build.sh $SRC/build.sh
COPY .clusterfuzzlite/build_rust.sh $SRC/build_rust.sh

WORKDIR $SRC/edge-ai
