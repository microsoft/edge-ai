#!/usr/bin/env bash
set -euo pipefail

# Build WASM modules for AIO dataflow graphs
# Usage: ./build-wasm.sh [app_path]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${1:-${SCRIPT_DIR}/..}"
OPERATORS_DIR="${APP_PATH}/operators"

build_operator() {
  local operator_path="$1"
  local operator_name
  operator_name=$(basename "${operator_path}")

  echo "Building WASM module: ${operator_name}"
  cargo build --release \
    --target wasm32-wasip2 \
    --manifest-path "${operator_path}/Cargo.toml" \
    --config "${operator_path}/../../.cargo/config.toml"
}

build_composed_map() {
  local map_path="${OPERATORS_DIR}/map"
  local custom_path="${OPERATORS_DIR}/custom-provider"
  local map_wasm="${map_path}/target/wasm32-wasip2/release/map_custom.wasm"
  local custom_wasm="${custom_path}/target/wasm32-wasip2/release/custom_provider.wasm"

  if [[ -f "${map_wasm}" ]] && [[ -f "${custom_wasm}" ]]; then
    echo "Composing map with custom-provider"

    wasm-tools metadata add \
      "${custom_wasm}" \
      --name "custom-provider" \
      -o "${custom_path}/target/wasm32-wasip2/release/custom-provider.wasm"

    wasm-tools compose \
      "${map_wasm}" \
      -d "${custom_path}/target/wasm32-wasip2/release/custom-provider.wasm" \
      -o "${map_path}/target/wasm32-wasip2/release/composed_map_custom.wasm"
  fi
}

if [[ -n "${2:-}" ]]; then
  build_operator "$2"
else
  for operator in "${OPERATORS_DIR}"/*; do
    if [[ -d "${operator}" ]] && [[ -f "${operator}/Cargo.toml" ]]; then
      build_operator "${operator}"
    fi
  done

  build_composed_map
fi

echo "WASM build complete"
