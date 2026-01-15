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

@description('Address prefix for the ACR subnet when creating a private endpoint.')
param subnetAddressPrefix string

@description('Whether default outbound internet access is enabled for the ACR subnet.')
param defaultOutboundAccessEnabled bool

@description('Whether to associate the ACR subnet with a NAT gateway for managed outbound egress.')
param shouldEnableNatGateway bool

@description('NAT Gateway ID to associate with the ACR subnet.')
param natGatewayId string?

/*
  Local Variables
*/

var labelPrefixAcr = '${common.resourcePrefix}-acr-${common.environment}-${common.instance}'

/*
  Resources
*/

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' existing = {
  name: virtualNetworkName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-01-01' existing = {
  name: networkSecurityGroupName
}

resource snetAcr 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' = if (shouldCreateAcrPrivateEndpoint) {
  parent: vnet
  name: 'subnet-${labelPrefixAcr}'
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
    privateEndpointNetworkPolicies: 'Disabled'
    defaultOutboundAccess: defaultOutboundAccessEnabled
    natGateway: shouldEnableNatGateway && !empty(natGatewayId)
      ? {
          id: natGatewayId!
        }
      : null
  }
}

/*
  Outputs
*/

@description('The subnet ID for the ACR private endpoint, if created.')
output snetAcrId string = shouldCreateAcrPrivateEndpoint ? snetAcr.id : ''

@description('The subnet name for the ACR private endpoint, if created.')
output snetAcrName string = shouldCreateAcrPrivateEndpoint ? snetAcr.name : ''

@description('Whether the subnet has NAT Gateway associated.')
output isNatGatewayEnabled bool = shouldEnableNatGateway && !empty(natGatewayId)
