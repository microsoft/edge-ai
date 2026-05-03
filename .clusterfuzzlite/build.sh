#!/usr/bin/env bash
# ClusterFuzzLite top-level build dispatcher. Selects the per-language
# builder based on the OSS-Fuzz canonical `FUZZING_LANGUAGE` env var, which
# is set by the CFLite action's `language:` input on the inner `compile`
# container. `LANGUAGE` is accepted as a fallback for local repro convenience
# and defaults to rust to preserve historical behavior when neither is set.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${FUZZING_LANGUAGE:-${LANGUAGE:-rust}}" in
  rust) bash "${SCRIPT_DIR}/build_rust.sh" ;;
  python) bash "${SCRIPT_DIR}/build_python.sh" ;;
  javascript) bash "${SCRIPT_DIR}/build_js.sh" ;;
  *)
    echo "build.sh: unsupported FUZZING_LANGUAGE='${FUZZING_LANGUAGE:-${LANGUAGE:-}}' (expected rust|python|javascript)" >&2
    exit 1
    ;;
esac
