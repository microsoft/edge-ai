#!/usr/bin/env bash
set -euo pipefail

# Build msg-to-dss-key WASM module for AIO dataflow graphs
# Usage: ./build-wasm.sh [app_path]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${1:-${SCRIPT_DIR}/..}"
OPERATOR_DIR="${APP_PATH}/operators/msg-to-dss-key"
WASM_OUTPUT="${OPERATOR_DIR}/target/wasm32-wasip2/release/msg_to_dss_key.wasm"

if ! rustup target list --installed | grep -q wasm32-wasip2; then
  echo "Installing wasm32-wasip2 target..."
  rustup target add wasm32-wasip2
fi

echo "Building msg-to-dss-key WASM module..."
cargo build --release \
  --target wasm32-wasip2 \
  --manifest-path "${OPERATOR_DIR}/Cargo.toml" \
  --config "${APP_PATH}/.cargo/config.toml"

if [[ ! -f "${WASM_OUTPUT}" ]]; then
  echo "ERROR: WASM file not found at ${WASM_OUTPUT}"
  exit 1
fi

echo ""
echo "WASM module built:"
echo "  msg-to-dss-key: $(du -h "${WASM_OUTPUT}" | cut -f1)"
echo "  Path: ${WASM_OUTPUT}"
echo ""
echo "WASM build complete"
