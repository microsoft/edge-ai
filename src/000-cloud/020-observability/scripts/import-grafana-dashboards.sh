#!/bin/bash

# Script to import Grafana dashboards for AIO monitoring
# This script imports both local dashboard files and remote dashboards from GitHub

set -euo pipefail

# Environment variables (passed from Terraform)
GRAFANA_NAME="${GRAFANA_NAME:-}"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-}"
# Name of the Azure Monitor Workspace whose auto-provisioned managed Prometheus
# datasource backs the AIO sample dashboard panels.
MONITOR_WORKSPACE_NAME="${MONITOR_WORKSPACE_NAME:-}"

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
      echo "Failed after ${max_attempts} attempts" >&2
      return 1
    fi
    echo "Attempt ${attempt}/${max_attempts} failed, retrying in ${delay}s..." >&2
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

AIO_DASHBOARD_URL="https://raw.githubusercontent.com/Azure/azure-iot-operations/refs/heads/main/samples/grafana-dashboard/aio.sample.json"

# The AIO sample dashboard is a Grafana export: every panel references its
# datasource through the "${DS_MANAGED_PROMETHEUS_INSTANCE}" __inputs placeholder.
# az grafana dashboard import only auto-binds that placeholder when a matching
# Prometheus datasource is Grafana's default. In Azure Managed Grafana the
# managed Prometheus datasource is not the default, so the placeholder would be
# imported literally and panels fail with
# "Datasource ${DS_MANAGED_PROMETHEUS_INSTANCE} was not found".
# Resolve the managed Prometheus datasource uid and bind it before importing.
resolve_prometheus_datasource_uid() {
  az grafana data-source list -g "$RESOURCE_GROUP_NAME" -n "$GRAFANA_NAME" -o json |
    jq -r --arg name "$MONITOR_WORKSPACE_NAME" '
      (map(select(.name == $name)) | .[0].uid)
      // (map(select(.type == "prometheus")) | .[0].uid)
      // empty
    '
}

DS_UID="$(retry resolve_prometheus_datasource_uid)"

if [[ -z "$DS_UID" ]]; then
  echo "Warning: could not resolve a managed Prometheus datasource; importing AIO dashboard as-is"
  retry az grafana dashboard import \
    -g "$RESOURCE_GROUP_NAME" \
    -n "$GRAFANA_NAME" \
    --overwrite \
    --definition "$AIO_DASHBOARD_URL"
else
  echo "Binding AIO dashboard datasource to Prometheus uid: ${DS_UID}"
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  AIO_DASHBOARD_FILE="${TMP_DIR}/aio.sample.json"

  curl -fsSL "$AIO_DASHBOARD_URL" |
    jq --arg uid "$DS_UID" '
      walk(if type == "object" and .uid == "${DS_MANAGED_PROMETHEUS_INSTANCE}" then .uid = $uid else . end)
      | del(.__inputs)
    ' >"$AIO_DASHBOARD_FILE"

  retry az grafana dashboard import \
    -g "$RESOURCE_GROUP_NAME" \
    -n "$GRAFANA_NAME" \
    --overwrite \
    --definition "$AIO_DASHBOARD_FILE"
fi

echo "Dashboard import completed successfully"
