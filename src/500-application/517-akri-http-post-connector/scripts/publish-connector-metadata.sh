#!/usr/bin/env bash
set -euo pipefail

# Publishes connector-metadata.json as an independent OCI artifact to an ACR, so
# custom_connector_metadata_ref (Terraform) / customConnectorMetadataRef (Bicep)
# can reference it directly.
# Usage: ./publish-connector-metadata.sh <acr_name> [metadata_tag]

command -v oras >/dev/null 2>&1 || {
  echo "oras CLI required: https://oras.land/docs/installation" >&2
  exit 1
}

ACR_NAME="${1:?ACR name required, e.g. ./publish-connector-metadata.sh acrkd0805dev001}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
METADATA_DIR="${APP_DIR}/connector-metadata"
ARTIFACT_NAME="akri-http-post-connector-metadata"
METADATA_TAG="${2:-$(grep '^version' "${APP_DIR}/services/akri-http-post-connector/Cargo.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')}"
ARTIFACT_REF="${ACR_NAME}.azurecr.io/${ARTIFACT_NAME}:${METADATA_TAG}"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

echo "Publishing ${ARTIFACT_REF}"
(cd "${METADATA_DIR}" && oras push "${ARTIFACT_REF}" \
  --config connector-metadata.json:application/vnd.microsoft.akri-connector.v1+json \
  --artifact-type application/vnd.microsoft.akri-connector.v1+json)

echo "Published ${ARTIFACT_REF}"
