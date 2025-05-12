metadata name = 'Azure IoT Operations Messaging CI'
metadata description = 'CI deployment wrapper for Dataflow endpoints and dataflows for Azure IoT Operations messaging integration.'

import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Required Parameters
*/

// Arc connected cluster name is used indirectly through resource group references
@description('The resource group name where the Arc connected cluster is located.')
param arcConnectedClusterResourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioUserAssignedIdentityName string = 'id-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Optional Parameters - Messaging
*/

@description('The values for the existing Event Hub namespace and Event Hub. If not provided, Event Hub dataflow will not be created.')
param eventHubConfig object?

@description('The values for the existing Event Grid. If not provided, Event Grid dataflow will not be created.')
param eventGridConfig object?

/*
  Modules
*/

module ci '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
    aioIdentityName: aioUserAssignedIdentityName
    aioCustomLocationName: aioCustomLocations.name
    aioInstanceName: aioInstance.name
    aioDataflowProfileName: aioDataflowProfile.name
    eventHub: eventHubConfig
    eventGrid: eventGridConfig
  }
}

/*
  Resource References
*/

resource aioCustomLocations 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' existing = {
  scope: resourceGroup(arcConnectedClusterResourceGroupName)
  name: 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}-cl'
}

resource aioInstance 'Microsoft.IoTOperations/instances@2025-04-01' existing = {
  scope: resourceGroup(arcConnectedClusterResourceGroupName)
  name: 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}-ops-instance'
}

resource aioDataflowProfile 'Microsoft.IoTOperations/instances/dataflowProfiles@2025-04-01' existing = {
  parent: aioInstance
  name: 'default'
}
