#!/bin/bash
set -euo pipefail

###########################################################################
# Deploy Edge Applications to Kubernetes
###########################################################################
#
# Deploys leak-detection application workloads to a Kubernetes cluster
# after Terraform infrastructure provisioning completes.
#
# Usage:
#   ./deploy-edge-apps.sh --kubeconfig <path> \
#     --acr-login-server <server> [--namespace <ns>] [--dry-run]
#
###########################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Deploy edge application workloads to a Kubernetes cluster.

Required:
  --kubeconfig PATH       Path to kubeconfig file
  --acr-login-server URL  ACR login server (e.g. myacr.azurecr.io)

Optional:
  --namespace NS          Target namespace (default: azure-iot-operations)
  --image-tag TAG         Image tag (default: latest)
  --dry-run               Validate without deploying
  -h, --help              Show this help message
EOF
  exit "${1:-0}"
}

KUBECONFIG_PATH=""
ACR_LOGIN_SERVER=""
NAMESPACE="azure-iot-operations"
IMAGE_TAG="latest"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig)
      KUBECONFIG_PATH="$2"
      shift 2
      ;;
    --acr-login-server)
      ACR_LOGIN_SERVER="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --image-tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
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

if [[ -z "${KUBECONFIG_PATH}" || -z "${ACR_LOGIN_SERVER}" ]]; then
  echo "ERROR: --kubeconfig and --acr-login-server required" >&2
  usage 1
fi

export KUBECONFIG="${KUBECONFIG_PATH}"

dry_run_flag=""
if [[ "${DRY_RUN}" == true ]]; then
  dry_run_flag="--dry-run=client"
  echo "=== DRY RUN MODE ==="
fi

# Verify cluster connectivity
echo "=== Verifying cluster connectivity ==="
if ! kubectl cluster-info &>/dev/null; then
  echo "ERROR: Cannot connect to cluster" >&2
  echo "  kubeconfig: ${KUBECONFIG_PATH}" >&2
  exit 1
fi
echo "  Cluster reachable"

# Ensure namespace exists
echo "=== Ensuring namespace: ${NAMESPACE} ==="
kubectl create namespace "${NAMESPACE}" \
  ${dry_run_flag} \
  --save-config 2>/dev/null || true

# App paths
readonly APP_509="${REPO_ROOT}/src/500-application/509-sse-connector"
readonly APP_508="${REPO_ROOT}/src/500-application/508-media-connector"
readonly APP_507="${REPO_ROOT}/src/500-application/507-ai-inference"
readonly APP_503="${REPO_ROOT}/src/500-application/503-media-capture-service"

deploy_count=0
skip_count=0

deploy_kustomize() {
  local name="$1"
  local app_path="$2"
  local charts_dir="${app_path}/charts"

  if [[ ! -d "${charts_dir}" ]]; then
    echo "  SKIP: No charts/ directory found"
    ((skip_count++))
    return
  fi

  # Generate patches if gen-patch.sh exists
  if [[ -x "${charts_dir}/gen-patch.sh" ]]; then
    "${charts_dir}/gen-patch.sh" \
      --acr-name "${ACR_LOGIN_SERVER%%.*}" \
      --image-name "${name}" \
      --image-version "${IMAGE_TAG}" \
      --namespace "${NAMESPACE}"
  fi

  kubectl apply -k "${charts_dir}" \
    --namespace "${NAMESPACE}" \
    ${dry_run_flag}
  ((deploy_count++))
}

deploy_helm() {
  local release="$1"
  local chart_path="$2"
  local image_name="$3"

  if [[ ! -d "${chart_path}" ]]; then
    echo "  SKIP: Helm chart not found at ${chart_path}"
    ((skip_count++))
    return
  fi

  local -a helm_args=(
    upgrade --install "${release}" "${chart_path}"
    --namespace "${NAMESPACE}"
    --set "image.repository=${ACR_LOGIN_SERVER}/${image_name}"
    --set "image.tag=${IMAGE_TAG}"
  )

  if [[ "${DRY_RUN}" == true ]]; then
    helm_args+=(--dry-run)
  fi

  helm "${helm_args[@]}"
  ((deploy_count++))
}

deploy_yaml() {
  local manifest="$1"

  if [[ ! -f "${manifest}" ]]; then
    echo "  SKIP: Manifest not found: ${manifest}"
    ((skip_count++))
    return
  fi

  kubectl apply -f "${manifest}" \
    --namespace "${NAMESPACE}" \
    ${dry_run_flag}
  ((deploy_count++))
}

# Deployment order follows dependency chain:
#   509 (event ingestion) → 508 (media connector) →
#   507 (AI inference) → 503 (media capture)

echo ""
echo "=== Step 1: Deploying 509-sse-connector ==="
deploy_kustomize "sse-server" "${APP_509}"

echo ""
echo "=== Step 2: Deploying 508-media-connector ==="
if [[ -d "${APP_508}/kubernetes" ]]; then
  for manifest in "${APP_508}"/kubernetes/*.yaml; do
    deploy_yaml "${manifest}"
  done
else
  echo "  SKIP: No kubernetes/ directory"
  ((skip_count++))
fi

echo ""
echo "=== Step 3: Deploying 507-ai-inference ==="
deploy_kustomize "ai-edge-inference" "${APP_507}"

# Deploy model-downloader job if present
model_job="${APP_507}/charts/model-downloader-job.yaml"
if [[ -f "${model_job}" ]]; then
  echo "  Applying model-downloader job"
  kubectl apply -f "${model_job}" \
    --namespace "${NAMESPACE}" \
    ${dry_run_flag} 2>/dev/null || true
fi

echo ""
echo "=== Step 4: Deploying 503-media-capture-service ==="
deploy_helm \
  "media-capture-service" \
  "${APP_503}/charts/media-capture-service" \
  "media-capture-service"

# Wait for rollouts (skip in dry-run)
if [[ "${DRY_RUN}" != true ]]; then
  echo ""
  echo "=== Waiting for rollouts ==="

  readonly -a DEPLOYMENTS=(
    "sse-server|120"
    "ai-edge-inference|300"
    "media-capture-service|300"
  )

  for entry in "${DEPLOYMENTS[@]}"; do
    IFS='|' read -r dep_name timeout <<<"${entry}"
    echo "  Waiting for ${dep_name}..."
    kubectl rollout status "deployment/${dep_name}" \
      -n "${NAMESPACE}" \
      --timeout="${timeout}s" || true
  done
fi

echo ""
echo "=== Deployment Summary ==="
echo "  Deployed: ${deploy_count}"
echo "  Skipped:  ${skip_count}"
echo "  Dry run:  ${DRY_RUN}"
echo "=== Done ==="
