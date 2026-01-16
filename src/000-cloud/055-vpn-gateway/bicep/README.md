<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# VPN Gateway Component

Creates a VPN Gateway with Point-to-Site and optional Site-to-Site connectivity.
Ths component currently only supports Azure AD (Entra ID) authentication for Point-to-Site VPN connections.

## Parameters

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

## Resources

| Name       | Type                              | API Version |
|:-----------|:----------------------------------|:------------|
| vpnGateway | `Microsoft.Resources/deployments` | 2025-04-01  |
| siteToSite | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name       | Description                                                                    |
|:-----------|:-------------------------------------------------------------------------------|
| vpnGateway | Provision the VPN gateway, gateway subnet, and supporting public IP resources. |
| siteToSite | Creates local network gateways and VPN connections for each configured site.   |

## Module Details

### vpnGateway

Provision the VPN gateway, gateway subnet, and supporting public IP resources.

#### Parameters for vpnGateway

| Name                         | Description                                                         | Type                                         | Default | Required |
|:-----------------------------|:--------------------------------------------------------------------|:---------------------------------------------|:--------|:---------|
| common                       | Common component configuration for naming and location.             | `[_2.Common](#user-defined-types)`           | n/a     | yes      |
| vpnGatewayConfig             | VPN Gateway configuration settings.                                 | `[_1.VpnGatewayConfig](#user-defined-types)` | n/a     | yes      |
| virtualNetworkName           | Name of the existing virtual network containing the gateway subnet. | `string`                                     | n/a     | yes      |
| gatewaySubnetAddressPrefix   | Address prefix applied to the GatewaySubnet resource.               | `string`                                     | n/a     | yes      |
| defaultOutboundAccessEnabled | Whether to enable default outbound access on the gateway subnet.    | `bool`                                       | n/a     | yes      |
| azureAdConfig                | Azure AD configuration values (audience, issuer, tenant).           | `[_1.AzureAdConfig](#user-defined-types)`    | n/a     | yes      |
| tags                         | Resource tags applied to all created assets.                        | `object`                                     | n/a     | yes      |

#### Resources for vpnGateway

| Name          | Type                                        | API Version |
|:--------------|:--------------------------------------------|:------------|
| gatewaySubnet | `Microsoft.Network/virtualNetworks/subnets` | 2024-05-01  |
| publicIp      | `Microsoft.Network/publicIPAddresses`       | 2024-05-01  |
| vpnGateway    | `Microsoft.Network/virtualNetworkGateways`  | 2024-05-01  |

#### Outputs for vpnGateway

| Name                 | Type     | Description                                                |
|:---------------------|:---------|:-----------------------------------------------------------|
| vpnGateway           | `object` | VPN Gateway resource object.                               |
| vpnGatewayId         | `string` | VPN Gateway resource ID.                                   |
| vpnGatewayName       | `string` | VPN Gateway resource name.                                 |
| gatewaySubnetId      | `string` | Gateway subnet resource ID.                                |
| publicIpAddress      | `string` | VPN Gateway public IP address.                             |
| clientConnectionInfo | `object` | VPN client connection metadata mirroring Terraform output. |

### siteToSite

Creates local network gateways and VPN connections for each configured site.

#### Parameters for siteToSite

| Name                      | Description                                                | Type                                       | Default | Required |
|:--------------------------|:-----------------------------------------------------------|:-------------------------------------------|:--------|:---------|
| common                    | Common component configuration for naming conventions.     | `[_2.Common](#user-defined-types)`         | n/a     | yes      |
| location                  | Azure region for all created resources.                    | `string`                                   | n/a     | yes      |
| tags                      | Resource tags applied to all site-to-site assets.          | `object`                                   | n/a     | yes      |
| vpnGatewayId              | VPN Gateway resource ID used for the site connections.     | `string`                                   | n/a     | yes      |
| vpnSiteConnections        | Site-to-site VPN connection definitions.                   | `array`                                    | n/a     | yes      |
| vpnSiteDefaultIpsecPolicy | Fallback IPsec policy applied when sites omit an override. | `[_1.VpnIpsecPolicy](#user-defined-types)` | n/a     | no       |
| vpnSiteSharedKeys         | Pre-shared keys keyed by sharedKeyReference values.        | `secureObject`                             | n/a     | yes      |

#### Resources for siteToSite

| Name                | Type                                     | API Version |
|:--------------------|:-----------------------------------------|:------------|
| localNetworkGateway | `Microsoft.Network/localNetworkGateways` | 2024-05-01  |
| vpnConnections      | `Microsoft.Network/connections`          | 2024-05-01  |

#### Outputs for siteToSite

| Name                 | Type     | Description                                                  |
|:---------------------|:---------|:-------------------------------------------------------------|
| localNetworkGateways | `object` | Local network gateway metadata keyed by VPN site name.       |
| siteConnections      | `object` | Site-to-site VPN connection metadata keyed by VPN site name. |

## User Defined Types

### `_1.AzureAdConfig`

Azure AD authentication configuration.

| Property | Type     | Description                         |
|:---------|:---------|:------------------------------------|
| tenantId | `string` | Azure AD tenant ID.                 |
| audience | `string` | Azure AD audience (application ID). |
| issuer   | `string` | Azure AD issuer URL.                |

### `_1.VpnGatewayConfig`

VPN Gateway configuration.

| Property          | Type     | Description                                                    |
|:------------------|:---------|:---------------------------------------------------------------|
| sku               | `string` | SKU name for VPN Gateway. AZ variants provide zone redundancy. |
| generation        | `string` | Generation of VPN Gateway.                                     |
| clientAddressPool | `array`  | Client address pool for P2S VPN.                               |
| vpnProtocols      | `array`  | VPN protocols to enable.                                       |

### `_1.VpnIpsecPolicy`

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

### `_1.VpnSiteBgpSettings`

BGP settings for a VPN site connection.

| Property    | Type     | Description                                                    |
|:------------|:---------|:---------------------------------------------------------------|
| asn         | `int`    | Autonomous system number advertised by the on-premises device. |
| peerAddress | `string` | Peer address Azure uses for BGP sessions.                      |
| peerWeight  | `int`    | Optional weight applied to the BGP peer.                       |

### `_1.VpnSiteConnection`

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
| bgpSettings             | `[_1.VpnSiteBgpSettings](#user-defined-types)` | Optional BGP configuration for the site.                           |
| ipsecPolicy             | `[_1.VpnIpsecPolicy](#user-defined-types)`     | Optional IPsec policy override for the site.                       |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                       |
|:---------------|:---------|:------------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module.                          |
| location       | `string` | Location for all resources in this module.                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod. |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc.          |

## Outputs

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

<!-- END_BICEP_DOCS -->