#!/usr/bin/env bash

set -e

# Versions
K3S_VERSION=v1.31.2+k3s1

# Args from environment variables

device_username="${ENV_HOST_USERNAME}"
arc_resource_group="${ENV_ARC_RESOURCE_GROUP}"
arc_resource_name="${ENV_ARC_RESOURCE_NAME}"

custom_locations_oid="${ENV_CUSTOM_LOCATIONS_OID}"

# Optional args

environment="${ENV_ENVIRONMENT}"

add_user_as_cluster_admin="${ENV_ADD_USER_AS_CLUSTER_ADMIN}"
aad_user_id="${ENV_AAD_USER_ID}"

arc_auto_upgrade="${ENV_ARC_AUTO_UPGRADE}"

arc_sp_client_id="${ENV_ARC_SP_CLIENT_ID}"
arc_sp_secret="${ENV_ARC_SP_SECRET}"
tenant_id="${ENV_TENANT_ID}"

###################
# Dependencies Install
###################

# Install K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION sh -

# Install kubectl
if ! command -v kubectl &>/dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin
fi
# Configure kubectl
mkdir -p "/home/$device_username/.kube"
sudo cat /etc/rancher/k3s/k3s.yaml | tee "/home/$device_username/.kube/config" >/dev/null
mkdir -p ~/.kube
sudo cat /etc/rancher/k3s/k3s.yaml | tee ~/.kube/config >/dev/null
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Install Azure CLI
echo "========== Installing Azure CLI =========="
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
echo "========== Enable Azure CLI extension connectedk8s =========="
az extension add --name connectedk8s --system

# Login to Azure CLI
echo "========== Logging in to Azure CLI =========="

if [ -z "$arc_sp_client_id" ] || [ -z "$arc_sp_secret" ] || [ -z "$tenant_id" ]; then
    az login --identity
else
    az login --service-principal -u "$arc_sp_client_id" -p "$arc_sp_secret" --tenant "$tenant_id"
fi

# Connect to Azure Arc

connect_arc() {
    args="--name $arc_resource_name \
        --resource-group $arc_resource_group \
        --enable-oidc-issuer \
        --enable-workload-identity \
        --custom-locations-oid $custom_locations_oid"

    if [ "$arc_auto_upgrade" = "false" ]; then
        args+=" --disable-auto-upgrade"
    fi
    echo "========== Connecting to Azure Arc =========="
    echo "Executing arc connect command: az connectedk8s connect $args"
    eval "az connectedk8s connect $args"
}

if [ "$environment" = "prod" ]; then
    connect_arc
else
    # These steps are only required for development environments

    # Configure Kubernetes nice-to-have bashrc
    {
        echo "source <(kubectl completion bash)"
        echo "alias k=kubectl"
        echo "complete -o default -F __start_kubectl k"
        echo "alias kubens='kubectl config set-context --current --namespace '"
    } >>/etc/bash.bashrc

    # Install k9s
    wget https://github.com/derailed/k9s/releases/download/v0.28.0/k9s_Linux_amd64.tar.gz &&
        tar xf k9s_Linux_amd64.tar.gz --directory=/usr/local/bin k9s &&
        chmod +x /usr/local/bin/k9s &&
        rm -rf k9s_Linux_amd64.tar.gz

    # If connecting to cluster fails then delete existing Azure Arc connectedCluster in Azure and retry connecting
    # This can happen because Azure Arc resource isn't deleted when the VM is deleted
    if ! connect_arc; then
        echo "========== Connecting to Azure Arc failed =========="
        echo "========== Attempting to reconnect by deleting Azure Arc connectedCluster resource in Azure =========="
        # This deletion is only required in environments that are recreated
        # Remove this for productions environments
        az connectedk8s delete --name "$arc_resource_name" --resource-group "$arc_resource_group" --yes
        connect_arc
    fi
fi

# Enable cluster connect feature as it is required by custom locations
# https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/custom-locations#enable-custom-locations-on-your-cluster
az connectedk8s enable-features -n "$arc_resource_name" --resource-group "$arc_resource_group" --features cluster-connect

# Add user as cluster admin
if [ "$add_user_as_cluster_admin" = true ] && [ -z "$aad_user_id" ]; then
    short_id=$(echo "$aad_user_id" | cut -c1-7)
    kubectl create clusterrolebinding "$short_id"-user-binding --clusterrole cluster-admin --user="$aad_user_id"
fi

# Update k3s config with OIDC issuer url
issuerUrl=$(az connectedk8s show --resource-group "$arc_resource_group" --name "$arc_resource_name" --query oidcIssuerProfile.issuerUrl --output tsv)
sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF
kube-apiserver-arg:
- service-account-issuer=$issuerUrl
- service-account-max-token-expiration=24h
EOF
systemctl restart k3s

# Increase limits for Azure Container Storage
# https://learn.microsoft.com/en-us/azure/azure-arc/container-storage/single-node-cluster-edge-volumes?pivots=other#prepare-linux-with-other-platforms
sudo tee -a /etc/sysctl.conf >/dev/null <<EOF
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=524288
EOF
sudo sysctl -p
