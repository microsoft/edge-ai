#!/usr/bin/env bash
set -euo pipefail

# Push msg-to-dss WASM operator modules and graph definitions to ACR
# Usage: ./push-to-acr.sh <acr_name> [operator] [app_path]

OPERATORS=("msg-to-dss-key" "dss-enricher-key")

ACR_NAME="${1:?ACR name required}"
shift
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

APP_DIR="${1:-${SCRIPT_DIR}/..}"

if [[ -n "${OPERATOR_FILTER}" ]]; then
  PUSH_OPERATORS=("${OPERATOR_FILTER}")
else
  PUSH_OPERATORS=("${OPERATORS[@]}")
fi

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

for operator in "${PUSH_OPERATORS[@]}"; do
  OPERATOR_DIR="${APP_DIR}/operators/${operator}"
  VERSION="$(grep '^version' "${OPERATOR_DIR}/Cargo.toml" \
    | head -1 | sed 's/.*= *"\(.*\)"/\1/')"

  WASM_FILE="${OPERATOR_DIR}/target/wasm32-wasip2/release/${operator//-/_}.wasm"
  if [[ ! -f "${WASM_FILE}" ]]; then
    echo "WASM module not found for ${operator}. Run build-wasm.sh first."
    exit 1
  fi

  echo "Pushing ${operator} module v${VERSION}"
  oras push \
    "${ACR_NAME}.azurecr.io/${operator}:${VERSION}" \
    --artifact-type application/vnd.module.wasm.content.layer.v1+wasm \
    "${WASM_FILE}:application/wasm" \
    --disable-path-validation

  GRAPH_FILE="${APP_DIR}/resources/graphs/graph-${operator}.yaml"
  if [[ -f "${GRAPH_FILE}" ]]; then
    GRAPH_TEMP=$(mktemp)
    trap 'rm -f "${GRAPH_TEMP}"' EXIT
    export VERSION
    # shellcheck disable=SC2016 # Single quotes intentional - passing literal to envsubst
    envsubst '${VERSION}' <"${GRAPH_FILE}" >"${GRAPH_TEMP}"

    echo "Pushing ${operator} graph definition v${VERSION}"
    oras push \
      "${ACR_NAME}.azurecr.io/${operator}-graph:${VERSION}" \
      --config \
      /dev/null:application/vnd.microsoft.aio.graph.v1+yaml \
      "${GRAPH_TEMP}:application/yaml" \
      --disable-path-validation

    rm -f "${GRAPH_TEMP}"
    trap - EXIT
  fi
done

echo "ACR push complete"
