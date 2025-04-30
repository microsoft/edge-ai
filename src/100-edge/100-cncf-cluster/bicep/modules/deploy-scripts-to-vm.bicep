metadata name = 'Deploy Script to VM Module'
metadata description = 'Deploys a script to a virtual machine using the CustomScript extension.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Cluster Parameters
*/

@description('The node virtual machines names.')
param clusterNodeVirtualMachineNames string[]

@description('The script for setting up the host machine for the cluster node.')
@secure()
param clusterNodeScript string

@description('The server virtual machines name.')
param clusterServerVirtualMachineName string

@description('The script for setting up the host machine for the cluster server.')
@secure()
param clusterServerScript string

/*
  Resources
*/

resource clusterServerVirtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: clusterServerVirtualMachineName

  resource linuxServerScriptSetup 'extensions' = {
    name: 'linux-cluster-server-setup'
    location: common.location
    properties: {
      publisher: 'Microsoft.Azure.Extensions'
      type: 'CustomScript'
      typeHandlerVersion: '2.1'
      autoUpgradeMinorVersion: false
      suppressFailures: false
      enableAutomaticUpgrade: false
      settings: {}
      protectedSettings: {
        script: base64(clusterServerScript)
      }
    }
  }
}

resource clusterNodeVirtualMachines 'Microsoft.Compute/virtualMachines@2024-11-01' existing = [
  for (clusterNodeVirtualMachineName, index) in clusterNodeVirtualMachineNames: {
    name: clusterNodeVirtualMachineName
  }
]

resource linuxNodeScriptSetup 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for (clusterNodeVirtualMachineName, index) in clusterNodeVirtualMachineNames: {
    name: 'linux-cluster-node-setup'
    location: common.location
    parent: clusterNodeVirtualMachines[index]
    dependsOn: [clusterServerVirtualMachine::linuxServerScriptSetup]

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
