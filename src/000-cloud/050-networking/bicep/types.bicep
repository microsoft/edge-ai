@export()
@description('Networking configuration settings.')
type NetworkingConfig = {
  @description('The address prefix for the virtual network.')
  addressPrefix: string

  @description('The subnet address prefix.')
  subnetAddressPrefix: string
}

@export()
var networkingConfigDefaults = {
  addressPrefix: '10.0.0.0/16'
  subnetAddressPrefix: '10.0.1.0/24'
}

@export()
@description('NAT Gateway configuration settings.')
type NatGatewayConfig = {
  @description('Whether to enable NAT Gateway for managed outbound access.')
  shouldEnable: bool

  @description('Number of public IP addresses to allocate (1-16).')
  @minValue(1)
  @maxValue(16)
  publicIpCount: int

  @description('Idle timeout in minutes (4-120).')
  @minValue(4)
  @maxValue(120)
  idleTimeoutMinutes: int

  @description('Availability zones for the NAT Gateway. Empty array for regional deployment.')
  zones: string[]
}

@export()
var natGatewayConfigDefaults = {
  shouldEnable: false
  publicIpCount: 1
  idleTimeoutMinutes: 4
  zones: []
}

@export()
@description('Private DNS Resolver configuration.')
type PrivateResolverConfig = {
  @description('Whether to enable Private DNS Resolver.')
  shouldEnable: bool

  @description('Address prefix for resolver subnet.')
  subnetAddressPrefix: string
}

@export()
var privateResolverConfigDefaults = {
  shouldEnable: false
  subnetAddressPrefix: '10.0.254.0/28'
}
