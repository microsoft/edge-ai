#!/usr/bin/env bash
set -euo pipefail

# Push Avro to JSON WASM module and graph definition to ACR
# Usage: ./push-to-acr.sh <acr_name> [app_path]

ACR_NAME="${1:?ACR name required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${2:-${SCRIPT_DIR}/..}"
OPERATOR_DIR="${APP_DIR}/operators/avro-to-json"
VERSION="$(grep '^version' "${OPERATOR_DIR}/Cargo.toml" \
  | head -1 | sed 's/.*= *"\(.*\)"/\1/')"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

WASM_FILE="${OPERATOR_DIR}/target/wasm32-wasip2/release/avro_to_json.wasm"
if [[ ! -f "${WASM_FILE}" ]]; then
  echo "WASM module not found. Run build-wasm.sh first."
  exit 1
fi

echo "Pushing avro-to-json module v${VERSION}"
oras push \
  "${ACR_NAME}.azurecr.io/avro-to-json:${VERSION}" \
  --artifact-type \
  application/vnd.module.wasm.content.layer.v1+wasm \
  "${WASM_FILE}:application/wasm" \
  --disable-path-validation

GRAPH_FILE="${APP_DIR}/resources/graphs/graph-avro-to-json.yaml"
if [[ -f "${GRAPH_FILE}" ]]; then
  GRAPH_TEMP=$(mktemp)
  trap 'rm -f "${GRAPH_TEMP}"' EXIT
  export VERSION
  envsubst <"${GRAPH_FILE}" >"${GRAPH_TEMP}"

  echo "Pushing graph definition v${VERSION}"
  oras push \
    "${ACR_NAME}.azurecr.io/avro-to-json-graph:${VERSION}" \
    --config \
    /dev/null:application/vnd.microsoft.aio.graph.v1+yaml \
    "${GRAPH_TEMP}:application/yaml" \
    --disable-path-validation
fi

echo "ACR push complete"
