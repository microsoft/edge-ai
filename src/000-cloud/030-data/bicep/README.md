<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Data Component

Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|shouldCreateStorageAccount|Whether to create the Storage Account.|`bool`|`true`|no|
|storageAccountResourceGroupName|The name for the Resource Group for the Storage Account.|`string`|[if(parameters('shouldCreateStorageAccount'), resourceGroup().name, fail('storageAccountResourceGroupName required when shouldCreateStorageAccount is false'))]|no|
|storageAccountName|The name for the Storage Account used by the Schema Registry.|`string`|[if(parameters('shouldCreateStorageAccount'), format('st{0}', uniqueString(resourceGroup().id)), fail('storageAccountName required when shouldCreateStorageAccount is false'))]|no|
|storageAccountSettings|The settings for the new Storage Account.|`[_1.StorageAccountSettings](#user-defined-types)`|[variables('_1.storageAccountSettingsDefaults')]|no|
|shouldCreateSchemaRegistry|Whether to create the ADR Schema Registry.|`bool`|`true`|no|
|shouldCreateSchemaContainer|Whether to create the Blob Container for schemas.|`bool`|`true`|no|
|schemaContainerName|The name for the Blob Container for schemas.|`string`|schemas|no|
|schemaRegistryName|The name for the ADR Schema Registry.|`string`|[format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|schemaRegistryNamespace|The ADLS Gen2 namespace for the ADR Schema Registry.|`string`|[format('srns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|storageAccount|`Microsoft.Resources/deployments`|2022-09-01|
|schemaRegistry|`Microsoft.Resources/deployments`|2022-09-01|
|schemaRegistryRoleAssignment|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|storageAccount|Creates an Azure Storage Account and blob container for storing schemas.|
|schemaRegistry|Creates an Azure Device Registry (ADR) Schema Registry for storing and managing device schemas.|
|schemaRegistryRoleAssignment|Creates role assignments for the Schema Registry to access the storage account.|

## Module Details

### storageAccount

Creates an Azure Storage Account and blob container for storing schemas.

#### Parameters for storageAccount

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|storageAccountSettings|The settings for the storage account.|`[_1.StorageAccountSettings](#user-defined-types)`|[variables('_1.storageAccountSettingsDefaults')]|no|
|storageAccountName|The name of the storage account.|`string`|n/a|yes|
|shouldCreateSchemaContainer|Whether to create the Blob Container for schemas.|`bool`|n/a|yes|
|schemaContainerName|The name of the blob container for schemas.|`string`|n/a|yes|

#### Resources for storageAccount

|Name|Type|API Version|
| :--- | :--- | :--- |
|storageAccount::blobService::container|`Microsoft.Storage/storageAccounts/blobServices/containers`|2024-01-01|
|storageAccount::blobService|`Microsoft.Storage/storageAccounts/blobServices`|2024-01-01|
|storageAccount|`Microsoft.Storage/storageAccounts`|2024-01-01|

#### Outputs for storageAccount

|Name|Type|Description|
| :--- | :--- | :--- |
|storageAccountName|`string`|The name of the storage account.|
|storageAccountId|`string`|The resource ID of the storage account.|
|primaryBlobEndpoint|`string`|The primary blob endpoint URL of the storage account.|
|schemaContainerName|`string`|The name of the schema container.|
|schemaContainerId|`string`|The resource ID of the schema container, or null if not created.|

### schemaRegistry

Creates an Azure Device Registry (ADR) Schema Registry for storing and managing device schemas.

#### Parameters for schemaRegistry

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|storageAccountContainerUrl|The URL for the Blob Container for the schemas.|`string`|n/a|yes|
|schemaRegistryName|The name for the ADR Schema Registry.|`string`|n/a|yes|
|schemaRegistryNamespace|The ADLS Gen2 namespace for the ADR Schema Registry.|`string`|n/a|yes|

#### Resources for schemaRegistry

|Name|Type|API Version|
| :--- | :--- | :--- |
|schemaRegistry|`Microsoft.DeviceRegistry/schemaRegistries`|2024-09-01-preview|

#### Outputs for schemaRegistry

|Name|Type|Description|
| :--- | :--- | :--- |
|schemaRegistryName|`string`|The name of the schema registry.|
|schemaRegistryId|`string`|The resource ID of the schema registry.|
|schemaRegistryPrincipalId|`string`|The principal ID of the schema registry managed identity.|

### schemaRegistryRoleAssignment

Creates role assignments for the Schema Registry to access the storage account.

#### Parameters for schemaRegistryRoleAssignment

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|storageAccountName|The name of the storage account.|`string`|n/a|yes|
|schemaBlobContainerName|The name of the blob container for schemas.|`string`|n/a|yes|
|schemaRegistryPrincipalId|The principal ID of the schema registry.|`string`|n/a|yes|

#### Resources for schemaRegistryRoleAssignment

|Name|Type|API Version|
| :--- | :--- | :--- |
|[guid(parameters('schemaBlobContainerName'), parameters('schemaRegistryPrincipalId'), variables('storageBlobDataContributorRoleId'))]|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for schemaRegistryRoleAssignment

|Name|Type|Description|
| :--- | :--- | :--- |
|roleAssignmentId|`string`|The resource ID of the role assignment.|

## User Defined Types

### `_1.SchemaRegistrySettings`

Schema Registry settings.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|The name of the schema registry.|
|namespace|`string`|The namespace for the schema registry.|
|containerName|`string`|The name of the container for schemas.|

### `_1.StorageAccountSettings`

Settings for the storage account.

|Property|Type|Description|
| :--- | :--- | :--- |
|tier|`string`|The tier of the storage account: Standard or Premium.|
|replicationType|`string`|The replication type of the storage account: LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS.|

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
|schemaRegistryName|`string`|The ADR Schema Registry Name.|
|schemaRegistryId|`string`|The ADR Schema Registry ID.|
|storageAccountName|`string`|The Storage Account Name.|
|storageAccountId|`string`|The Storage Account ID.|
|schemaContainerName|`string`|The Schema Container Name.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->