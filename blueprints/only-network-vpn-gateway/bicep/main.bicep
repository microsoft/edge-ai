metadata name = 'Only Network VPN Gateway Blueprint'
metadata description = '''
Deploys a standalone resource group, virtual network, and VPN Gateway for Point-to-Site client connectivity.
This is Step 1 of a two-step deployment pattern: deploy this blueprint, connect over VPN, then layer
full-multi-node-cluster (with useExistingNetworking = true) on top of the resulting virtual network to
safely disable public network access once connected.

This Bicep blueprint only supports Azure AD (Entra ID) authentication for the VPN Gateway, because the
underlying 055-vpn-gateway Bicep component does not support certificate-based authentication (Azure Key
Vault certificates cannot be created via native Bicep/ARM resources). Use the Terraform version of this
blueprint for certificate-based authentication.'''

import * as core from './types.core.bicep'
import * as networkingTypes from '../../../src/000-cloud/050-networking/bicep/types.bicep'
import * as vpnGatewayTypes from '../../../src/000-cloud/055-vpn-gateway/bicep/types.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Whether to use an existing resource group instead of creating a new one.')
param useExistingResourceGroup bool = false

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Virtual Network Parameters
*/

@description('Networking configuration settings including address space and subnet prefix.')
param networkingConfig networkingTypes.NetworkingConfig = networkingTypes.networkingConfigDefaults

@description('Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints.')
param shouldEnablePrivateResolver bool = false

@description('Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets.')
param resolverSubnetAddressPrefix string = '10.0.9.0/28'

/*
  Networking and Outbound Access Parameters
*/

@description('Whether to enable managed outbound egress via NAT gateway instead of platform default internet access.')
param shouldEnableManagedOutboundAccess bool = true

@description('Number of public IP addresses for NAT Gateway (1-16).')
@minValue(1)
@maxValue(16)
param natGatewayPublicIpCount int = 1

@description('Idle timeout in minutes for NAT gateway connections (4-120).')
@minValue(4)
@maxValue(120)
param natGatewayIdleTimeoutMinutes int = 4

@description('Availability zones for NAT Gateway. Empty array for regional deployment.')
param natGatewayZones string[] = []

/*
  VPN Gateway Parameters
*/

@description('VPN Gateway configuration settings.')
param vpnGatewayConfig vpnGatewayTypes.VpnGatewayConfig = vpnGatewayTypes.vpnGatewayConfigDefaults

@description('Address prefix for the GatewaySubnet.')
param vpnGatewaySubnetAddressPrefix string = '10.0.2.0/27'

@description('Azure AD authentication configuration for VPN Gateway.')
param vpnGatewayAzureAdConfig vpnGatewayTypes.AzureAdConfig = vpnGatewayTypes.azureAdConfigDefaults

/*
  Site-to-Site Parameters
*/

@description('Site-to-site VPN connection definitions.')
param vpnSiteConnections vpnGatewayTypes.VpnSiteConnection[] = []

@description('Fallback IPsec parameters applied when site definitions omit an override.')
param vpnSiteDefaultIpsecPolicy vpnGatewayTypes.VpnIpsecPolicy?

@secure()
@description('Pre-shared keys for site connections keyed by sharedKeyReference values.')
param vpnSiteSharedKeys object = {}

/*
  Tags
*/

@description('Additional tags to add to the resources.')
param tags object = {}

/*
  Resources
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

/*
  Modules
*/

module cloudResourceGroup '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: '${deployment().name}-crg0'
  params: {
    common: common
    useExistingResourceGroup: useExistingResourceGroup
    resourceGroupName: !empty(resourceGroupName) ? resourceGroupName : null
    tags: tags
  }
}

module cloudNetworking '../../../src/000-cloud/050-networking/bicep/main.bicep' = {
  name: '${deployment().name}-cvn1'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [cloudResourceGroup]
  params: {
    common: common
    networkingConfig: networkingConfig
    natGatewayConfig: {
      shouldEnable: shouldEnableManagedOutboundAccess
      publicIpCount: natGatewayPublicIpCount
      idleTimeoutMinutes: natGatewayIdleTimeoutMinutes
      zones: natGatewayZones
    }
    privateResolverConfig: {
      shouldEnable: shouldEnablePrivateResolver
      subnetAddressPrefix: resolverSubnetAddressPrefix
    }
    defaultOutboundAccessEnabled: !shouldEnableManagedOutboundAccess
  }
}

module cloudVpnGateway '../../../src/000-cloud/055-vpn-gateway/bicep/main.bicep' = {
  name: '${deployment().name}-cvg2'
  scope: resourceGroup(resourceGroupName)
  params: {
    common: common
    virtualNetworkName: cloudNetworking.outputs.virtualNetworkName
    gatewaySubnetAddressPrefix: vpnGatewaySubnetAddressPrefix
    vpnGatewayConfig: vpnGatewayConfig
    azureAdConfig: vpnGatewayAzureAdConfig
    defaultOutboundAccessEnabled: !shouldEnableManagedOutboundAccess
    vpnSiteConnections: vpnSiteConnections
    vpnSiteDefaultIpsecPolicy: vpnSiteDefaultIpsecPolicy
    vpnSiteSharedKeys: vpnSiteSharedKeys
    tags: tags
  }
}

/*
  Outputs
*/

@description('The resource group containing the networking and VPN gateway resources.')
output resourceGroup object = {
  id: cloudResourceGroup.outputs.resourceGroupId
  name: resourceGroupName
  location: cloudResourceGroup.outputs.location
}

@description('The virtual network object (id, name).')
output virtualNetwork object = {
  id: cloudNetworking.outputs.virtualNetworkId
  name: cloudNetworking.outputs.virtualNetworkName
}

@description('The ID of the subnet used for private endpoints and workloads.')
output subnetId string = cloudNetworking.outputs.subnetId

@description('The VPN Gateway configuration and details.')
output vpnGateway object = {
  id: cloudVpnGateway.outputs.vpnGatewayId
  name: cloudVpnGateway.outputs.vpnGatewayName
}

@description('The public IP address of the VPN Gateway.')
output vpnGatewayPublicIp string = cloudVpnGateway.outputs.vpnGatewayPublicIp

@description('Client address pool, protocols, and public IP needed to configure clients.')
output vpnClientConnectionInfo object = cloudVpnGateway.outputs.clientConnectionInfo
