<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# IoT Operations Cloud Requirements Component

Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|shouldCreateArcOnboardingUami|Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.|`bool`|`true`|no|
|shouldCreateKeyVault|Whether or not to create a new Key Vault for the Secret Sync Extension.|`bool`|`true`|no|
|keyVaultName|The name of the Key Vault.|`string`|[format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|keyVaultResourceGroupName|The name for the Resource Group for the Key Vault.|`string`|[resourceGroup().name]|no|
|shouldAssignAdminUserRole|Whether or not to create a role assignment for an admin user.|`bool`|`true`|no|
|adminUserObjectId|The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.|`string`|[deployer().objectId]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|identity|`Microsoft.Resources/deployments`|2022-09-01|
|keyVault|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||
|identity|Creates user-assigned managed identities for Secret Store Extension, Azure IoT Operations components and optionally Arc onboarding.|
|keyVault|Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.|

## Module Details

### attribution

### identity

Creates user-assigned managed identities for Secret Store Extension, Azure IoT Operations components and optionally Arc onboarding.

#### Parameters for identity

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|shouldCreateArcOnboardingUami|Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.|`bool`|n/a|yes|

#### Resources for identity

|Name|Type|API Version|
| :--- | :--- | :--- |
|arcOnboardingIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|aioIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|deployIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|

#### Outputs for identity

|Name|Type|Description|
| :--- | :--- | :--- |
|sseIdentityName|`string`|The Secret Store Extension User Assigned Managed Identity name.|
|sseIdentityId|`string`|The Secret Store Extension User Assigned Managed Identity ID.|
|sseIdentityPrincipalId|`string`|The Secret Store Extension User Assigned Managed Identity Principal ID.|
|aioIdentityName|`string`|The Azure IoT Operations User Assigned Managed Identity name.|
|aioIdentityId|`string`|The Azure IoT Operations User Assigned Managed Identity ID.|
|aioIdentityPrincipalId|`string`|The Azure IoT Operations User Assigned Managed Identity Principal ID.|
|deployIdentityName|`string`|The Deployment User Assigned Managed Identity name.|
|deployIdentityId|`string`|The Deployment User Assigned Managed Identity ID.|
|deployIdentityPrincipalId|`string`|The Deployment User Assigned Managed Identity Principal ID.|
|arcOnboardingIdentityId|`string`|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingIdentityName|`string`|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

### keyVault

Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.

#### Parameters for keyVault

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|keyVaultName|The name of the Key Vault.|`string`|n/a|yes|
|shouldAssignAdminUserRole|Whether or not to create a role assignment for an admin user.|`bool`|n/a|yes|
|adminUserObjectId|The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.|`string`|n/a|yes|

#### Resources for keyVault

|Name|Type|API Version|
| :--- | :--- | :--- |
|keyVault|`Microsoft.KeyVault/vaults`|2023-07-01|
|keyVaultSecretsOfficerCurrentUser|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for keyVault

|Name|Type|Description|
| :--- | :--- | :--- |
|keyVaultName|`string`|The name of the Secret Store Extension Key Vault.|
|keyVaultId|`string`|The resource ID of the Secret Store Extension Key Vault.|

## User Defined Types

### `_1.Common`

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
|keyVaultName|`string`|The name of the Secret Store Extension Key Vault.|
|keyVaultId|`string`|The resource ID of the Secret Store Extension Key Vault.|
|sseIdentityName|`string`|The Secret Store Extension User Assigned Managed Identity name.|
|sseIdentityId|`string`|The Secret Store Extension User Assigned Managed Identity ID.|
|sseIdentityPrincipalId|`string`|The Secret Store Extension User Assigned Managed Identity Principal ID.|
|aioIdentityName|`string`|The Azure IoT Operations User Assigned Managed Identity name.|
|aioIdentityId|`string`|The Azure IoT Operations User Assigned Managed Identity ID.|
|aioIdentityPrincipalId|`string`|The Azure IoT Operations User Assigned Managed Identity Principal ID.|
|deployIdentityName|`string`|The Deployment User Assigned Managed Identity name.|
|deployIdentityId|`string`|The Deployment User Assigned Managed Identity ID.|
|deployIdentityPrincipalId|`string`|The Deployment User Assigned Managed Identity Principal ID.|
|arcOnboardingIdentityId|`string`|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingIdentityName|`string`|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
