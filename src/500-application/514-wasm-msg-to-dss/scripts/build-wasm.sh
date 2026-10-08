#!/usr/bin/env bash
set -euo pipefail

# Build msg-to-dss WASM operator modules for AIO dataflow graphs
# Usage: ./build-wasm.sh [operator] [app_path]

OPERATORS=("msg-to-dss-key" "dss-enricher-key")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OPERATOR_FILTER=""
if [[ $# -gt 0 ]]; then
  case "$1" in
    msg-to-dss-key | dss-enricher-key)
      OPERATOR_FILTER="$1"
      shift
      ;;
    *)
      echo "ERROR: Unknown operator '$1'. Valid operators: ${OPERATORS[*]}"
      exit 1
      ;;
  esac
fi

APP_PATH="${1:-${SCRIPT_DIR}/..}"

if [[ -n "${OPERATOR_FILTER}" ]]; then
  BUILD_OPERATORS=("${OPERATOR_FILTER}")
else
  BUILD_OPERATORS=("${OPERATORS[@]}")
fi

if ! rustup target list --installed | grep -q wasm32-wasip2; then
  echo "Installing wasm32-wasip2 target..."
  rustup target add wasm32-wasip2
fi

echo ""
for operator in "${BUILD_OPERATORS[@]}"; do
  OPERATOR_DIR="${APP_PATH}/operators/${operator}"
  WASM_OUTPUT="${OPERATOR_DIR}/target/wasm32-wasip2/release/${operator//-/_}.wasm"

  echo "Building ${operator} WASM module..."
  cargo build --release \
    --target wasm32-wasip2 \
    --manifest-path "${OPERATOR_DIR}/Cargo.toml" \
    --config "${APP_PATH}/.cargo/config.toml"

  if [[ ! -f "${WASM_OUTPUT}" ]]; then
    echo "ERROR: WASM file not found at ${WASM_OUTPUT}"
    exit 1
  fi

  echo "  ${operator}: $(du -h "${WASM_OUTPUT}" | cut -f1)"
  echo "  Path: ${WASM_OUTPUT}"
  echo ""
done

echo "WASM build complete"
