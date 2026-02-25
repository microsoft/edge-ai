metadata name = 'Azure IoT Operations Dataflow Module'
metadata description = 'Provisions dataflows for Azure IoT Operations with source, built-in transformation, and destination operations.'

import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The name of the Azure IoT Operations Instance.')
param aioInstanceName string

@description('The name of the Azure IoT Operations Dataflow Profile.')
param aioDataflowProfileName string

@description('The resource ID of the Custom Location.')
param customLocationId string

@description('The list of dataflows to create.')
param dataflows types.Dataflow[]

/*
  Resources
*/

resource aioInstanceResource 'Microsoft.IoTOperations/instances@2025-10-01' existing = {
  name: aioInstanceName
}

resource aioDataflowProfileResource 'Microsoft.IoTOperations/instances/dataflowProfiles@2025-10-01' existing = {
  parent: aioInstanceResource
  name: aioDataflowProfileName
}

resource dataflow 'Microsoft.IoTOperations/instances/dataflowProfiles/dataflows@2025-10-01' = [
  for df in dataflows: {
    parent: aioDataflowProfileResource
    name: df.name
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
    properties: {
      mode: df.mode ?? types.dataflowDefaults.mode
      requestDiskPersistence: df.requestDiskPersistence ?? types.dataflowDefaults.requestDiskPersistence
      operations: [
        for op in df.operations: {
          operationType: op.operationType
          ...(op.name != null ? { name: op.name } : {})
          ...(op.sourceSettings != null ? { sourceSettings: op.sourceSettings } : {})
          ...(op.builtInTransformationSettings != null
            ? { builtInTransformationSettings: op.builtInTransformationSettings }
            : {})
          ...(op.destinationSettings != null ? { destinationSettings: op.destinationSettings } : {})
        }
      ]
    }
  }
]

/*
  Outputs
*/

@description('The names of the created dataflows.')
output dataflowNames string[] = [for (df, i) in dataflows: dataflow[i].name]
