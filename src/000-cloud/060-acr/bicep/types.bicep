metadata name = 'ACR Component Types'
metadata description = 'Type definitions and defaults for the ACR component.'

/*
  Container Registry Configuration
*/

@export()
@description('The settings for the Azure Container Registry.')
type ContainerRegistry = {
  @description('The SKU for the Azure Container Registry. Options are Basic, Standard, Premium.')
  sku: 'Basic' | 'Standard' | 'Premium'
}

@export()
var containerRegistryDefaults = {
  sku: 'Premium'
}

/*
  ACR Networking Configuration
*/

@export()
@description('Networking configuration for the ACR subnet.')
type AcrNetworkConfig = {
  @description('Address prefix for the ACR subnet when creating a private endpoint.')
  subnetAddressPrefix: string

  @description('Whether default outbound internet access is enabled for the ACR subnet.')
  defaultOutboundAccessEnabled: bool

  @description('Whether to associate the ACR subnet with a NAT gateway for managed outbound egress.')
  shouldEnableNatGateway: bool
}

@export()
var acrNetworkConfigDefaults = {
  subnetAddressPrefix: '10.0.3.0/24'
  defaultOutboundAccessEnabled: false
  shouldEnableNatGateway: false
}

/*
  ACR Firewall Configuration
*/

@export()
@description('Firewall and public access configuration for the ACR.')
type AcrFirewallConfig = {
  @description('Whether to enable the registry public endpoint alongside private connectivity.')
  publicNetworkAccessEnabled: bool

  @description('Whether trusted Azure services can bypass registry network rules when the public endpoint is restricted.')
  allowTrustedServices: bool

  @description('CIDR ranges permitted to reach the registry public endpoint.')
  allowedPublicIpRanges: string[]

  @description('Whether to enable dedicated data endpoints for the registry (Premium SKU only).')
  shouldEnableDataEndpoints: bool
}

@export()
var acrFirewallConfigDefaults = {
  publicNetworkAccessEnabled: false
  allowTrustedServices: true
  allowedPublicIpRanges: []
  shouldEnableDataEndpoints: true
}
