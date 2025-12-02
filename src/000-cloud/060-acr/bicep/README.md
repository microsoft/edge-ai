<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# ACR Resources

Deploys Azure Container Registry (ACR) resources.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupName|Network security group name to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|`false`|no|
|containerRegistryConfig|The settings for the Azure Container Registry.|`[_1.ContainerRegistry](#user-defined-types)`|[variables('_1.containerRegistryDefaults')]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|network|`Microsoft.Resources/deployments`|2025-04-01|
|containerRegistry|`Microsoft.Resources/deployments`|2025-04-01|

## Modules

|Name|Description|
| :--- | :--- |
|network|Creates subnets for ACR private endpoints in an existing Virtual Network.|
|containerRegistry|Deploys an Azure Container Registry with optional private endpoint.|

## Module Details

### network

Creates subnets for ACR private endpoints in an existing Virtual Network.

#### Parameters for network

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupName|Network security group name to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint subnet for the Azure Container Registry.|`bool`|n/a|yes|

#### Resources for network

|Name|Type|API Version|
| :--- | :--- | :--- |
|snetAcr|`Microsoft.Network/virtualNetworks/subnets`|2024-05-01|

#### Outputs for network

|Name|Type|Description|
| :--- | :--- | :--- |
|snetAcrId|`string`|The subnet ID for the ACR private endpoint, if created.|

### containerRegistry

Deploys an Azure Container Registry with optional private endpoint.

#### Parameters for containerRegistry

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|sku|The SKU for the Azure Container Registry.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|snetAcrId|Subnet ID for ACR private endpoint.|`string`|n/a|yes|

#### Resources for containerRegistry

|Name|Type|API Version|
| :--- | :--- | :--- |
|acr|`Microsoft.ContainerRegistry/registries`|2023-01-01-preview|
|privateEndpoint|`Microsoft.Network/privateEndpoints`|2022-07-01|
|privateDnsZone|`Microsoft.Network/privateDnsZones`|2020-06-01|
|vnetLink|`Microsoft.Network/privateDnsZones/virtualNetworkLinks`|2020-06-01|
|aRecord|`Microsoft.Network/privateDnsZones/A`|2020-06-01|

#### Outputs for containerRegistry

|Name|Type|Description|
| :--- | :--- | :--- |
|acrId|`string`|The Azure Container Registry ID.|
|acrName|`string`|The Azure Container Registry name.|

## User Defined Types

### `_1.ContainerRegistry`

The settings for the Azure Container Registry.

|Property|Type|Description|
| :--- | :--- | :--- |
|sku|`string`|The SKU for the Azure Container Registry. Options are Basic, Standard, Premium.|

### `_2.Common`

Common settings for the components.

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|`string`|Prefix for all resources in this module.|
|location|`string`|Location for all resources in this module.|
|environment|`string`|Environment for all resources in this module: dev, test, or prod.|
|instance|`string`|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|acrName|`string`|The Azure Container Registry name.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->