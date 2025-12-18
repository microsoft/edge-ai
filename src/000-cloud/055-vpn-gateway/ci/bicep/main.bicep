import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  VPN Gateway Parameters
*/

@description('VPN Gateway configuration settings.')
param vpnGatewayConfig types.VpnGatewayConfig = types.vpnGatewayConfigDefaults

@description('Gateway subnet address prefix.')
param gatewaySubnetAddressPrefix string = '10.0.2.0/27'

/*
  Authentication Parameters
*/

@description('Azure AD configuration for VPN Gateway authentication.')
param azureAdConfig types.AzureAdConfig = types.azureAdConfigDefaults

/*
  Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-${common.environment}-${common.instance}'
var virtualNetworkName = 'vnet-${resourceNamePrefix}'

/*
  Existing Resources
*/

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}

/*
  Modules
*/

module vpnGateway '../../bicep/main.bicep' = {
  name: '${deployment().name}-main'
  params: {
    common: common
    vpnGatewayConfig: vpnGatewayConfig
    gatewaySubnetAddressPrefix: gatewaySubnetAddressPrefix
    virtualNetworkName: virtualNetwork.name
    azureAdConfig: azureAdConfig
  }
}
