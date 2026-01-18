#!/usr/bin/env bash

# Azure Arc-enabled Kubernetes Proxy Initialization Script
#
# This script establishes connectivity to an Azure Arc-enabled Kubernetes cluster
# by managing the az connectedk8s proxy lifecycle and ensuring the AIO namespace exists.
#
# Key Features:
# - Detects existing kubectl connectivity before starting a new proxy
# - Manages az connectedk8s proxy with proper cleanup on exit/interrupt
# - Implements race condition fix for kubeconfig file creation
# - Creates AIO namespace if not present
#
# Race Condition Fix:
# The az connectedk8s proxy writes kubeconfig asynchronously in the background.
# To prevent partial/incomplete reads, the proxy writes to a temporary file first.
# A wrapper process monitors the temp file, waits for it to be complete, then
# atomically moves it to the final location. This ensures the kubeconfig file
# only appears when fully written and ready for use.
#
# Required Environment Variables:
# - TF_CONNECTED_CLUSTER_NAME: Name of the Arc-enabled Kubernetes cluster
# - TF_RESOURCE_GROUP_NAME: Azure resource group containing the cluster
# - TF_AIO_NAMESPACE: Namespace to create/ensure exists
# - TF_MODULE_PATH: Path to module containing YAML resources
#
# Optional Environment Variables:
# - DEPLOY_USER_TOKEN_SECRET: Key Vault secret name for deploy token
# - DEPLOY_KEY_VAULT_NAME: Key Vault name for deploy token retrieval
#   (both must be set together if using token-based authentication)

# Set error handling to continue on errors
set +e

# Validate required environment variables
required_vars=(
  "TF_CONNECTED_CLUSTER_NAME"
  "TF_RESOURCE_GROUP_NAME"
  "TF_AIO_NAMESPACE"
  "TF_MODULE_PATH"
)

missing_vars=()
for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
  echo "ERROR: Required environment variables not set:" >&2
  printf "  - %s\n" "${missing_vars[@]}" >&2
  exit 1
fi

# Validate optional token variables are both set or both unset
if [[ -n "${DEPLOY_USER_TOKEN_SECRET}" && -z "${DEPLOY_KEY_VAULT_NAME}" ]]; then
  echo "ERROR: DEPLOY_USER_TOKEN_SECRET is set but DEPLOY_KEY_VAULT_NAME is not" >&2
  exit 1
elif [[ -z "${DEPLOY_USER_TOKEN_SECRET}" && -n "${DEPLOY_KEY_VAULT_NAME}" ]]; then
  echo "ERROR: DEPLOY_KEY_VAULT_NAME is set but DEPLOY_USER_TOKEN_SECRET is not" >&2
  exit 1
fi

# Function to clean up resources
cleanup() {
  local exit_code=$?
  echo "Cleaning up..."

  [ -f "$kube_config_file" ] && rm "$kube_config_file" && echo "Deleted kubeconfig file"
  [ -f "${kube_config_temp:-}" ] && rm "$kube_config_temp" && echo "Deleted temporary kubeconfig file"

  # Kill the proxy process group
  if [[ ${proxy_pid:-} ]]; then
    if [[ ! ${proxy_pgid:-} ]]; then
      proxy_pgid="$proxy_pid"
    fi

    if [[ ${proxy_pgid:-} ]]; then
      if kill -INT -- "-${proxy_pgid}"; then
        echo "Killing proxy process $proxy_pid and process group $proxy_pgid with SIGINT, waiting for completion"
      else
        echo "Process group signal failed, attempting to signal proxy process $proxy_pid"
        kill -INT "$proxy_pid"
      fi

      local wait_elapsed=0
      while kill -0 "$proxy_pid" 2>/dev/null; do
        echo "Waiting for process to exit..."
        sleep 1
        ((wait_elapsed += 1))
        if ((wait_elapsed == 5)); then
          echo "Proxy still running, sending SIGTERM..."
          if ! kill -TERM -- "-${proxy_pgid}"; then
            kill -TERM "$proxy_pid"
          fi
        elif ((wait_elapsed > 10)); then
          echo "Proxy did not exit after SIGTERM, sending SIGKILL..."
          if ! kill -KILL -- "-${proxy_pgid}"; then
            kill -KILL "$proxy_pid"
          fi
        fi
      done
    fi
  fi

  echo "Cleanup done"
  trap - EXIT INT TERM
  exit "$exit_code"
}

check_connected_to_cluster() {
  # Check if kubeconfig file exists and has already been populated by az connectedk8s proxy running in background
  if [[ ! -s "$kube_config_file" ]]; then
    return 1
  fi

  # Verify connectivity and cluster identity
  if connected_to_cluster=$(kubectl get cm azure-clusterconfig -n azure-arc -o jsonpath="{.data.AZURE_RESOURCE_NAME}" --kubeconfig "$kube_config_file" --request-timeout=10s 2>/dev/null); then
    if [ "$connected_to_cluster" == "$TF_CONNECTED_CLUSTER_NAME" ]; then
      return 0
    fi
  fi
  return 1
}

start_proxy() {
  # Use a custom kubeconfig file to ensure the current user's context is not affected
  if ! kube_config_file=$(mktemp -t "${TF_CONNECTED_CLUSTER_NAME}.XXX"); then
    echo "ERROR: Failed to create temporary kubeconfig file" >&2
    exit 1
  fi

  # Race condition fix: az connectedk8s proxy writes to temp file first, then atomically moved to final location
  # This ensures kubeconfig file only has non-empty content when fully written, avoiding partial/incomplete reads
  if ! kube_config_temp=$(mktemp -t "${TF_CONNECTED_CLUSTER_NAME}.temp.XXX"); then
    echo "ERROR: Failed to create secondary temporary kubeconfig file" >&2
    exit 1
  fi

  # Build proxy arguments
  local -a proxy_args=(
    "-n" "$TF_CONNECTED_CLUSTER_NAME"
    "-g" "$TF_RESOURCE_GROUP_NAME"
    "--port" "9800"
    "--file" "$kube_config_temp"
  )
  local deploy_user_token=""
  if [[ $DEPLOY_USER_TOKEN_SECRET ]]; then
    echo "Getting Deploy User Token..."
    if ! deploy_user_token=$(az keyvault secret show \
      --name "$DEPLOY_USER_TOKEN_SECRET" \
      --vault-name "$DEPLOY_KEY_VAULT_NAME" \
      --query "value" \
      -o tsv); then
      echo "ERROR: failed to retrieve Deploy User Token from Key Vault" >&2
      exit 1
    fi
    echo "Got Deploy User Token..."
    proxy_args+=("--token" "$deploy_user_token")
  fi

  # Start proxy wrapper in its own process group
  set -m
  {
    # Start az connectedk8s proxy writing to temp file
    az connectedk8s proxy "${proxy_args[@]}" >/dev/null &
    az_pid=$!

    # Wait for temp file to have content
    local wait_count=0
    while [[ ! -s "$kube_config_temp" ]]; do
      if ! kill -0 "$az_pid" 2>/dev/null; then
        echo "ERROR: az connectedk8s proxy exited unexpectedly" >&2
        kill "$az_pid" 2>/dev/null
        # Signal parent to trigger cleanup and exit
        kill -INT $$ 2>/dev/null
        exit 1
      fi
      sleep 0.5
      ((wait_count += 1))
      if [ "$wait_count" -gt 60 ]; then
        echo "ERROR: timeout waiting for kubeconfig file creation" >&2
        kill "$az_pid" 2>/dev/null
        # Signal parent to trigger cleanup and exit
        kill -INT $$ 2>/dev/null
        exit 1
      fi
    done

    # Give az connectedk8s proxy time to finish writing
    sleep 2

    # Atomically move temp file to final location
    if ! mv "$kube_config_temp" "$kube_config_file"; then
      echo "ERROR: Failed to move kubeconfig file from temp location" >&2
      kill "$az_pid" 2>/dev/null
      # Signal parent to trigger cleanup and exit
      kill -INT $$ 2>/dev/null
      exit 1
    fi

    # Keep az proxy running in foreground of this subshell
    wait "$az_pid" || exit 1
  } &

  export proxy_pid=$!
  proxy_pgid=$(ps -o pgid= -p "$proxy_pid" 2>/dev/null | tr -d ' ')
  if [[ ! $proxy_pgid ]]; then
    proxy_pgid="$proxy_pid"
  fi
  export proxy_pgid
  set +m

  echo "Proxy PID: $proxy_pid, PGID: $proxy_pgid"

  timeout=0
  until check_connected_to_cluster; do
    if ! kill -0 "$proxy_pid" 2>/dev/null; then
      echo "ERROR: az connectedk8s proxy wrapper exited unexpectedly" >&2
      return 1
    fi
    sleep 1
    ((timeout += 1))
    if [ "$timeout" -gt 30 ]; then
      echo "ERROR: unable to reach $TF_CONNECTED_CLUSTER_NAME with kubectl, follow diagnostic instructions located at: https://learn.microsoft.com/azure/azure-arc/kubernetes/diagnose-connection-issues"
      exit 1
    fi
  done
}

if ! command -v "kubectl" &>/dev/null; then
  echo "ERROR: kubectl required" >&2
  exit 1
fi

# Get the default kubeconfig to check for connectivity
export kube_config_file=${KUBECONFIG:-${HOME}/.kube/config}

if check_connected_to_cluster; then
  echo "Cluster is already available from kubectl, continuing..."
else
  # Trap any error or exit to cleanup
  trap cleanup EXIT INT TERM

  echo "Starting 'az connectedk8s proxy'"

  start_proxy || exit 1
fi

# Ensure aio namespace is created and exists
if ! kubectl get namespace "$TF_AIO_NAMESPACE" --kubeconfig "$kube_config_file" &>/dev/null; then
  echo "Namespace $TF_AIO_NAMESPACE not found, attempting to create..."
  timeout=0
  until envsubst <"$TF_MODULE_PATH/yaml/aio-namespace.yaml" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
    echo "Error applying aio-namespace.yaml, retrying in 5 seconds..."
    sleep 5
    ((timeout += 5))
    if [ "$timeout" -gt 60 ]; then
      echo "ERROR: timed out creating namespace $TF_AIO_NAMESPACE" >&2
      exit 1
    fi
  done
fi

set -e
