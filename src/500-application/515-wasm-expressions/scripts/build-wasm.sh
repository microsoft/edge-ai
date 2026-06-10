#!/usr/bin/env bash
set -euo pipefail

# Build wasm-expressions operator modules for AIO dataflow graphs
# Usage: ./build-wasm.sh [app_path]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${1:-${SCRIPT_DIR}/..}"

# Add new sibling operators here as they are introduced.
OPERATORS=("datetime")

if ! rustup target list --installed | grep -q wasm32-wasip2; then
  echo "Installing wasm32-wasip2 target..."
  rustup target add wasm32-wasip2
fi

for operator in "${OPERATORS[@]}"; do
  operator_dir="${APP_PATH}/operators/${operator}"
  wasm_output="${operator_dir}/target/wasm32-wasip2/release/${operator}.wasm"

  echo "Building ${operator} WASM module..."
  cargo build --release \
    --target wasm32-wasip2 \
    --manifest-path "${operator_dir}/Cargo.toml" \
    --config "${APP_PATH}/.cargo/config.toml"

  if [[ ! -f "${wasm_output}" ]]; then
    echo "ERROR: WASM file not found at ${wasm_output}"
    exit 1
  fi

  echo ""
  echo "WASM module built:"
  echo "  ${operator}: $(du -h "${wasm_output}" | cut -f1)"
  echo "  Path: ${wasm_output}"
  echo ""
done

echo "WASM build complete"
