#!/bin/bash

# Deploy Chat With Factory
#
# Builds the container image, pushes to ACR, and deploys via Helm.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly COMPONENT_ROOT="${SCRIPT_DIR}/.."
readonly SERVICE_DIR="${COMPONENT_ROOT}/services/chat-with-your-factory"
readonly CHART_DIR="${COMPONENT_ROOT}/charts/chat-with-your-factory"
readonly DEFAULT_IMAGE_NAME="chat-with-your-factory"
readonly DEFAULT_IMAGE_VERSION="latest"
readonly DEFAULT_NAMESPACE="default"

required_vars=(
  "ACR_NAME"
  "RESOURCE_GROUP"
)

IMAGE_NAME="${IMAGE_NAME:-${DEFAULT_IMAGE_NAME}}"
IMAGE_VERSION="${IMAGE_VERSION:-${DEFAULT_IMAGE_VERSION}}"
NAMESPACE="${NAMESPACE:-${DEFAULT_NAMESPACE}}"
SPEECH_PROVIDER="${SPEECH_PROVIDER:-azure}"
HELM_RELEASE="${HELM_RELEASE:-chat-with-your-factory}"
AGENT_BACKEND="${AGENT_BACKEND:-foundry}"
FOUNDRY_AGENT_ID="${FOUNDRY_AGENT_ID:-}"
FABRIC_WORKSPACE_ID="${FABRIC_WORKSPACE_ID:-}"
FABRIC_LAKEHOUSE_ID="${FABRIC_LAKEHOUSE_ID:-}"
FABRIC_SQL_ENDPOINT="${FABRIC_SQL_ENDPOINT:-}"
FABRIC_LAKEHOUSE_DATABASE="${FABRIC_LAKEHOUSE_DATABASE:-}"

usage() {
  cat <<EOF
Usage: $0 [--uninstall]

Deploy Chat With Factory to a Kubernetes cluster via Helm.

Options:
  --uninstall/-u  Remove the deployment

Required environment variables:
  ACR_NAME        Azure Container Registry name
  RESOURCE_GROUP  Resource group containing ACR

Optional environment variables:
  IMAGE_NAME       Docker image name (default: ${DEFAULT_IMAGE_NAME})
  IMAGE_VERSION    Docker image version (default: ${DEFAULT_IMAGE_VERSION})
  NAMESPACE        Kubernetes namespace (default: ${DEFAULT_NAMESPACE})
  SPEECH_PROVIDER  Speech provider for client build (default: azure)
  HELM_RELEASE     Helm release name (default: chat-with-your-factory)

  Factory ontology tool (foundry backend) - read at service runtime:
  FABRIC_WORKSPACE_ID       Fabric workspace id (host discovery via Fabric REST)
  FABRIC_LAKEHOUSE_ID       Fabric lakehouse id (host discovery via Fabric REST)
  FABRIC_SQL_ENDPOINT       Explicit lakehouse SQL host (overrides discovery)
  FABRIC_LAKEHOUSE_DATABASE Lakehouse SQL database (default: RoboticsOntologyLH)

Example:
  export ACR_NAME="myacr"
  export RESOURCE_GROUP="my-rg"
  $0
EOF
}

check_prerequisites() {
  echo "Checking prerequisites..."

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      echo "ERROR: Required environment variable ${var} is not set"
      usage
      exit 1
    fi
  done

  local -a required_tools=(docker az kubectl helm)
  for tool in "${required_tools[@]}"; do
    if ! command -v "${tool}" &>/dev/null; then
      echo "ERROR: ${tool} is required but not installed"
      exit 1
    fi
  done

  echo "All prerequisites met."
}

build_and_push() {
  local acr_login_server
  acr_login_server="${ACR_NAME}.azurecr.io"

  echo "Logging in to ACR ${ACR_NAME}..."
  az acr login --name "${ACR_NAME}"

  local full_image="${acr_login_server}/${IMAGE_NAME}:${IMAGE_VERSION}"
  echo "Building image ${full_image}..."
  docker build \
    --build-arg "SPEECH_PROVIDER=${SPEECH_PROVIDER}" \
    -t "${full_image}" \
    "${SERVICE_DIR}"

  echo "Pushing image ${full_image}..."
  docker push "${full_image}"

  echo "Image pushed successfully."
}

# Provision the Foundry agent when targeting the foundry backend and no agent id
# was supplied. Captures the resolved id so it flows into the Helm release.
provision_agent() {
  if [[ "${AGENT_BACKEND}" != "foundry" ]]; then
    return 0
  fi

  if [[ -n "${FOUNDRY_AGENT_ID}" ]]; then
    echo "Using provided FOUNDRY_AGENT_ID; skipping provisioning."
    return 0
  fi

  echo "Provisioning Foundry agent..."
  (cd "${SERVICE_DIR}" && npm run build:server)
  FOUNDRY_AGENT_ID="$(node "${SERVICE_DIR}/dist/provisioning/provisionAgent.js")"
  echo "Resolved FOUNDRY_AGENT_ID=${FOUNDRY_AGENT_ID}"
}

deploy() {
  local acr_login_server
  acr_login_server="${ACR_NAME}.azurecr.io"

  echo "Deploying ${HELM_RELEASE} to namespace ${NAMESPACE}..."
  helm upgrade --install "${HELM_RELEASE}" "${CHART_DIR}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set "image.repository=${acr_login_server}/${IMAGE_NAME}" \
    --set "image.tag=${IMAGE_VERSION}" \
    ${FOUNDRY_AGENT_ID:+--set "env.FOUNDRY_AGENT_ID=${FOUNDRY_AGENT_ID}"} \
    ${FABRIC_WORKSPACE_ID:+--set "env.FABRIC_WORKSPACE_ID=${FABRIC_WORKSPACE_ID}"} \
    ${FABRIC_LAKEHOUSE_ID:+--set "env.FABRIC_LAKEHOUSE_ID=${FABRIC_LAKEHOUSE_ID}"} \
    ${FABRIC_SQL_ENDPOINT:+--set "env.FABRIC_SQL_ENDPOINT=${FABRIC_SQL_ENDPOINT}"} \
    ${FABRIC_LAKEHOUSE_DATABASE:+--set "env.FABRIC_LAKEHOUSE_DATABASE=${FABRIC_LAKEHOUSE_DATABASE}"} \
    --wait \
    --timeout 300s

  echo "Deployment complete."
}

uninstall() {
  echo "Uninstalling ${HELM_RELEASE} from namespace ${NAMESPACE}..."
  helm uninstall "${HELM_RELEASE}" --namespace "${NAMESPACE}" || true
  echo "Uninstall complete."
}

main() {
  if [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
    uninstall
    exit 0
  fi

  check_prerequisites
  build_and_push
  provision_agent
  deploy
}

main "$@"
