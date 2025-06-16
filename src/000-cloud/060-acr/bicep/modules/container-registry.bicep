metadata name = 'Azure Container Registry'
metadata description = 'Deploys an Azure Container Registry with optional private endpoint.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Container Registry Parameters
*/

@description('The SKU for the Azure Container Registry.')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string

@description('Whether to create a private endpoint for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool

@description('Virtual network name for subnet creation.')
param virtualNetworkName string

@description('Subnet ID for ACR private endpoint.')
param snetAcrId string

/*
  Resources
*/

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acr${common.resourcePrefix}${common.environment}${common.instance}'
  location: common.location
  tags: {
    environment: common.environment
    component: 'container-registry'
  }
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = if (shouldCreateAcrPrivateEndpoint) {
  name: 'pe-${common.resourcePrefix}-acr-${common.environment}-${common.instance}'
  location: common.location
  tags: {
    environment: common.environment
    component: 'container-registry'
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-connection-acr'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnet: {
      id: snetAcrId
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldCreateAcrPrivateEndpoint) {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldCreateAcrPrivateEndpoint) {
  name: 'vnet-pzl-acr-${common.resourcePrefix}-${common.environment}-${common.instance ?? ''}'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource aRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (shouldCreateAcrPrivateEndpoint) {
  name: acr.name
  parent: privateDnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: shouldCreateAcrPrivateEndpoint ? privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0] : ''
      }
    ]
  }
}

/*
  Outputs
*/

@description('The Azure Container Registry ID.')
output acrId string = acr.id

@description('The Azure Container Registry name.')
output acrName string = acr.name
