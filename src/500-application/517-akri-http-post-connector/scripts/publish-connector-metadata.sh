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
command -v jq >/dev/null 2>&1 || {
  echo "jq CLI required" >&2
  exit 1
}

ACR_NAME="${1:?ACR name required, e.g. ./publish-connector-metadata.sh myacr001}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
METADATA_DIR="${APP_DIR}/connector-metadata"
METADATA_FILE="${METADATA_DIR}/connector-metadata.json"
SERVICE_DIR="${APP_DIR}/services/akri-http-post-connector"
ARTIFACT_NAME="akri-http-post-connector-metadata"
CRATE_VERSION="$(grep '^version' "${SERVICE_DIR}/Cargo.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')"
CONNECTOR_VERSION="$(jq -r '.version' "${METADATA_FILE}")"
METADATA_IMAGE_TAG="$(jq -r '.imageConfigurationSettings.tag' "${METADATA_FILE}")"
METADATA_TAG="${2:-${CRATE_VERSION}}"
ARTIFACT_REF="${ACR_NAME}.azurecr.io/${ARTIFACT_NAME}:${METADATA_TAG}"

if [[ "${CONNECTOR_VERSION}" != "${CRATE_VERSION}" || "${METADATA_IMAGE_TAG}" != "${CRATE_VERSION}" ]]; then
  echo "Connector version, metadata image tag, and Cargo package version must all match" >&2
  exit 1
fi

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

echo "Publishing ${ARTIFACT_REF}"
(cd "${METADATA_DIR}" && oras push "${ARTIFACT_REF}" \
  --config /dev/null:application/vnd.microsoft.akri-connector.v1+json \
  connector-metadata.json:application/json)

echo "Published ${ARTIFACT_REF}"
