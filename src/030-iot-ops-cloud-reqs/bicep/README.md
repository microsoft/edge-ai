<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# IoT Operations Cloud Requirements Component
  
Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.  

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|shouldCreateStorageAccount|Whether or not to create a new Storage Account for the ADR Schema Registry.|bool|true|no|
|storageAccountResourceGroupName|The name for the Resource Group for the Storage Account.|string|[resourceGroup().name]|no|
|storageAccountName|The name for the Storage Account used by the Schema Registry.|string|[format('st{0}', uniqueString(resourceGroup().id))]|no|
|storageAccountSettings|The settings for the new Storage Account.|[_1.StorageAccountSettings](#user-defined-types)|{"replicationType": "LRS", "tier": "Standard"}|no|
|schemaContainerName|The name for the Blob Container for schemas.|string|schemas|no|
|schemaRegistryName|The name for the ADR Schema Registry.|string|[format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|schemaRegistryNamespace|The ADLS Gen2 namespace for the ADR Schema Registry.|string|[format('srns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|shouldCreateKeyVault|Whether or not to create a new Key Vault for the Secret Sync Extension.|bool|true|no|
|keyVaultName|The name of the Key Vault.|string|[format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|keyVaultResourceGroupName|The name for the Resource Group for the Key Vault.|string|[resourceGroup().name]|no|
|shouldAssignAdminUserRole|Whether or not to create a role assignment for an admin user.|bool|true|no|
|adminUserObjectId|The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.|string|[deployer().objectId]|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|schemaRegistryStorageAccount|Microsoft.Resources/deployments|2022-09-01|
|schemaRegistry|Microsoft.Resources/deployments|2022-09-01|
|schemaRegistryRoleAssignments|Microsoft.Resources/deployments|2022-09-01|
|uami|Microsoft.Resources/deployments|2022-09-01|
|sseKeyVault|Microsoft.Resources/deployments|2022-09-01|
|sseKeyVaultRoleAssignments|Microsoft.Resources/deployments|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|schemaRegistryStorageAccount|Creates a secure storage account and blob container for storing schemas used by Azure IoT Operations.|
|schemaRegistry|Creates an Azure Device Registry (ADR) Schema Registry for storing and managing device schemas.|
|schemaRegistryRoleAssignments|Configures necessary RBAC permissions for Schema Registry to access its storage container.|
|uami|Creates user-assigned managed identities for Secret Store Extension and Azure IoT Operations components.|
|sseKeyVault|Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.|
|sseKeyVaultRoleAssignments|Configures RBAC permissions for Secret Store Extension and administrators to access Key Vault secrets.|

## Module Details

### schemaRegistryStorageAccount
  
Creates a secure storage account and blob container for storing schemas used by Azure IoT Operations.  

#### Parameters for schemaRegistryStorageAccount

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|storageAccountName|The name for the new Storage Account.|string|n/a|yes|
|storageAccountSettings|The settings for the new Storage Account.|[_1.StorageAccountSettings](#user-defined-types)|n/a|yes|
|schemaContainerName|The name for the new Blob Container for schemas.|string|n/a|yes|

#### Resources for schemaRegistryStorageAccount

|Name|Type|API Version|
| :--- | :--- | :--- |
|schemaRegistryStore::schemaBlobServices::schemaContainer|Microsoft.Storage/storageAccounts/blobServices/containers|2023-05-01|
|schemaRegistryStore::schemaBlobServices|Microsoft.Storage/storageAccounts/blobServices|2023-05-01|
|schemaRegistryStore|Microsoft.Storage/storageAccounts|2023-05-01|

#### Outputs for schemaRegistryStorageAccount

|Name|Type|Description|
| :--- | :--- | :--- |
|storageAccountName|string||
|storageAccountId|string||
|schemaContainerName|string||
|schemaContainerUrl|string||

### schemaRegistry
  
Creates an Azure Device Registry (ADR) Schema Registry for storing and managing device schemas.  

#### Parameters for schemaRegistry

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|
|storageAccountContainerUrl|The URL for the Blob Container for the schemas.|string|n/a|yes|
|schemaRegistryName|The name for the ADR Schema Registry.|string|n/a|yes|
|schemaRegistryNamespace|The ADLS Gen2 namespace for the ADR Schema Registry.|string|n/a|yes|

#### Resources for schemaRegistry

|Name|Type|API Version|
| :--- | :--- | :--- |
|schemaRegistry|Microsoft.DeviceRegistry/schemaRegistries|2024-09-01-preview|

#### Outputs for schemaRegistry

|Name|Type|Description|
| :--- | :--- | :--- |
|schemaRegistryName|string||
|schemaRegistryId|string||
|schemaRegistryPrincipalId|string||

### schemaRegistryRoleAssignments
  
Configures necessary RBAC permissions for Schema Registry to access its storage container.  

#### Parameters for schemaRegistryRoleAssignments

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|storageAccountName|The name for the Storage Account used by the Schema Registry.|string|n/a|yes|
|schemaBlobContainerName|The name for the Blob Container for the schemas.|string|n/a|yes|
|schemaRegistryPrincipalId|The Principal ID for the Schema Registry.|string|n/a|yes|

#### Resources for schemaRegistryRoleAssignments

|Name|Type|API Version|
| :--- | :--- | :--- |
|schemaRegistryStore::schemaBlobServices::schemaContainer|Microsoft.Storage/storageAccounts/blobServices/containers|2023-05-01|
|schemaRegistryStore::schemaBlobServices|Microsoft.Storage/storageAccounts/blobServices|2023-05-01|
|schemaRegistryStore|Microsoft.Storage/storageAccounts|2023-05-01|
|registryStorageContributor|Microsoft.Authorization/roleAssignments|2022-04-01|

### uami
  
Creates user-assigned managed identities for Secret Store Extension and Azure IoT Operations components.  

#### Parameters for uami

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|

#### Resources for uami

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseUami|Microsoft.ManagedIdentity/userAssignedIdentities|2023-01-31|
|aioUami|Microsoft.ManagedIdentity/userAssignedIdentities|2023-01-31|

#### Outputs for uami

|Name|Type|Description|
| :--- | :--- | :--- |
|sseUamiName|string||
|sseUamiId|string||
|sseUamiPrincipalId|string||
|aioUamiName|string||
|aioUamiId|string||
|aioUamiPrincipalId|string||

### sseKeyVault
  
Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.  

#### Parameters for sseKeyVault

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|
|keyVaultName|The name of the Key Vault.|string|n/a|yes|

#### Resources for sseKeyVault

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseKeyVault|Microsoft.KeyVault/vaults|2023-07-01|

#### Outputs for sseKeyVault

|Name|Type|Description|
| :--- | :--- | :--- |
|sseKeyVaultName|string||
|sseKeyVaultId|string||

### sseKeyVaultRoleAssignments
  
Configures RBAC permissions for Secret Store Extension and administrators to access Key Vault secrets.  

#### Parameters for sseKeyVaultRoleAssignments

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|keyVaultName|The name of the Key Vault to scope the role assignments.|string|n/a|yes|
|sseUamiPrincipalId|The Principal ID for the Secret Sync User Assigned Managed Identity.|string|n/a|yes|
|shouldAssignAdminUserRole|Whether or not to create a role assignment for an admin user.|bool|n/a|yes|
|adminUserObjectId|The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.|string|n/a|yes|

#### Resources for sseKeyVaultRoleAssignments

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseKeyVault|Microsoft.KeyVault/vaults|2023-07-01|
|keyVaultSecretsOfficerCurrentUser|Microsoft.Authorization/roleAssignments|2022-04-01|
|keyVaultReaderSseUami|Microsoft.Authorization/roleAssignments|2022-04-01|
|keyVaultSecretsUserSseUami|Microsoft.Authorization/roleAssignments|2022-04-01|

## User Defined Types

### `_1.StorageAccountSettings`
  
Settings for the Storage Account.  

|Property|Type|Description|
| :--- | :--- | :--- |
|tier|string|Tier for the Storage Account.|
|replicationType|string|Replication Type for the Storage Account.|

### `_2.Common`
  
Common settings for the components.  

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|string|Prefix for all resources in this module|
|location|string|Location for all resources in this module|
|environment|string|Environment for all resources in this module: dev, test, or prod|
|instance|string|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|adrSchemaRegistryId|string|The ADR Schema Registry ID.|
|sseKeyVaultName|string|The Key Vault ID.|
|sseUamiName|string|The Secret Sync Extension Managed Identity Name.|
|aioUamiName|string|The AIO Managed Identity Name.|
|aioUamiId|string|The User Assigned Managed Identity ID for Azure IoT Operations.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
