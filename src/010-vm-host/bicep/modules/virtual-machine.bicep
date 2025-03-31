import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

@description('The common component configuration.')
param common core.Common

@description('The storage profile for the VM.')
param storageProfile types.StorageProfile = types.storageProfileDefaults

/*
* Parameters
*/

// Note this wil be replaced with SSH public key usage in future, simplifying until we have automation scripts for Bicep deployment
@description('The admin password for the VM.')
@secure()
param adminPassword string

@description('The user-assigned identity for Arc onboarding.')
param arcOnboardingUserAssignedIdentityId string?

@description('The subnet ID to connect the VM to.')
param subnetId string

@description('The VM index for naming purposes.')
param vmIndex int = 0

@description('Size of the VM')
param vmSkuSize string = 'Standard_D8s_v3'

@description('Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)')
param vmUsername string?

/*
* Local variables
*/

var labelPrefix = '${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
var adminVmUsername = vmUsername ?? common.resourcePrefix

/*
* Resources
*/

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${labelPrefix}-${vmIndex}'
  location: common.location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'dns-${labelPrefix}-${vmIndex}'
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${labelPrefix}-${vmIndex}'
  location: common.location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-${labelPrefix}-${vmIndex}'
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
  name: 'vm-${labelPrefix}-${vmIndex}'
  location: common.location
  properties: {
    hardwareProfile: {
      vmSize: vmSkuSize
    }
    osProfile: {
      computerName: 'vm-${labelPrefix}-${vmIndex}'
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

  identity: empty(arcOnboardingUserAssignedIdentityId)
  ? {
      type: 'None'
    }
  : {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${arcOnboardingUserAssignedIdentityId}': {}
    }
  }
}

/*
* Outputs
*/

output adminUsername string = adminVmUsername
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
output publicFqdn string = publicIp.properties.dnsSettings.fqdn
output publicIpAddress string = publicIp.properties.ipAddress
output vmId string = linuxVm.id
output vmName string = linuxVm.name
