metadata name = 'ACR Resources'
metadata description = 'Deploys Azure Container Registry (ACR) resources.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

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

@description('NAT Gateway ID to associate with the ACR subnet for managed outbound egress.')
param natGatewayId string?

/*
  Container Registry Parameters
*/

@description('Whether to create a private endpoint for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool = false

@description('The settings for the Azure Container Registry.')
param containerRegistryConfig types.ContainerRegistry = types.containerRegistryDefaults

@description('Networking configuration for the ACR subnet.')
param acrNetworkConfig types.AcrNetworkConfig = types.acrNetworkConfigDefaults

@description('Firewall and public access configuration for the ACR.')
param acrFirewallConfig types.AcrFirewallConfig = types.acrFirewallConfigDefaults

/*
  Telemetry Parameter
*/

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

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

module network './modules/network.bicep' = {
  name: '${deployment().name}-network'
  params: {
    common: common
    virtualNetworkName: virtualNetworkName
    networkSecurityGroupName: networkSecurityGroupName
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
    subnetAddressPrefix: acrNetworkConfig.subnetAddressPrefix
    defaultOutboundAccessEnabled: acrNetworkConfig.defaultOutboundAccessEnabled
    shouldEnableNatGateway: acrNetworkConfig.shouldEnableNatGateway
    natGatewayId: natGatewayId
  }
}

module containerRegistry './modules/container-registry.bicep' = {
  name: '${deployment().name}-containerRegistry'
  params: {
    common: common
    sku: containerRegistryConfig.sku
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
    snetAcrId: shouldCreateAcrPrivateEndpoint ? network.outputs.snetAcrId : ''
    virtualNetworkName: virtualNetworkName
    publicNetworkAccessEnabled: acrFirewallConfig.publicNetworkAccessEnabled
    allowTrustedServices: acrFirewallConfig.allowTrustedServices
    allowedPublicIpRanges: acrFirewallConfig.allowedPublicIpRanges
    shouldEnableDataEndpoints: acrFirewallConfig.shouldEnableDataEndpoints
  }
}

/*
  Outputs
*/

@description('The Azure Container Registry ID.')
output acrId string = containerRegistry.outputs.acrId

@description('The Azure Container Registry name.')
output acrName string = containerRegistry.outputs.acrName

@description('The ACR subnet ID (if private endpoint is enabled).')
output acrSubnetId string? = shouldCreateAcrPrivateEndpoint ? network.outputs.snetAcrId : null

@description('The ACR private endpoint ID (if enabled).')
output acrPrivateEndpointId string? = shouldCreateAcrPrivateEndpoint
  ? containerRegistry.outputs.?privateEndpointId
  : null

@description('The ACR private DNS zone name (if enabled).')
output acrPrivateDnsZoneName string? = shouldCreateAcrPrivateEndpoint
  ? containerRegistry.outputs.?privateDnsZoneName
  : null

@description('Whether NAT Gateway is associated with the ACR subnet.')
output isNatGatewayEnabled bool = acrNetworkConfig.shouldEnableNatGateway && !empty(natGatewayId)
