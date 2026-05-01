#!/usr/bin/env bash
# ClusterFuzzLite top-level build dispatcher. Selects the per-language
# builder based on the LANGUAGE env var (forwarded by the CFLite action's
# `language:` input). Defaults to rust to preserve historical behavior when
# LANGUAGE is unset (e.g. local repro of the rust path).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${LANGUAGE:-rust}" in
  rust)       bash "${SCRIPT_DIR}/build_rust.sh"   ;;
  python)     bash "${SCRIPT_DIR}/build_python.sh" ;;
  javascript) bash "${SCRIPT_DIR}/build_js.sh"     ;;
  *)
    echo "build.sh: unsupported LANGUAGE='${LANGUAGE}' (expected rust|python|javascript)" >&2
    exit 1
    ;;
esac
