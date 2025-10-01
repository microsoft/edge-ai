#!/usr/bin/env bash

# Deploys the ros2-simulator Helm chart
# Optionally creates the rosbag PVC for simulator playback and loads local bag data.
# If USE_BAG_PLAYBACK is false, bag PVC operations are skipped.

set -euo pipefail

# Debug trap (enabled when DEBUG=1)
if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
  trap 'echo "[DEBUG] FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
err() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [-u|--uninstall] [--help]

Deploy (or uninstall) the ros2-simulator Helm release. Optional rosbag PVC + data load when USE_BAG_PLAYBACK=true/yes.
Reads .env for image, CycloneDDS, ROS2, MQTT, bag, and network settings.

Key env (.env):
  ACR_NAME (required) SIMULATOR_IMAGE IMAGE_TAG BUILD_PLATFORM NAMESPACE USE_BAG_PLAYBACK
  PVC_NAME PVC_SIZE LOCAL_PATH TARGET_PATH CYCLONEDDS_PEERS CYCLONEDDS_INTERFACES
  ROS_DOMAIN_ID LOG_LEVEL TOPIC_FILTER_PATTERNS EXCLUDE_SYSTEM_TOPICS MQTT_* SIMULATOR_PUBLISH_RATE BAG_PATH

Examples:
  ACR_NAME=myacr USE_BAG_PLAYBACK=true LOCAL_PATH=/resources/data ./scripts/deploy-ros2-simulator.sh
  ./scripts/deploy-ros2-simulator.sh --uninstall
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
# Core namespace & workload behavior (single unified namespace)
NAMESPACE="${NAMESPACE:-azure-iot-operations}"              # Namespace for PVC and simulator deployment
USE_BAG_PLAYBACK="${USE_BAG_PLAYBACK:-false}"               # true/yes to enable PVC + copy operations

# Rosbag PVC settings
PVC_NAME="${PVC_NAME:-rosbag-pvc}"                          # PVC name for rosbag storage
PVC_SIZE="${PVC_SIZE:-5Gi}"                                # Requested size for PVC creation
PVC_STORAGE_CLASS="${PVC_STORAGE_CLASS:-}"                  # Optional StorageClass name
TARGET_PATH="${TARGET_PATH:-/data}"                         # Mount path inside loader pod
LOCAL_PATH="${LOCAL_PATH:-}"                                # Local file/dir to copy into PVC (optional)
IMAGE="${IMAGE:-busybox:1.36}"                              # Loader pod image
POD_NAME="rosbag-pvc-loader-$(date +%s)"                    # Ephemeral loader pod name

# Container image build/publish configuration (ALWAYS executed)
ACR_NAME="${ACR_NAME:-}"                                    # Azure Container Registry name, no domain e.g. myregistry (required for deployment)
SIMULATOR_IMAGE_NAME="${SIMULATOR_IMAGE_NAME:-${SIMULATOR_IMAGE:-ros2-simulator}}" # Image name (no registry domain)
SIMULATOR_IMAGE_TAG="${SIMULATOR_IMAGE_TAG:-${IMAGE_TAG:-latest}}"        # Image tag
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"            # Target platform for deployment (amd64 by default)                  # Additional docker build args
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && cd .. && pwd)}" # Component root directory

check_prereqs() {
  command -v kubectl >/dev/null 2>&1 || err "kubectl required"
  [[ -n ${ACR_NAME} ]] || err "ACR_NAME required"
  if [[ ${USE_BAG_PLAYBACK,,} == true || ${USE_BAG_PLAYBACK,,} == yes ]]; then
    if [[ -n ${LOCAL_PATH} ]]; then
      LOCAL_PATH="${PROJECT_ROOT}${LOCAL_PATH}"
      [[ -e ${LOCAL_PATH} ]] || err "LOCAL_PATH does not exist: ${LOCAL_PATH}"
    else
      warn "LOCAL_PATH not provided; will only ensure PVC exists"
    fi
  fi
}

# -----------------------------------------------------------------------------
# Environment Variable Loading
# -----------------------------------------------------------------------------
load_env_variables() {
  local script_dir component_root env_file loaded skipped
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  component_root="${script_dir}/.."
  env_file="${component_root}/.env"
  loaded=0; skipped=0
  [[ -f "${env_file}" ]] || { warn "Environment file not found at ${env_file}"; return 0; }
  log "Loading environment variables from ${env_file}"
  # Use a simple read loop; the previous pattern with '|| [[ -n ${line} ]]' caused premature exit under 'set -e'
  while IFS= read -r line; do
    line="${line%%$'\r'}"                                   # strip CR
    [[ $line =~ ^[[:space:]]*$ || $line == \#* ]] && continue # skip blank/comment
    local key="${line%%=*}" value="${line#*=}"
    if [[ "${DEBUG:-0}" == "1" ]]; then echo "[DEBUG] parsing line: '$line'" >&2; fi
    # trim leading/trailing whitespace (parameter expansion method)
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue        # validate key
    # strip balanced single/double quotes
    if [[ ( $value == "\"*\"" && $value == *"\"" ) || ( $value == "'*'" && $value == *"'" ) ]]; then
      value="${value:1:-1}"
    fi
    if [[ -z "${!key:-}" ]]; then
      export "${key}=${value}"; loaded=$((loaded+1))
    else
      skipped=$((skipped+1))
    fi
  done < "${env_file}"
  log "Environment variables loaded: ${loaded} new, ${skipped} skipped"
}

# Load environment variables from .env file
load_env_variables

if [[ "${DEBUG:-0}" == "1" ]]; then
  echo "[DEBUG] Key vars: ACR_NAME='${ACR_NAME:-<unset>}' BUILD_PLATFORM='${BUILD_PLATFORM:-<unset>}' DOCKERFILE_PATH='${DOCKERFILE_PATH:-<unset>}'" >&2
fi

prepare_ros2_env_args() {
  # Emits each required --set pair as a separate newline-delimited token for safe array capture
  local -a ros2_env_vars=(
    ROS_DOMAIN_ID
    RMW_IMPLEMENTATION
    ROS_LOCALHOST_ONLY
    LOG_LEVEL
    TOPIC_FILTER_PATTERNS
    EXCLUDE_SYSTEM_TOPICS
    MQTT_BROKER
    MQTT_PORT
    MQTT_TOPIC_PREFIX
    SIMULATOR_PUBLISH_RATE
    BAG_PATH
    USE_BAG_PLAYBACK
  )
  local emitted=0
  for env_var in "${ros2_env_vars[@]}"; do
    local env_value="${!env_var:-}"
    if [[ -n ${env_value} ]]; then
      printf '%s\n' "--set" "env.${env_var}=${env_value}"
      emitted=1
    fi
  done
  if (( emitted )); then
    log "Configuring ROS2 environment variables for deployment" >&2
  fi
}

full_image_ref() {
  local arch_suffix
  # Extract architecture from platform format (linux/amd64 -> amd64)
  arch_suffix=$(echo "${BUILD_PLATFORM}" | cut -d'/' -f2)
  printf "%s/%s:%s-%s" "${ACR_NAME}.azurecr.io" "${SIMULATOR_IMAGE_NAME}" "${SIMULATOR_IMAGE_TAG}" "${arch_suffix}"
}



parse_cyclonedds_peers() {
  # CYCLONEDDS_PEERS is already loaded from .env file by load_env_variables function.
  # Treat ANY non-empty value (including 'eth0') as an explicit peer configuration; previously 'eth0' was implicitly ignored.
  local peers_value="${CYCLONEDDS_PEERS:-}"

  if [[ -n "${peers_value}" ]]; then
    log "Using CycloneDDS peers from environment: ${peers_value}"
  else
    log "CycloneDDS peers not set - using dynamic discovery"
  fi

  export CYCLONEDDS_PEERS="${peers_value}"
}

deploy_simulator_workload() {
  local image_ref
  image_ref="$(full_image_ref)"
  kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}" >/dev/null

  # Parse CycloneDDS peers from .env file
  parse_cyclonedds_peers

  # Prepare ROS2 environment variables for helm
  local -a ros2_env_array=()
  while IFS= read -r token; do
    ros2_env_array+=("${token}")
  done < <(prepare_ros2_env_args)

  # Helm deployment path
  local chart_dir="${PROJECT_ROOT}/charts/ros2-simulator"
  [[ -d ${chart_dir} ]] || err "Helm chart not found at ${chart_dir}"

  local release_name
  release_name="${HELM_RELEASE_NAME:-ros2-simulator}"
  local image_repo image_tag
  image_repo="${image_ref%:*}"   # everything before last :
  image_tag="${image_ref##*:}"

  # Prepare CycloneDDS peer configuration for helm
  # Arrays accumulate dynamic --set arguments for Helm (prevents unsafe word splitting)
  local -a cyclonedds_set_args=()
  if [[ -n "${CYCLONEDDS_PEERS:-}" ]]; then
    # Convert comma-separated peers to helm array format
    local index=0
    IFS=',' read -ra peers_array <<< "${CYCLONEDDS_PEERS}"
    for peer in "${peers_array[@]}"; do
      cyclonedds_set_args+=("--set" "cycloneDDS.peers[${index}]=${peer}")
      ((++index))
    done
    log "Configuring CycloneDDS with peers: ${CYCLONEDDS_PEERS}"
  else
    log "No specific CycloneDDS peers configured, using default discovery"
  fi

  # Interfaces list (env: CYCLONEDDS_INTERFACES comma-separated). Takes precedence over deprecated primary interface env.
  if [[ -n "${CYCLONEDDS_INTERFACES:-}" ]]; then
    local if_index=0
    IFS=',' read -ra if_array <<< "${CYCLONEDDS_INTERFACES}"
    for iface in "${if_array[@]}"; do
      cyclonedds_set_args+=("--set" "cycloneDDS.interfaces[${if_index}]=${iface}")
      ((++if_index))
    done
    log "Configuring CycloneDDS interfaces: ${CYCLONEDDS_INTERFACES}"
  fi

  # Prepare rosbag configuration for helm
  local -a rosbag_set_args=()
  if [[ ${USE_BAG_PLAYBACK,,} == true || ${USE_BAG_PLAYBACK,,} == yes ]]; then
    rosbag_set_args=(
      "--set" "rosbag.enabled=true"
      "--set" "rosbag.pvcName=${PVC_NAME}"
      "--set" "rosbag.mountPath=${TARGET_PATH:-/app/data}"
    )
    log "Configuring rosbag playback with PVC: ${PVC_NAME}"
  fi

  log "Deploying Helm release ${release_name} (chart=${chart_dir}) image=${image_repo}:${image_tag} namespace=${NAMESPACE}"
  helm upgrade --install "${release_name}" "${chart_dir}" \
    --namespace "${NAMESPACE}" \
    --set image.repository="${image_repo}" \
    --set image.tag="${image_tag}" \
    --set image.pullPolicy=IfNotPresent \
    --set "imagePullSecrets[0].name=acr-auth" \
    "${cyclonedds_set_args[@]}" \
    "${rosbag_set_args[@]}" \
    "${ros2_env_array[@]}"
}

ensure_pvc() {
  if kubectl get pvc "${PVC_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    log "PVC ${PVC_NAME} already exists in namespace ${NAMESPACE}"
    return 0
  fi
  log "Creating PVC ${PVC_NAME} (size=${PVC_SIZE})"
  cat <<PVC | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PVC_SIZE}
$(if [[ -n ${PVC_STORAGE_CLASS} ]]; then echo "  storageClassName: ${PVC_STORAGE_CLASS}"; fi)
PVC
}

create_loader_pod() {
  log "Creating temporary loader pod ${POD_NAME} mounting PVC ${PVC_NAME}"
  cat <<POD | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  labels:
    app: rosbag-loader
spec:
  restartPolicy: Never
  containers:
    - name: loader
      image: ${IMAGE}
      command: ['sh','-c','sleep 3600']
      volumeMounts:
        - name: bag-data
          mountPath: ${TARGET_PATH}
  volumes:
    - name: bag-data
      persistentVolumeClaim:
        claimName: ${PVC_NAME}
POD
}

wait_for_pod() {
  log "Waiting for pod to be Ready"
  for _ in {1..20}; do
    phase=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || echo Pending)
    if [[ ${phase} == Running ]]; then
      log "Pod running"
      return 0
    fi
    sleep 3
  done
  err "Pod did not become Running in time (phase: ${phase})"
}

copy_data() {
  if [[ -z ${LOCAL_PATH} ]]; then
    log "No LOCAL_PATH provided; skipping copy phase"
    return 0
  fi

  log "Copying ${LOCAL_PATH} -> ${POD_NAME}:${TARGET_PATH}"

  # Check if we have large files (>1GB) in source to determine copy method
  local has_large_files=false
  local total_size=0

  if [[ -f "${LOCAL_PATH}" ]]; then
    # Single file - check size
    local file_size
    file_size=$(stat -c%s "${LOCAL_PATH}" 2>/dev/null || echo 0)
    total_size=${file_size}
    if [[ ${file_size} -gt 1073741824 ]]; then
      has_large_files=true
    fi
  elif [[ -d "${LOCAL_PATH}" ]]; then
    # Directory - check for large files within
    while IFS= read -r -d '' file; do
      local file_size
      file_size=$(stat -c%s "${file}" 2>/dev/null || echo 0)
      total_size=$((total_size + file_size))
      if [[ ${file_size} -gt 1073741824 ]]; then
        has_large_files=true
        break
      fi
    done < <(find "${LOCAL_PATH}" -type f -print0)
  fi

  # Use tar streaming for large files or large total size (>2GB) to avoid kubectl cp limitations
  if [[ ${has_large_files} == true ]] || [[ ${total_size} -gt 2147483648 ]]; then
  log "Large files detected (total: $(numfmt --to=iec "${total_size}")), using tar streaming"
    if [[ -f "${LOCAL_PATH}" ]]; then
      # Single file
      tar -cf - -C "$(dirname "${LOCAL_PATH}")" "$(basename "${LOCAL_PATH}")" | \
        kubectl exec -i -n "${NAMESPACE}" "${POD_NAME}" -- tar -xf - -C "${TARGET_PATH}"
    else
      # Directory - create the target directory and copy contents
      local dir_name
      dir_name=$(basename "${LOCAL_PATH}")
      kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- mkdir -p "${TARGET_PATH}/${dir_name}"
      tar -cf - -C "${LOCAL_PATH}" . | \
        kubectl exec -i -n "${NAMESPACE}" "${POD_NAME}" -- tar -xf - -C "${TARGET_PATH}/${dir_name}"
    fi
  else
    # Use kubectl cp for smaller files
    kubectl cp "${LOCAL_PATH}" "${NAMESPACE}/${POD_NAME}:${TARGET_PATH}" >/dev/null
  fi

  log "Listing contents in PVC mount path"
  kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- ls -la "${TARGET_PATH}" || warn "Listing failed"
}

pvc_creator() {
 # Bag playback operations only if gate enabled
  if [[ ${USE_BAG_PLAYBACK,,} == true || ${USE_BAG_PLAYBACK,,} == yes ]]; then
    ensure_pvc
    if [[ -n ${LOCAL_PATH} ]]; then
      create_loader_pod
      wait_for_pod
      copy_data
      cleanup_loader_pod
      log "Rosbag data prepared in PVC ${PVC_NAME}"
    else
      log "PVC ensured; no data copied."
    fi
  else
    log "Bag playback gate not enabled (USE_BAG_PLAYBACK=false); skipping PVC operations."
  fi
}

cleanup_loader_pod() {
  log "Cleaning up temporary loader pod ${POD_NAME}"
  kubectl delete pod "${POD_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1 || warn "Loader pod ${POD_NAME} not found or failed to delete"
}

uninstall_simulator() {
  # Uninstall Helm release if requested
  log "Attempting helm uninstall ${SIMULATOR_IMAGE_NAME} (namespace=${NAMESPACE})"
  helm uninstall "${SIMULATOR_IMAGE_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1 || warn "Helm release ${SIMULATOR_IMAGE_NAME} not found or failed to uninstall"
  echo "Helm release '${SIMULATOR_IMAGE_NAME}' has been uninstalled successfully!"
}

main() {
  # Handle uninstall option before parsing other args
  if [[ "${1:-}" == "-u" ]] || [[ "${1:-}" == "--uninstall" ]]; then
    uninstall_simulator
    exit 0
  fi

  check_prereqs
  pvc_creator
  deploy_simulator_workload
}

main "$@"
