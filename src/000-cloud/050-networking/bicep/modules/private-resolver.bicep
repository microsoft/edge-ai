metadata name = 'Private DNS Resolver Module'
metadata description = 'Creates Azure Private DNS Resolver for private endpoint DNS resolution.'

/*
  Parameters
*/

@description('Resource name prefix.')
param resourcePrefix string

@description('Azure region.')
param location string

@description('Environment name.')
param environment string

@description('Instance identifier.')
param instance string

@description('Virtual network ID.')
param virtualNetworkId string

@description('Virtual network name.')
param virtualNetworkName string

@description('Subnet address prefix for resolver.')
param subnetAddressPrefix string

@description('NAT Gateway ID for resolver subnet (optional).')
param natGatewayId string?

@description('Whether default outbound access is enabled.')
param defaultOutboundAccessEnabled bool

@description('Resource tags.')
param tags object = {}

/*
  Variables
*/

var resolverName = 'dnspr-${resourcePrefix}-${environment}-${instance}'
var subnetName = 'snet-resolver-${resourcePrefix}-${environment}-${instance}'
var inboundEndpointName = 'in-${resolverName}'

/*
  Resources
*/

resource resolverSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' = {
  name: '${virtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    defaultOutboundAccess: defaultOutboundAccessEnabled
    natGateway: natGatewayId != null ? { id: natGatewayId! } : null
    delegations: [
      {
        name: 'Microsoft.Network.dnsResolvers'
        properties: {
          serviceName: 'Microsoft.Network/dnsResolvers'
        }
      }
    ]
  }
}

resource dnsResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: resolverName
  location: location
  tags: tags
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource inboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: dnsResolver
  name: inboundEndpointName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: resolverSubnet.id
        }
      }
    ]
  }
}

/*
  Outputs
*/

@description('Private DNS Resolver ID.')
output resolverId string = dnsResolver.id

@description('Private DNS Resolver name.')
output resolverName string = dnsResolver.name

@description('DNS server IP address from inbound endpoint.')
output dnsServerIp string = inboundEndpoint.properties.ipConfigurations[0].privateIpAddress
