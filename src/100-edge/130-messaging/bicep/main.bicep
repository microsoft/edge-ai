metadata name = 'Azure IoT Operations Messaging'
metadata description = 'Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Required Parameters
*/

@description('The name of the User-Assigned Managed Identity for Azure IoT Operations.')
param aioIdentityName string

@description('The name of the Azure IoT Operations Custom Location.')
param aioCustomLocationName string

@description('The name of the Azure IoT Operations Instance.')
param aioInstanceName string

@description('The name of the Azure IoT Operations Dataflow Profile.')
param aioDataflowProfileName string = 'default'

/*
  Optional Parameters
*/

@description('The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.')
param assetName string = 'oven'

@description('Values for the existing Event Hub namespace and Event Hub. If not provided, Event Hub dataflow will not be created.')
param eventHub types.EventHub?

@description('Values for the existing Event Grid. If not provided, Event Grid dataflow will not be created.')
param eventGrid types.EventGrid?

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Resources
*/

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

/*
  Resource References
*/

resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: aioIdentityName
}

resource aioCustomLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' existing = {
  name: aioCustomLocationName
}

/*
  Modules
*/

module eventHubDataflow 'modules/event-hub.bicep' = if (eventHub != null) {
  name: '${deployment().name}-eh'
  params: {
    common: common
    eventHub: eventHub!
    assetName: assetName
    aioUamiTenantId: aioIdentity.properties.tenantId
    aioUamiClientId: aioIdentity.properties.clientId
    aioInstanceName: aioInstanceName
    aioDataflowProfileName: aioDataflowProfileName
    customLocationId: aioCustomLocation.id
  }
}

module eventGridDataflow 'modules/event-grid.bicep' = if (eventGrid != null) {
  name: '${deployment().name}-eg'
  params: {
    common: common
    eventGrid: eventGrid!
    assetName: assetName
    aioUamiTenantId: aioIdentity.properties.tenantId
    aioUamiClientId: aioIdentity.properties.clientId
    aioInstanceName: aioInstanceName
    aioDataflowProfileName: aioDataflowProfileName
    customLocationId: aioCustomLocation.id
  }
}
