metadata name = 'Cloud Resource Group'
metadata description = 'Creates the required resources needed for an edge IaC deployment.'

import * as core from './types.core.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Resource Group Parameters
*/

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Whether to use an existing resource group instead of creating a new one.')
param useExistingResourceGroup bool = false

@description('Additional tags to add to the resources.')
param tags object = {}

/*
  Local Variables
*/

var defaultTags = {
  Environment: common.environment
  Instance: common.instance
}

/*
  Resources
*/

// Create new resource group if useExistingResourceGroup is false
resource newResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = if (!useExistingResourceGroup) {
  name: resourceGroupName
  location: common.location
  tags: union(defaultTags, tags)
}

// Reference existing resource group if useExistingResourceGroup is true
resource existingResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = if (useExistingResourceGroup) {
  name: resourceGroupName
}

/*
  Outputs
*/

@description('The ID of the resource group.')
output resourceGroupId string = useExistingResourceGroup ? existingResourceGroup.id : newResourceGroup.id

@description('The name of the resource group.')
output resourceGroupName string = resourceGroupName

@description('The location of the resource group.')
output location string = useExistingResourceGroup ? existingResourceGroup.location : newResourceGroup.location
