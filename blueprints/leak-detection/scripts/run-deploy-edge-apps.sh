#!/bin/bash
set -euo pipefail

##############################################################################
# Run Deploy Edge Apps — Connect to cluster and deploy all edge applications
##############################################################################
#
# DESCRIPTION:
#   Wrapper script that establishes an Arc proxy connection, exports required
#   environment variables from Terraform outputs, and runs deploy-edge-apps.sh.
#
#   This script is shell-agnostic — it runs in bash regardless of the user's
#   login shell (fish, zsh, etc.), avoiding compatibility issues with
#   init-scripts.sh which uses bash-specific syntax (e.g. indirect expansion).
#
# USAGE:
#   cd blueprints/leak-detection/terraform
#   ../scripts/run-deploy-edge-apps.sh
#
# ENVIRONMENT VARIABLES (optional):
#   TF_IMAGE_VERSION - Image tag for deployments (default: "latest")
#
# PREREQUISITES:
#   - Terraform apply has completed successfully (Phase 2)
#   - Images have been pushed to ACR (Phase 3)
#   - az CLI, kubectl, helm, and jq are installed
#
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
readonly TERRAFORM_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT

# Verify we can access Terraform state
if ! terraform -chdir="${TERRAFORM_DIR}" output -json >/dev/null 2>&1; then
  echo "ERROR: Cannot read Terraform outputs. Run 'terraform apply' first (Phase 2)." >&2
  exit 1
fi

# Verify required tools
for cmd in az kubectl helm jq; do
  if ! command -v "${cmd}" &>/dev/null; then
    echo "ERROR: ${cmd} is required but not installed." >&2
    exit 1
  fi
done

echo "=== Reading Terraform outputs ==="

export TF_CONNECTED_CLUSTER_NAME
TF_CONNECTED_CLUSTER_NAME=$(terraform -chdir="${TERRAFORM_DIR}" output -json cluster_connection | jq -r .arc_cluster_name)

export TF_RESOURCE_GROUP_NAME
TF_RESOURCE_GROUP_NAME=$(terraform -chdir="${TERRAFORM_DIR}" output -json cluster_connection | jq -r .arc_cluster_resource_group)

export TF_AIO_NAMESPACE="azure-iot-operations"

export TF_MODULE_PATH="${REPO_ROOT}/src/100-edge/110-iot-ops"

export TF_ACR_NAME
TF_ACR_NAME=$(terraform -chdir="${TERRAFORM_DIR}" output -json container_registry | jq -r .name)

export TF_IMAGE_VERSION="${TF_IMAGE_VERSION:-latest}"

STORAGE_NAME=$(terraform -chdir="${TERRAFORM_DIR}" output -json data_storage | jq -r .storage_account_name)
export TF_STORAGE_ACCOUNT_ENDPOINT="https://${STORAGE_NAME}.blob.core.windows.net"

export TF_APP_509_PATH="${REPO_ROOT}/src/500-application/509-sse-connector"
export TF_APP_507_PATH="${REPO_ROOT}/src/500-application/507-ai-inference"
export TF_APP_503_PATH="${REPO_ROOT}/src/500-application/503-media-capture-service"
export TF_BLUEPRINT_DIR="${SCRIPT_DIR}/.."

echo "  Cluster:  ${TF_CONNECTED_CLUSTER_NAME}"
echo "  RG:       ${TF_RESOURCE_GROUP_NAME}"
echo "  ACR:      ${TF_ACR_NAME}"
echo "  Version:  ${TF_IMAGE_VERSION}"
echo ""

echo "=== Establishing Arc proxy connection ==="
source "${REPO_ROOT}/src/100-edge/110-iot-ops/scripts/init-scripts.sh"

echo "=== Deploying edge applications ==="
"${SCRIPT_DIR}/deploy-edge-apps.sh"
