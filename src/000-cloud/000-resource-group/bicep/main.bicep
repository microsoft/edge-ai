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

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: common.location
  tags: union(defaultTags, tags)
}

/*
  Outputs
*/

@description('The ID of the resource group.')
output resourceGroupId string = resourceGroup.id

@description('The name of the resource group.')
output resourceGroupName string = resourceGroupName

@description('The location of the resource group.')
output location string = resourceGroup.location
