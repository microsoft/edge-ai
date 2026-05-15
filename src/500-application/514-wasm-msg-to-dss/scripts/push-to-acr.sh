#!/usr/bin/env bash
set -euo pipefail

# Push msg-to-dss-key WASM module and graph definition to ACR
# Usage: ./push-to-acr.sh <acr_name> [app_path]

ACR_NAME="${1:?ACR name required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${2:-${SCRIPT_DIR}/..}"
OPERATOR_DIR="${APP_DIR}/operators/msg-to-dss-key"
VERSION="$(grep '^version' "${OPERATOR_DIR}/Cargo.toml" \
  | head -1 | sed 's/.*= *"\(.*\)"/\1/')"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

WASM_FILE="${OPERATOR_DIR}/target/wasm32-wasip2/release/msg_to_dss_key.wasm"
if [[ ! -f "${WASM_FILE}" ]]; then
  echo "WASM module not found. Run build-wasm.sh first."
  exit 1
fi

echo "Pushing msg-to-dss-key module v${VERSION}"
oras push \
  "${ACR_NAME}.azurecr.io/msg-to-dss-key:${VERSION}" \
  --artifact-type application/vnd.module.wasm.content.layer.v1+wasm \
  "${WASM_FILE}:application/wasm" \
  --disable-path-validation

GRAPH_FILE="${APP_DIR}/resources/graphs/graph-msg-to-dss-key.yaml"
if [[ -f "${GRAPH_FILE}" ]]; then
  GRAPH_TEMP=$(mktemp)
  trap 'rm -f "${GRAPH_TEMP}"' EXIT
  export VERSION
  # shellcheck disable=SC2016 # Single quotes intentional - passing literal to envsubst
  envsubst '${VERSION}' <"${GRAPH_FILE}" >"${GRAPH_TEMP}"

  echo "Pushing graph definition v${VERSION}"
  oras push \
    "${ACR_NAME}.azurecr.io/msg-to-dss-key-graph:${VERSION}" \
    --config \
    /dev/null:application/vnd.microsoft.aio.graph.v1+yaml \
    "${GRAPH_TEMP}:application/yaml" \
    --disable-path-validation
fi

echo "ACR push complete"
