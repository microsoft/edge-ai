#!/usr/bin/env bash
# ClusterFuzzLite top-level build dispatcher. Delegates to per-language builders.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/build_rust.sh"
# Python (Atheris) and JavaScript (Jazzer.js) builds deferred to per-language
# builder containers. Tracked in a follow-up issue split from #150.
# bash "${SCRIPT_DIR}/build_python.sh"
# bash "${SCRIPT_DIR}/build_js.sh"
