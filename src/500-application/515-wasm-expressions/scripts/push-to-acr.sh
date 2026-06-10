#!/usr/bin/env bash
set -euo pipefail

# Push wasm-expressions operator modules and graph definitions to ACR
# Usage: ./push-to-acr.sh <acr_name> [app_path]

ACR_NAME="${1:?ACR name required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${2:-${SCRIPT_DIR}/..}"

# Add new sibling operators here as they are introduced.
OPERATORS=("datetime")

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

for operator in "${OPERATORS[@]}"; do
  operator_dir="${APP_DIR}/operators/${operator}"
  version="$(grep '^version' "${operator_dir}/Cargo.toml" \
    | head -1 | sed 's/.*= *"\(.*\)"/\1/')"

  wasm_file="${operator_dir}/target/wasm32-wasip2/release/${operator}.wasm"
  if [[ ! -f "${wasm_file}" ]]; then
    echo "WASM module not found for ${operator}. Run build-wasm.sh first."
    exit 1
  fi

  echo "Pushing ${operator} module v${version}"
  oras push \
    "${ACR_NAME}.azurecr.io/${operator}:${version}" \
    --artifact-type application/vnd.module.wasm.content.layer.v1+wasm \
    "${wasm_file}:application/wasm" \
    --disable-path-validation

  graph_file="${APP_DIR}/resources/graphs/graph-${operator}.yaml"
  if [[ -f "${graph_file}" ]]; then
    graph_temp=$(mktemp)
    trap 'rm -f "${graph_temp}"' EXIT
    export VERSION="${version}"
    # shellcheck disable=SC2016 # Single quotes intentional - passing literal to envsubst
    envsubst '${VERSION}' <"${graph_file}" >"${graph_temp}"

    echo "Pushing ${operator} graph definition v${version}"
    oras push \
      "${ACR_NAME}.azurecr.io/${operator}-graph:${version}" \
      --config \
      /dev/null:application/vnd.microsoft.aio.graph.v1+yaml \
      "${graph_temp}:application/yaml" \
      --disable-path-validation

    rm -f "${graph_temp}"
    trap - EXIT
  fi
done

echo "ACR push complete"
