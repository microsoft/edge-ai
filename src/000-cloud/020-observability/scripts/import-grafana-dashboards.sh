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

# Retry wrapper for Grafana API calls (SSL cert may not be ready immediately)
retry() {
    local max_attempts=10
    local delay=30
    local attempt=1
    while true; do
        if "$@"; then
            return 0
        fi
        if ((attempt >= max_attempts)); then
            echo "Failed after ${max_attempts} attempts"
            return 1
        fi
        echo "Attempt ${attempt}/${max_attempts} failed, retrying in ${delay}s..."
        sleep "$delay"
        ((attempt++))
    done
}

# Import dashboards from local files
echo "Importing local dashboard files..."
for dashboard in "${SCRIPT_DIR}"/*.json; do
    if [[ -f "$dashboard" ]]; then
        echo "Importing dashboard: $(basename "$dashboard")"
        retry az grafana dashboard import \
            -g "$RESOURCE_GROUP_NAME" \
            -n "$GRAFANA_NAME" \
            --overwrite \
            --definition "$dashboard"
    fi
done

# Import dashboard from GitHub
echo "Importing AIO sample dashboard from GitHub..."
retry az grafana dashboard import \
    -g "$RESOURCE_GROUP_NAME" \
    -n "$GRAFANA_NAME" \
    --overwrite \
    --definition "https://raw.githubusercontent.com/Azure/azure-iot-operations/refs/heads/main/samples/grafana-dashboard/aio.sample.json"

echo "Dashboard import completed successfully"
