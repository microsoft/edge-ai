#!/usr/bin/env bash

# Set error handling to continue on errors
set +e

# Function to clean up resources
cleanup() {
  local exit_code=$?
  echo "Cleaning up..."

  [ -f "$kube_config_file" ] && rm "$kube_config_file" && echo "Deleted kubeconfig file"

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
  if connected_to_cluster=$(kubectl get cm azure-clusterconfig -n azure-arc -o jsonpath="{.data.AZURE_RESOURCE_NAME}" --kubeconfig "$kube_config_file" 2>/dev/null); then
    if [ "$connected_to_cluster" == "$TF_CONNECTED_CLUSTER_NAME" ]; then
      return 0
    fi
  fi
  return 1
}

start_proxy() {
  # Use a custom kubeconfig file to ensure the current user's context is not affected
  kube_config_file=$(mktemp -t "${TF_CONNECTED_CLUSTER_NAME}.XXX")
  # Start proxy in its own process group with -m
  set -m
  local -a proxy_args=(
    "-n" "$TF_CONNECTED_CLUSTER_NAME"
    "-g" "$TF_RESOURCE_GROUP_NAME"
    "--port" "9800"
    "--file" "$kube_config_file"
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
  az connectedk8s proxy "${proxy_args[@]}" >/dev/null &
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

  start_proxy
fi

# Ensure aio namespace is created and exists
if ! kubectl get namespace "$TF_AIO_NAMESPACE" --kubeconfig "$kube_config_file"; then
  until envsubst <"$TF_MODULE_PATH/yaml/aio-namespace.yaml" | kubectl apply -f - --kubeconfig "$kube_config_file"; do
    echo "Error applying aio-namespace.yaml, retrying in 5 seconds"
    sleep 5
  done
fi

set -e
