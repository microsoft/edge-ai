metadata name = 'Virtual Machine Module'
metadata description = 'Creates a Linux virtual machine with networking components for Azure IoT Operations deployments.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

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

@description('Size of the VM.')
param vmSkuSize string = 'Standard_D8s_v3'

@description('Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param vmUsername string?

/*
  Network Parameters
*/

@description('The subnet ID to connect the VM to.')
param subnetId string

@description('The VM index for naming purposes.')
param vmIndex int = 0

/*
  Local Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
var adminVmUsername = vmUsername ?? common.resourcePrefix

/*
  Resources
*/

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = if (!empty(arcOnboardingIdentityName)) {
  name: arcOnboardingIdentityName!
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${resourceNamePrefix}-${vmIndex}'
  location: common.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'dns-${resourceNamePrefix}-${vmIndex}'
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${resourceNamePrefix}-${vmIndex}'
  location: common.location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-${resourceNamePrefix}-${vmIndex}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource linuxVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-${resourceNamePrefix}-${vmIndex}'
  location: common.location
  properties: {
    hardwareProfile: {
      vmSize: vmSkuSize
    }
    osProfile: {
      computerName: 'vm-${resourceNamePrefix}-${vmIndex}'
      adminUsername: adminVmUsername
      adminPassword: adminPassword

      linuxConfiguration: {
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'AutomaticByPlatform'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    storageProfile: storageProfile
  }

  identity: empty(arcOnboardingIdentityName)
    ? {
        type: 'None'
      }
    : {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${arcOnboardingIdentity.id}': {}
        }
      }
}

/*
  Outputs
*/

@description('The admin username for SSH access to the VM.')
output adminUsername string = adminVmUsername

@description('The private IP address of the VM.')
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

@description('The public FQDN of the VM.')
output publicFqdn string = publicIp.properties.dnsSettings.fqdn

@description('The public IP address of the VM.')
output publicIpAddress string = publicIp.properties.ipAddress

@description('The ID of the VM.')
output vmId string = linuxVm.id

@description('The name of the VM.')
output vmName string = linuxVm.name
