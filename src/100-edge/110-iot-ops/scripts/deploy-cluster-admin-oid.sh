#!/usr/bin/env bash

set -e

# Refer to: https://learn.microsoft.com/azure/azure-arc/kubernetes/cluster-connect?tabs=azure-cli

# ARC_RESOURCE_GROUP_NAME=
# ARC_RESOURCE_NAME=

if [[ -n $SHOULD_USE_CURRENT_USER ]]; then
  DEPLOY_ADMIN_OID=$(az ad signed-in-user show --query id -o tsv)
  echo "DEPLOY_ADMIN_OID=$DEPLOY_ADMIN_OID"
  echo ""
fi

# From a place that has role assignment privs:

if [[ -n $SHOULD_ASSIGN_ROLES ]]; then
  CONNECTED_CLUSTER_ID=$(az resource show -g "$ARC_RESOURCE_GROUP_NAME" -n "$ARC_RESOURCE_NAME" --resource-type "microsoft.kubernetes/connectedclusters" --query id --output tsv)
  az role assignment create --role "Azure Arc Kubernetes Viewer" --assignee "$DEPLOY_ADMIN_OID" --scope "$CONNECTED_CLUSTER_ID"
  az role assignment create --role "Azure Arc Enabled Kubernetes Cluster User Role" --assignee "$DEPLOY_ADMIN_OID" --scope "$CONNECTED_CLUSTER_ID"
fi

echo "Adding $DEPLOY_ADMIN_OID as deployment admin"

kubectl create clusterrolebinding "$(echo "$DEPLOY_ADMIN_OID" | cut -c1-7)-deploy-binding" --clusterrole cluster-admin --user="$DEPLOY_ADMIN_OID" --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "az connectedk8s proxy -n $ARC_RESOURCE_NAME -g $ARC_RESOURCE_GROUP_NAME"
