<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Virtual Network Component

Creates virtual network, subnet, and network security group resources for Azure deployments.

## Parameters

| Name                                             | Description                                                                                                                                     | Type                                              | Default                                         | Required |
|:-------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------|:------------------------------------------------|:---------|
| common                                           | The common component configuration.                                                                                                             | `[_2.Common](#user-defined-types)`                | n/a                                             | yes      |
| networkingConfig                                 | Networking configuration settings.                                                                                                              | `[_1.NetworkingConfig](#user-defined-types)`      | [variables('_1.networkingConfigDefaults')]      | no       |
| natGatewayConfig                                 | NAT Gateway configuration settings.                                                                                                             | `[_1.NatGatewayConfig](#user-defined-types)`      | [variables('_1.natGatewayConfigDefaults')]      | no       |
| privateResolverConfig                            | Private DNS Resolver configuration settings.                                                                                                    | `[_1.PrivateResolverConfig](#user-defined-types)` | [variables('_1.privateResolverConfigDefaults')] | no       |
| defaultOutboundAccessEnabled                     | Whether default outbound access is enabled for subnets.                                                                                         | `bool`                                            | `false`                                         | no       |
| shouldUseNetworkSecurityPerimeter                | Whether to create a Network Security Perimeter that allows the detected deployment client IP for supported PaaS resources.                      | `bool`                                            | `false`                                         | no       |
| networkSecurityPerimeterAllowedIpAddressPrefixes | Additional IPv4 or IPv6 CIDR prefixes allowed through the Network Security Perimeter; the detected deployment client IP is added automatically. | `string[]`                                        | []                                              | no       |
| telemetry_opt_out                                | Whether to opt out of telemetry data collection.                                                                                                | `bool`                                            | `false`                                         | no       |
| useExistingVirtualNetwork                        | Whether to reference an existing virtual network, subnet, and network security group instead of creating new ones.                              | `bool`                                            | `false`                                         | no       |
| existingResourceGroupName                        | Resource group name containing the existing virtual network when useExistingVirtualNetwork is true. Otherwise, the deployment resource group.   | `string`                                          | n/a                                             | no       |
| virtualNetworkName                               | Name of the virtual network to create or reference. Otherwise, computed from common naming.                                                     | `string`                                          | n/a                                             | no       |
| subnetName                                       | Name of the subnet to create or reference. Otherwise, computed from common naming.                                                              | `string`                                          | n/a                                             | no       |
| networkSecurityGroupName                         | Name of the network security group to create or reference. Otherwise, computed from common naming.                                              | `string`                                          | n/a                                             | no       |

## Resources

| Name                     | Type                              | API Version |
|:-------------------------|:----------------------------------|:------------|
| networkSecurityPerimeter | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                     | Description                                                                                                                        |
|:-------------------------|:-----------------------------------------------------------------------------------------------------------------------------------|
| natGateway               | Creates NAT Gateway with public IP addresses for managed outbound internet access.                                                 |
| privateResolver          | Creates Azure Private DNS Resolver for private endpoint DNS resolution.                                                            |
| networkSecurityPerimeter | Creates a Network Security Perimeter profile with inbound access for deployment clients and resources in the current subscription. |

## Module Details

### natGateway

Creates NAT Gateway with public IP addresses for managed outbound internet access.

#### Parameters for natGateway

| Name               | Description                     | Type     | Default | Required |
|:-------------------|:--------------------------------|:---------|:--------|:---------|
| resourcePrefix     | Resource name prefix.           | `string` | n/a     | yes      |
| location           | Azure region.                   | `string` | n/a     | yes      |
| environment        | Environment name.               | `string` | n/a     | yes      |
| instance           | Instance identifier.            | `string` | n/a     | yes      |
| publicIpCount      | Number of public IPs to create. | `int`    | n/a     | yes      |
| zones              | Availability zones.             | `array`  | n/a     | yes      |
| idleTimeoutMinutes | Idle timeout in minutes.        | `int`    | n/a     | yes      |
| tags               | Resource tags.                  | `object` | {}      | no       |

#### Resources for natGateway

| Name       | Type                                  | API Version |
|:-----------|:--------------------------------------|:------------|
| publicIps  | `Microsoft.Network/publicIPAddresses` | 2025-01-01  |
| natGateway | `Microsoft.Network/natGateways`       | 2025-01-01  |

#### Outputs for natGateway

| Name           | Type     | Description                                      |
|:---------------|:---------|:-------------------------------------------------|
| natGatewayId   | `string` | NAT Gateway resource ID.                         |
| natGatewayName | `string` | NAT Gateway resource name.                       |
| publicIps      | `array`  | Public IP addresses associated with NAT Gateway. |

### privateResolver

Creates Azure Private DNS Resolver for private endpoint DNS resolution.

#### Parameters for privateResolver

| Name                         | Description                                    | Type     | Default | Required |
|:-----------------------------|:-----------------------------------------------|:---------|:--------|:---------|
| resourcePrefix               | Resource name prefix.                          | `string` | n/a     | yes      |
| location                     | Azure region.                                  | `string` | n/a     | yes      |
| environment                  | Environment name.                              | `string` | n/a     | yes      |
| instance                     | Instance identifier.                           | `string` | n/a     | yes      |
| virtualNetworkId             | Virtual network ID.                            | `string` | n/a     | yes      |
| virtualNetworkName           | Virtual network name.                          | `string` | n/a     | yes      |
| subnetAddressPrefix          | Subnet address prefix for resolver.            | `string` | n/a     | yes      |
| natGatewayId                 | NAT Gateway ID for resolver subnet (optional). | `string` | n/a     | no       |
| defaultOutboundAccessEnabled | Whether default outbound access is enabled.    | `bool`   | n/a     | yes      |
| tags                         | Resource tags.                                 | `object` | {}      | no       |

#### Resources for privateResolver

| Name            | Type                                              | API Version |
|:----------------|:--------------------------------------------------|:------------|
| resolverSubnet  | `Microsoft.Network/virtualNetworks/subnets`       | 2025-01-01  |
| dnsResolver     | `Microsoft.Network/dnsResolvers`                  | 2022-07-01  |
| inboundEndpoint | `Microsoft.Network/dnsResolvers/inboundEndpoints` | 2022-07-01  |

#### Outputs for privateResolver

| Name         | Type     | Description                                  |
|:-------------|:---------|:---------------------------------------------|
| resolverId   | `string` | Private DNS Resolver ID.                     |
| resolverName | `string` | Private DNS Resolver name.                   |
| dnsServerIp  | `string` | DNS server IP address from inbound endpoint. |

### networkSecurityPerimeter

Creates a Network Security Perimeter profile with inbound access for deployment clients and resources in the current subscription.

#### Parameters for networkSecurityPerimeter

| Name                     | Description                                                                                                                                                                                                                                                 | Type                               | Default | Required |
|:-------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                   | The common component configuration.                                                                                                                                                                                                                         | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| allowedIpAddressPrefixes | IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the perimeter. Supply the deployment client public CIDR here when running data-plane operations from a workstation; this module does not auto-detect it (unlike the Terraform path). | `array`                            | n/a     | yes      |

#### Resources for networkSecurityPerimeter

| Name                       | Type                                                               | API Version |
|:---------------------------|:-------------------------------------------------------------------|:------------|
| networkSecurityPerimeter   | `Microsoft.Network/networkSecurityPerimeters`                      | 2025-01-01  |
| profile                    | `Microsoft.Network/networkSecurityPerimeters/profiles`             | 2025-01-01  |
| deploymentClientAccessRule | `Microsoft.Network/networkSecurityPerimeters/profiles/accessRules` | 2025-01-01  |
| subscriptionAccessRule     | `Microsoft.Network/networkSecurityPerimeters/profiles/accessRules` | 2025-01-01  |

#### Outputs for networkSecurityPerimeter

| Name                                      | Type     | Description                                                   |
|:------------------------------------------|:---------|:--------------------------------------------------------------|
| networkSecurityPerimeterId                | `string` | The resource ID of the Network Security Perimeter.            |
| networkSecurityPerimeterResourceGroupName | `string` | The resource group containing the Network Security Perimeter. |
| profileId                                 | `string` | The resource ID of the Network Security Perimeter profile.    |

## User Defined Types

### `_1.NatGatewayConfig`

NAT Gateway configuration settings.

| Property           | Type    | Description                                                                  |
|:-------------------|:--------|:-----------------------------------------------------------------------------|
| shouldEnable       | `bool`  | Whether to enable NAT Gateway for managed outbound access.                   |
| publicIpCount      | `int`   | Number of public IP addresses to allocate (1-16).                            |
| idleTimeoutMinutes | `int`   | Idle timeout in minutes (4-120).                                             |
| zones              | `array` | Availability zones for the NAT Gateway. Empty array for regional deployment. |

### `_1.NetworkingConfig`

Networking configuration settings.

| Property            | Type     | Description                                 |
|:--------------------|:---------|:--------------------------------------------|
| addressPrefix       | `string` | The address prefix for the virtual network. |
| subnetAddressPrefix | `string` | The subnet address prefix.                  |

### `_1.PrivateResolverConfig`

Private DNS Resolver configuration.

| Property            | Type     | Description                             |
|:--------------------|:---------|:----------------------------------------|
| shouldEnable        | `bool`   | Whether to enable Private DNS Resolver. |
| subnetAddressPrefix | `string` | Address prefix for resolver subnet.     |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                                      | Type     | Description                                                                |
|:------------------------------------------|:---------|:---------------------------------------------------------------------------|
| networkSecurityGroupId                    | `string` | The ID of the created network security group.                              |
| networkSecurityGroupName                  | `string` | The name of the created network security group.                            |
| subnetId                                  | `string` | The ID of the created subnet.                                              |
| subnetName                                | `string` | The name of the created subnet.                                            |
| virtualNetworkId                          | `string` | The ID of the created virtual network.                                     |
| virtualNetworkName                        | `string` | The name of the created virtual network.                                   |
| natGatewayId                              | `string` | The ID of the NAT Gateway (if enabled).                                    |
| natGatewayName                            | `string` | The name of the NAT Gateway (if enabled).                                  |
| natGatewayPublicIps                       | `array`  | The public IP addresses associated with NAT Gateway (if enabled).          |
| privateResolverId                         | `string` | The Private DNS Resolver ID (if enabled).                                  |
| privateResolverName                       | `string` | The Private DNS Resolver name (if enabled).                                |
| dnsServerIp                               | `string` | The DNS server IP address from Private Resolver (if enabled).              |
| defaultOutboundAccessEnabled              | `bool`   | Whether default outbound access remains enabled for the shared subnet(s).  |
| subnetAddressPrefix                       | `string` | The address prefix allocated to the default subnet.                        |
| virtualNetworkAddressPrefix               | `string` | The address prefix allocated to the virtual network.                       |
| networkSecurityPerimeterId                | `string` | The resource ID of the Network Security Perimeter when created.            |
| networkSecurityPerimeterResourceGroupName | `string` | The resource group containing the Network Security Perimeter when created. |
| networkSecurityPerimeterProfileId         | `string` | The resource ID of the Network Security Perimeter profile when created.    |

<!-- END_BICEP_DOCS -->