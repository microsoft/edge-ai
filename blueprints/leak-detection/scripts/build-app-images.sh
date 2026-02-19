#!/bin/bash
set -euo pipefail

##############################################################################
# Push App Images — Tag and push local images to ACR
##############################################################################
#
# DESCRIPTION:
#   Pushes pre-built local Docker images to Azure Container Registry.
#   Images must be built first using build-app-images-local.sh.
#
# ENVIRONMENT VARIABLES (required, set by Terraform):
#   TF_ACR_NAME      - Azure Container Registry name
#   TF_IMAGE_VERSION - Image tag for all builds
#
##############################################################################

readonly REQUIRED_VARS=(
  TF_ACR_NAME
  TF_IMAGE_VERSION
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Required variable ${var} is not set" >&2
    exit 1
  fi
done

readonly ACR_NAME="${TF_ACR_NAME}"
readonly VERSION="${TF_IMAGE_VERSION}"
readonly ACR_LOGIN="${ACR_NAME}.azurecr.io"

readonly -a IMAGES=(
  "sse-server"
  "ai-edge-inference"
  "media-capture-service"
)

# Verify all local images exist before pushing
for img in "${IMAGES[@]}"; do
  if ! docker image inspect "${img}:${VERSION}" \
    &>/dev/null; then
    echo "ERROR: Local image ${img}:${VERSION} not found." >&2
    echo "Run build-app-images-local.sh first." >&2
    exit 1
  fi
done

echo "=== Logging into ACR: ${ACR_NAME} ==="
az acr login --name "${ACR_NAME}"

for img in "${IMAGES[@]}"; do
  local_tag="${img}:${VERSION}"
  remote_tag="${ACR_LOGIN}/${img}:${VERSION}"
  echo "=== Pushing ${local_tag} ==="
  docker tag "${local_tag}" "${remote_tag}"
  docker push "${remote_tag}"
done

echo "=== All images pushed successfully ==="
