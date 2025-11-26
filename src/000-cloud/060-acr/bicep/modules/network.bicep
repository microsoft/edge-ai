metadata name = 'ACR Network Resources'
metadata description = 'Creates subnets for ACR private endpoints in an existing Virtual Network.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Network Parameters
*/

@description('Virtual network name for subnet creation.')
param virtualNetworkName string

@description('Network security group name to apply to the subnets.')
param networkSecurityGroupName string

@description('Whether to create a private endpoint subnet for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool

/*
  Local Variables
*/

var labelPrefixAcr = '${common.resourcePrefix}-acr-${common.environment}-${common.instance}'

/*
  Resources
*/

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' existing = {
  name: networkSecurityGroupName
}

resource snetAcr 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = if (shouldCreateAcrPrivateEndpoint) {
  parent: vnet
  name: 'subnet-${labelPrefixAcr}'
  properties: {
    addressPrefix: '10.0.3.0/24'
    networkSecurityGroup: {
      id: nsg.id
    }
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

/*
  Outputs
*/

@description('The subnet ID for the ACR private endpoint, if created.')
output snetAcrId string = shouldCreateAcrPrivateEndpoint ? snetAcr.id : ''
