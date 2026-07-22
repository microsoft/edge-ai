#!/usr/bin/env bash
# shellcheck disable=SC2269

## Required Environment Variables:

KEY_VAULT_NAME="${KEY_VAULT_NAME}"       # The Azure Key Vault name where the deployment script secret is stored
KUBERNETES_DISTRO="${KUBERNETES_DISTRO}" # The kubernetes distribution being installed (ex. 'k3s', 'aks')
NODE_TYPE="${NODE_TYPE}"                 # The type of this node (ex. 'server', 'node')

## Optional Environment Variables:

CLIENT_ID="${CLIENT_ID:-}"                   # Client ID of the User Assigned Managed Identity to use for authentication
SECRET_NAME_PREFIX="${SECRET_NAME_PREFIX}"   # Optional prefix for constructing the secret name
SKIP_INSTALL_AZ_CLI="${SKIP_INSTALL_AZ_CLI}" # Skips downloading and installing Azure CLI (Ubuntu, Debian) from https://aka.ms/InstallAzureCLIDeb
SKIP_AZ_LOGIN="${SKIP_AZ_LOGIN}"             # Skips calling 'az login' and instead expects this to have been done previously

## Examples
##  KEY_VAULT_NAME=kv-example KUBERNETES_DISTRO=k3s NODE_TYPE=server CLIENT_ID=12345678-abcd-1234-abcd-123456789012 ./deploy-script-secrets.sh
##  KEY_VAULT_NAME=kv-example KUBERNETES_DISTRO=k3s NODE_TYPE=server SKIP_AZ_LOGIN=true ./deploy-script-secrets.sh
###

usage() {
  echo "usage: ${0##*./}"
  grep -x -B99 -m 1 "^###" "$0" \
    | sed -E -e '/^[^#]+=/ {s/^([^ ])/  \1/ ; s/#/ / ; s/=[^ ]*$// ;}' \
    | sed -E -e ':x' -e '/^[^#]+=/ {s/^(  [^ ]+)[^ ] /\1  / ;}' -e 'tx' \
    | sed -e 's/^## //' -e '/^#/d' -e '/^$/d'
  exit 1
}

log() {
  printf "========== %s ==========\n" "$1"
}

err() {
  printf "[ ERROR ]: %s\n" "$1" >&2
  exit 1
}

enable_debug() {
  echo "[ DEBUG ]: Enabling writing out all commands being executed"
  set -x
}

if [ $# -gt 0 ]; then
  case "$1" in
    -d | --debug)
      enable_debug
      ;;
    *)
      usage
      ;;
  esac
fi

set -e

# Check for required environment variables
if [ -z "$KEY_VAULT_NAME" ]; then
  err "KEY_VAULT_NAME environment variable is required"
fi

if [ -z "$KUBERNETES_DISTRO" ]; then
  err "KUBERNETES_DISTRO environment variable is required"
fi

if [ -z "$NODE_TYPE" ]; then
  err "NODE_TYPE environment variable is required"
fi

####
# Detect OS Type
####
log "Detecting OS type..."

# Print OS information for debugging
echo "OS Information:"
if [ -f /etc/os-release ]; then
  cat /etc/os-release
elif [ -f /etc/system-release ]; then
  cat /etc/system-release
else
  uname -a
fi

# Setting to ubuntu until other OS are supported
OS_TYPE="ubuntu"

####
# Azure Login
####
log "Setting up AZ CLI and authentication..."

# Check if Azure CLI is installed
if ! command -v "az" &>/dev/null; then
  if [ -z "$SKIP_INSTALL_AZ_CLI" ]; then
    log "Installing Azure CLI"
    case "$OS_TYPE" in
      ubuntu)
        # Pin Azure CLI install via Microsoft apt keyring/repo and explicit version (OSSF Scorecard pinned-dependencies)
        AZ_CLI_INSTALL_VER="${AZ_CLI_VER:-2.67.0}"
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
        sudo mkdir -p /etc/apt/keyrings
        curl -sLS https://packages.microsoft.com/keys/microsoft.asc \
          | gpg --dearmor \
          | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
        AZ_REPO=$(lsb_release -cs)
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_REPO} main" \
          | sudo tee /etc/apt/sources.list.d/azure-cli.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y "azure-cli=${AZ_CLI_INSTALL_VER}-1~${AZ_REPO}"
        ;;
      *)
        err "'az' command missing and not able to install Azure CLI. Please install Azure CLI before running this script."
        ;;
    esac
  else
    err "'az' is missing and required"
  fi
fi

# Log in to Azure if not skipped
if [ -z "$SKIP_AZ_LOGIN" ]; then
  if [ -n "$CLIENT_ID" ]; then
    log "Logging in with User Assigned Managed Identity (client ID: $CLIENT_ID)"
    if ! az login --identity --client-id "$CLIENT_ID"; then
      err "Failed to login with User Assigned Managed Identity (client ID: $CLIENT_ID)"
    fi
  else
    log "Logging in with default managed identity"
    if ! az login --identity; then
      err "Failed to login with managed identity. If the VM has multiple identities, provide CLIENT_ID to specify which one to use"
    fi
  fi

fi

####
# Download and Execute Script from Key Vault
####
log "Preparing to download deployment script from Key Vault..."

# Construct the secret name
SECRET_NAME=""
if [ -n "$SECRET_NAME_PREFIX" ]; then
  SECRET_NAME="${SECRET_NAME_PREFIX}${OS_TYPE}-${KUBERNETES_DISTRO}-${NODE_TYPE}-script"
else
  SECRET_NAME="${OS_TYPE}-${KUBERNETES_DISTRO}-${NODE_TYPE}-script"
fi

# Path to the downloaded script
SCRIPT_PATH="./$SECRET_NAME.sh"
trap 'rm "$SCRIPT_PATH"' EXIT

log "Downloading script: az keyvault secret download --vault-name $KEY_VAULT_NAME --name $SECRET_NAME --file $SCRIPT_PATH"

# Download the script from Key Vault. Retry with backoff to handle RBAC
# propagation delay when using system-assigned managed identity.
KV_OK=false
for attempt in $(seq 1 10); do
  if az keyvault secret download --vault-name "$KEY_VAULT_NAME" --name "$SECRET_NAME" --file "$SCRIPT_PATH" 2>&1; then
    KV_OK=true
    break
  fi
  log "Key Vault download attempt $attempt/10 failed, retrying in 30s..."
  rm -f "$SCRIPT_PATH"
  sleep 30
done

if [ "$KV_OK" != true ]; then
  err "Failed to download script from Key Vault after 10 attempts"
fi

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Execute the downloaded script
log "Executing the downloaded script..."
sudo CLIENT_ID="$CLIENT_ID" bash "$SCRIPT_PATH"

log "Script execution completed successfully"
