#!/bin/bash
set -euo pipefail

###########################################################################
# Build and Push App Images to ACR
###########################################################################
#
# Builds Docker images for leak-detection blueprint application
# components and pushes them to Azure Container Registry.
#
# Usage:
#   ./build-app-images.sh --acr-name <acr> --resource-group <rg> \
#     [--tag <version>]
#
###########################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build and push application container images to ACR.

Required:
  --acr-name NAME        Azure Container Registry name
  --resource-group RG    Resource group containing the ACR

Optional:
  --tag TAG              Image tag (default: latest)
  -h, --help             Show this help message
EOF
  exit "${1:-0}"
}

ACR_NAME=""
RESOURCE_GROUP=""
IMAGE_TAG="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --acr-name)
      ACR_NAME="$2"
      shift 2
      ;;
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    -h | --help)
      usage 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

if [[ -z "${ACR_NAME}" || -z "${RESOURCE_GROUP}" ]]; then
  echo "ERROR: --acr-name and --resource-group are required" >&2
  usage 1
fi

readonly ACR_LOGIN="${ACR_NAME}.azurecr.io"

# Component image definitions: name|dockerfile|context
readonly -a COMPONENTS=(
  "ai-edge-inference|\
src/500-application/507-ai-inference/\
services/ai-edge-inference/Dockerfile.acr|\
src/500-application/507-ai-inference/\
services/ai-edge-inference"
  "sse-server|\
src/500-application/509-sse-connector/\
services/sse-server/Dockerfile|\
src/500-application/509-sse-connector/\
services/sse-server"
  "media-capture-service|\
src/500-application/503-media-capture-service/\
services/media-capture-service/Dockerfile|\
src/500-application/503-media-capture-service/\
services/media-capture-service"
)

build_count=0
fail_count=0

echo "=== Logging into ACR: ${ACR_NAME} ==="
az acr login \
  --name "${ACR_NAME}" \
  --resource-group "${RESOURCE_GROUP}"

for entry in "${COMPONENTS[@]}"; do
  IFS='|' read -r img_name dockerfile context <<< "${entry}"

  dockerfile_path="${REPO_ROOT}/${dockerfile}"
  context_path="${REPO_ROOT}/${context}"

  if [[ ! -f "${dockerfile_path}" ]]; then
    echo "WARN: Dockerfile not found: ${dockerfile_path}" >&2
    echo "  Skipping ${img_name}"
    continue
  fi

  remote_tag="${ACR_LOGIN}/${img_name}:${IMAGE_TAG}"
  echo "=== Building ${img_name} (tag: ${IMAGE_TAG}) ==="

  if docker build \
    -t "${remote_tag}" \
    -f "${dockerfile_path}" \
    "${context_path}"; then
    echo "=== Pushing ${remote_tag} ==="
    docker push "${remote_tag}"
    ((build_count++))
  else
    echo "ERROR: Build failed for ${img_name}" >&2
    ((fail_count++))
  fi
done

echo ""
echo "=== Build Summary ==="
echo "  Succeeded: ${build_count}"
echo "  Failed:    ${fail_count}"

if ((fail_count > 0)); then
  exit 1
fi

echo "=== All images built and pushed successfully ==="
