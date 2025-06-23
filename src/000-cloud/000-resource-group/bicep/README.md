<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Cloud Resource Group

Creates the required resources needed for an edge IaC deployment.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|useExistingResourceGroup|Whether to use an existing resource group instead of creating a new one.|`bool`|`false`|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|
|tags|Additional tags to add to the resources.|`object`|{}|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|newResourceGroup|`Microsoft.Resources/resourceGroups`|2022-09-01|
|existingResourceGroup|`Microsoft.Resources/resourceGroups`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||

## Module Details

### attribution



## User Defined Types

### `_1.Common`

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
|resourceGroupId|`string`|The ID of the resource group.|
|resourceGroupName|`string`|The name of the resource group.|
|location|`string`|The location of the resource group.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->