#!/usr/bin/env bash
set -euo pipefail

# Builds and pushes the Akri HTTP POST Connector runtime image to an ACR.
# Usage: ./build-and-push-image.sh <acr_name> [image_tag]

command -v jq >/dev/null 2>&1 || {
	echo "jq CLI required" >&2
	exit 1
}

ACR_NAME="${1:?ACR name required, e.g. ./build-and-push-image.sh myacr}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICE_DIR="${APP_DIR}/services/akri-http-post-connector"
METADATA_FILE="${APP_DIR}/connector-metadata/connector-metadata.json"
IMAGE_NAME="akri-http-post-connector"
CRATE_VERSION="$(grep '^version' "${SERVICE_DIR}/Cargo.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')"
METADATA_IMAGE_TAG="$(jq -r '.imageConfigurationSettings.tag' "${METADATA_FILE}")"
IMAGE_TAG="${2:-${CRATE_VERSION}}"
IMAGE_REF="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"

if [[ "${IMAGE_TAG}" != "${CRATE_VERSION}" || "${METADATA_IMAGE_TAG}" != "${CRATE_VERSION}" ]]; then
	echo "Image tag, metadata image tag, and Cargo package version must all match" >&2
	exit 1
fi

echo "Building ${IMAGE_REF} from ${SERVICE_DIR}"
docker build -f "${SERVICE_DIR}/Dockerfile" -t "${IMAGE_REF}" "${SERVICE_DIR}"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

echo "Pushing ${IMAGE_REF}"
docker push "${IMAGE_REF}"

echo "Pushed ${IMAGE_REF}"
