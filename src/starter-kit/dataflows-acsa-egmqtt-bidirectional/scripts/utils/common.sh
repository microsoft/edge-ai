#!/bin/bash

# Function to check if the required environment variables are set
check_env_var() {
  if [[ -z "${!1}" ]]; then
    echo "Error: The required environment variable '$1' is not set." >&2
    exit 1
  fi
}

# Function to navigate to the scripts directory when executing the script
navigate_to_scripts_dir() {
  UTILS_DIR=$(dirname "$0")
  SCRIPT_DIR=$(dirname "$UTILS_DIR")
  cd "$SCRIPT_DIR" || exit
}

# Function to test the kubeapi connection to the cluster with retry
test_kubeapi_connection_with_retry() {
  echo "Testing connection to the cluster is working, you may need to run 'az connectedk8s proxy' command"
  timeout 3m bash -c 'until kubectl get pods -A; do echo "Waiting for kubectl to become ready..."; sleep 10; done'
}

# Function to verify if kubectl is installed
verify_kubectl_installed() {
  # Check if kubectl is installed
  if ! command -v kubectl &>/dev/null; then
    echo "Kubectl could not be found. Please install it and try again."
    exit 1
  fi
}

# Function to verify if az cli is installed
verify_azcli_installed() {
  # check if az cli is installed
  if ! command -v az &>/dev/null; then
    echo "AZ CLI could not be found. Please install it and try again."
    exit 1
  fi
}

# Function to verify if envsubst is installed
verify_envsubst_installed() {
  if ! command -v envsubst &>/dev/null; then
    echo "envsubst could not be found. Please install the gettext package which includes envsubst and try again."
    exit 1
  fi
}

# Function to apply template with envsubst
apply_template_with_envsubst() {
  local template_file="$1"

  # Apply template with environment variable substitution
  envsubst <"$template_file"
}
