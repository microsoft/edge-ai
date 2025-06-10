metadata name = 'Virtual Network Component'
metadata description = 'Creates virtual network, subnet, and network security group resources for Azure deployments.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Virtual Network Parameters
*/

@description('Networking configuration settings.')
param networkingConfig types.NetworkingConfig = types.networkingConfigDefaults

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Local Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-aio-${common.environment}-${common.instance}'

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

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${resourceNamePrefix}'
  location: common.location
  properties: {}
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${resourceNamePrefix}'
  location: common.location
  properties: {
    addressSpace: {
      addressPrefixes: [networkingConfig.addressPrefix]
    }
    subnets: [
      {
        name: 'subnet-${resourceNamePrefix}'
        properties: {
          addressPrefix: networkingConfig.subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

/*
  Outputs
*/

@description('The ID of the created network security group.')
output networkSecurityGroupId string = networkSecurityGroup.id

@description('The name of the created network security group.')
output networkSecurityGroupName string = networkSecurityGroup.name

@description('The ID of the created subnet.')
output subnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  virtualNetwork.name,
  'subnet-${resourceNamePrefix}'
)

@description('The ID of the created virtual network.')
output virtualNetworkId string = virtualNetwork.id

@description('The name of the created virtual network.')
output virtualNetworkName string = virtualNetwork.name
