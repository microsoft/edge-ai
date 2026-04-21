#!/bin/bash

# Deploy Media Capture Service
#
# This script is the complete solution for deploying the Media Capture Service
# to your Azure Arc-enabled Kubernetes cluster. It handles ALL deployment steps.
#
# The script automates steps 1-8 from the Manual Deployment section in the README:
# 1. Generate and Configure environment variables
# 2. Build and push container image to ACR
# 3. Connect to Kubernetes cluster
# 4. Configure Azure Container Storage (ACSA)
# 5. Assign storage roles
# 6. Create storage container
# 7. Apply subvolume configuration
# 8. Deploy with Helm chart
#
# It automatically:
# - Connects to your Arc-enabled cluster via proxy
# - Manages all Azure resources and permissions
# - Deploys the complete service stack
# - Verifies successful deployment
# - Cleans up cluster connections when done

set -euo pipefail

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly COMPONENT_ROOT="${SCRIPT_DIR}/.."
readonly COMPONENT_DIR="${COMPONENT_ROOT}/services/media-capture-service"
readonly YAML_DIR="${COMPONENT_ROOT}/yaml"
readonly DEFAULT_IMAGE_NAME="media-capture-service"
readonly DEFAULT_IMAGE_VERSION="latest"
readonly DEFAULT_RUST_LOG="info"
readonly DEFAULT_FIELD_NAMESPACE="azure-iot-operations"

# Required environment variables
required_vars=(
  "ACR_NAME"
  "STORAGE_ACCOUNT_NAME"
  "ST_ACCOUNT_RESOURCE_GROUP"
  "CLUSTER_NAME"
  "CLUSTER_RESOURCE_GROUP"
)

# Optional environment variables with defaults
IMAGE_NAME="${IMAGE_NAME:-${DEFAULT_IMAGE_NAME}}"
IMAGE_VERSION="${IMAGE_VERSION:-${DEFAULT_IMAGE_VERSION}}"
RUST_LOG="${RUST_LOG:-${DEFAULT_RUST_LOG}}"
FIELD_NAMESPACE="${FIELD_NAMESPACE:-${DEFAULT_FIELD_NAMESPACE}}"

usage() {
  cat <<EOF
Usage: $0 [--uninstall]

🚀 COMPLETE MEDIA CAPTURE SERVICE DEPLOYMENT SCRIPT 🚀

This script is your one-stop solution for deploying the Media Capture Service
to Azure Arc-enabled Kubernetes clusters. It handles EVERYTHING automatically:

✅ Automatic cluster proxy management (no manual az connectedk8s proxy needed)
✅ Container image building and registry push
✅ Azure storage configuration and permissions
✅ Kubernetes deployment via Helm
✅ Complete deployment verification
✅ Automatic cleanup of connections

This script automates steps 1-8 from the Manual Deployment section in the README.

Options:
  --uninstall/-u              - Remove the media capture service deployment

Required environment variables:
  ACR_NAME                  - Azure Container Registry name
  STORAGE_ACCOUNT_NAME      - Azure Storage Account name
  ST_ACCOUNT_RESOURCE_GROUP - Storage Account resource group
  CLUSTER_NAME              - Kubernetes cluster name
  CLUSTER_RESOURCE_GROUP    - Cluster resource group

Optional environment variables:
  IMAGE_NAME                - Docker image name (default: ${DEFAULT_IMAGE_NAME})
  IMAGE_VERSION             - Docker image version (default: ${DEFAULT_IMAGE_VERSION})
  RUST_LOG                  - Logging level (default: ${DEFAULT_RUST_LOG})
  FIELD_NAMESPACE           - Kubernetes namespace (default: ${DEFAULT_FIELD_NAMESPACE})

Example:
  export ACR_NAME="myacr"
  export STORAGE_ACCOUNT_NAME="mystorageaccount"
  export ST_ACCOUNT_RESOURCE_GROUP="my-storage-rg"
  export CLUSTER_NAME="my-cluster"
  export CLUSTER_RESOURCE_GROUP="my-cluster-rg"
  $0
EOF
}

check_prerequisites() {
  echo "Checking prerequisites..."

  # Check for required environment variables
  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      echo "ERROR: Required environment variable ${var} is not set"
      usage
      exit 1
    fi
  done

  # Check for required commands
  local commands=("docker" "az" "kubectl" "helm")
  for cmd in "${commands[@]}"; do
    if ! command -v "${cmd}" &>/dev/null; then
      echo "ERROR: Required command '${cmd}' not found"
      exit 1
    fi
  done

  # Check if component directory exists
  if [[ ! -d "${COMPONENT_DIR}" ]]; then
    echo "ERROR: Component directory not found: ${COMPONENT_DIR}"
    exit 1
  fi

  echo "Prerequisites check passed"
}

load_env_file() {
  local env_file="${SCRIPT_DIR}/../.env"

  if [[ -f "${env_file}" ]]; then
    echo "Loading configuration from ${env_file}"

    # Export variables from .env file, handling quotes and comments
    while IFS= read -r line || [[ -n "${line}" ]]; do
      # Skip comments and empty lines
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line// /}" ]] && continue

      # Extract key=value pairs
      if [[ "${line}" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"

        # Remove surrounding quotes if present
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        # Export the variable if not already set
        if [[ -z "${!key:-}" ]]; then
          export "${key}"="${value}"
        fi
      fi
    done <"${env_file}"
  else
    echo "ERROR: .env file not found at ${env_file}. This file is required for deployment."
    echo "Please create a .env file with the necessary configuration variables."
    exit 1
  fi
}

check_cluster_connectivity() {
  echo "Checking cluster connectivity..."

  if kubectl get nodes &>/dev/null; then
    echo "Cluster is connected"
    return 0
  else
    echo "No cluster connection found"
    return 1
  fi
}

connect_to_cluster() {
  echo "🔗 Connecting to Azure Arc-enabled Kubernetes cluster..."

  # Check if already connected
  if check_cluster_connectivity; then
    return 0
  fi

  # Start the proxy in the background
  echo "🚀 Starting Azure Arc Connected Kubernetes proxy in background..."
  echo "   Running: az connectedk8s proxy -n \"${CLUSTER_NAME}\" -g \"${CLUSTER_RESOURCE_GROUP}\""
  az connectedk8s proxy -n "${CLUSTER_NAME}" -g "${CLUSTER_RESOURCE_GROUP}" &

  # Wait a moment for the proxy to start
  echo "⏳ Waiting for proxy to establish connection..."
  sleep 10

  if check_cluster_connectivity; then
    echo "✅ Successfully connected to cluster"
    kubectl get nodes
  else
    echo "❌ WARNING: kubectl connection verification failed, exiting."
    exit 1
  fi
}

step1_build_and_push_image() {
  echo "Step 1: Building and pushing container image..."

  cd "${COMPONENT_ROOT}"

  local image_tag="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION}"

  echo "Building Docker image: ${image_tag}"
  docker build -f "${COMPONENT_DIR}/Dockerfile" -t "${image_tag}" .

  echo "Logging into Azure Container Registry..."
  az acr login --name "${ACR_NAME}"

  echo "Pushing image to registry..."
  docker push "${image_tag}"
}

step2_configure_acsa() {

  echo "Step 2: Configuring Azure Container Storage (ACSA)..."

  if [[ -f "${YAML_DIR}/cloudBackedPVC.yaml" ]]; then
    kubectl apply -f "${YAML_DIR}/cloudBackedPVC.yaml"
  else
    echo "ERROR: cloudBackedPVC.yaml not found at ${YAML_DIR}/cloudBackedPVC.yaml"
    echo "This file is required for ACSA configuration."
    exit 1
  fi
}

step3_assign_storage_roles() {
  echo "Step 3: Assigning storage roles..."

  cd "${COMPONENT_DIR}"

  # Get the subscription ID
  echo "Retrieving subscription ID..."
  subscriptionId=$(az account show --query id --output tsv)
  echo "Subscription ID: $subscriptionId"

  # Assign 'Storage Blob Data Contributor' role to the signed-in user
  echo "Assigning 'Storage Blob Data Contributor' role to the signed-in user..."
  az ad signed-in-user show --query id -o tsv | az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee @- \
    --scope /subscriptions/"$subscriptionId"/resourceGroups/"$ST_ACCOUNT_RESOURCE_GROUP"/providers/Microsoft.Storage/storageAccounts/"$STORAGE_ACCOUNT_NAME"

  # Get the ACSA extension identity
  echo "Retrieving ACSA extension identity..."
  acsaExtensionIdentity=$(az k8s-extension list --cluster-name "$CLUSTER_NAME" --resource-group "$CLUSTER_RESOURCE_GROUP" --cluster-type connectedClusters | jq --arg extType "microsoft.arc.containerstorage" 'map(select(.extensionType | ascii_downcase == $extType)) | .[] | .identity.principalId' -r)
  echo "ACSA Extension Identity: $acsaExtensionIdentity"

  # Assign 'Storage Blob Data Owner' role to the ACSA extension identity
  echo "Assigning 'Storage Blob Data Owner' role to the ACSA extension identity..."
  az role assignment create \
    --assignee "$acsaExtensionIdentity" \
    --role "Storage Blob Data Owner" \
    --scope /subscriptions/"$subscriptionId"/resourceGroups/"$ST_ACCOUNT_RESOURCE_GROUP"/providers/Microsoft.Storage/storageAccounts/"$STORAGE_ACCOUNT_NAME"
  echo "'Storage Blob Data Owner' role assigned successfully."

  echo "ACSA role configuration completed successfully."
}

step4_create_storage_container() {
  echo "Step 4: Creating storage container..."

  echo "Creating media container in storage account..."
  az storage container create \
    --account-name "${STORAGE_ACCOUNT_NAME}" \
    --name media \
    --auth-mode login || echo "Container may already exist"
}

step5_apply_subvolume_config() {
  echo "Step 5: Applying subvolume configuration..."

  if [[ -f "${YAML_DIR}/mediaEdgeSubvolume.yaml" ]]; then
    # Set the storage account endpoint environment variable
    export STORAGE_ACCOUNT_ENDPOINT="https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/"

    echo "Applying subvolume configuration with storage account: ${STORAGE_ACCOUNT_NAME}"
    envsubst <"${YAML_DIR}/mediaEdgeSubvolume.yaml" | kubectl apply -f -
  else
    echo "WARNING: mediaEdgeSubvolume.yaml not found, skipping subvolume configuration"
  fi
}

step6_generate_env_configuration() {
  echo "Step 6: Generating environment configuration file..."

  cd "${COMPONENT_DIR}"

  if [[ -f "${SCRIPT_DIR}/generate-env-config.sh" ]]; then
    echo "Creating .env file with current environment variables..."
    "${SCRIPT_DIR}/generate-env-config.sh"
  else
    echo "ERROR: generate-env-config.sh not found at ${SCRIPT_DIR}/generate-env-config.sh"
    echo "This script is required to generate the .env configuration file."
    exit 1
  fi
}

step7_deploy_helm_chart() {
  echo "Step 7: Deploying with Helm chart..."

  # Load environment variables from .env file
  load_env_file

  local chart_path="${SCRIPT_DIR}/../charts/media-capture-service"
  local release_name="media-capture-service"

  # Check if Helm chart exists
  if [[ ! -f "${chart_path}/Chart.yaml" ]]; then
    echo "ERROR: Helm chart not found at ${chart_path}"
    exit 1
  fi

  # Validate Helm chart
  echo "Validating Helm chart..."
  if ! helm lint "${chart_path}"; then
    echo "ERROR: Helm chart validation failed"
    exit 1
  fi

  # Check if namespace exists
  if ! kubectl get namespace "${FIELD_NAMESPACE}" &>/dev/null; then
    echo "Creating namespace '${FIELD_NAMESPACE}'..."
    kubectl create namespace "${FIELD_NAMESPACE}"
  fi

  # Build Helm set arguments from environment variables
  local helm_sets=()

  # Image configuration
  if [[ -n "${ACR_NAME:-}" ]]; then
    # Add .azurecr.io if not already present
    if [[ "${ACR_NAME}" != *.azurecr.io ]]; then
      helm_sets+=("--set" "image.repository=${ACR_NAME}.azurecr.io/${IMAGE_NAME}")
    else
      helm_sets+=("--set" "image.repository=${ACR_NAME}/${IMAGE_NAME}")
    fi
  fi

  [[ -n "${IMAGE_VERSION:-}" ]] && helm_sets+=("--set" "image.tag=${IMAGE_VERSION}")

  # MQTT Configuration
  [[ -n "${AIO_BROKER_HOSTNAME:-}" ]] && helm_sets+=("--set" "mediaCapture.mqtt.brokerHostname=${AIO_BROKER_HOSTNAME}")
  [[ -n "${AIO_BROKER_TCP_PORT:-}" ]] && helm_sets+=("--set" "mediaCapture.mqtt.brokerTcpPort=${AIO_BROKER_TCP_PORT}")
  [[ -n "${AIO_MQTT_CLIENT_ID:-}" ]] && helm_sets+=("--set" "mediaCapture.mqtt.clientId=${AIO_MQTT_CLIENT_ID}")
  [[ -n "${AIO_TLS_CA_FILE:-}" ]] && helm_sets+=("--set" "mediaCapture.mqtt.tlsCaFile=${AIO_TLS_CA_FILE}")
  [[ -n "${AIO_SAT_FILE:-}" ]] && helm_sets+=("--set" "mediaCapture.mqtt.satFile=${AIO_SAT_FILE}")

  # Video Configuration
  [[ -n "${RTSP_URL:-}" ]] && helm_sets+=("--set" "mediaCapture.video.rtspUrl=${RTSP_URL}")
  [[ -n "${VIDEO_FPS:-}" ]] && helm_sets+=("--set" "mediaCapture.video.fps=${VIDEO_FPS}")
  [[ -n "${FRAME_WIDTH:-}" ]] && helm_sets+=("--set" "mediaCapture.video.frameWidth=${FRAME_WIDTH}")
  [[ -n "${FRAME_HEIGHT:-}" ]] && helm_sets+=("--set" "mediaCapture.video.frameHeight=${FRAME_HEIGHT}")
  [[ -n "${BUFFER_SECONDS:-}" ]] && helm_sets+=("--set" "mediaCapture.video.bufferSeconds=${BUFFER_SECONDS}")
  [[ -n "${CAPTURE_DURATION_SECONDS:-}" ]] && helm_sets+=("--set" "mediaCapture.video.captureDurationSeconds=${CAPTURE_DURATION_SECONDS}")
  [[ -n "${VIDEO_FEED_DELAY_SECONDS:-}" ]] && helm_sets+=("--set" "mediaCapture.video.feedDelaySeconds=${VIDEO_FEED_DELAY_SECONDS}")

  # Storage Configuration
  [[ -n "${MEDIA_CLOUD_SYNC_DIR:-}" ]] && helm_sets+=("--set" "mediaCapture.storage.cloudSyncDir=${MEDIA_CLOUD_SYNC_DIR}")

  # Trigger Topics - use --set-json for JSON array
  if [[ -n "${TRIGGER_TOPICS:-}" ]]; then
    helm_sets+=("--set-json" "mediaCapture.triggerTopics=${TRIGGER_TOPICS}")
  fi

  # Logging
  [[ -n "${RUST_LOG:-}" ]] && helm_sets+=("--set" "logging.level=${RUST_LOG}")

  # Set namespace
  helm_sets+=("--set" "namespace=${FIELD_NAMESPACE}")

  echo "Deploying Helm chart with the following configuration:"
  echo "  Release Name: ${release_name}"
  echo "  Namespace: ${FIELD_NAMESPACE}"
  echo "  Chart Path: ${chart_path}"
  echo "  Image: ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_VERSION}"

  # Execute helm upgrade --install command
  if helm list -n "${FIELD_NAMESPACE}" | grep -q "${release_name}"; then
    echo "Upgrading existing Helm release..."
    helm upgrade "${release_name}" "${chart_path}" \
      --namespace "${FIELD_NAMESPACE}" \
      "${helm_sets[@]}" \
      --wait \
      --timeout=300s
  else
    echo "Installing new Helm release..."
    helm install "${release_name}" "${chart_path}" \
      --namespace "${FIELD_NAMESPACE}" \
      "${helm_sets[@]}" \
      --wait \
      --timeout=300s
  fi

  echo "Helm deployment completed successfully!"
}

uninstall_media_capture_service() {
  echo "Uninstalling Media Capture Service..."

  # Set up trap to always disconnect from cluster on exit (success or failure)
  trap disconnect_from_cluster EXIT

  check_prerequisites
  connect_to_cluster

  # Load environment variables from .env file
  load_env_file

  local release_name="media-capture-service"

  echo "Checking if Helm release '${release_name}' exists in namespace '${FIELD_NAMESPACE}'..."

  if helm list -n "${FIELD_NAMESPACE}" | grep -q "${release_name}"; then
    echo "Found release '${release_name}'. Uninstalling..."
    helm uninstall "${release_name}" --namespace "${FIELD_NAMESPACE}"
    echo "Helm release '${release_name}' has been uninstalled successfully!"
  else
    echo "No Helm release '${release_name}' found in namespace '${FIELD_NAMESPACE}'"
  fi

  echo "Uninstall completed."
}

verify_deployment() {
  echo "Verifying Helm deployment..."

  echo "Waiting for pods to be ready..."
  echo "This may take a few minutes depending on image size and network speed..."

  local retry_count=0
  local max_retries=10
  local wait_seconds=15

  while [ $retry_count -lt $max_retries ]; do
    echo "Checking pod status (attempt $((retry_count + 1))/$max_retries)..."

    # Check if pods exist and are running
    local running_pods
    running_pods=$(kubectl get pod -l "app.kubernetes.io/name=media-capture-service" -n "${FIELD_NAMESPACE}" --no-headers 2>/dev/null | grep -c "Running" || echo "0")

    if [ "$running_pods" -gt 0 ]; then
      echo "✅ Pod is running successfully!"
      kubectl get pod -l "app.kubernetes.io/name=media-capture-service" -n "${FIELD_NAMESPACE}"
      echo ""
      echo "Helm release status:"
      helm status media-capture-service -n "${FIELD_NAMESPACE}"
      echo ""
      echo "Deployment completed successfully!"
      return 0
    else
      echo "Pods not yet running. Current status:"
      kubectl get pod -l "app.kubernetes.io/name=media-capture-service" -n "${FIELD_NAMESPACE}" || echo "No pods found yet"
      echo "Waiting ${wait_seconds} seconds before next check..."
      sleep $wait_seconds
    fi

    retry_count=$((retry_count + 1))
  done

  echo "⚠️  Warning: Pods did not reach running state within expected time"
  echo "Final pod status:"
  kubectl get pod -l "app.kubernetes.io/name=media-capture-service" -n "${FIELD_NAMESPACE}" || echo "No pods found"
  echo ""
  echo "Helm release status:"
  helm status media-capture-service -n "${FIELD_NAMESPACE}" || echo "Helm release status unavailable"
  echo ""
  echo "You can continue monitoring with: kubectl get pod -l app.kubernetes.io/name=media-capture-service -n ${FIELD_NAMESPACE} -w"
}

disconnect_from_cluster() {
  echo "Disconnecting from Kubernetes cluster..."

  # Find and kill the arcProxy_linux processes
  local arc_proxy_pids
  arc_proxy_pids=$(pgrep -f "arcProxy_linux" || echo "")

  if [[ -n "${arc_proxy_pids}" ]]; then
    echo "Stopping arcProxy_linux processes (PIDs: ${arc_proxy_pids})..."
    kill "${arc_proxy_pids}" 2>/dev/null || echo "arcProxy processes may have already stopped"
    sleep 2

    # Force kill if still running
    for pid in ${arc_proxy_pids}; do
      if kill -0 "${pid}" 2>/dev/null; then
        echo "Force stopping arcProxy process (PID: ${pid})..."
        kill -9 "${pid}" 2>/dev/null || echo "Process already terminated"
      fi
    done
  else
    echo "No arcProxy processes found"
  fi

  # Find and kill the az connectedk8s proxy process
  local proxy_pid
  proxy_pid=$(pgrep -f "connectedk8s proxy" || echo "")

  if [[ -n "${proxy_pid}" ]]; then
    echo "Stopping connectedk8s proxy process (PID: ${proxy_pid})..."
    kill "${proxy_pid}" 2>/dev/null || echo "Proxy process may have already stopped"
    sleep 2

    # Force kill if still running
    if kill -0 "${proxy_pid}" 2>/dev/null; then
      echo "Force stopping proxy process..."
      kill -9 "${proxy_pid}" 2>/dev/null || echo "Process already terminated"
    fi

    echo "Cluster connection stopped"
  else
    echo "No connectedk8s proxy process found"
  fi
}

main() {
  echo "🚀 Starting Media Capture Service deployment..."
  echo "📁 Component directory: ${COMPONENT_DIR}"
  echo ""
  echo "ℹ️  This script handles ALL deployment steps automatically including:"
  echo "   • Azure Arc cluster proxy management"
  echo "   • Container image building and pushing"
  echo "   • Azure storage configuration and permissions"
  echo "   • Kubernetes deployment via Helm"
  echo "   • Deployment verification and cleanup"
  echo ""

  # Set up trap to always disconnect from cluster on exit (success or failure)
  trap disconnect_from_cluster EXIT

  check_prerequisites
  step1_build_and_push_image
  connect_to_cluster
  step2_configure_acsa
  step3_assign_storage_roles
  step4_create_storage_container
  step5_apply_subvolume_config
  step6_generate_env_configuration
  step7_deploy_helm_chart
  verify_deployment

  echo ""
  echo "🎉 Media Capture Service deployment completed successfully!"
}

# Show usage if help requested
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Handle uninstall option
if [[ "${1:-}" == "-u" ]] || [[ "${1:-}" == "--uninstall" ]]; then
  uninstall_media_capture_service
  exit 0
fi

main "$@"
