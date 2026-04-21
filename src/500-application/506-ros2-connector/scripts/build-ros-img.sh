#!/usr/bin/env bash

# build-ros-img.sh
# Builds and pushes ROS2 simulator and connector container images to the specified Azure Container Registry (ACR)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
err() {
  printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [--no-push] [--platform PLATFORM] [--tag TAG]

Build ROS2 simulator and connector images (multi-arch aware). Auto-loads .env if present.

Options:
  --no-push            Build only; skip pushing to ACR
  --platform PLATFORM  Target platform (default: auto / linux/amd64)
  --tag TAG            Base image tag (default: latest)
  --help               Show this help

Env / .env keys:
  ACR_NAME (required to push)  SIMULATOR_IMAGE  CONNECTOR_IMAGE  IMAGE_TAG
  BUILD_PLATFORM (linux/amd64|linux/arm64)  DOCKERFILE_SIMULATOR_PATH  DOCKERFILE_CONNECTOR_PATH

Examples:
  $0
  ACR_NAME=myacr $0 --tag dev
  BUILD_PLATFORM=linux/arm64 ACR_NAME=myacr $0
EOF
}

# Early help handling
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
# Container image build/publish configuration
ACR_NAME="${ACR_NAME:-}"                                                                     # Azure Container Registry name, no domain e.g. myregistry (required)
SIMULATOR_IMAGE_NAME="${SIMULATOR_IMAGE_NAME:-ros2-simulator}"                               # Simulator image name (no registry domain)
SIMULATOR_IMAGE_TAG="${SIMULATOR_IMAGE_TAG:-latest}"                                         # Simulator image tag
DOCKERFILE_SIMULATOR_PATH="${DOCKERFILE_SIMULATOR_PATH:-services/ros2-simulator/Dockerfile}" # Simulator Dockerfile relative to project root
CONNECTOR_IMAGE_NAME="${CONNECTOR_IMAGE_NAME:-ros2-connector}"                               # Connector image name
CONNECTOR_IMAGE_TAG="${CONNECTOR_IMAGE_TAG:-${SIMULATOR_IMAGE_TAG}}"                         # Connector image tag (defaults to simulator tag)
DOCKERFILE_CONNECTOR_PATH="${DOCKERFILE_CONNECTOR_PATH:-services/ros2-connector/Dockerfile}" # Connector Dockerfile
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"                                              # Target platform for deployment (amd64 by default)
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)}"       # Component root directory
PUSH_IMAGES="${PUSH_IMAGES:-true}"                                                           # Push images to ACR

check_prereqs() {
  command -v docker >/dev/null 2>&1 || err "docker required to build image"
  if [[ ${PUSH_IMAGES} == "true" ]]; then
    [[ -n ${ACR_NAME} ]] || err "ACR_NAME required for pushing images"
    command -v az >/dev/null 2>&1 || warn "az CLI not found (will rely on existing docker login to ${ACR_NAME}.azurecr.io)"
  fi
}

# Detect local architecture and convert to Docker platform format
detect_local_platform() {
  local arch
  arch=$(uname -m)
  case "${arch}" in
    x86_64) echo "linux/amd64" ;;
    aarch64) echo "linux/arm64" ;;
    armv7l) echo "linux/arm/v7" ;;
    *) echo "linux/${arch}" ;;
  esac
}

# If BUILD_PLATFORM not explicitly set, use local platform
if [[ "${BUILD_PLATFORM}" == "linux/amd64" && "$(detect_local_platform)" != "linux/amd64" ]]; then
  BUILD_PLATFORM="$(detect_local_platform)"
  log "Auto-detected platform: ${BUILD_PLATFORM}"
fi

parse_env_file() {
  local env_file="${PROJECT_ROOT}/.env"

  if [[ ! -f "${env_file}" ]]; then
    warn ".env file not found at ${env_file}, using defaults"
    return 0
  fi

  log "Loading configuration from ${env_file}"

  # Parse common build-related variables from .env if not already set
  if [[ -z "${ACR_NAME:-}" ]]; then
    ACR_NAME=$(grep -E "^ACR_NAME=" "${env_file}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
  fi

  if [[ -z "${BUILD_PLATFORM_FROM_ENV:-}" ]]; then
    BUILD_PLATFORM_FROM_ENV=$(grep -E "^BUILD_PLATFORM=" "${env_file}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
    if [[ -n "${BUILD_PLATFORM_FROM_ENV}" && "${BUILD_PLATFORM}" == "$(detect_local_platform)" ]]; then
      BUILD_PLATFORM="${BUILD_PLATFORM_FROM_ENV}"
      log "Using BUILD_PLATFORM from .env: ${BUILD_PLATFORM}"
    fi
  fi

  if [[ -z "${SIMULATOR_IMAGE_NAME_FROM_ENV:-}" ]]; then
    SIMULATOR_IMAGE_NAME_FROM_ENV=$(grep -E "^SIMULATOR_IMAGE=" "${env_file}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
    if [[ -n "${SIMULATOR_IMAGE_NAME_FROM_ENV}" ]]; then
      SIMULATOR_IMAGE_NAME="${SIMULATOR_IMAGE_NAME_FROM_ENV}"
      log "Using SIMULATOR_IMAGE_NAME from .env: ${SIMULATOR_IMAGE_NAME}"
    fi
  fi

  if [[ -z "${CONNECTOR_IMAGE_NAME_FROM_ENV:-}" ]]; then
    CONNECTOR_IMAGE_NAME_FROM_ENV=$(grep -E "^CONNECTOR_IMAGE=" "${env_file}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
    if [[ -n "${CONNECTOR_IMAGE_NAME_FROM_ENV}" ]]; then
      CONNECTOR_IMAGE_NAME="${CONNECTOR_IMAGE_NAME_FROM_ENV}"
      log "Using CONNECTOR_IMAGE_NAME from .env: ${CONNECTOR_IMAGE_NAME}"
    fi
  fi

  if [[ -z "${IMAGE_TAG_FROM_ENV:-}" ]]; then
    IMAGE_TAG_FROM_ENV=$(grep -E "^IMAGE_TAG=" "${env_file}" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ' || echo "")
    if [[ -n "${IMAGE_TAG_FROM_ENV}" ]]; then
      SIMULATOR_IMAGE_TAG="${IMAGE_TAG_FROM_ENV}"
      log "Using IMAGE_TAG from .env: ${SIMULATOR_IMAGE_TAG}"
    fi
  fi

  # Log final configuration
  log "Configuration loaded:"
  log "  ACR_NAME: ${ACR_NAME:-<not set>}"
  log "  BUILD_PLATFORM: ${BUILD_PLATFORM}"
  log "  SIMULATOR_IMAGE_NAME: ${SIMULATOR_IMAGE_NAME}"
  log "  SIMULATOR_IMAGE_TAG: ${SIMULATOR_IMAGE_TAG}"
  log "  CONNECTOR_IMAGE_NAME: ${CONNECTOR_IMAGE_NAME}"
  log "  CONNECTOR_IMAGE_TAG: ${CONNECTOR_IMAGE_TAG}"
}

full_simulator_image_ref() {
  local arch_suffix
  # Extract architecture from platform format (linux/amd64 -> amd64)
  arch_suffix=$(echo "${BUILD_PLATFORM}" | cut -d'/' -f2)
  printf "%s/%s:%s-%s" "${ACR_NAME}.azurecr.io" "${SIMULATOR_IMAGE_NAME}" "${SIMULATOR_IMAGE_TAG}" "${arch_suffix}"
}

full_connector_image_ref() {
  local arch_suffix
  arch_suffix=$(echo "${BUILD_PLATFORM}" | cut -d'/' -f2)
  printf "%s/%s:%s-%s" "${ACR_NAME}.azurecr.io" "${CONNECTOR_IMAGE_NAME}" "${CONNECTOR_IMAGE_TAG}" "${arch_suffix}"
}

check_cross_compile_needed() {
  local target_platform="$1"
  local current_arch
  current_arch=$(uname -m)

  # Normalize current architecture
  case "${current_arch}" in
    x86_64) current_arch="amd64" ;;
    aarch64) current_arch="arm64" ;;
  esac

  # Extract target architecture from platform string
  local target_arch
  case "${target_platform}" in
    linux/amd64) target_arch="amd64" ;;
    linux/arm64) target_arch="arm64" ;;
    *) target_arch="unknown" ;;
  esac

  # Return true if cross-compilation is needed
  [[ "${current_arch}" != "${target_arch}" ]]
}

ensure_buildx_builder() {
  local builder_name="multiarch-builder"

  # Check if builder already exists
  if ! docker buildx ls | grep -q "${builder_name}"; then
    log "Creating buildx builder ${builder_name} for multi-platform builds"
    docker buildx create --name "${builder_name}" --platform linux/amd64,linux/arm64 --use >/dev/null
  else
    log "Using existing buildx builder ${builder_name}"
    docker buildx use "${builder_name}" >/dev/null
  fi
}

build_simulator_image() {
  local dockerfile_path="${PROJECT_ROOT}/${DOCKERFILE_SIMULATOR_PATH}"
  local image_ref
  image_ref="$(full_simulator_image_ref)"
  log "Building simulator image ${image_ref} for platform ${BUILD_PLATFORM} (Dockerfile=${DOCKERFILE_SIMULATOR_PATH})"

  if check_cross_compile_needed "${BUILD_PLATFORM}"; then
    log "Cross-compilation required: building ${BUILD_PLATFORM} on $(uname -m)"
    ensure_buildx_builder
    # Use buildx for cross-compilation
    (cd "${PROJECT_ROOT}" && docker buildx build --platform="${BUILD_PLATFORM}" -f "${dockerfile_path}" -t "${image_ref}" --load .)
  else
    log "Native build: building ${BUILD_PLATFORM} on $(uname -m)"
    # Native build
    (cd "${PROJECT_ROOT}" && docker build --platform="${BUILD_PLATFORM}" -f "${dockerfile_path}" -t "${image_ref}" .)
  fi
}

push_simulator_image() {
  if [[ ${PUSH_IMAGES} != "true" ]]; then
    log "Skipping push of simulator image (PUSH_IMAGES=false)"
    return 0
  fi

  local image_ref
  image_ref="$(full_simulator_image_ref)"
  local login_server="${ACR_NAME}.azurecr.io"

  if command -v az >/dev/null 2>&1; then
    log "Ensuring ACR login via az for ${login_server}"
    if az acr login --name "${ACR_NAME}" >/dev/null; then
      log "Pushing simulator image ${image_ref}"
      docker push "${image_ref}"
    else
      warn "ACR login failed, skipping simulator image push"
      return 0
    fi
  else
    warn "az CLI not available"
    return 0
  fi
}

build_connector_image() {
  local dockerfile_path="${PROJECT_ROOT}/${DOCKERFILE_CONNECTOR_PATH}"
  if [[ ! -f "${dockerfile_path}" ]]; then
    warn "Connector Dockerfile not found at ${dockerfile_path}, skipping connector image build"
    return 0
  fi

  local image_ref
  image_ref="$(full_connector_image_ref)"
  log "Building connector image ${image_ref} for platform ${BUILD_PLATFORM} (Dockerfile=${DOCKERFILE_CONNECTOR_PATH})"

  if check_cross_compile_needed "${BUILD_PLATFORM}"; then
    log "Cross-compilation required: building ${BUILD_PLATFORM} on $(uname -m)"
    ensure_buildx_builder
    (cd "${PROJECT_ROOT}" && docker buildx build --platform="${BUILD_PLATFORM}" -f "${dockerfile_path}" -t "${image_ref}" --load .)
  else
    log "Native build: building ${BUILD_PLATFORM} on $(uname -m)"
    (cd "${PROJECT_ROOT}" && docker build --platform="${BUILD_PLATFORM}" -f "${dockerfile_path}" -t "${image_ref}" .)
  fi
}

push_connector_image() {
  if [[ ${PUSH_IMAGES} != "true" ]]; then
    log "Skipping push of connector image (PUSH_IMAGES=false)"
    return 0
  fi

  local image_ref
  image_ref="$(full_connector_image_ref)"
  local login_server="${ACR_NAME}.azurecr.io"

  if command -v az >/dev/null 2>&1; then
    log "Ensuring ACR login via az for ${login_server}"
    if az acr login --name "${ACR_NAME}" >/dev/null; then
      log "Pushing connector image ${image_ref}"
      docker push "${image_ref}"
    else
      warn "ACR login failed, skipping connector image push"
      return 0
    fi
  else
    warn "az CLI not available"
    return 0
  fi
}

main() {
  parse_env_file
  check_prereqs

  # Build application images
  build_simulator_image || err "Simulator image build failed"
  if [[ ${PUSH_IMAGES} == "true" ]]; then
    push_simulator_image || err "Simulator image push failed"
  fi

  build_connector_image || err "Connector image build failed"
  if [[ ${PUSH_IMAGES} == "true" ]]; then
    push_connector_image || err "Connector image push failed"
  fi

  log "Build process completed successfully"
}

main "$@"
