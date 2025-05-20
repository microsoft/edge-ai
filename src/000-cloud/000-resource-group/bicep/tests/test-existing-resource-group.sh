#!/bin/bash
# filepath: ./src/000-cloud/000-resource-group/bicep/tests/test-existing-resource-group.sh
#
# This script tests the "existing resource group" functionality in Bicep by:
# 1. Creating a resource group in Azure
# 2. Running a Bicep deployment that references the existing resource group
# 3. Verifying the outputs reference the existing resource group
# 4. Cleaning up the resource group

set -e

# Configuration
RESOURCE_GROUP_NAME="existing-rg-test-$(date +%s)"
LOCATION="eastus"
TEST_DIR="$(dirname "$(readlink -f "$0")")/existing-rg-test"

# Create test directory
echo "Creating test directory at $TEST_DIR"
mkdir -p "$TEST_DIR"

# Create main.bicep file
cat >"$TEST_DIR/main.bicep" <<EOF
targetScope = 'subscription'

param location string = '$LOCATION'
param resourceGroupName string = '$RESOURCE_GROUP_NAME'
param environmentName string = 'dev'
param instanceName string = '001'
param useExistingResourceGroup bool = true

module resourceGroup '../../main.bicep' = {
  name: 'resourceGroupModule'
  params: {
    location: location
    resourceGroupName: resourceGroupName
    environmentName: environmentName
    instanceName: instanceName
    useExistingResourceGroup: useExistingResourceGroup
  }
}

output resourceGroupId string = resourceGroup.outputs.resourceGroupId
output resourceGroupName string = resourceGroup.outputs.resourceGroupName
output resourceGroupLocation string = resourceGroup.outputs.location
EOF

# Step 1: Create resource group in Azure
echo "Creating resource group $RESOURCE_GROUP_NAME in $LOCATION"
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --tags "TestPurpose=ExistingRGTest"

# Step 2: Deploy Bicep template
echo "Deploying Bicep template..."
DEPLOYMENT_NAME="existing-rg-test-$(date +%s)"
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location "$LOCATION" \
  --template-file "$TEST_DIR/main.bicep"

# Step 3: Verify outputs
echo "Verifying outputs..."
RG_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.resourceGroupName.value' -o tsv)
RG_LOCATION=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.resourceGroupLocation.value' -o tsv)

if [ "$RG_NAME" == "$RESOURCE_GROUP_NAME" ]; then
  echo "✓ Resource group name output matches: $RG_NAME"
else
  echo "✗ Resource group name output mismatch: $RG_NAME != $RESOURCE_GROUP_NAME"
  exit 1
fi

if [ "$RG_LOCATION" == "$LOCATION" ]; then
  echo "✓ Resource group location output matches: $RG_LOCATION"
else
  echo "✗ Resource group location output mismatch: $RG_LOCATION != $LOCATION"
  exit 1
fi

# Step 4: Clean up
echo "Cleaning up..."
az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait

echo "Removing test directory..."
rm -rf "$TEST_DIR"

echo "✓ Test completed successfully!"
