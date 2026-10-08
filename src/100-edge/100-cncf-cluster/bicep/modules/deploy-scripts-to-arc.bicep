metadata name = 'Deploy Script to Arc Machine Module'
metadata description = 'Deploys a script to an Azure Arc-enabled machine using the CustomScript machine extension.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Cluster Parameters
*/

@description('The name of the Arc-enabled server machine.')
param clusterServerArcMachineName string

@description('The names of the Arc-enabled node machines.')
param clusterNodeArcMachineNames string[]

@description('The script for setting up the host machine for the cluster node.')
@secure()
param clusterNodeScript string

@description('The script for setting up the host machine for the cluster server.')
@secure()
param clusterServerScript string

/*
  Resources
*/

resource clusterServerArcMachine 'Microsoft.HybridCompute/machines@2025-06-01' existing = {
  name: clusterServerArcMachineName
}

resource clusterNodeArcMachines 'Microsoft.HybridCompute/machines@2025-06-01' existing = [
  for clusterNodeArcMachineName in clusterNodeArcMachineNames: {
    name: clusterNodeArcMachineName
  }
]

resource linuxServerScriptSetup 'Microsoft.HybridCompute/machines/extensions@2025-06-01' = {
  name: 'linux-cluster-server-setup'
  location: common.location
  parent: clusterServerArcMachine
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: false
    enableAutomaticUpgrade: false
    settings: {}
    protectedSettings: {
      script: base64(clusterServerScript)
    }
  }
}

resource linuxNodeScriptSetup 'Microsoft.HybridCompute/machines/extensions@2025-06-01' = [
  for (clusterNodeArcMachineName, index) in clusterNodeArcMachineNames: {
    name: 'linux-cluster-node-setup'
    location: common.location
    parent: clusterNodeArcMachines[index]
    dependsOn: [linuxServerScriptSetup]

    properties: {
      publisher: 'Microsoft.Azure.Extensions'
      type: 'CustomScript'
      typeHandlerVersion: '2.1'
      autoUpgradeMinorVersion: false
      settings: {}
      protectedSettings: {
        script: base64(clusterNodeScript)
      }
    }
  }
]
