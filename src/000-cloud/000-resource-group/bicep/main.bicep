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

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

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

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  location: common.location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

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
