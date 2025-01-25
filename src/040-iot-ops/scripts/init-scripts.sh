#!/bin/bash

# Set error handling to continue on errors
set +e

# Function to clean up resources
cleanup() {
  echo "Cleaning up..."

  [ -f "$kube_config_file" ] && rm "$kube_config_file" && echo "Deleted kubeconfig file"

  # Kill the proxy process group
  if kill -INT -"$proxy_pgid"; then
    echo "Killing proxy process $proxy_pid and process group $proxy_pgid with SIGINT, waiting for completion"
    # Monitor for process to exit, kill -0 only checks for existence of process
    while kill -0 "$proxy_pid" 2>/dev/null; do
      echo "Waiting for process to exit..."
      sleep 1
    done
  fi

  echo "Cleanup done"
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
  az connectedk8s proxy -n "$TF_CONNECTED_CLUSTER_NAME" -g "$TF_RESOURCE_GROUP_NAME" --port 9800 --file "$kube_config_file" >/dev/null &
  export proxy_pid=$!
  proxy_pgid=$(ps -o pgid= -p $proxy_pid | tr -d ' ')
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
  trap cleanup EXIT

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
