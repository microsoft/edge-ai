#!/bin/bash
set -euo pipefail

##############################################################################
# Deploy Leak Detection Edge Apps
##############################################################################
#
# DESCRIPTION:
#   Deploys leak detection edge applications on top of an existing
#   full-single-node-cluster deployment. Layers the ONVIF camera simulator,
#   507-ai-inference, and optionally 503-media-capture-service and ACSA
#   storage onto an Arc-connected K3s cluster running Azure IoT Operations.
#
# PREREQUISITES:
#   - full-single-node-cluster blueprint already deployed
#   - kubectl configured with Arc proxy or kubeconfig for the cluster
#   - Container images built and pushed to ACR (see
#     blueprints/leak-detection/scripts/build-app-images-local.sh)
#   - helm, kubectl, and az CLI available on PATH
#
# USAGE:
#   ./deploy-leak-detection-apps.sh [OPTIONS]
#
# OPTIONS:
#   --acr-name <name>                 ACR name (required)
#   --cluster-name <name>             Arc connected cluster name (required)
#   --resource-group <name>           Azure resource group (required)
#   --namespace <ns>                  AIO namespace (default: azure-iot-operations)
#   --image-version <tag>             Image tag (default: latest)
#   --storage-account-endpoint <url>  Blob endpoint for ACSA (optional)
#   --rtsp-url <url>                  RTSP feed URL (default: rtsp://onvif-camera-simulator:8554/cam1)
#   --skip-acsa                       Skip ACSA PVC + EdgeSubvolume creation
#   --skip-media-capture              Skip 503-media-capture-service deployment
#   --skip-anonymous-pull             Skip enabling ACR anonymous pull
#   --help                            Show this help
#
# EXAMPLES:
#   ./deploy-leak-detection-apps.sh \
#     --acr-name myacr \
#     --cluster-name my-cluster \
#     --resource-group rg-mygroup \
#     --storage-account-endpoint https://mystorageacct.blob.core.windows.net/
#
#   ./deploy-leak-detection-apps.sh \
#     --acr-name myacr \
#     --cluster-name my-cluster \
#     --resource-group rg-mygroup \
#     --skip-acsa
#
#   ./deploy-leak-detection-apps.sh \
#     --acr-name myacr \
#     --cluster-name my-cluster \
#     --resource-group rg-mygroup \
#     --skip-media-capture
#
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT

# Source paths
readonly ONVIF_CHARTS="${REPO_ROOT}/blueprints/leak-detection/services/onvif-camera-simulator/charts"
readonly APP_507="${REPO_ROOT}/src/500-application/507-ai-inference"
readonly APP_503="${REPO_ROOT}/src/500-application/503-media-capture-service"

# Defaults
ACR_NAME=""
CLUSTER_NAME=""
RESOURCE_GROUP=""
AIO_NAMESPACE="azure-iot-operations"
IMAGE_VERSION="latest"
STORAGE_ACCOUNT_ENDPOINT=""
RTSP_URL="rtsp://onvif-camera-simulator:8554/cam1"
SKIP_ACSA=false
SKIP_MEDIA_CAPTURE=false
SKIP_ANONYMOUS_PULL=false

show_help() {
  sed -n '/^# USAGE:/,/^##/p' "${BASH_SOURCE[0]}" | head -n -1
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --acr-name)
      ACR_NAME="$2"
      shift 2
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --namespace)
      AIO_NAMESPACE="$2"
      shift 2
      ;;
    --image-version)
      IMAGE_VERSION="$2"
      shift 2
      ;;
    --storage-account-endpoint)
      STORAGE_ACCOUNT_ENDPOINT="$2"
      shift 2
      ;;
    --rtsp-url)
      RTSP_URL="$2"
      shift 2
      ;;
    --skip-acsa)
      SKIP_ACSA=true
      shift
      ;;
    --skip-media-capture)
      SKIP_MEDIA_CAPTURE=true
      shift
      ;;
    --skip-anonymous-pull)
      SKIP_ANONYMOUS_PULL=true
      shift
      ;;
    --help)
      show_help
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information." >&2
      exit 1
      ;;
  esac
done

# Validate required parameters
missing=()
[[ -z "${ACR_NAME}" ]] && missing+=("--acr-name")
[[ -z "${CLUSTER_NAME}" ]] && missing+=("--cluster-name")
[[ -z "${RESOURCE_GROUP}" ]] && missing+=("--resource-group")

if (( ${#missing[@]} > 0 )); then
  echo "ERROR: Missing required parameters: ${missing[*]}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

if [[ "${SKIP_ACSA}" == "false" && -z "${STORAGE_ACCOUNT_ENDPOINT}" ]]; then
  echo "ERROR: --storage-account-endpoint is required unless --skip-acsa is set" >&2
  exit 1
fi

# Validate source paths exist
required_dirs=("${ONVIF_CHARTS}" "${APP_507}/charts")
if [[ "${SKIP_MEDIA_CAPTURE}" == "false" ]]; then
  required_dirs+=("${APP_503}/charts/media-capture-service")
fi
for dir in "${required_dirs[@]}"; do
  if [[ ! -d "${dir}" ]]; then
    echo "ERROR: Required directory not found: ${dir}" >&2
    exit 1
  fi
done

# Validate CLI tools
for cmd in kubectl helm az; do
  if ! command -v "${cmd}" &>/dev/null; then
    echo "ERROR: ${cmd} is not installed or not on PATH" >&2
    exit 1
  fi
done

echo "=== Deploy Leak Detection Edge Apps ==="
echo "Cluster:   ${CLUSTER_NAME}"
echo "Group:     ${RESOURCE_GROUP}"
echo "ACR:       ${ACR_NAME}"
echo "Version:   ${IMAGE_VERSION}"
echo "Namespace: ${AIO_NAMESPACE}"
echo "RTSP URL:  ${RTSP_URL}"
echo ""

# Step 0 — Enable anonymous pull on ACR
if [[ "${SKIP_ANONYMOUS_PULL}" == "false" ]]; then
  echo "=== Step 0: Enabling ACR anonymous pull ==="
  az acr update --name "${ACR_NAME}" --anonymous-pull-enabled
fi

# Step 1 — Deploy ONVIF Camera Simulator (Kustomize)
echo "=== Step 1: Deploying onvif-camera-simulator ==="
"${ONVIF_CHARTS}/gen-patch.sh" \
  --acr-name "${ACR_NAME}" \
  --image-name "onvif-camera-simulator" \
  --image-version "${IMAGE_VERSION}" \
  --namespace "${AIO_NAMESPACE}"
kubectl apply -k "${ONVIF_CHARTS}" \
  --namespace "${AIO_NAMESPACE}"

# Step 2 — Deploy 507-ai-inference (Kustomize)
echo "=== Step 2: Deploying 507-ai-inference ==="
"${APP_507}/charts/gen-patch.sh" \
  --acr-name "${ACR_NAME}" \
  --image-name "ai-edge-inference" \
  --image-version "${IMAGE_VERSION}" \
  --namespace "${AIO_NAMESPACE}"
kubectl apply -k "${APP_507}/charts/" \
  --namespace "${AIO_NAMESPACE}"

# Step 3 — Deploy model-downloader job for 507
echo "=== Step 3: Deploying model-downloader job ==="
kubectl apply \
  -f "${APP_507}/charts/model-downloader-job.yaml" \
  --namespace "${AIO_NAMESPACE}" 2>/dev/null || true

# Step 4 — Create ACSA PVC + EdgeSubvolume
if [[ "${SKIP_ACSA}" == "false" ]]; then
  echo "=== Step 4a: Creating ACSA PVC ==="
  kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-acsa-cloud-backed
  namespace: ${AIO_NAMESPACE}
spec:
  storageClassName: cloud-backed-sc
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

  echo "=== Step 4b: Creating ACSA EdgeSubvolume ==="
  kubectl apply -f - <<EOF
apiVersion: arccontainerstorage.azure.net/v1
kind: EdgeSubvolume
metadata:
  name: media-subvolume
  namespace: ${AIO_NAMESPACE}
spec:
  edgevolume: pvc-acsa-cloud-backed
  path: media
  auth:
    authType: MANAGED_IDENTITY
  storageaccountendpoint: ${STORAGE_ACCOUNT_ENDPOINT}
  container: media
  ingestPolicy: edgeingestpolicy-default
EOF
else
  echo "=== Step 4: Skipping ACSA (--skip-acsa) ==="
fi

# Step 5 — Deploy 503-media-capture-service (Helm)
if [[ "${SKIP_MEDIA_CAPTURE}" == "false" ]]; then
  echo "=== Step 5: Deploying 503-media-capture-service ==="
  helm upgrade --install media-capture-service \
    "${APP_503}/charts/media-capture-service" \
    --namespace "${AIO_NAMESPACE}" \
    --set "image.repository=${ACR_NAME}.azurecr.io/media-capture-service" \
    --set "image.tag=${IMAGE_VERSION}" \
    --set "mediaCapture.storage.pvcName=pvc-acsa-cloud-backed" \
    --set "mediaCapture.video.rtspUrl=${RTSP_URL}" \
    --set "mediaCapture.triggerTopics=[\"edge-ai/+/+/camera/detections\"]"
else
  echo "=== Step 5: Skipping media-capture (--skip-media-capture) ==="
fi

# Step 6 — Wait for rollouts
echo "=== Step 6: Waiting for rollouts ==="
kubectl rollout status deployment/onvif-camera-simulator \
  -n "${AIO_NAMESPACE}" --timeout=120s
kubectl rollout status deployment/ai-edge-inference \
  -n "${AIO_NAMESPACE}" --timeout=300s
if [[ "${SKIP_MEDIA_CAPTURE}" == "false" ]]; then
  kubectl rollout status deployment/media-capture-service \
    -n "${AIO_NAMESPACE}" --timeout=300s
fi

echo ""
echo "=== All leak detection edge apps deployed ==="
echo ""
echo "Deployed:"
echo "  - onvif-camera-simulator (RTSP at ${RTSP_URL})"
echo "  - 507-ai-inference (subscribes to edge-ai/+/+/camera/snapshots)"
if [[ "${SKIP_MEDIA_CAPTURE}" == "false" ]]; then
  echo "  - 503-media-capture-service (triggers on edge-ai/+/+/camera/detections)"
fi
echo ""
echo "Verify with:"
echo "  kubectl get pods -n ${AIO_NAMESPACE}"
