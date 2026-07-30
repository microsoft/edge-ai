<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Only Network VPN Gateway Blueprint

Deploys a standalone resource group, virtual network, and VPN Gateway for Point-to-Site client connectivity.
This is Step 1 of a two-step deployment pattern: deploy this blueprint, connect over VPN, then layer
full-multi-node-cluster (with useExistingNetworking = true) on top of the resulting virtual network to
safely disable public network access once connected.

This Bicep blueprint only supports Azure AD (Entra ID) authentication for the VPN Gateway, because the
underlying 055-vpn-gateway Bicep component does not support certificate-based authentication (Azure Key
Vault certificates cannot be created via native Bicep/ARM resources). Use the Terraform version of this
blueprint for certificate-based authentication.

## Parameters

| Name                              | Description                                                                                               | Type                                            | Default                                                                                                                          | Required |
|:----------------------------------|:----------------------------------------------------------------------------------------------------------|:------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                            | The common component configuration.                                                                       | `[_3.Common](#user-defined-types)`              | n/a                                                                                                                              | yes      |
| resourceGroupName                 | The name for the resource group. If not provided, a default name will be generated.                       | `string`                                        | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| useExistingResourceGroup          | Whether to use an existing resource group instead of creating a new one.                                  | `bool`                                          | `false`                                                                                                                          | no       |
| telemetry_opt_out                 | Whether to opt out of telemetry data collection.                                                          | `bool`                                          | `false`                                                                                                                          | no       |
| networkingConfig                  | Networking configuration settings including address space and subnet prefix.                              | `[_1.NetworkingConfig](#user-defined-types)`    | [variables('_1.networkingConfigDefaults')]                                                                                       | no       |
| shouldEnablePrivateResolver       | Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints.              | `bool`                                          | `false`                                                                                                                          | no       |
| resolverSubnetAddressPrefix       | Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets. | `string`                                        | 10.0.9.0/28                                                                                                                      | no       |
| shouldEnableManagedOutboundAccess | Whether to enable managed outbound egress via NAT gateway instead of platform default internet access.    | `bool`                                          | `true`                                                                                                                           | no       |
| natGatewayPublicIpCount           | Number of public IP addresses for NAT Gateway (1-16).                                                     | `int`                                           | 1                                                                                                                                | no       |
| natGatewayIdleTimeoutMinutes      | Idle timeout in minutes for NAT gateway connections (4-120).                                              | `int`                                           | 4                                                                                                                                | no       |
| natGatewayZones                   | Availability zones for NAT Gateway. Empty array for regional deployment.                                  | `string[]`                                      | []                                                                                                                               | no       |
| vpnGatewayConfig                  | VPN Gateway configuration settings.                                                                       | `[_2.VpnGatewayConfig](#user-defined-types)`    | [variables('_2.vpnGatewayConfigDefaults')]                                                                                       | no       |
| vpnGatewaySubnetAddressPrefix     | Address prefix for the GatewaySubnet.                                                                     | `string`                                        | 10.0.2.0/27                                                                                                                      | no       |
| vpnGatewayAzureAdConfig           | Azure AD authentication configuration for VPN Gateway.                                                    | `[_2.AzureAdConfig](#user-defined-types)`       | [variables('_2.azureAdConfigDefaults')]                                                                                          | no       |
| vpnSiteConnections                | Site-to-site VPN connection definitions.                                                                  | `[_2.VpnSiteConnection](#user-defined-types)[]` | []                                                                                                                               | no       |
| vpnSiteDefaultIpsecPolicy         | Fallback IPsec parameters applied when site definitions omit an override.                                 | `[_2.VpnIpsecPolicy](#user-defined-types)`      | n/a                                                                                                                              | no       |
| vpnSiteSharedKeys                 | Pre-shared keys for site connections keyed by sharedKeyReference values.                                  | `secureObject`                                  | {}                                                                                                                               | no       |
| tags                              | Additional tags to add to the resources.                                                                  | `object`                                        | {}                                                                                                                               | no       |

## Resources

| Name               | Type                              | API Version |
|:-------------------|:----------------------------------|:------------|
| cloudResourceGroup | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudNetworking    | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudVpnGateway    | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name               | Description                                                                                                                                                                                     |
|:-------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cloudResourceGroup | Creates the required resources needed for an edge IaC deployment.                                                                                                                               |
| cloudNetworking    | Creates virtual network, subnet, and network security group resources for Azure deployments.                                                                                                    |
| cloudVpnGateway    | Creates a VPN Gateway with Point-to-Site and optional Site-to-Site connectivity.<br>Ths component currently only supports Azure AD (Entra ID) authentication for Point-to-Site VPN connections. |

## Module Details

### cloudResourceGroup

Creates the required resources needed for an edge IaC deployment.

#### Parameters for cloudResourceGroup

| Name                     | Description                                                                         | Type                               | Default                                                                                                                          | Required |
|:-------------------------|:------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                   | The common component configuration.                                                 | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| resourceGroupName        | The name for the resource group. If not provided, a default name will be generated. | `string`                           | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| useExistingResourceGroup | Whether to use an existing resource group instead of creating a new one.            | `bool`                             | `false`                                                                                                                          | no       |
| telemetry_opt_out        | Whether to opt out of telemetry data collection.                                    | `bool`                             | `false`                                                                                                                          | no       |
| tags                     | Additional tags to add to the resources.                                            | `object`                           | {}                                                                                                                               | no       |

#### Outputs for cloudResourceGroup

| Name              | Type     | Description                         |
|:------------------|:---------|:------------------------------------|
| resourceGroupId   | `string` | The ID of the resource group.       |
| resourceGroupName | `string` | The name of the resource group.     |
| location          | `string` | The location of the resource group. |

### cloudNetworking

Creates virtual network, subnet, and network security group resources for Azure deployments.

#### Parameters for cloudNetworking

| Name                                             | Description                                                                                                                                     | Type                                              | Default                                         | Required |
|:-------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------|:------------------------------------------------|:---------|
| common                                           | The common component configuration.                                                                                                             | `[_2.Common](#user-defined-types)`                | n/a                                             | yes      |
| networkingConfig                                 | Networking configuration settings.                                                                                                              | `[_1.NetworkingConfig](#user-defined-types)`      | [variables('_1.networkingConfigDefaults')]      | no       |
| natGatewayConfig                                 | NAT Gateway configuration settings.                                                                                                             | `[_1.NatGatewayConfig](#user-defined-types)`      | [variables('_1.natGatewayConfigDefaults')]      | no       |
| privateResolverConfig                            | Private DNS Resolver configuration settings.                                                                                                    | `[_1.PrivateResolverConfig](#user-defined-types)` | [variables('_1.privateResolverConfigDefaults')] | no       |
| defaultOutboundAccessEnabled                     | Whether default outbound access is enabled for subnets.                                                                                         | `bool`                                            | `false`                                         | no       |
| shouldUseNetworkSecurityPerimeter                | Whether to create a Network Security Perimeter that allows the detected deployment client IP for supported PaaS resources.                      | `bool`                                            | `false`                                         | no       |
| networkSecurityPerimeterAllowedIpAddressPrefixes | Additional IPv4 or IPv6 CIDR prefixes allowed through the Network Security Perimeter; the detected deployment client IP is added automatically. | `array`                                           | []                                              | no       |
| telemetry_opt_out                                | Whether to opt out of telemetry data collection.                                                                                                | `bool`                                            | `false`                                         | no       |
| useExistingVirtualNetwork                        | Whether to reference an existing virtual network, subnet, and network security group instead of creating new ones.                              | `bool`                                            | `false`                                         | no       |
| existingResourceGroupName                        | Resource group name containing the existing virtual network when useExistingVirtualNetwork is true. Otherwise, the deployment resource group.   | `string`                                          | n/a                                             | no       |
| virtualNetworkName                               | Name of the virtual network to create or reference. Otherwise, computed from common naming.                                                     | `string`                                          | n/a                                             | no       |
| subnetName                                       | Name of the subnet to create or reference. Otherwise, computed from common naming.                                                              | `string`                                          | n/a                                             | no       |
| networkSecurityGroupName                         | Name of the network security group to create or reference. Otherwise, computed from common naming.                                              | `string`                                          | n/a                                             | no       |

#### Resources for cloudNetworking

| Name                     | Type                              | API Version |
|:-------------------------|:----------------------------------|:------------|
| networkSecurityPerimeter | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudNetworking

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

### cloudVpnGateway

Creates a VPN Gateway with Point-to-Site and optional Site-to-Site connectivity.
Ths component currently only supports Azure AD (Entra ID) authentication for Point-to-Site VPN connections.

#### Parameters for cloudVpnGateway

| Name                         | Description                                                    | Type                                         | Default                                    | Required |
|:-----------------------------|:---------------------------------------------------------------|:---------------------------------------------|:-------------------------------------------|:---------|
| common                       | The common component configuration.                            | `[_2.Common](#user-defined-types)`           | n/a                                        | yes      |
| vpnGatewayConfig             | VPN Gateway configuration settings.                            | `[_1.VpnGatewayConfig](#user-defined-types)` | [variables('_1.vpnGatewayConfigDefaults')] | no       |
| gatewaySubnetAddressPrefix   | Gateway subnet address prefix.                                 | `string`                                     | 10.0.2.0/27                                | no       |
| virtualNetworkName           | Virtual network name for Gateway subnet creation.              | `string`                                     | n/a                                        | yes      |
| azureAdConfig                | Azure AD configuration for VPN Gateway authentication.         | `[_1.AzureAdConfig](#user-defined-types)`    | [variables('_1.azureAdConfigDefaults')]    | no       |
| defaultOutboundAccessEnabled | Whether default outbound access is enabled for Gateway subnet. | `bool`                                       | `false`                                    | no       |
| tags                         | Resource tags.                                                 | `object`                                     | {}                                         | no       |
| telemetry_opt_out            | Whether to opt out of telemetry data collection.               | `bool`                                       | `false`                                    | no       |
| vpnSiteConnections           | Site-to-site VPN connection definitions.                       | `array`                                      | []                                         | no       |
| vpnSiteDefaultIpsecPolicy    | Fallback IPsec policy applied when sites omit an override.     | `[_1.VpnIpsecPolicy](#user-defined-types)`   | n/a                                        | no       |
| vpnSiteSharedKeys            | Pre-shared keys keyed by sharedKeyReference values.            | `secureObject`                               | {}                                         | no       |

#### Resources for cloudVpnGateway

| Name       | Type                              | API Version |
|:-----------|:----------------------------------|:------------|
| vpnGateway | `Microsoft.Resources/deployments` | 2025-04-01  |
| siteToSite | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudVpnGateway

| Name                        | Type     | Description                                            |
|:----------------------------|:---------|:-------------------------------------------------------|
| vpnGateway                  | `object` | VPN Gateway resource projection.                       |
| vpnGatewayId                | `string` | VPN Gateway resource ID.                               |
| vpnGatewayName              | `string` | VPN Gateway resource name.                             |
| vpnGatewaySku               | `string` | VPN Gateway SKU.                                       |
| vpnGatewayPublicIp          | `string` | VPN Gateway public IP address.                         |
| clientConnectionInfo        | `object` | VPN client connection information.                     |
| gatewaySubnetId             | `string` | Gateway subnet ID.                                     |
| vpnSiteConnections          | `object` | VPN site connection metadata keyed by VPN site name.   |
| vpnSiteLocalNetworkGateways | `object` | Local network gateway metadata keyed by VPN site name. |

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

### `_2.AzureAdConfig`

Azure AD authentication configuration.

| Property | Type     | Description                         |
|:---------|:---------|:------------------------------------|
| tenantId | `string` | Azure AD tenant ID.                 |
| audience | `string` | Azure AD audience (application ID). |
| issuer   | `string` | Azure AD issuer URL.                |

### `_2.VpnGatewayConfig`

VPN Gateway configuration.

| Property          | Type     | Description                                                    |
|:------------------|:---------|:---------------------------------------------------------------|
| sku               | `string` | SKU name for VPN Gateway. AZ variants provide zone redundancy. |
| generation        | `string` | Generation of VPN Gateway.                                     |
| clientAddressPool | `array`  | Client address pool for P2S VPN.                               |
| vpnProtocols      | `array`  | VPN protocols to enable.                                       |

### `_2.VpnIpsecPolicy`

IPsec/IKE settings applied to VPN tunnels.

| Property          | Type     | Description                                             |
|:------------------|:---------|:--------------------------------------------------------|
| dhGroup           | `string` | Diffie-Hellman group for the IKE phase.                 |
| ikeEncryption     | `string` | IKE phase encryption algorithm.                         |
| ikeIntegrity      | `string` | IKE phase integrity algorithm.                          |
| ipsecEncryption   | `string` | IPsec phase encryption algorithm.                       |
| ipsecIntegrity    | `string` | IPsec phase integrity algorithm.                        |
| pfsGroup          | `string` | Perfect forward secrecy group.                          |
| saDataSizeKb      | `int`    | Optional data size threshold in kilobytes for rekeying. |
| saLifetimeSeconds | `int`    | Optional lifetime in seconds before rekeying the SA.    |

### `_2.VpnSiteBgpSettings`

BGP settings for a VPN site connection.

| Property    | Type     | Description                                                    |
|:------------|:---------|:---------------------------------------------------------------|
| asn         | `int`    | Autonomous system number advertised by the on-premises device. |
| peerAddress | `string` | Peer address Azure uses for BGP sessions.                      |
| peerWeight  | `int`    | Optional weight applied to the BGP peer.                       |

### `_2.VpnSiteConnection`

Site-to-site VPN connection definition.

| Property                | Type                                           | Description                                                        |
|:------------------------|:-----------------------------------------------|:-------------------------------------------------------------------|
| name                    | `string`                                       | Friendly name for the on-premises site.                            |
| addressSpaces           | `array`                                        | Address spaces reachable through the site.                         |
| sharedKeyReference      | `string`                                       | Reference key used to look up the shared key input.                |
| connectionMode          | `string`                                       | Optional connection mode (defaults to Default).                    |
| dpdTimeoutSeconds       | `int`                                          | Optional DPD timeout in seconds.                                   |
| gatewayFqdn             | `string`                                       | Optional fully qualified domain name for the on-premises gateway.  |
| gatewayIpAddress        | `string`                                       | Optional public IP address for the on-premises gateway.            |
| ikeProtocol             | `string`                                       | IKE protocol version (defaults to IKEv2).                          |
| usePolicyBasedSelectors | `bool`                                         | Whether to use policy-based traffic selectors (defaults to false). |
| bgpSettings             | `[_2.VpnSiteBgpSettings](#user-defined-types)` | Optional BGP configuration for the site.                           |
| ipsecPolicy             | `[_2.VpnIpsecPolicy](#user-defined-types)`     | Optional IPsec policy override for the site.                       |

### `_3.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                    | Type     | Description                                                                |
|:------------------------|:---------|:---------------------------------------------------------------------------|
| resourceGroup           | `object` | The resource group containing the networking and VPN gateway resources.    |
| virtualNetwork          | `object` | The virtual network object (id, name).                                     |
| subnetId                | `string` | The ID of the subnet used for private endpoints and workloads.             |
| vpnGateway              | `object` | The VPN Gateway configuration and details.                                 |
| vpnGatewayPublicIp      | `string` | The public IP address of the VPN Gateway.                                  |
| vpnClientConnectionInfo | `object` | Client address pool, protocols, and public IP needed to configure clients. |

<!-- END_BICEP_DOCS -->