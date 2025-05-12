metadata name = 'Azure IoT Operations Dataflow Event Hub Module'
metadata description = 'Provisions the ARM based data flow endpoint and data flow for Event Hub, requires Asset.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The values for the existing Event Hub namespace and Event Hub.')
param eventHub types.EventHub

@description('The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.')
param assetName string

@description('The tenant ID of the User-Assigned Managed Identity for Azure IoT Operations.')
param aioUamiTenantId string

@description('The client ID of the User-Assigned Managed Identity for Azure IoT Operations.')
param aioUamiClientId string

@description('The name of the Azure IoT Operations Instance.')
param aioInstanceName string

@description('The name of the Azure IoT Operations Dataflow Profile.')
param aioDataflowProfileName string = 'default'

@description('The resource ID of the Custom Location.')
param customLocationId string

/*
  Resources
*/

resource aioInstanceResource 'Microsoft.IoTOperations/instances@2025-04-01' existing = {
  name: aioInstanceName
}

resource aioDataflowProfileResource 'Microsoft.IoTOperations/instances/dataflowProfiles@2025-04-01' existing = {
  parent: aioInstanceResource
  name: aioDataflowProfileName
}

resource dataflowEndpointToEventHub 'Microsoft.IoTOperations/instances/dataflowEndpoints@2025-04-01' = {
  name: 'dfe-eh-${common.resourcePrefix}-${common.environment}-sample-${common.instance}'
  parent: aioInstanceResource
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    endpointType: 'Kafka'
    kafkaSettings: {
      host: '${eventHub.namespaceName}.servicebus.windows.net:9093'
      batching: {
        latencyMs: 0
        maxMessages: 100
      }
      tls: {
        mode: 'Enabled'
      }
      authentication: {
        method: 'UserAssignedManagedIdentity'
        userAssignedManagedIdentitySettings: {
          tenantId: aioUamiTenantId
          clientId: aioUamiClientId
        }
      }
    }
  }
}

resource dataflowToEventHub 'Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-04-01' = {
  parent: aioDataflowProfileResource
  name: 'df-eh-${common.resourcePrefix}-${common.environment}-passthrough-${common.instance}'
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    mode: 'Enabled'
    operations: [
      {
        operationType: 'Source'
        sourceSettings: {
          endpointRef: 'default'
          assetRef: assetName
          serializationFormat: 'Json'
          dataSources: ['azure-iot-operations/data/${assetName}']
        }
      }
      {
        operationType: 'BuiltInTransformation'
        builtInTransformationSettings: {
          serializationFormat: 'Json'
          map: [
            {
              type: 'PassThrough'
              inputs: ['*']
              output: '*'
            }
          ]
        }
      }
      {
        operationType: 'Destination'
        destinationSettings: {
          endpointRef: dataflowEndpointToEventHub.name
          dataDestination: eventHub.eventHubName
        }
      }
    ]
  }
}
