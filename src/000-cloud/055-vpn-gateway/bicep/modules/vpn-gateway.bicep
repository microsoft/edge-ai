metadata name = 'VPN Gateway Module'
metadata description = 'Provision the VPN gateway, gateway subnet, and supporting public IP resources.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('Common component configuration for naming and location.')
param common core.Common

@description('VPN Gateway configuration settings.')
param vpnGatewayConfig types.VpnGatewayConfig

@description('Name of the existing virtual network containing the gateway subnet.')
param virtualNetworkName string

@description('Address prefix applied to the GatewaySubnet resource.')
param gatewaySubnetAddressPrefix string

@description('Whether to enable default outbound access on the gateway subnet.')
param defaultOutboundAccessEnabled bool

@description('Azure AD configuration values (audience, issuer, tenant).')
param azureAdConfig types.AzureAdConfig

@description('Resource tags applied to all created assets.')
param tags object

/*
  Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-${common.environment}-${common.instance}'
var gatewaySubnetName = 'GatewaySubnet'
var publicIpName = 'pip-vpngateway-${resourceNamePrefix}'
var vpnGatewayName = 'vng-${resourceNamePrefix}'
var tenantId = azureAdConfig.?tenantId ?? tenant().tenantId
var aadLoginEndpoint = environment().authentication.loginEndpoint
var aadTenant = '${aadLoginEndpoint}${tenantId}/'
var aadIssuerBase = replace(aadLoginEndpoint, 'login.', 'sts.')
var aadIssuer = azureAdConfig.?issuer ?? '${aadIssuerBase}${tenantId}/'

/*
  Resources
*/

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: virtualNetwork
  name: gatewaySubnetName
  properties: {
    addressPrefix: gatewaySubnetAddressPrefix
    defaultOutboundAccess: defaultOutboundAccessEnabled
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: common.location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: vpnGatewayName
  location: common.location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: vpnGatewayConfig.sku
      tier: vpnGatewayConfig.sku
    }
    vpnGatewayGeneration: vpnGatewayConfig.generation
    enableBgp: false
    activeActive: false
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: gatewaySubnet.id
          }
        }
      }
    ]
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: vpnGatewayConfig.clientAddressPool
      }
      vpnClientProtocols: ['OpenVPN']
      vpnAuthenticationTypes: ['AAD']
      aadTenant: aadTenant
      aadAudience: azureAdConfig.audience
      aadIssuer: aadIssuer
    }
  }
}

/*
  Outputs
*/

@description('VPN Gateway resource object.')
output vpnGateway object = vpnGateway

@description('VPN Gateway resource ID.')
output vpnGatewayId string = vpnGateway.id

@description('VPN Gateway resource name.')
output vpnGatewayName string = vpnGateway.name

@description('Gateway subnet resource ID.')
output gatewaySubnetId string = gatewaySubnet.id

@description('VPN Gateway public IP address.')
output publicIpAddress string = publicIp.properties.ipAddress

@description('VPN client connection metadata mirroring Terraform output.')
output clientConnectionInfo object = {
  vpnGatewayPublicIp: publicIp.properties.ipAddress
  clientAddressPool: vpnGatewayConfig.clientAddressPool
  protocols: ['OpenVPN']
}
