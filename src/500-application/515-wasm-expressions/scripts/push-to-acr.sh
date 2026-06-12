#!/usr/bin/env bash
set -euo pipefail

# Push wasm-expressions operator modules and graph definitions to ACR
# Usage: ./push-to-acr.sh <acr_name> [app_path]
#
# Publishing requires only the AcrPush role on the target registry; do not run
# this with Owner/Contributor credentials. When this is promoted to automation,
# use an OIDC-federated service principal scoped to AcrPush instead of an
# interactive login.
#
# Set ALLOW_OVERWRITE=true to permit pushing over an existing tag; by default an
# existing tag aborts the push so a published artifact is never silently
# replaced. The ACR login token is revoked on exit.

ACR_NAME="${1:?ACR name required}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${2:-${SCRIPT_DIR}/..}"
ALLOW_OVERWRITE="${ALLOW_OVERWRITE:-false}"

# Add new sibling operators here as they are introduced.
OPERATORS=("datetime")

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"
trap 'az acr logout --name "${ACR_NAME}" >/dev/null 2>&1 || true' EXIT

audit_log="${APP_DIR}/push-audit-$(date -u +%Y%m%dT%H%M%SZ).log"
echo "Recording push provenance to ${audit_log}"

# Validates a semantic version (major.minor.patch with optional pre-release/build).
is_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]]
}

# Pushes one artifact and records its digest. Pushes from the artifact's own
# directory using the basename so the OCI title annotation never embeds an
# absolute or temporary host path (avoids needing --disable-path-validation).
push_artifact() {
  local reference="$1" artifact_dir="$2" artifact_name="$3"
  shift 3

  if [[ "${ALLOW_OVERWRITE}" != "true" ]] && oras manifest fetch "${reference}" >/dev/null 2>&1; then
    echo "ERROR: ${reference} already exists. Set ALLOW_OVERWRITE=true to replace it."
    exit 1
  fi

  local push_json digest
  push_json="$(cd "${artifact_dir}" && oras push "${reference}" --format json "$@" "${artifact_name}")"
  digest="$(printf '%s' "${push_json}" | sed -n 's/.*"digest"[: ]*"\([^"]*\)".*/\1/p' | head -1)"
  echo "${reference} ${digest:-unknown}" >>"${audit_log}"
  echo "  pushed ${reference} (${digest:-digest unavailable})"
}

for operator in "${OPERATORS[@]}"; do
  operator_dir="${APP_DIR}/operators/${operator}"
  version="$(grep '^version' "${operator_dir}/Cargo.toml" \
    | head -1 | sed 's/.*= *"\(.*\)"/\1/')"

  if ! is_semver "${version}"; then
    echo "ERROR: derived version '${version}' for ${operator} is not a valid semantic version."
    exit 1
  fi

  wasm_file="${operator_dir}/target/wasm32-wasip2/release/${operator}.wasm"
  if [[ ! -f "${wasm_file}" ]]; then
    echo "WASM module not found for ${operator}. Run build-wasm.sh first."
    exit 1
  fi

  echo "Pushing ${operator} module v${version}"
  push_artifact \
    "${ACR_NAME}.azurecr.io/${operator}:${version}" \
    "$(dirname "${wasm_file}")" \
    "$(basename "${wasm_file}"):application/wasm" \
    --artifact-type application/vnd.module.wasm.content.layer.v1+wasm

  graph_file="${APP_DIR}/resources/graphs/graph-${operator}.yaml"
  if [[ -f "${graph_file}" ]]; then
    graph_dir="$(mktemp -d)"
    trap 'rm -rf "${graph_dir}"; az acr logout --name "${ACR_NAME}" >/dev/null 2>&1 || true' EXIT
    graph_temp="${graph_dir}/graph-${operator}.yaml"
    export VERSION="${version}"
    # shellcheck disable=SC2016 # Single quotes intentional - passing literal to envsubst
    envsubst '${VERSION}' <"${graph_file}" >"${graph_temp}"

    echo "Pushing ${operator} graph definition v${version}"
    push_artifact \
      "${ACR_NAME}.azurecr.io/${operator}-graph:${version}" \
      "${graph_dir}" \
      "$(basename "${graph_temp}"):application/yaml" \
      --config /dev/null:application/vnd.microsoft.aio.graph.v1+yaml

    rm -rf "${graph_dir}"
    trap 'az acr logout --name "${ACR_NAME}" >/dev/null 2>&1 || true' EXIT
  fi
done

echo "ACR push complete"
echo "Push provenance recorded in ${audit_log}"
