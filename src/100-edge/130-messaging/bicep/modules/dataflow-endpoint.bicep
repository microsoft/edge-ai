metadata name = 'Azure IoT Operations Dataflow Endpoint Module'
metadata description = 'Provisions dataflow endpoints for Azure IoT Operations connecting dataflows to external services.'

import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The name of the Azure IoT Operations Instance.')
param aioInstanceName string

@description('The resource ID of the Custom Location.')
param customLocationId string

@description('The list of dataflow endpoints to create.')
param dataflowEndpoints types.DataflowEndpoint[]

/*
  Resources
*/

resource aioInstanceResource 'Microsoft.IoTOperations/instances@2025-10-01' existing = {
  name: aioInstanceName
}

resource dataflowEndpoint 'Microsoft.IoTOperations/instances/dataflowEndpoints@2025-10-01' = [
  for ep in dataflowEndpoints: {
    parent: aioInstanceResource
    name: ep.name
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
    properties: {
      endpointType: ep.endpointType
      ...(ep.hostType != null ? { hostType: ep.hostType } : {})
      ...(ep.dataExplorerSettings != null ? { dataExplorerSettings: ep.dataExplorerSettings } : {})
      ...(ep.dataLakeStorageSettings != null ? { dataLakeStorageSettings: ep.dataLakeStorageSettings } : {})
      ...(ep.fabricOneLakeSettings != null ? { fabricOneLakeSettings: ep.fabricOneLakeSettings } : {})
      ...(ep.kafkaSettings != null ? { kafkaSettings: ep.kafkaSettings } : {})
      ...(ep.localStorageSettings != null ? { localStorageSettings: ep.localStorageSettings } : {})
      ...(ep.mqttSettings != null ? { mqttSettings: ep.mqttSettings } : {})
      ...(ep.openTelemetrySettings != null ? { openTelemetrySettings: ep.openTelemetrySettings } : {})
    }
  }
]

/*
  Outputs
*/

@description('The names of the created dataflow endpoints.')
output dataflowEndpointNames string[] = [for (ep, i) in dataflowEndpoints: dataflowEndpoint[i].name]
