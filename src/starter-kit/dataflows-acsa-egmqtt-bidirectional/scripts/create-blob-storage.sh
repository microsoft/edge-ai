#!/bin/bash

set -e
set -u
set -o pipefail

# shellcheck disable=SC1091
source ./utils/common.sh

verify_kubectl_installed
verify_azcli_installed
verify_envsubst_installed
test_kubeapi_connection_with_retry

check_env_var "RESOURCE_GROUP"
check_env_var "CLUSTER_NAME"
check_env_var "LOCATION"
STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME:-$(echo "st${RESOURCE_GROUP:0:22}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')}
ACSA_CLOUD_BACKED_AIO_PVC_NAME=${ACSA_CLOUD_BACKED_AIO_PVC_NAME:-"pvc-acsa-cloud-backed-aio"}
METRIC1_TOPIC_PATH_NAME=${METRIC1_TOPIC_PATH_NAME:-"machine-status"}
METRIC2_TOPIC_PATH_NAME=${METRIC2_TOPIC_PATH_NAME:-"total-counter"}
METRIC3_TOPIC_TEMPLATE_NAME=${METRIC3_TOPIC_TEMPLATE_NAME:-"devices-health"}

navigate_to_scripts_dir

wait_for_edge_volume() {
  local edgeVolumeName=$1

  echo "Waiting for edge volume $edgeVolumeName to be deployed..."
  kubectl wait --for=jsonpath='{.status.state}'="deployed" edgevolumes/"$edgeVolumeName" --timeout=120s
}

# Create a storage account
echo "Creating storage account $STORAGE_ACCOUNT_NAME in resource group $RESOURCE_GROUP..."
az storage account create --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --sku Standard_RAGRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --enable-hierarchical-namespace

# Create role assignment to be able to contribute to the storage account
subscriptionId=$(az account show --query id --output tsv)

az ad signed-in-user show --query id -o tsv | az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee @- \
  --scope /subscriptions/"$subscriptionId"/resourceGroups/"$RESOURCE_GROUP"/providers/Microsoft.Storage/storageAccounts/"$STORAGE_ACCOUNT_NAME"

# Get ACSA extension identity
echo "Getting the identity of the ACSA extension..."

EXTENSION_TYPE=${1:-"microsoft.arc.containerstorage"}

acsaExtensionIdentity=$(az k8s-extension list --cluster-name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --cluster-type connectedClusters | jq --arg extType "$EXTENSION_TYPE" 'map(select(.extensionType | ascii_downcase == $extType)) | .[] | .identity.principalId' -r)

# Add Extension Identity permissions to Storage Account
echo "Assigning the Storage Blob Data Owner role to the ACSA extension principal..."

az role assignment create \
  --assignee "$acsaExtensionIdentity" \
  --role "Storage Blob Data Owner" \
  --scope /subscriptions/"$subscriptionId"/resourceGroups/"$RESOURCE_GROUP"/providers/Microsoft.Storage/storageAccounts/"$STORAGE_ACCOUNT_NAME"

# Create a container in the storage account to store total counter metric
totalCouterContainerName=$METRIC2_TOPIC_PATH_NAME
echo "Creating container $totalCouterContainerName in storage account $STORAGE_ACCOUNT_NAME"
az storage container create \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --name "$totalCouterContainerName" \
  --auth-mode login

# Create a container in the storage account to store mashine status metric
machineStatusContainerName=$METRIC1_TOPIC_PATH_NAME
echo "Creating container $machineStatusContainerName in storage account $STORAGE_ACCOUNT_NAME"
az storage container create \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --name "$machineStatusContainerName" \
  --auth-mode login

edgeVolumeAioName=$ACSA_CLOUD_BACKED_AIO_PVC_NAME
# Wait until Edge Volume is deployed
wait_for_edge_volume "$edgeVolumeAioName"

# Update the edge volume with the new subvolumes to connect to the storage account
totalCouterPath=$METRIC2_TOPIC_PATH_NAME
echo "Adding subvolume $totalCouterPath to edge volume $edgeVolumeAioName to sync with storage account $STORAGE_ACCOUNT_NAME"

export SUBVOLUME_NAME=$totalCouterPath
export EDGE_VOLUME_NAME=$edgeVolumeAioName
export PATH_VALUE=$totalCouterPath # Using PATH_VALUE instead of PATH to avoid conflicts with system PATH
export STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME
export CONTAINER_NAME=$totalCouterContainerName

apply_template_with_envsubst "../yaml/acsa/edgeSubvolume.yaml" | kubectl apply -f -

# Update the edge volume with the new subvolumes to connect to the storage account
machineStatusPath=$METRIC1_TOPIC_PATH_NAME
echo "Adding subvolume $machineStatusPath to edge volume $edgeVolumeAioName to sync with storage account $STORAGE_ACCOUNT_NAME"

export SUBVOLUME_NAME=$machineStatusPath
export EDGE_VOLUME_NAME=$edgeVolumeAioName
export PATH_VALUE=$machineStatusPath # Using PATH_VALUE instead of PATH to avoid conflicts with system PATH
export STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME
export CONTAINER_NAME=$machineStatusContainerName

apply_template_with_envsubst "../yaml/acsa/edgeSubvolume.yaml" | kubectl apply -f -

kubectl get edgevolume "$edgeVolumeAioName" -o json

echo "Successfully added subvolumes to $edgeVolumeAioName edge volume to sync with storage account $STORAGE_ACCOUNT_NAME"
