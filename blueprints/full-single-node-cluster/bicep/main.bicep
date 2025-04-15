metadata name = 'Full Single Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end environment for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Virtual Machine Parameters
*/

@secure()
@description('Password used for the host VM.')
param adminPassword string

/*
  CNCF Arc cluster parameters
*/

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string

/*
  IoT Operations Parameters
*/

@description('Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)')
param shouldCreateAnonymousBrokerListener bool = false

/*
  Modules
*/

module cloudResourceGroup '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: '${deployment().name}-cloudResourceGroup'
  params: {
    common: common
  }
}

module cloudSecurityIdentity '../../../src/000-cloud/010-security-identity/bicep/main.bicep' = {
  name: '${deployment().name}-cloudSecurityIdentity'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
  }
}

module cloudData '../../../src/000-cloud/030-data/bicep/main.bicep' = {
  name: '${deployment().name}-cloudData'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
  }
}

module cloudVmHost '../../../src/000-cloud/050-vm-host/bicep/main.bicep' = {
  name: '${deployment().name}-cloudVmHost'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
  }
}

module edgeCncfCluster '../../../src/100-edge/100-cncf-cluster/bicep/main.bicep' = {
  name: '${deployment().name}-edgeCncfCluster'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    clusterServerVirtualMachineName: cloudVmHost.outputs.vmNames[0]
    clusterNodeVirtualMachineNames: skip(cloudVmHost.outputs.vmNames, 1)
    shouldGenerateServerToken: true
    clusterServerIp: cloudVmHost.outputs.privateIpAddresses[0]
    customLocationsOid: customLocationsOid
    arcOnboardingIdentityName: cloudSecurityIdentity.outputs.arcOnboardingIdentityName!
    keyVaultName: cloudSecurityIdentity.outputs.keyVaultName!
  }
}

module edgeIotOps '../../../src/100-edge/110-iot-ops/bicep/main.bicep' = {
  name: '${deployment().name}-edgeIotOps'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    arcConnectedClusterName: edgeCncfCluster.outputs.connectedClusterName
    schemaRegistryName: cloudData.outputs.schemaRegistryName
    aioIdentityName: cloudSecurityIdentity.outputs.aioIdentityName
    sseKeyVaultName: cloudSecurityIdentity.outputs.keyVaultName!
    sseIdentityName: cloudSecurityIdentity.outputs.sseIdentityName
    shouldCreateAnonymousBrokerListener: shouldCreateAnonymousBrokerListener
  }
}

/*
  Outputs
*/
@description('The name of the Arc Connected Cluster.')
output arcConnectedClusterName string = edgeCncfCluster.outputs.connectedClusterName

@description('The VM username for SSH access.')
output vmUsername string = cloudVmHost.outputs.adminUsername

@description('The names of all virtual machines deployed.')
output vmNames array = cloudVmHost.outputs.vmNames
