metadata name = 'VPN Gateway Component'
metadata description = '''
Creates a VPN Gateway with Point-to-Site and optional Site-to-Site connectivity.
Ths component currently only supports Azure AD (Entra ID) authentication for Point-to-Site VPN connections.'''

/*

### Certificate-Based Authentication (Not Supported), this is different from the Terraform version

Certificate-based authentication is not currently supported in this Bicep component. This is because:
- Azure Key Vault certificates cannot be created via native Bicep/ARM resources
- The `Microsoft.KeyVault/vaults/certificates` resource type does not exist in ARM
- Certificate creation requires the Key Vault data plane API, which necessitates deployment scripts
- Deployment scripts require storage accounts with shared key access, which may conflict with Azure Policy
- See <https://github.com/Azure/bicep/discussions/10044> for more details

*/

import * as core from './types.core.bicep'
import * as types from './types.bicep'

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

@description('Virtual network name for Gateway subnet creation.')
param virtualNetworkName string

/*
  Authentication Parameters
*/

@description('Azure AD configuration for VPN Gateway authentication.')
param azureAdConfig types.AzureAdConfig = types.azureAdConfigDefaults

/*
  Optional Parameters
*/

@description('Whether default outbound access is enabled for Gateway subnet.')
param defaultOutboundAccessEnabled bool = false

@description('Resource tags.')
param tags object = {}

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Site-to-Site Parameters
*/

@description('Site-to-site VPN connection definitions.')
param vpnSiteConnections types.VpnSiteConnection[] = []

@description('Fallback IPsec policy applied when sites omit an override.')
param vpnSiteDefaultIpsecPolicy types.VpnIpsecPolicy?

@secure()
@description('Pre-shared keys keyed by sharedKeyReference values.')
param vpnSiteSharedKeys object = {}

/*
  Variables
*/

var shouldDeploySiteToSite = length(vpnSiteConnections) > 0
var resolvedVpnSiteDefaultIpsecPolicy = vpnSiteDefaultIpsecPolicy ?? types.vpnSiteDefaultIpsecPolicyDefaults

/*
  Resources & Modules
*/

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

module vpnGateway './modules/vpn-gateway.bicep' = {
  name: '${deployment().name}-vng'
  params: {
    common: common
    vpnGatewayConfig: vpnGatewayConfig
    virtualNetworkName: virtualNetworkName
    gatewaySubnetAddressPrefix: gatewaySubnetAddressPrefix
    defaultOutboundAccessEnabled: defaultOutboundAccessEnabled
    azureAdConfig: azureAdConfig
    tags: tags
  }
}

module siteToSite './modules/site-to-site.bicep' = if (shouldDeploySiteToSite) {
  name: '${deployment().name}-s2s'
  params: {
    common: common
    location: common.location
    tags: tags
    vpnGatewayId: vpnGateway.outputs.vpnGatewayId
    vpnSiteConnections: vpnSiteConnections
    vpnSiteDefaultIpsecPolicy: resolvedVpnSiteDefaultIpsecPolicy
    vpnSiteSharedKeys: vpnSiteSharedKeys
  }
}

var vpnSiteConnectionsOutput = shouldDeploySiteToSite ? siteToSite.?outputs.?siteConnections : null
var vpnSiteLocalNetworkGatewaysOutput = shouldDeploySiteToSite ? siteToSite.?outputs.?localNetworkGateways : null

/*
  Outputs
*/

@description('VPN Gateway resource projection.')
output vpnGateway object = vpnGateway.outputs.vpnGateway

@description('VPN Gateway resource ID.')
output vpnGatewayId string = vpnGateway.outputs.vpnGatewayId

@description('VPN Gateway resource name.')
output vpnGatewayName string = vpnGateway.outputs.vpnGatewayName

@description('VPN Gateway SKU.')
output vpnGatewaySku string = vpnGatewayConfig.sku

@description('VPN Gateway public IP address.')
output vpnGatewayPublicIp string = vpnGateway.outputs.publicIpAddress

@description('VPN client connection information.')
output clientConnectionInfo object = vpnGateway.outputs.clientConnectionInfo

@description('Gateway subnet ID.')
output gatewaySubnetId string = vpnGateway.outputs.gatewaySubnetId

@description('VPN site connection metadata keyed by VPN site name.')
output vpnSiteConnections object? = vpnSiteConnectionsOutput

@description('Local network gateway metadata keyed by VPN site name.')
output vpnSiteLocalNetworkGateways object? = vpnSiteLocalNetworkGatewaysOutput
