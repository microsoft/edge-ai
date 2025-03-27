import * as core from './types.core.bicep'
import * as types from './types.bicep'

@description('The common component configuration.')
param common core.Common

/*
* Virtual Machine Parameters
*/

// Note this wil be replaced with SSH public key usage in future, simplifying until we have automation scripts for Bicep deployment
@description('The admin password for the VM(s).')
@secure()
param adminPassword string

@description('The user-assigned identity for Arc onboarding.')
param arcOnboardingUserAssignedIdentityId string?

@description('The storage profile for the VM.')
param storageProfile types.StorageProfile = types.storageProfileDefaults

@description('Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param vmUsername string?

@description('The number of host VMs to create if a multi-node cluster is needed.')
param vmCount int = 1

@description('Size of the VM')
param vmSkuSize string = 'Standard_D8s_v3'

/*
* Modules
*/

module network 'modules/network.bicep' = {
  name: '${common.resourcePrefix}-network'
  params: {
    common: common
    addressPrefix: '10.0.0.0/16'
    subnetAddressPrefix: '10.0.1.0/24'
  }
}

module virtualMachine 'modules/virtual-machine.bicep' = [for i in range(0, vmCount): {
  name: '${common.resourcePrefix}-virtualMachine-${i}'
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingUserAssignedIdentityId: arcOnboardingUserAssignedIdentityId
    storageProfile: storageProfile
    subnetId: network.outputs.subnetId
    vmSkuSize: vmSkuSize
    vmUsername: vmUsername
    vmIndex: i
  }
}]

/*
* Outputs
*/

output adminUsername string = virtualMachine[0].outputs.adminUsername
output privateIpAddresses array = [for i in range(0, vmCount): virtualMachine[i].outputs.privateIpAddress]
output publicFqdns array = [for i in range(0, vmCount): virtualMachine[i].outputs.publicFqdn]
output publicIpAddresses array = [for i in range(0, vmCount): virtualMachine[i].outputs.publicIpAddress]
output vmIds array = [for i in range(0, vmCount): virtualMachine[i].outputs.vmId]
output vmNames array = [for i in range(0, vmCount): virtualMachine[i].outputs.vmName]
