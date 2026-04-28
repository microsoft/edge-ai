#!/usr/bin/env bash
# ClusterFuzzLite top-level build dispatcher. Delegates to per-language builders.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/build_rust.sh"
bash "${SCRIPT_DIR}/build_python.sh"
bash "${SCRIPT_DIR}/build_js.sh"
