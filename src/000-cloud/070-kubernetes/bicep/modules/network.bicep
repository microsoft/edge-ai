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

@description('Network security group ID to apply to the subnets.')
param networkSecurityGroupId string

/*
  Local Variables
*/

var labelPrefixAks = '${common.resourcePrefix}-aks-${common.environment}-${common.instance}'
var labelPrefixAksPod = '${common.resourcePrefix}-aks-pod-${common.environment}-${common.instance}'

/*
  Resources
*/

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}

resource snetAks 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'subnet-${labelPrefixAks}'
  properties: {
    addressPrefix: '10.0.3.0/24'
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
  }
}

resource snetAksPod 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'subnet-${labelPrefixAksPod}'
  properties: {
    addressPrefix: '10.0.4.0/24'
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
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
