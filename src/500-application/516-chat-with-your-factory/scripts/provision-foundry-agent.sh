#!/bin/bash

# Provision Foundry Agent for Chat With Factory
#
# Creates (or updates) the module's Foundry agent and prints its FOUNDRY_AGENT_ID.
# The agent definition lives with this application; this is the reproducible entry
# point that replaces manual portal creation. Idempotent by agent name.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly COMPONENT_ROOT="${SCRIPT_DIR}/.."
readonly SERVICE_DIR="${COMPONENT_ROOT}/services/chat-with-your-factory"

required_vars=(
  "FOUNDRY_ENDPOINT"
  "FOUNDRY_MODEL_DEPLOYMENT"
)

usage() {
  cat <<EOF
Usage: $0

Create or update the Chat With Factory Foundry agent and print its
FOUNDRY_AGENT_ID for use in .env / Helm values. Re-running updates the
existing agent in place rather than creating a duplicate.

Required environment variables:
  FOUNDRY_ENDPOINT          Foundry project endpoint
  FOUNDRY_MODEL_DEPLOYMENT  Model deployment name (from 085-ai-foundry)

Optional environment variables:
  AZURE_TENANT_ID             Tenant for DefaultAzureCredential
  FOUNDRY_AGENT_NAME          Agent name (default: chat-with-your-factory)
  FOUNDRY_AGENT_INSTRUCTIONS  System instructions override

The provisioned agent attaches the query_factory_ontology tool. The tool's Fabric
lakehouse vars (FABRIC_WORKSPACE_ID / FABRIC_LAKEHOUSE_ID or FABRIC_SQL_ENDPOINT,
and FABRIC_LAKEHOUSE_DATABASE) are read at SERVICE RUNTIME, not during provisioning.

Example:
  export FOUNDRY_ENDPOINT="https://<account>.services.ai.azure.com/api/projects/<project>"
  export FOUNDRY_MODEL_DEPLOYMENT="gpt-4o"
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

  if ! command -v node &>/dev/null; then
    echo "ERROR: node is required but not installed"
    exit 1
  fi

  echo "All prerequisites met."
}

provision() {
  echo "Building server and provisioning Foundry agent..."
  (cd "${SERVICE_DIR}" && npm run build:server)

  local agent_id
  agent_id="$(node "${SERVICE_DIR}/dist/provisioning/provisionAgent.js")"

  echo ""
  echo "Set this in your .env / Helm values:"
  echo "FOUNDRY_AGENT_ID=${agent_id}"
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  check_prerequisites
  provision
}

main "$@"
