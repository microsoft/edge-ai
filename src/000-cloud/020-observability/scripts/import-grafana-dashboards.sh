#!/bin/bash

# Script to import Grafana dashboards for AIO monitoring
# This script imports both local dashboard files and remote dashboards from GitHub

set -euo pipefail

# Environment variables (passed from Terraform)
GRAFANA_NAME="${GRAFANA_NAME:-}"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-}"

if [[ -z "$GRAFANA_NAME" || -z "$RESOURCE_GROUP_NAME" ]]; then
  echo "Error: GRAFANA_NAME and RESOURCE_GROUP_NAME environment variables must be set"
  exit 1
fi

echo "Importing Grafana dashboards for ${GRAFANA_NAME} in resource group ${RESOURCE_GROUP_NAME}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import dashboards from local files
echo "Importing local dashboard files..."
for dashboard in "${SCRIPT_DIR}"/*.json; do
  if [[ -f "$dashboard" ]]; then
    echo "Importing dashboard: $(basename "$dashboard")"
    az grafana dashboard import \
      -g "$RESOURCE_GROUP_NAME" \
      -n "$GRAFANA_NAME" \
      --definition "$dashboard"
  fi
done

# Import dashboard from GitHub
echo "Importing AIO sample dashboard from GitHub..."
az grafana dashboard import \
  -g "$RESOURCE_GROUP_NAME" \
  -n "$GRAFANA_NAME" \
  --definition "https://raw.githubusercontent.com/Azure/azure-iot-operations/refs/heads/main/samples/grafana-dashboard/aio.sample.json"

echo "Dashboard import completed successfully"
