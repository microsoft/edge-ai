#!/bin/bash
set -euo pipefail

##############################################################################
# Build App Images — ACR Build for 509, 507, 503
##############################################################################
#
# DESCRIPTION:
#   Builds container images for all three edge applications using
#   az acr build. Runs sequentially: 509 (fastest) -> 507 -> 503
#   (slowest, 15-30 min).
#
# ENVIRONMENT VARIABLES (required, set by Terraform):
#   TF_ACR_NAME      - Azure Container Registry name
#   TF_IMAGE_VERSION - Image tag for all builds
#   TF_APP_509_PATH  - Path to 509-sse-connector component
#   TF_APP_507_PATH  - Path to 507-ai-inference component
#   TF_APP_503_PATH  - Path to 503-media-capture-service component
#
##############################################################################

readonly REQUIRED_VARS=(
  TF_ACR_NAME
  TF_IMAGE_VERSION
  TF_APP_509_PATH
  TF_APP_507_PATH
  TF_APP_503_PATH
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Required variable ${var} is not set" >&2
    exit 1
  fi
done

echo "=== Building 509-sse-connector ==="
az acr build \
  --registry "${TF_ACR_NAME}" \
  --image "sse-server:${TF_IMAGE_VERSION}" \
  --file \
  "${TF_APP_509_PATH}/services/sse-server/Dockerfile" \
  "${TF_APP_509_PATH}/services/sse-server"

echo "=== Building 507-ai-inference ==="
az acr build \
  --registry "${TF_ACR_NAME}" \
  --image "ai-edge-inference:${TF_IMAGE_VERSION}" \
  --file \
  "${TF_APP_507_PATH}/services/ai-edge-inference/Dockerfile" \
  "${TF_APP_507_PATH}/services/"

echo "=== Building 503-media-capture-service ==="
az acr build \
  --registry "${TF_ACR_NAME}" \
  --image "media-capture-service:${TF_IMAGE_VERSION}" \
  --file \
  "${TF_APP_503_PATH}/services/media-capture-service/Dockerfile" \
  "${TF_APP_503_PATH}"

echo "=== All images built successfully ==="
