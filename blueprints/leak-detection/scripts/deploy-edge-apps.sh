#!/bin/bash
set -euo pipefail

##############################################################################
# Deploy Edge Apps — 509, 507, 503
##############################################################################
#
# DESCRIPTION:
#   Deploys all three edge applications to the Arc-connected cluster.
#   Assumes init-scripts.sh is already sourced (Arc proxy running).
#
# ENVIRONMENT VARIABLES (required, set by Terraform):
#   TF_CONNECTED_CLUSTER_NAME    - Arc connected cluster name
#   TF_RESOURCE_GROUP_NAME       - Azure resource group
#   TF_AIO_NAMESPACE             - AIO Kubernetes namespace
#   TF_MODULE_PATH               - Terraform module path
#   TF_ACR_NAME                  - Azure Container Registry name
#   TF_IMAGE_VERSION             - Image tag for deployments
#   TF_APP_509_PATH              - Path to 509-sse-connector
#   TF_APP_507_PATH              - Path to 507-ai-inference
#   TF_APP_503_PATH              - Path to 503-media-capture-service
#   TF_STORAGE_ACCOUNT_ENDPOINT  - Blob storage endpoint for ACSA
#
##############################################################################

readonly REQUIRED_VARS=(
  TF_CONNECTED_CLUSTER_NAME
  TF_RESOURCE_GROUP_NAME
  TF_AIO_NAMESPACE
  TF_MODULE_PATH
  TF_ACR_NAME
  TF_IMAGE_VERSION
  TF_APP_509_PATH
  TF_APP_507_PATH
  TF_APP_503_PATH
  TF_STORAGE_ACCOUNT_ENDPOINT
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: Required variable ${var} is not set" >&2
    exit 1
  fi
done

# Step 0 — Enable anonymous pull on ACR (for Arc cluster to pull images without auth)
az acr update --name "${TF_ACR_NAME}" --anonymous-pull-enabled

# Step 1 — Deploy 509 (Kustomize)
echo "=== Step 1: Deploying 509-sse-connector ==="
"${TF_APP_509_PATH}/charts/gen-patch.sh" \
  --acr-name "${TF_ACR_NAME}" \
  --image-name "sse-server" \
  --image-version "${TF_IMAGE_VERSION}" \
  --namespace "${TF_AIO_NAMESPACE}"
kubectl apply -k "${TF_APP_509_PATH}/charts/" \
  --namespace "${TF_AIO_NAMESPACE}"

# Step 2 — Deploy 507 (Kustomize)
echo "=== Step 2: Deploying 507-ai-inference ==="
"${TF_APP_507_PATH}/charts/gen-patch.sh" \
  --acr-name "${TF_ACR_NAME}" \
  --image-name "ai-edge-inference" \
  --image-version "${TF_IMAGE_VERSION}" \
  --namespace "${TF_AIO_NAMESPACE}"
kubectl apply -k "${TF_APP_507_PATH}/charts/" \
  --namespace "${TF_AIO_NAMESPACE}"

# Step 3 — Create ACSA PVC
echo "=== Step 3: Creating ACSA PVC ==="
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-acsa-cloud-backed
  namespace: azure-iot-operations
spec:
  storageClassName: cloud-backed-sc
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

# Step 4 — Create ACSA EdgeSubvolume
echo "=== Step 4: Creating ACSA EdgeSubvolume ==="
kubectl apply -f - <<EOF
apiVersion: arccontainerstorage.azure.net/v1
kind: EdgeSubvolume
metadata:
  name: media-subvolume
  namespace: azure-iot-operations
spec:
  edgevolume: pvc-acsa-cloud-backed
  path: media
  auth:
    authType: MANAGED_IDENTITY
  storageaccountendpoint: ${TF_STORAGE_ACCOUNT_ENDPOINT}
  container: media
  ingestPolicy: edgeingestpolicy-default
EOF

# Step 5 — Deploy 503 (Helm)
echo "=== Step 5: Deploying 503-media-capture-service ==="
helm upgrade --install media-capture-service \
  "${TF_APP_503_PATH}/charts/media-capture-service" \
  --namespace "${TF_AIO_NAMESPACE}" \
  --set "image.repository=${TF_ACR_NAME}.azurecr.io/media-capture-service" \
  --set "image.tag=${TF_IMAGE_VERSION}" \
  --set "mediaCapture.storage.pvcName=pvc-acsa-cloud-backed"

# Step 6 — Deploy model-downloader job for 507
echo "=== Step 6: Deploying model-downloader job ==="
kubectl apply \
  -f "${TF_APP_507_PATH}/charts/model-downloader-job.yaml" \
  --namespace "${TF_AIO_NAMESPACE}" 2>/dev/null || true

# Wait for rollouts
echo "=== Waiting for rollouts ==="
kubectl rollout status deployment/sse-server \
  -n "${TF_AIO_NAMESPACE}" --timeout=120s
kubectl rollout status deployment/ai-edge-inference \
  -n "${TF_AIO_NAMESPACE}" --timeout=300s
kubectl rollout status deployment/media-capture-service \
  -n "${TF_AIO_NAMESPACE}" --timeout=300s

echo "=== All edge apps deployed successfully ==="
