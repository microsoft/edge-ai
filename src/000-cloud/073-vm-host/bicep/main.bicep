metadata name = 'VM Host Component'
metadata description = 'Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Virtual Machine Parameters
*/

@description('The admin password for the VM.')
@secure()
param adminPassword string

@description('The user-assigned identity for Arc onboarding.')
param arcOnboardingIdentityName string?

@description('The storage profile for the VM.')
param storageProfile types.StorageProfile = types.storageProfileDefaults

@description('Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param vmUsername string?

@description('The number of host VMs to create if a multi-node cluster is needed.')
param vmCount int = 1

@description('Size of the VM.')
param vmSkuSize string = 'Standard_D8s_v3'

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
  Network Parameters
*/

@description('The subnet ID to connect the VMs to.')
param subnetId string

/*
  Modules
*/

module virtualMachine 'modules/virtual-machine.bicep' = [
  for i in range(0, vmCount): {
    name: '${common.resourcePrefix}-virtualMachine-${i}'
    params: {
      common: common
      adminPassword: adminPassword
      arcOnboardingIdentityName: arcOnboardingIdentityName
      storageProfile: storageProfile
      subnetId: subnetId
      vmSkuSize: vmSkuSize
      vmUsername: vmUsername
      vmIndex: i
    }
  }
]

/*
  Outputs
*/

@description('The admin username for SSH access to the VMs.')
output adminUsername string = virtualMachine[0].outputs.adminUsername

@description('An array containing the private IP addresses of all deployed VMs.')
output privateIpAddresses array = [for i in range(0, vmCount): virtualMachine[i].outputs.privateIpAddress]

@description('An array containing the public FQDNs of all deployed VMs.')
output publicFqdns array = [for i in range(0, vmCount): virtualMachine[i].outputs.publicFqdn]

@description('An array containing the public IP addresses of all deployed VMs.')
output publicIpAddresses array = [for i in range(0, vmCount): virtualMachine[i].outputs.publicIpAddress]

@description('An array containing the IDs of all deployed VMs.')
output vmIds array = [for i in range(0, vmCount): virtualMachine[i].outputs.vmId]

@description('An array containing the names of all deployed VMs.')
output vmNames array = [for i in range(0, vmCount): virtualMachine[i].outputs.vmName]
