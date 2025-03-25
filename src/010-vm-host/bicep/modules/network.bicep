import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

/*
* Parameters
*/

@description('The address prefix for the virtual network.')
param addressPrefix string = '10.0.0.0/16'

@description('The subnet address prefix.')
param subnetAddressPrefix string = '10.0.1.0/24'

/*
* Local variables
*/

var labelPrefix = '${common.resourcePrefix}-aio-${common.environment}-${common.instance}'

/*
* Resources
*/

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${labelPrefix}'
  location: common.location
  properties: {}
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${labelPrefix}'
  location: common.location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      {
        name: 'subnet-${labelPrefix}'
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

/*
* Outputs
*/

output networkSecurityGroupId string = networkSecurityGroup.id
output networkSecurityGroupName string = networkSecurityGroup.name
output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'subnet-${labelPrefix}')
output virtualNetworkId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
