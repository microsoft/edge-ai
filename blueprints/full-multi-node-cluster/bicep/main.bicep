metadata name = 'Full Multi-node Cluster Blueprint'
metadata description = 'Deploys a complete end-to-end environment for Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster.'

import * as core from './types.core.bicep'

/*
  Common Parameters
*/
@description('The common component configuration.')
param common core.Common

/*
  Virtual Machine Parameters
*/
@secure()
@description('Password used for the host VM.')
param adminPassword string

@description('Flag to determine if the custom locations OID should be retrieved.')
param shouldGetCustomLocationsOid bool = true

@description('''
The object id of the Custom Locations Entra ID application for your tenant.
If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.
Can be retrieved using:

  ```sh
  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
  ```
''')
param customLocationsOid string?

@description('The number of host VMs to create for the cluster. (The first host VM will be the cluster server)')
@minValue(2)
param hostMachineCount int = 3

/*
  Modules
*/
// Deploy onboard requirements (identity for Arc onboarding)
module onboardReqs '../../../src/005-onboard-reqs/bicep/main.bicep' = {
  name: 'onboardReqs'
  params: {
    common: common
  }
}

// Deploy VM hosts
module vmHost '../../../src/010-vm-host/bicep/main.bicep' = {
  name: 'vmHost'
  params: {
    common: common
    arcOnboardingUserAssignedIdentityId: onboardReqs.outputs.arcOnboardingUserManagedIdentityId
    adminPassword: adminPassword
    vmCount: hostMachineCount
  }
}

// Deploy CNCF cluster with K3s
module cncfCluster '../../../src/020-cncf-cluster/bicep/main.bicep' = {
  name: 'cncfCluster'
  params: {
    common: common
    clusterServerVirtualMachineName: vmHost.outputs.vmNames[0]
    clusterNodeVirtualMachineNames: skip(vmHost.outputs.vmNames, 1)
    shouldGenerateServerToken: true
    clusterServerIp: vmHost.outputs.privateIpAddresses[0]
    shouldGetCustomLocationsOid: shouldGetCustomLocationsOid
    customLocationsOid: customLocationsOid
  }
}

// Deploy IoT Ops cloud requirements
module iotOpsCloudReqs '../../../src/030-iot-ops-cloud-reqs/bicep/main.bicep' = {
  name: 'iotOpsCloudReqs'
  params: {
    common: common
  }
}

// Deploy Azure IoT Operations
module iotOps '../../../src/040-iot-ops/bicep/main.bicep' = {
  name: 'iotOps'
  params: {
    common: common
    arcConnectedClusterName: cncfCluster.outputs.connectedClusterName
    schemaRegistryId: iotOpsCloudReqs.outputs.adrSchemaRegistryId
    aioUserAssignedIdentityId: iotOpsCloudReqs.outputs.aioUamiId
    aioUserAssignedIdentityName: iotOpsCloudReqs.outputs.aioUamiName
    sseKeyVaultName: iotOpsCloudReqs.outputs.sseKeyVaultName
    sseUserAssignedIdentityName: iotOpsCloudReqs.outputs.sseUamiName
  }
}

/*
  Outputs
*/
@description('The name of the Arc Connected Cluster.')
output arcConnectedClusterName string = cncfCluster.outputs.connectedClusterName

@description('The VM username for SSH access.')
output vmUsername string = vmHost.outputs.adminUsername

@description('The names of all virtual machines deployed.')
output vmNames array = vmHost.outputs.vmNames
