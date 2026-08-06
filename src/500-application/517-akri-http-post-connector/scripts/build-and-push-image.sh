#!/usr/bin/env bash
set -euo pipefail

# Builds and pushes the Akri HTTP POST Connector runtime image to an ACR.
# Usage: ./build-and-push-image.sh <acr_name> [image_tag]

ACR_NAME="${1:?ACR name required, e.g. ./build-and-push-image.sh acrkd0805dev001}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICE_DIR="${APP_DIR}/services/akri-http-post-connector"
IMAGE_NAME="akri-http-post-connector"
IMAGE_TAG="${2:-$(grep '^version' "${SERVICE_DIR}/Cargo.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')}"
IMAGE_REF="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building ${IMAGE_REF} from ${SERVICE_DIR}"
docker build -f "${SERVICE_DIR}/Dockerfile" -t "${IMAGE_REF}" "${SERVICE_DIR}"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

echo "Pushing ${IMAGE_REF}"
docker push "${IMAGE_REF}"

echo "Pushed ${IMAGE_REF}"
