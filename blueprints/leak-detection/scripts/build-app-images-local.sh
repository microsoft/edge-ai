#!/bin/bash
set -euo pipefail

##############################################################################
# Build App Images Locally — Docker Build for 509, 507, 503, ONVIF Simulator
##############################################################################
#
# DESCRIPTION:
#   Builds container images for all edge applications using
#   local docker build (linux/amd64). Run this before pushing
#   images with build-app-images.sh.
#
# ENVIRONMENT VARIABLES (optional):
#   TF_IMAGE_VERSION - Image tag for all builds (default: "latest")
#
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT

readonly VERSION="${TF_IMAGE_VERSION:-latest}"
readonly PLATFORM="linux/amd64"

readonly APP_509="${REPO_ROOT}/src/500-application/509-sse-connector"
readonly APP_507="${REPO_ROOT}/src/500-application/507-ai-inference"
readonly APP_503="${REPO_ROOT}/src/500-application/503-media-capture-service"
readonly BLUEPRINT_DIR="${SCRIPT_DIR}/.."

readonly -a IMAGES=(
  "sse-server"
  "ai-edge-inference"
  "media-capture-service"
  "onvif-camera-simulator"
)

readonly -a DOCKERFILES=(
  "${APP_509}/services/sse-server/Dockerfile"
  "${APP_507}/services/ai-edge-inference/Dockerfile"
  "${APP_503}/services/media-capture-service/Dockerfile"
  "${BLUEPRINT_DIR}/services/onvif-camera-simulator/Dockerfile"
)

readonly -a CONTEXTS=(
  "${APP_509}/services/sse-server"
  "${APP_507}/services/"
  "${APP_503}"
  "${BLUEPRINT_DIR}/services/onvif-camera-simulator"
)

readonly -a LABELS=(
  "509-sse-connector"
  "507-ai-inference"
  "503-media-capture-service"
  "onvif-camera-simulator"
)

echo "=== Local Docker Build ==="
echo "Version: ${VERSION}"
echo "Platform: ${PLATFORM}"
echo ""

for i in "${!IMAGES[@]}"; do
  echo "=== Building ${LABELS[${i}]} ==="
  docker build \
    --platform "${PLATFORM}" \
    --tag "${IMAGES[${i}]}:${VERSION}" \
    --file "${DOCKERFILES[${i}]}" \
    "${CONTEXTS[${i}]}"
  echo ""
done

echo "=== Build Summary ==="
printf "%-30s %s\n" "IMAGE" "SIZE"
printf "%-30s %s\n" "-----" "----"
for img in "${IMAGES[@]}"; do
  local_size=$(
    docker image inspect "${img}:${VERSION}" \
      --format '{{.Size}}' 2>/dev/null || echo "0"
  )
  # Convert bytes to human-readable
  if (( local_size > 1073741824 )); then
    hr_size="$(( local_size / 1073741824 )) GB"
  elif (( local_size > 1048576 )); then
    hr_size="$(( local_size / 1048576 )) MB"
  else
    hr_size="${local_size} B"
  fi
  printf "%-30s %s\n" "${img}:${VERSION}" "${hr_size}"
done

echo ""
echo "=== All images built successfully ==="
echo "Run build-app-images.sh to push to ACR."
