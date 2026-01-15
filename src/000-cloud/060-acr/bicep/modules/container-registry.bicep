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
  Firewall and Access Parameters
*/

@description('Whether to enable the registry public endpoint alongside private connectivity.')
param publicNetworkAccessEnabled bool

@description('Whether trusted Azure services can bypass registry network rules when the public endpoint is restricted.')
param allowTrustedServices bool

@description('CIDR ranges permitted to reach the registry public endpoint.')
param allowedPublicIpRanges string[]

@description('Whether to enable dedicated data endpoints for the registry (Premium SKU only).')
param shouldEnableDataEndpoints bool

/*
  Local Variables
*/

var shouldEnableDataEndpoint = shouldEnableDataEndpoints && shouldCreateAcrPrivateEndpoint && toLower(sku) == 'premium'
var shouldConfigureNetworkRules = publicNetworkAccessEnabled && length(allowedPublicIpRanges) > 0
var ipRules = [
  for ipCidr in allowedPublicIpRanges: {
    action: 'Allow'
    value: ipCidr
  }
]

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
    publicNetworkAccess: publicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
    dataEndpointEnabled: shouldEnableDataEndpoint
    networkRuleBypassOptions: allowTrustedServices ? 'AzureServices' : 'None'
    networkRuleSet: shouldConfigureNetworkRules
      ? {
          defaultAction: 'Deny'
          ipRules: ipRules
        }
      : null
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (shouldCreateAcrPrivateEndpoint) {
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
  name: 'vnet-pzl-acr-${common.resourcePrefix}-${common.environment}-${common.instance}'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (shouldCreateAcrPrivateEndpoint) {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acr-dns-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
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

@description('The ACR private endpoint ID (if enabled).')
output privateEndpointId string? = shouldCreateAcrPrivateEndpoint ? privateEndpoint.id : null

@description('The ACR private DNS zone name (if enabled).')
output privateDnsZoneName string? = shouldCreateAcrPrivateEndpoint ? privateDnsZone.name : null

@description('The ACR private DNS zone ID (if enabled).')
output privateDnsZoneId string? = shouldCreateAcrPrivateEndpoint ? privateDnsZone.id : null

@description('Whether data endpoints are enabled for the ACR.')
output isDataEndpointEnabled bool = shouldEnableDataEndpoint

@description('Whether public network access is enabled for the ACR.')
output isPublicNetworkAccessEnabled bool = publicNetworkAccessEnabled
