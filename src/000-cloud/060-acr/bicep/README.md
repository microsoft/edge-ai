<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# ACR Resources

Deploys Azure Container Registry (ACR) resources.

## Parameters

| Name                           | Description                                                                  | Type                                          | Default                                     | Required |
|:-------------------------------|:-----------------------------------------------------------------------------|:----------------------------------------------|:--------------------------------------------|:---------|
| common                         | The common component configuration.                                          | `[_2.Common](#user-defined-types)`            | n/a                                         | yes      |
| virtualNetworkName             | Virtual network name for subnet creation.                                    | `string`                                      | n/a                                         | yes      |
| networkSecurityGroupName       | Network security group name to apply to the subnets.                         | `string`                                      | n/a                                         | yes      |
| natGatewayId                   | NAT Gateway ID to associate with the ACR subnet for managed outbound egress. | `string`                                      | n/a                                         | no       |
| shouldCreateAcrPrivateEndpoint | Whether to create a private endpoint for the Azure Container Registry.       | `bool`                                        | `false`                                     | no       |
| containerRegistryConfig        | The settings for the Azure Container Registry.                               | `[_1.ContainerRegistry](#user-defined-types)` | [variables('_1.containerRegistryDefaults')] | no       |
| acrNetworkConfig               | Networking configuration for the ACR subnet.                                 | `[_1.AcrNetworkConfig](#user-defined-types)`  | [variables('_1.acrNetworkConfigDefaults')]  | no       |
| acrFirewallConfig              | Firewall and public access configuration for the ACR.                        | `[_1.AcrFirewallConfig](#user-defined-types)` | [variables('_1.acrFirewallConfigDefaults')] | no       |
| telemetry_opt_out              | Whether to opt out of telemetry data collection.                             | `bool`                                        | `false`                                     | no       |

## Resources

| Name              | Type                              | API Version |
|:------------------|:----------------------------------|:------------|
| network           | `Microsoft.Resources/deployments` | 2025-04-01  |
| containerRegistry | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name              | Description                                                               |
|:------------------|:--------------------------------------------------------------------------|
| network           | Creates subnets for ACR private endpoints in an existing Virtual Network. |
| containerRegistry | Deploys an Azure Container Registry with optional private endpoint.       |

## Module Details

### network

Creates subnets for ACR private endpoints in an existing Virtual Network.

#### Parameters for network

| Name                           | Description                                                                         | Type                               | Default | Required |
|:-------------------------------|:------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                         | The common component configuration.                                                 | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| virtualNetworkName             | Virtual network name for subnet creation.                                           | `string`                           | n/a     | yes      |
| networkSecurityGroupName       | Network security group name to apply to the subnets.                                | `string`                           | n/a     | yes      |
| shouldCreateAcrPrivateEndpoint | Whether to create a private endpoint subnet for the Azure Container Registry.       | `bool`                             | n/a     | yes      |
| subnetAddressPrefix            | Address prefix for the ACR subnet when creating a private endpoint.                 | `string`                           | n/a     | yes      |
| defaultOutboundAccessEnabled   | Whether default outbound internet access is enabled for the ACR subnet.             | `bool`                             | n/a     | yes      |
| shouldEnableNatGateway         | Whether to associate the ACR subnet with a NAT gateway for managed outbound egress. | `bool`                             | n/a     | yes      |
| natGatewayId                   | NAT Gateway ID to associate with the ACR subnet.                                    | `string`                           | n/a     | no       |

#### Resources for network

| Name    | Type                                        | API Version |
|:--------|:--------------------------------------------|:------------|
| snetAcr | `Microsoft.Network/virtualNetworks/subnets` | 2025-01-01  |

#### Outputs for network

| Name                | Type     | Description                                               |
|:--------------------|:---------|:----------------------------------------------------------|
| snetAcrId           | `string` | The subnet ID for the ACR private endpoint, if created.   |
| snetAcrName         | `string` | The subnet name for the ACR private endpoint, if created. |
| isNatGatewayEnabled | `bool`   | Whether the subnet has NAT Gateway associated.            |

### containerRegistry

Deploys an Azure Container Registry with optional private endpoint.

#### Parameters for containerRegistry

| Name                           | Description                                                                                              | Type                               | Default | Required |
|:-------------------------------|:---------------------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                         | The common component configuration.                                                                      | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| sku                            | The SKU for the Azure Container Registry.                                                                | `string`                           | n/a     | yes      |
| shouldCreateAcrPrivateEndpoint | Whether to create a private endpoint for the Azure Container Registry.                                   | `bool`                             | n/a     | yes      |
| virtualNetworkName             | Virtual network name for subnet creation.                                                                | `string`                           | n/a     | yes      |
| snetAcrId                      | Subnet ID for ACR private endpoint.                                                                      | `string`                           | n/a     | yes      |
| publicNetworkAccessEnabled     | Whether to enable the registry public endpoint alongside private connectivity.                           | `bool`                             | n/a     | yes      |
| allowTrustedServices           | Whether trusted Azure services can bypass registry network rules when the public endpoint is restricted. | `bool`                             | n/a     | yes      |
| allowedPublicIpRanges          | CIDR ranges permitted to reach the registry public endpoint.                                             | `array`                            | n/a     | yes      |
| shouldEnableDataEndpoints      | Whether to enable dedicated data endpoints for the registry (Premium SKU only).                          | `bool`                             | n/a     | yes      |

#### Resources for containerRegistry

| Name                | Type                                                      | API Version        |
|:--------------------|:----------------------------------------------------------|:-------------------|
| acr                 | `Microsoft.ContainerRegistry/registries`                  | 2023-01-01-preview |
| privateEndpoint     | `Microsoft.Network/privateEndpoints`                      | 2024-05-01         |
| privateDnsZone      | `Microsoft.Network/privateDnsZones`                       | 2020-06-01         |
| vnetLink            | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01         |
| privateDnsZoneGroup | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` | 2024-05-01         |

#### Outputs for containerRegistry

| Name                         | Type     | Description                                           |
|:-----------------------------|:---------|:------------------------------------------------------|
| acrId                        | `string` | The Azure Container Registry ID.                      |
| acrName                      | `string` | The Azure Container Registry name.                    |
| privateEndpointId            | `string` | The ACR private endpoint ID (if enabled).             |
| privateDnsZoneName           | `string` | The ACR private DNS zone name (if enabled).           |
| privateDnsZoneId             | `string` | The ACR private DNS zone ID (if enabled).             |
| isDataEndpointEnabled        | `bool`   | Whether data endpoints are enabled for the ACR.       |
| isPublicNetworkAccessEnabled | `bool`   | Whether public network access is enabled for the ACR. |

## User Defined Types

### `_1.AcrFirewallConfig`

Firewall and public access configuration for the ACR.

| Property                   | Type    | Description                                                                                              |
|:---------------------------|:--------|:---------------------------------------------------------------------------------------------------------|
| publicNetworkAccessEnabled | `bool`  | Whether to enable the registry public endpoint alongside private connectivity.                           |
| allowTrustedServices       | `bool`  | Whether trusted Azure services can bypass registry network rules when the public endpoint is restricted. |
| allowedPublicIpRanges      | `array` | CIDR ranges permitted to reach the registry public endpoint.                                             |
| shouldEnableDataEndpoints  | `bool`  | Whether to enable dedicated data endpoints for the registry (Premium SKU only).                          |

### `_1.AcrNetworkConfig`

Networking configuration for the ACR subnet.

| Property                     | Type     | Description                                                                         |
|:-----------------------------|:---------|:------------------------------------------------------------------------------------|
| subnetAddressPrefix          | `string` | Address prefix for the ACR subnet when creating a private endpoint.                 |
| defaultOutboundAccessEnabled | `bool`   | Whether default outbound internet access is enabled for the ACR subnet.             |
| shouldEnableNatGateway       | `bool`   | Whether to associate the ACR subnet with a NAT gateway for managed outbound egress. |

### `_1.ContainerRegistry`

The settings for the Azure Container Registry.

| Property | Type     | Description                                                                     |
|:---------|:---------|:--------------------------------------------------------------------------------|
| sku      | `string` | The SKU for the Azure Container Registry. Options are Basic, Standard, Premium. |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                       |
|:---------------|:---------|:------------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module.                          |
| location       | `string` | Location for all resources in this module.                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod. |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...        |

## Outputs

| Name                  | Type     | Description                                            |
|:----------------------|:---------|:-------------------------------------------------------|
| acrId                 | `string` | The Azure Container Registry ID.                       |
| acrName               | `string` | The Azure Container Registry name.                     |
| acrSubnetId           | `string` | The ACR subnet ID (if private endpoint is enabled).    |
| acrPrivateEndpointId  | `string` | The ACR private endpoint ID (if enabled).              |
| acrPrivateDnsZoneName | `string` | The ACR private DNS zone name (if enabled).            |
| isNatGatewayEnabled   | `bool`   | Whether NAT Gateway is associated with the ACR subnet. |

<!-- END_BICEP_DOCS -->