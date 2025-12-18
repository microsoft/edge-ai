metadata name = 'NAT Gateway Module'
metadata description = 'Creates NAT Gateway with public IP addresses for managed outbound internet access.'

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

@description('Number of public IPs to create.')
@minValue(1)
@maxValue(16)
param publicIpCount int

@description('Availability zones.')
param zones string[]

@description('Idle timeout in minutes.')
@minValue(4)
@maxValue(120)
param idleTimeoutMinutes int

@description('Resource tags.')
param tags object = {}

/*
  Variables
*/

var natGatewayName = 'nat-${resourcePrefix}-${environment}-${instance}'
var publicIpPrefix = 'pip-nat-${resourcePrefix}-${environment}-${instance}'

/*
  Resources
*/

resource publicIps 'Microsoft.Network/publicIPAddresses@2025-01-01' = [
  for i in range(0, publicIpCount): {
    name: '${publicIpPrefix}-${i + 1}'
    location: location
    tags: tags
    sku: {
      name: 'Standard'
    }
    zones: !empty(zones) ? zones : []
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
]

resource natGateway 'Microsoft.Network/natGateways@2025-01-01' = {
  name: natGatewayName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: !empty(zones) ? zones : []
  properties: {
    idleTimeoutInMinutes: idleTimeoutMinutes
    publicIpAddresses: [
      for i in range(0, publicIpCount): {
        id: publicIps[i].id
      }
    ]
  }
}

/*
  Outputs
*/

@description('NAT Gateway resource ID.')
output natGatewayId string = natGateway.id

@description('NAT Gateway resource name.')
output natGatewayName string = natGateway.name

@description('Public IP addresses associated with NAT Gateway.')
output publicIps array = [
  for i in range(0, publicIpCount): {
    name: publicIps[i].name
    id: publicIps[i].id
    ipAddress: publicIps[i].properties.ipAddress
  }
]
