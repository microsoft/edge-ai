#!/usr/bin/env bash
set -euo pipefail

# Push composed WASM module and graph definition to Azure Container Registry
# Usage: ./push-to-acr.sh <acr_name> [app_path]

ACR_NAME="${1:?ACR name required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${2:-${SCRIPT_DIR}/..}"
OPERATORS_DIR="${APP_DIR}/operators"
VERSION="$(grep '^version' "${OPERATORS_DIR}/map/Cargo.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

COMPOSED_MAP="${OPERATORS_DIR}/map/target/wasm32-wasip2/release/composed_map_custom.wasm"
if [[ ! -f "${COMPOSED_MAP}" ]]; then
    echo "Composed module not found. Run build-wasm.sh first."
    exit 1
fi

echo "Pushing composed module: map-custom"
oras push "${ACR_NAME}.azurecr.io/map-custom:${VERSION}" \
    --artifact-type application/vnd.module.wasm.content.layer.v1+wasm \
    "${COMPOSED_MAP}:application/wasm" \
    --disable-path-validation

GRAPH_FILE="${APP_DIR}/resources/graphs/graph-simple-map-custom.yaml"
GRAPH_VERSIONED="${APP_DIR}/resources/graphs/graph-simple-map-custom-${VERSION}.yaml"
if [[ -f "${GRAPH_FILE}" ]]; then
    sed "s|map-custom:[0-9][0-9.]*|map-custom:${VERSION}|g" "${GRAPH_FILE}" >"${GRAPH_VERSIONED}"
    echo "Pushing graph definition: graph-simple-map-custom"
    oras push "${ACR_NAME}.azurecr.io/graph-simple-map-custom:${VERSION}" \
        --config /dev/null:application/vnd.microsoft.aio.graph.v1+yaml \
        "${GRAPH_VERSIONED}:application/yaml" \
        --disable-path-validation
fi

echo "ACR push complete"
