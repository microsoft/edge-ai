metadata name = 'AKS Network Resources'
metadata description = 'Creates subnets for AKS private endpoints in an existing Virtual Network.'

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

@description('Address prefix for the AKS system node subnet.')
param subnetAddressPrefixAks string

@description('Address prefix for the AKS pod subnet.')
param subnetAddressPrefixAksPod string

@description('Whether to enable default outbound internet access for AKS subnets.')
param defaultOutboundAccessEnabled bool

@description('Whether to associate AKS subnets with a NAT gateway for managed outbound egress.')
param shouldEnableNatGateway bool

@description('NAT gateway ID for associating AKS subnets.')
param natGatewayId string?

/*
  Local Variables
*/

var labelPrefixAks = '${common.resourcePrefix}-aks-${common.environment}-${common.instance}'
var labelPrefixAksPod = '${common.resourcePrefix}-aks-pod-${common.environment}-${common.instance}'

/*
  Resources
*/

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' existing = {
  name: virtualNetworkName
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-01-01' existing = {
  name: networkSecurityGroupName
}

resource snetAks 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' = {
  parent: vnet
  name: 'subnet-${labelPrefixAks}'
  properties: {
    addressPrefix: subnetAddressPrefixAks
    networkSecurityGroup: {
      id: nsg.id
    }
    defaultOutboundAccess: defaultOutboundAccessEnabled
    natGateway: shouldEnableNatGateway && !empty(natGatewayId)
      ? {
          id: natGatewayId!
        }
      : null
  }
}

resource snetAksPod 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' = {
  parent: vnet
  name: 'subnet-${labelPrefixAksPod}'
  properties: {
    addressPrefix: subnetAddressPrefixAksPod
    networkSecurityGroup: {
      id: nsg.id
    }
    defaultOutboundAccess: defaultOutboundAccessEnabled
    natGateway: shouldEnableNatGateway && !empty(natGatewayId)
      ? {
          id: natGatewayId!
        }
      : null
    // Delegation required for Azure CNI with dedicated pod subnet (podSubnetID)
    delegations: [
      {
        name: 'aks-delegation'
        properties: {
          serviceName: 'Microsoft.ContainerService/managedClusters'
        }
      }
    ]
  }
  dependsOn: [
    snetAks // Make sure subnets are created in sequence to avoid conflicts
  ]
}

/*
  Outputs
*/

@description('The subnet ID for the AKS cluster.')
output snetAksId string = snetAks.id

@description('The subnet name for the AKS cluster.')
output snetAksName string = last(split(snetAks.name, '/'))

@description('The subnet ID for the AKS pods.')
output snetAksPodId string = snetAksPod.id

@description('The subnet name for the AKS pods.')
output snetAksPodName string = last(split(snetAksPod.name, '/'))

@description('The address prefix for the AKS system node subnet.')
output snetAksAddressPrefix string = subnetAddressPrefixAks

@description('The address prefix for the AKS pod subnet.')
output snetAksPodAddressPrefix string = subnetAddressPrefixAksPod
