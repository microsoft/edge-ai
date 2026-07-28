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

@description('Whether to create a Network Security Perimeter that allows the detected deployment client IP for supported PaaS resources.')
param shouldUseNetworkSecurityPerimeter bool = false

@description('Additional IPv4 or IPv6 CIDR prefixes allowed through the Network Security Perimeter; the detected deployment client IP is added automatically.')
param networkSecurityPerimeterAllowedIpAddressPrefixes string[] = []

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Existing Networking Parameters
*/

@description('Whether to reference an existing virtual network, subnet, and network security group instead of creating new ones.')
param useExistingVirtualNetwork bool = false

@description('Resource group name containing the existing virtual network when useExistingVirtualNetwork is true. Otherwise, the deployment resource group.')
param existingResourceGroupName string?

@description('Name of the virtual network to create or reference. Otherwise, computed from common naming.')
param virtualNetworkName string?

@description('Name of the subnet to create or reference. Otherwise, computed from common naming.')
param subnetName string?

@description('Name of the network security group to create or reference. Otherwise, computed from common naming.')
param networkSecurityGroupName string?

/*
  Local Variables
*/

var resourceNamePrefix = '${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
var resolvedNetworkSecurityGroupName = networkSecurityGroupName ?? 'nsg-${resourceNamePrefix}'
var resolvedVirtualNetworkName = virtualNetworkName ?? 'vnet-${resourceNamePrefix}'
var resolvedSubnetName = subnetName ?? 'subnet-${resourceNamePrefix}'
var resolvedExistingResourceGroupName = existingResourceGroupName ?? resourceGroup().name
// Resource group that owns the virtual network/subnet/NSG referenced by the resolved IDs below.
var targetResourceGroupName = useExistingVirtualNetwork ? resolvedExistingResourceGroupName : resourceGroup().name
var resolvedVirtualNetworkId = resourceId(
  subscription().subscriptionId,
  targetResourceGroupName,
  'Microsoft.Network/virtualNetworks',
  resolvedVirtualNetworkName
)
var resolvedNetworkSecurityGroupId = resourceId(
  subscription().subscriptionId,
  targetResourceGroupName,
  'Microsoft.Network/networkSecurityGroups',
  resolvedNetworkSecurityGroupName
)
var resolvedSubnetId = resourceId(
  subscription().subscriptionId,
  targetResourceGroupName,
  'Microsoft.Network/virtualNetworks/subnets',
  resolvedVirtualNetworkName,
  resolvedSubnetName
)

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

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2025-01-01' = if (!useExistingVirtualNetwork) {
  name: resolvedNetworkSecurityGroupName
  location: common.location
  properties: {}
}

/*
  Modules
*/

module natGateway './modules/nat-gateway.bicep' = if (!useExistingVirtualNetwork && natGatewayConfig.shouldEnable) {
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
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-01-01' = if (!useExistingVirtualNetwork) {
  name: resolvedVirtualNetworkName
  location: common.location
  properties: {
    addressSpace: {
      addressPrefixes: [networkingConfig.addressPrefix]
    }
  }
}

// Default subnet as separate child resource
resource defaultSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-01-01' = if (!useExistingVirtualNetwork) {
  parent: virtualNetwork
  name: resolvedSubnetName
  properties: {
    addressPrefix: networkingConfig.subnetAddressPrefix
    defaultOutboundAccess: defaultOutboundAccessEnabled
    networkSecurityGroup: {
      id: resolvedNetworkSecurityGroupId
    }
    natGateway: natGatewayConfig.shouldEnable && natGateway != null ? { id: natGateway!.outputs.natGatewayId } : null
  }
}

module privateResolver './modules/private-resolver.bicep' = if (!useExistingVirtualNetwork && privateResolverConfig.shouldEnable) {
  name: '${deployment().name}-resolver'
  dependsOn: [defaultSubnet]
  params: {
    resourcePrefix: common.resourcePrefix
    location: common.location
    environment: common.environment
    instance: common.instance
    virtualNetworkId: resolvedVirtualNetworkId
    virtualNetworkName: resolvedVirtualNetworkName
    subnetAddressPrefix: privateResolverConfig.subnetAddressPrefix
    natGatewayId: natGatewayConfig.shouldEnable ? natGateway.?outputs.?natGatewayId : null
    defaultOutboundAccessEnabled: defaultOutboundAccessEnabled
    tags: {
      'azd-env-name': common.environment
    }
  }
}

module networkSecurityPerimeter './modules/network-security-perimeter.bicep' = if (shouldUseNetworkSecurityPerimeter) {
  name: '${deployment().name}-networkSecurityPerimeter'
  params: {
    common: common
    allowedIpAddressPrefixes: networkSecurityPerimeterAllowedIpAddressPrefixes
  }
}

/*
  Outputs
*/

@description('The ID of the created network security group.')
output networkSecurityGroupId string = resolvedNetworkSecurityGroupId

@description('The name of the created network security group.')
output networkSecurityGroupName string = resolvedNetworkSecurityGroupName

@description('The ID of the created subnet.')
output subnetId string = resolvedSubnetId

@description('The name of the created subnet.')
output subnetName string = resolvedSubnetName

@description('The ID of the created virtual network.')
output virtualNetworkId string = resolvedVirtualNetworkId

@description('The name of the created virtual network.')
output virtualNetworkName string = resolvedVirtualNetworkName

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

@description('The resource ID of the Network Security Perimeter when created.')
output networkSecurityPerimeterId string? = shouldUseNetworkSecurityPerimeter
  ? networkSecurityPerimeter!.outputs.networkSecurityPerimeterId
  : null

@description('The resource group containing the Network Security Perimeter when created.')
output networkSecurityPerimeterResourceGroupName string? = shouldUseNetworkSecurityPerimeter
  ? networkSecurityPerimeter!.outputs.networkSecurityPerimeterResourceGroupName
  : null

@description('The resource ID of the Network Security Perimeter profile when created.')
output networkSecurityPerimeterProfileId string? = shouldUseNetworkSecurityPerimeter
  ? networkSecurityPerimeter!.outputs.profileId
  : null
