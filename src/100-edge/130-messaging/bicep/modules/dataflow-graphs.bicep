metadata name = 'Azure IoT Operations Dataflow Graphs Module'
metadata description = 'Provisions dataflow graphs for Azure IoT Operations with WASM operator and standard dataflow node support.'

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

@description('The list of dataflow graphs to create.')
param dataflowGraphs types.DataflowGraph[]

/*
  Resources
*/

resource aioInstanceResource 'Microsoft.IoTOperations/instances@2026-03-01' existing = {
  name: aioInstanceName
}

resource aioDataflowProfileResource 'Microsoft.IoTOperations/instances/dataflowProfiles@2026-03-01' existing = {
  parent: aioInstanceResource
  name: aioDataflowProfileName
}

resource dataflowGraph 'Microsoft.IoTOperations/instances/dataflowProfiles/dataflowGraphs@2026-03-01' = [
  for graph in dataflowGraphs: {
    parent: aioDataflowProfileResource
    name: graph.name
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
    properties: {
      mode: graph.?mode ?? types.dataflowGraphDefaults.mode
      requestDiskPersistence: graph.?requestDiskPersistence ?? types.dataflowGraphDefaults.requestDiskPersistence
      nodes: [
        for node in graph.nodes: {
          #disable-next-line BCP225
          nodeType: node.nodeType
          name: node.name
          ...(node.?sourceSettings != null ? { sourceSettings: node.?sourceSettings } : {})
          ...(node.?graphSettings != null ? { graphSettings: node.?graphSettings } : {})
          ...(node.?destinationSettings != null ? { destinationSettings: node.?destinationSettings } : {})
        }
      ]
      nodeConnections: graph.nodeConnections
    }
  }
]

/*
  Outputs
*/

@description('The names of the created dataflow graphs.')
output dataflowGraphNames string[] = [for (graph, i) in dataflowGraphs: dataflowGraph[i].name]
