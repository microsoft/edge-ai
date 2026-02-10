#!/usr/bin/env bash

# Deploys the ros2-connector Helm chart

set -euo pipefail

# Debug trap (enabled when DEBUG=1)
if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
  trap 'echo "[DEBUG] FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR
fi

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
Usage: $0 [-u|--uninstall] [--help]

Deploy (or uninstall) the ros2-connector Helm release.
Reads .env for: ACR_NAME CONNECTOR_IMAGE[_NAME] IMAGE_TAG BUILD_PLATFORM NAMESPACE and CycloneDDS/MQTT vars.

Env (from .env):
  ACR_NAME (required) CONNECTOR_IMAGE / CONNECTOR_IMAGE_NAME IMAGE_TAG BUILD_PLATFORM NAMESPACE
  CYCLONEDDS_PEERS CYCLONEDDS_INTERFACES MQTT_BROKER MQTT_PORT MQTT_TOPIC_PREFIX ROS_DOMAIN_ID LOG_LEVEL

Examples:
  ACR_NAME=myacr ./scripts/deploy-ros2-connector.sh
  ./scripts/deploy-ros2-connector.sh --uninstall
EOF
}

# Handle help flag first
for arg in "$@"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    usage
    exit 0
  fi
done

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
NAMESPACE="${NAMESPACE:-azure-iot-operations}" # Namespace for connector deployment
ACR_NAME="${ACR_NAME:-}"                       # Azure Container Registry name, no domain e.g. myregistry (required for deployment)
CONNECTOR_IMAGE_NAME="${CONNECTOR_IMAGE_NAME:-${CONNECTOR_IMAGE:-ros2-connector}}"
CONNECTOR_IMAGE_TAG="${CONNECTOR_IMAGE_TAG:-${IMAGE_TAG:-latest}}"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"                                            # Target platform for deployment (amd64 by default)
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && cd .. && pwd)}" # Component root directory

check_prereqs() {
  command -v kubectl >/dev/null 2>&1 || err "kubectl required"
  [[ -n ${ACR_NAME} ]] || err "ACR_NAME required"
}

# -----------------------------------------------------------------------------
# Environment Variable Loading
# -----------------------------------------------------------------------------
load_env_variables() {
  local script_dir component_root env_file loaded skipped
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  component_root="${script_dir}/.."
  env_file="${component_root}/.env"
  loaded=0
  skipped=0
  [[ -f "${env_file}" ]] || {
    warn "Environment file not found at ${env_file}"
    return 0
  }
  log "Loading environment variables from ${env_file}"
  # Use a simple read loop; the previous pattern with '|| [[ -n ${line} ]]' caused premature exit under 'set -e'
  while IFS= read -r line; do
    line="${line%%$'\r'}"                                     # strip CR
    [[ $line =~ ^[[:space:]]*$ || $line == \#* ]] && continue # skip blank/comment
    local key="${line%%=*}" value="${line#*=}"
    if [[ "${DEBUG:-0}" == "1" ]]; then echo "[DEBUG] parsing line: '$line'" >&2; fi
    # trim leading/trailing whitespace (parameter expansion method)
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue # validate key
    # strip balanced single/double quotes
    if [[ ($value == "\"*\"" && $value == *"\"") || ($value == "'*'" && $value == *"'") ]]; then
      value="${value:1:-1}"
    fi
    if [[ -z "${!key:-}" ]]; then
      export "${key}=${value}"
      loaded=$((loaded + 1))
    else
      skipped=$((skipped + 1))
    fi
  done <"${env_file}"
  log "Environment variables loaded: ${loaded} new, ${skipped} skipped"
}

# Load environment variables from .env file
load_env_variables

if [[ "${DEBUG:-0}" == "1" ]]; then
  echo "[DEBUG] Key vars: ACR_NAME='${ACR_NAME:-<unset>}' BUILD_PLATFORM='${BUILD_PLATFORM:-<unset>}' DOCKERFILE_PATH='${DOCKERFILE_PATH:-<unset>}'" >&2
fi

full_image_ref() {
  local arch_suffix
  # Extract architecture from platform format (linux/amd64 -> amd64)
  arch_suffix=$(echo "${BUILD_PLATFORM}" | cut -d'/' -f2)
  printf "%s/%s:%s-%s" "${ACR_NAME}.azurecr.io" "${CONNECTOR_IMAGE_NAME}" "${CONNECTOR_IMAGE_TAG}" "${arch_suffix}"
}

parse_cyclonedds_peers() {
  # CYCLONEDDS_PEERS is already loaded from .env file by load_env_variables function
  local peers_value="${CYCLONEDDS_PEERS:-}"

  if [[ -n "${peers_value}" && "${peers_value}" != "eth0" ]]; then
    log "Using CycloneDDS peers from environment: ${peers_value}"
  else
    # Use interface-based discovery or default
    log "CycloneDDS peers set to interface (${peers_value:-eth0}) - using dynamic discovery"
  fi

  # Export peers for helm deployment (already set, but ensure it's exported)
  export CYCLONEDDS_PEERS="${peers_value}"
}

deploy_connector_workload() {
  local image_ref
  image_ref="$(full_image_ref)"
  kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}" >/dev/null

  # Parse CycloneDDS peers from .env file
  parse_cyclonedds_peers

  # Helm deployment path for connector
  local chart_dir="${PROJECT_ROOT}/charts/ros2-connector"
  [[ -d ${chart_dir} ]] || err "Helm chart not found at ${chart_dir}"

  local release_name
  release_name="${HELM_RELEASE_NAME:-ros2-connector}"
  local image_repo image_tag
  image_repo="${image_ref%:*}" # everything before last :
  image_tag="${image_ref##*:}"

  # Prepare CycloneDDS peer/interface configuration for helm (use arrays for safe arg expansion)
  local -a cyclonedds_set_args=()
  if [[ -n "${CYCLONEDDS_PEERS:-}" && "${CYCLONEDDS_PEERS}" != "eth0" ]]; then
    local index=0
    IFS=',' read -ra peers_array <<<"${CYCLONEDDS_PEERS}"
    for peer in "${peers_array[@]}"; do
      cyclonedds_set_args+=(--set "cycloneDDS.peers[${index}]=${peer}")
      ((++index))
    done
    log "Configuring CycloneDDS with peers: ${CYCLONEDDS_PEERS}"
  else
    log "No specific CycloneDDS peers configured, using default discovery"
  fi

  if [[ -n "${CYCLONEDDS_INTERFACES:-}" ]]; then
    local if_index=0
    IFS=',' read -ra if_array <<<"${CYCLONEDDS_INTERFACES}"
    for iface in "${if_array[@]}"; do
      cyclonedds_set_args+=(--set "cycloneDDS.interfaces[${if_index}]=${iface}")
      ((++if_index))
    done
    log "Configuring CycloneDDS interfaces: ${CYCLONEDDS_INTERFACES}"
  fi

  # Prepare MQTT configuration for helm
  local -a mqtt_set_args=()
  if [[ -n "${MQTT_BROKER:-}" ]]; then
    mqtt_set_args+=(--set "env.MQTT_BROKER=${MQTT_BROKER}")
    log "Configuring MQTT broker: ${MQTT_BROKER}"
  fi
  if [[ -n "${MQTT_PORT:-}" ]]; then
    mqtt_set_args+=(--set "env.MQTT_PORT=${MQTT_PORT}")
    log "Configuring MQTT port: ${MQTT_PORT}"
  fi
  if [[ -n "${MQTT_TOPIC_PREFIX:-}" ]]; then
    mqtt_set_args+=(--set "env.MQTT_TOPIC_PREFIX=${MQTT_TOPIC_PREFIX}")
    log "Configuring MQTT topic prefix: ${MQTT_TOPIC_PREFIX}"
  fi

  # Prepare ROS2 configuration for helm
  local -a ros2_set_args=()
  if [[ -n "${ROS_DOMAIN_ID:-}" ]]; then
    ros2_set_args+=(--set "env.ROS_DOMAIN_ID=${ROS_DOMAIN_ID}")
  fi
  if [[ -n "${RMW_IMPLEMENTATION:-}" ]]; then
    ros2_set_args+=(--set "env.RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}")
  fi
  if [[ -n "${ROS_LOCALHOST_ONLY:-}" ]]; then
    ros2_set_args+=(--set "env.ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY}")
  fi
  if [[ -n "${TOPIC_FILTER_PATTERNS:-}" ]]; then
    ros2_set_args+=(--set "env.TOPIC_FILTER_PATTERNS=${TOPIC_FILTER_PATTERNS}")
  fi
  if [[ -n "${EXCLUDE_SYSTEM_TOPICS:-}" ]]; then
    ros2_set_args+=(--set "env.EXCLUDE_SYSTEM_TOPICS=${EXCLUDE_SYSTEM_TOPICS}")
  fi
  if [[ -n "${LOG_LEVEL:-}" ]]; then
    ros2_set_args+=(--set "env.LOG_LEVEL=${LOG_LEVEL}")
  fi

  # Prepare host network configuration for helm
  local -a host_network_set_args=()
  if [[ "${USE_HOST_NETWORK,,}" == "true" ]]; then
    host_network_set_args+=(--set networkPolicy.useHostNetwork=true --set networkPolicy.dnsPolicy=ClusterFirstWithHostNet)
    log "Configuring host network mode: enabled"
  else
    host_network_set_args+=(--set networkPolicy.useHostNetwork=false --set networkPolicy.dnsPolicy=ClusterFirst)
    log "Configuring host network mode: disabled"
  fi

  log "Deploying Helm release ${release_name} (chart=${chart_dir}) image=${image_repo}:${image_tag} namespace=${NAMESPACE}"
  helm upgrade --install "${release_name}" "${chart_dir}" \
    --namespace "${NAMESPACE}" \
    --set image.repository="${image_repo}" \
    --set image.tag="${image_tag}" \
    --set image.pullPolicy=IfNotPresent \
    --set "imagePullSecrets[0].name=acr-auth" \
    "${cyclonedds_set_args[@]}" \
    "${mqtt_set_args[@]}" \
    "${ros2_set_args[@]}" \
    "${host_network_set_args[@]}"
}

uninstall_connector() {
  # Uninstall Helm release if requested
  local release_name
  release_name="${HELM_RELEASE_NAME:-ros2-connector}"
  log "Attempting helm uninstall ${release_name} (namespace=${NAMESPACE})"
  helm uninstall "${release_name}" -n "${NAMESPACE}" >/dev/null 2>&1 || warn "Helm release ${release_name} not found or failed to uninstall"
  echo "Helm release '${release_name}' has been uninstalled successfully!"
}

main() {
  # Handle uninstall option before parsing other args
  if [[ "${1:-}" == "-u" ]] || [[ "${1:-}" == "--uninstall" ]]; then
    uninstall_connector
    exit 0
  fi

  check_prereqs
  deploy_connector_workload
}

main "$@"
