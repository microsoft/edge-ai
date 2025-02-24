#!/usr/bin/env bash
# shellcheck disable=SC2269

## Required Environment Variables:

ENVIRONMENT="${ENVIRONMENT}"                         # The environment for this cluster (ex. 'dev', 'prod')
ARC_RESOURCE_GROUP_NAME="${ARC_RESOURCE_GROUP_NAME}" # The Resource Group name where the Azure Arc cluster will be connected
ARC_RESOURCE_NAME="${ARC_RESOURCE_NAME}"             # The name of the Azure Arc resource that will be made on connection

## Optional Environment Variables:

K3S_VERSION="${K3S_VERSION}"                   # Version of k3s to install (ex. 'v1.31.2+k3s1') leave blank to install latest
CLUSTER_ADMIN_OID="${CLUSTER_ADMIN_OID}"       # The Object ID that would be given the cluster-admin permission in the cluster (ex. 'az ad signed-in-user show --query id -o tsv')
ARC_AUTO_UPGRADE="${ARC_AUTO_UPGRADE}"         # Enable/disable auto upgrade for Azure Arc cluster components (ex. 'false' to disable)
ARC_SP_CLIENT_ID="${ARC_SP_CLIENT_ID}"         # Service Principal Client ID used to connect the new cluster to Azure Arc
ARC_SP_SECRET="${ARC_SP_SECRET}"               # Service Principal Client Secret used to connect the new cluster to Azure Arc
ARC_TENANT_ID="${ARC_TENANT_ID}"               # Tenant where the new cluster will be connected to Azure Arc
AZ_CLI_VER="${AZ_CLI_VER}"                     # The Azure CLI version to install (ex. '2.51.0')
AZ_CONNECTEDK8S_VER="${AZ_CONNECTEDK8S_VER}"   # The Azure CLI extension connectedk8s version to install (ex. '1.10.0')
CUSTOM_LOCATIONS_OID="${CUSTOM_LOCATIONS_OID}" # Custom Locations Object ID needed if permissions are not allowed
DEVICE_USERNAME="${DEVICE_USERNAME}"           # Username for this device that will also need access to the k3s cluster
SKIP_INSTALL_AZ_CLI="${SKIP_INSTALL_AZ_CLI}"   # Skips downloading and installing Azure CLI (Ubuntu, Debian) from https://aka.ms/InstallAzureCLIDeb
SKIP_AZ_LOGIN="${SKIP_AZ_LOGIN}"               # Skips calling 'az login' and instead expects this to have been done previously
SKIP_INSTALL_K3S="${SKIP_INSTALL_K3S}"         # Skips downloading and installing k3s from https://get.k3s.io
SKIP_INSTALL_KUBECTL="${SKIP_INSTALL_KUBECTL}" # Skips downloading and installing kubectl if it is missing
SKIP_ARC_CONNECT="${SKIP_ARC_CONNECT}"         # Skips connecting the cluster Azure Arc

## Examples
##  ENVIRONMENT=dev ARC_RESOURCE_GROUP_NAME=rg-sample-eastu2-001 ARC_RESOURCE_NAME=arc-sample ./k3s-device-setup.sh
###

usage() {
  echo "usage: ${0##*./}"
  grep -x -B99 -m 1 "^###" "$0" |
    sed -E -e '/^[^#]+=/ {s/^([^ ])/  \1/ ; s/#/ / ; s/=[^ ]*$// ;}' |
    sed -E -e ':x' -e '/^[^#]+=/ {s/^(  [^ ]+)[^ ] /\1  / ;}' -e 'tx' |
    sed -e 's/^## //' -e '/^#/d' -e '/^$/d'
  exit 1
}

log() {
  printf "========== %s ==========\n" "$1"
}

err() {
  printf "[ ERROR ]: %s" "$1" >&2
  exit 1
}

enable_debug() {
  echo "[ DEBUG ]: Enabling writing out all commands being executed"
  set -x
}

if [[ $# -gt 0 ]]; then
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
set -o pipefail

####
# Setup Azure CLI
####

# Install Azure CLI.
if ! command -v "az" &>/dev/null; then
  if [[ ! $SKIP_INSTALL_AZ_CLI ]]; then
    log "Installing Azure CLI"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  else
    err "'az' is missing and required"
  fi
fi

# Verify correct version of Azure CLI and install if needed.
if [[ $AZ_CLI_VER && ! $SKIP_INSTALL_AZ_CLI ]]; then
  if ! az version | grep "\"azure-cli\"" | grep -Fq "$AZ_CLI_VER"; then
    log "Installing specified version of Azure CLI $AZ_CLI_VER"
    sudo apt-get remove -y azure-cli && log "Removed Azure CLI to install specific version"
    sudo apt-get install azure-cli="$AZ_CLI_VER-1~$(lsb_release -cs)"
  fi
fi

# Enable Azure CLI extension connectedk8s.
if [[ $AZ_CONNECTEDK8S_VER ]]; then
  if ! az version | grep "\"connectedk8s\"" | grep -Fq "$AZ_CONNECTEDK8S_VER"; then
    az extension remove --name connectedk8s 2>/dev/null && log "Removed Azure CLI extension [connectedk8s]"
    log "Enabling Azure CLI extension [connectedk8s] with version $AZ_CONNECTEDK8S_VER"
    az extension add --name connectedk8s --version "$AZ_CONNECTEDK8S_VER" -y
  fi
else
  log "Enabling and upgrading Azure CLI extension [connectedk8s]"
  az extension add --upgrade --name connectedk8s -y
fi

# Log in to the tenant with Azure CLI.
if [[ ! $SKIP_AZ_LOGIN ]]; then
  if [[ $ARC_SP_CLIENT_ID && $ARC_SP_SECRET && $ARC_TENANT_ID ]]; then
    az login --service-principal -u "$ARC_SP_CLIENT_ID" -p "$ARC_SP_SECRET" --tenant "$ARC_TENANT_ID"
  else
    az login --identity
  fi
fi

####
# Setup k3s
####

# Increase file system watches and notifies for AIO and ACSA
# https://learn.microsoft.com/en-us/azure/azure-arc/container-storage/single-node-cluster-edge-volumes?pivots=other#prepare-linux-with-other-platforms
max_user_instances=8192
max_user_watches=524288
file_max=100000

if [[ $(sudo cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 0) -lt "$max_user_instances" ]]; then
  echo "fs.inotify.max_user_instances=$max_user_instances" | sudo tee -a /etc/sysctl.conf
fi
if [[ $(sudo cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo 0) -lt "$max_user_watches" ]]; then
  echo "fs.inotify.max_user_watches=$max_user_watches" | sudo tee -a /etc/sysctl.conf
fi
if [[ $(sudo cat /proc/sys/fs/file-max 2>/dev/null || echo 0) -lt "$file_max" ]]; then
  echo "fs.file-max=$file_max" | sudo tee -a /etc/sysctl.conf
fi

sudo sysctl -p

# Install k3s if it is missing.
if ! command -v 'k3s' &>/dev/null; then
  if [[ ! $SKIP_INSTALL_K3S ]]; then
    log "Installing k3s"
    if [[ "$K3S_VERSION" ]]; then
      export INSTALL_K3S_VERSION="$K3S_VERSION"
    fi
    curl -sfL https://get.k3s.io | sh -
  else
    err "'k3s' is missing and required"
  fi
fi

# Install kubectl if it is missing.
if ! command -v 'kubectl' &>/dev/null; then
  if [[ ! $SKIP_INSTALL_KUBECTL ]]; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin
  else
    err "'kubectl' is missing and required"
  fi
fi

# Configure kubectl for k3s.
log "Creating $HOME/.kube/config"

sudo chmod 644 /etc/rancher/k3s/k3s.yaml

mkdir -p "$HOME/.kube"
KUBECONFIG="$HOME/.kube/config:/etc/rancher/k3s/k3s.yaml" kubectl config view --flatten >"$HOME/.kube/merged"
mv "$HOME/.kube/merged" "$HOME/.kube/config"
chmod 0600 "$HOME/.kube/config"

# shellcheck disable=SC2088
export KUBECONFIG="$HOME/.kube/config"
kubectl config use-context default

# Add ~/.kube/config to the user's .kube config folder and make it available to all users
if [[ "$DEVICE_USERNAME" && -d "/home/$DEVICE_USERNAME" && ! -f "/home/$DEVICE_USERNAME/.kube/config" ]]; then
  log "Creating /home/$DEVICE_USERNAME/.kube/config"
  mkdir -p "/home/$DEVICE_USERNAME/.kube"
  cp "$HOME/.kube/config" "/home/$DEVICE_USERNAME/.kube/config"
  chmod 666 "/home/$DEVICE_USERNAME/.kube/config"
fi

####
# Setup Azure Arc
####

connect_arc() {
  log "Connecting to Azure Arc"
  az_connectedk8s_connect=("az connectedk8s connect"
    "--name $ARC_RESOURCE_NAME"
    "--resource-group $ARC_RESOURCE_GROUP_NAME"
    "--enable-oidc-issuer"
    "--enable-workload-identity"
  )
  if [[ ${ARC_AUTO_UPGRADE,,} == "false" ]]; then
    az_connectedk8s_connect+=("--disable-auto-upgrade")
  fi
  echo "Executing: ${az_connectedk8s_connect[*]}"
  eval "${az_connectedk8s_connect[*]}"
}

# Connect the cluster to Azure Arc if it has not already been connected.
if [[ ! $SKIP_ARC_CONNECT ]]; then
  connected_to_cluster="$(kubectl get cm azure-clusterconfig -n azure-arc -o jsonpath="{.data.AZURE_RESOURCE_NAME}" 2>/dev/null || echo "")"
  if [[ ! $connected_to_cluster ]]; then
    # Do the 'az connectedk8s connect' and check for error.
    if ! connect_arc; then
      log "Connecting to Azure Arc failed"
      if [[ ${ENVIRONMENT,,} == "prod" ]]; then
        err "Cluster failed Azure Arc connect to resource: $ARC_RESOURCE_NAME in resource group: $ARC_RESOURCE_GROUP_NAME, \
          likely resource already exists and needs to be deleted"
      fi
      log "Attempting to reconnect by deleting Azure Arc connectedCluster resource in Azure"
      az connectedk8s delete --name "$ARC_RESOURCE_NAME" --resource-group "$ARC_RESOURCE_GROUP_NAME" --yes
      connect_arc
    fi
  elif [[ $connected_to_cluster != "$ARC_RESOURCE_NAME" ]]; then
    err "Cluster is already connected to a different Azure Arc resource: $connected_to_cluster"
  fi
fi

# Add additional helpful settings and tools for non-prod environments.
if [[ ${ENVIRONMENT,,} != "prod" ]]; then
  log "Configuring non-prod settings"
  # Configure Kubernetes nice-to-have bashrc settings.
  bash_rc="/etc/bash.bashrc"
  {
    for line in \
      "export KUBECONFIG=~/.kube/config" \
      "source <(kubectl completion bash)" \
      "alias k=kubectl" \
      "complete -o default -F __start_kubectl k" \
      "alias kubens='kubectl config set-context --current --namespace '"; do
      sudo grep -qxF -- "$line" "$bash_rc" || echo "$line"
    done
  } | sudo tee -a "$bash_rc" >/dev/null

  # Install k9s if missing.
  if ! command -v 'k9s' &>/dev/null; then
    log "Downloading and installing k9s"
    curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.tar.gz &&
      sudo tar -xf k9s_linux_amd64.tar.gz --directory=/usr/local/bin k9s &&
      sudo chmod +x /usr/local/bin/k9s &&
      rm k9s_linux_amd64.tar.gz
  fi
fi

# Cluster Connect is required for Custom Locations and needed for 'az connectedk8s proxy'.
log "Enabling Azure Arc feature [cluster-connect custom-locations]"
az_connectedk8s_enable_features=("az connectedk8s enable-features"
  "--name $ARC_RESOURCE_NAME"
  "--resource-group $ARC_RESOURCE_GROUP_NAME"
  "--features cluster-connect custom-locations"
)
if [[ $CUSTOM_LOCATIONS_OID ]]; then
  az_connectedk8s_enable_features+=("--custom-locations-oid $CUSTOM_LOCATIONS_OID")
fi
echo "Executing: ${az_connectedk8s_enable_features[*]}"
eval "${az_connectedk8s_enable_features[*]}"

# Add a 'cluster-admin' for the Object ID that was provided. This will be useful and
# needed for additional setup and configuration of the cluster at a later point.
if [[ $CLUSTER_ADMIN_OID ]]; then
  log "Adding $CLUSTER_ADMIN_OID as cluster admin"
  short_id="$(echo "$CLUSTER_ADMIN_OID" | cut -c1-7)"
  kubectl create clusterrolebinding "$short_id-user-binding" \
    --clusterrole cluster-admin \
    --user="$CLUSTER_ADMIN_OID" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

# Add the workload identity OIDC url to the kube-api server settings so it will be used on startup of the cluster.
if [[ ! $SKIP_ARC_CONNECT ]]; then
  log "Updating kube-api server settings with OIDC settings for Azure Arc workload identity"
  issuer_url=$(az connectedk8s show -g "$ARC_RESOURCE_GROUP_NAME" -n "$ARC_RESOURCE_NAME" --query oidcIssuerProfile.issuerUrl --output tsv 2>/dev/null || echo "")
  if [[ $issuer_url ]]; then
    k3s_config="/etc/rancher/k3s/config.yaml"
    {
      for line in \
        "kube-apiserver-arg:" \
        "- service-account-issuer=$issuer_url" \
        "- service-account-max-token-expiration=24h"; do
        sudo grep -qxF -- "$line" "$k3s_config" || echo "$line"
      done
    } | sudo tee -a "$k3s_config" >/dev/null

    # Restart the cluster to use the new settings.
    sudo systemctl restart k3s
  fi
fi
