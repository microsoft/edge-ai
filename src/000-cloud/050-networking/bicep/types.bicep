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
