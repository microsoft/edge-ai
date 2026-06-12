#!/usr/bin/env bash
set -euo pipefail

# Build wasm-expressions operator modules for AIO dataflow graphs
# Usage: ./build-wasm.sh [app_path]
#
# This component is excluded from the Docker build pipeline (.nobuild), so the
# quality gates CI would normally enforce run here before a publishable artifact
# is produced: clippy (with the crate's correctness=deny lints) against the
# wasm target, the unit tests on the host target, and a dependency audit.
# Set SKIP_AUDIT=true to skip the audit when cargo-audit is unavailable offline.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${1:-${SCRIPT_DIR}/..}"
SKIP_AUDIT="${SKIP_AUDIT:-false}"
HOST_TARGET="$(rustc -vV | sed -n 's/host: //p')"

# Add new sibling operators here as they are introduced.
OPERATORS=("datetime")

for operator in "${OPERATORS[@]}"; do
  operator_dir="${APP_PATH}/operators/${operator}"
  manifest="${operator_dir}/Cargo.toml"
  wasm_output="${operator_dir}/target/wasm32-wasip2/release/${operator}.wasm"

  echo "Linting ${operator} (clippy, wasm target)..."
  cargo clippy --locked \
    --manifest-path "${manifest}" \
    --config "${APP_PATH}/.cargo/config.toml" \
    --all-targets -- -D warnings

  echo "Testing ${operator} (host target)..."
  cargo test --locked --target "${HOST_TARGET}" --manifest-path "${manifest}"

  if [[ "${SKIP_AUDIT}" != "true" ]] && command -v cargo-audit >/dev/null 2>&1; then
    echo "Auditing ${operator} dependencies..."
    cargo audit --file "${operator_dir}/Cargo.lock"
  else
    echo "Skipping dependency audit for ${operator} (cargo-audit unavailable or SKIP_AUDIT=true)."
  fi

  echo "Building ${operator} WASM module..."
  cargo build --release --locked \
    --target wasm32-wasip2 \
    --manifest-path "${manifest}" \
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
