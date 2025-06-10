<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Virtual Network Component

Creates virtual network, subnet, and network security group resources for Azure deployments.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|networkingConfig|Networking configuration settings.|`[_1.NetworkingConfig](#user-defined-types)`|[variables('_1.networkingConfigDefaults')]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|networkSecurityGroup|`Microsoft.Network/networkSecurityGroups`|2024-05-01|
|virtualNetwork|`Microsoft.Network/virtualNetworks`|2024-05-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||

## Module Details

### attribution

## User Defined Types

### `_1.NetworkingConfig`

Networking configuration settings.

|Property|Type|Description|
| :--- | :--- | :--- |
|addressPrefix|`string`|The address prefix for the virtual network.|
|subnetAddressPrefix|`string`|The subnet address prefix.|

### `_2.Common`

Common settings for the components.

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|`string`|Prefix for all resources in this module|
|location|`string`|Location for all resources in this module|
|environment|`string`|Environment for all resources in this module: dev, test, or prod|
|instance|`string`|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|networkSecurityGroupId|`string`|The ID of the created network security group.|
|networkSecurityGroupName|`string`|The name of the created network security group.|
|subnetId|`string`|The ID of the created subnet.|
|virtualNetworkId|`string`|The ID of the created virtual network.|
|virtualNetworkName|`string`|The name of the created virtual network.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
