metadata name = 'Virtual Network Component'
metadata description = 'Creates virtual network, subnet, and network security group resources for Azure deployments.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Virtual Network Parameters
*/

@description('Networking configuration settings.')
param networkingConfig types.NetworkingConfig = types.networkingConfigDefaults

@description('NAT Gateway configuration settings.')
param natGatewayConfig types.NatGatewayConfig = types.natGatewayConfigDefaults

@description('Private DNS Resolver configuration settings.')
param privateResolverConfig types.PrivateResolverConfig = types.privateResolverConfigDefaults

@description('Whether default outbound access is enabled for subnets.')
param defaultOutboundAccessEnabled bool = false

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Local Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
var networkSecurityGroupName = 'nsg-${resourceNamePrefix}'
var virtualNetworkName = 'vnet-${resourceNamePrefix}'
var defaultSubnetName = 'subnet-${resourceNamePrefix}'

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

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2025-01-01' = {
  name: networkSecurityGroupName
  location: common.location
  properties: {}
}

/*
  Modules
*/

module natGateway './modules/nat-gateway.bicep' = if (natGatewayConfig.shouldEnable) {
  name: '${deployment().name}-nat'
  params: {
    resourcePrefix: common.resourcePrefix
    location: common.location
    environment: common.environment
    instance: common.instance
    publicIpCount: natGatewayConfig.publicIpCount
    zones: natGatewayConfig.zones
    idleTimeoutMinutes: natGatewayConfig.idleTimeoutMinutes
    tags: {
      'azd-env-name': common.environment
    }
  }
}

// VNet without inline subnets to avoid InUseSubnetCannotBeDeleted errors on redeployment
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: virtualNetworkName
  location: common.location
  properties: {
    addressSpace: {
      addressPrefixes: [networkingConfig.addressPrefix]
    }
  }
}

// Default subnet as separate child resource
resource defaultSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' = {
  parent: virtualNetwork
  name: defaultSubnetName
  properties: {
    addressPrefix: networkingConfig.subnetAddressPrefix
    defaultOutboundAccess: defaultOutboundAccessEnabled
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
    natGateway: natGatewayConfig.shouldEnable && natGateway != null ? { id: natGateway!.outputs.natGatewayId } : null
  }
}

module privateResolver './modules/private-resolver.bicep' = if (privateResolverConfig.shouldEnable) {
  name: '${deployment().name}-resolver'
  dependsOn: [defaultSubnet]
  params: {
    resourcePrefix: common.resourcePrefix
    location: common.location
    environment: common.environment
    instance: common.instance
    virtualNetworkId: virtualNetwork.id
    virtualNetworkName: virtualNetwork.name
    subnetAddressPrefix: privateResolverConfig.subnetAddressPrefix
    natGatewayId: natGatewayConfig.shouldEnable ? natGateway.?outputs.?natGatewayId : null
    defaultOutboundAccessEnabled: defaultOutboundAccessEnabled
    tags: {
      'azd-env-name': common.environment
    }
  }
}

/*
  Outputs
*/

@description('The ID of the created network security group.')
output networkSecurityGroupId string = networkSecurityGroup.id

@description('The name of the created network security group.')
output networkSecurityGroupName string = networkSecurityGroup.name

@description('The ID of the created subnet.')
output subnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, defaultSubnetName)

@description('The name of the created subnet.')
output subnetName string = defaultSubnetName

@description('The ID of the created virtual network.')
output virtualNetworkId string = virtualNetwork.id

@description('The name of the created virtual network.')
output virtualNetworkName string = virtualNetwork.name

@description('The ID of the NAT Gateway (if enabled).')
output natGatewayId string? = natGatewayConfig.shouldEnable ? natGateway.?outputs.?natGatewayId : null

@description('The name of the NAT Gateway (if enabled).')
output natGatewayName string? = natGatewayConfig.shouldEnable ? natGateway.?outputs.?natGatewayName : null

@description('The public IP addresses associated with NAT Gateway (if enabled).')
output natGatewayPublicIps array? = natGatewayConfig.shouldEnable ? natGateway.?outputs.?publicIps : null

@description('The Private DNS Resolver ID (if enabled).')
output privateResolverId string? = privateResolverConfig.shouldEnable ? privateResolver.?outputs.?resolverId : null

@description('The Private DNS Resolver name (if enabled).')
output privateResolverName string? = privateResolverConfig.shouldEnable ? privateResolver.?outputs.?resolverName : null

@description('The DNS server IP address from Private Resolver (if enabled).')
output dnsServerIp string? = privateResolverConfig.shouldEnable ? privateResolver.?outputs.?dnsServerIp : null

@description('Whether default outbound access remains enabled for the shared subnet(s).')
output defaultOutboundAccessEnabled bool = defaultOutboundAccessEnabled

@description('The address prefix allocated to the default subnet.')
output subnetAddressPrefix string = networkingConfig.subnetAddressPrefix

@description('The address prefix allocated to the virtual network.')
output virtualNetworkAddressPrefix string = networkingConfig.addressPrefix
