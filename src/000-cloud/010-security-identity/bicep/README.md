<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# IoT Operations Cloud Requirements Component

Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|onboardIdentityConfig|Settings for the onboarding identity.|`[_1.OnboardIdentitySettings](#user-defined-types)`|[variables('_1.onboardIdentityDefaults')]|no|
|shouldCreateKeyVault|Whether or not to create a new Key Vault for the Secret Sync Extension.|`bool`|`true`|no|
|keyVaultName|The name of the Key Vault.|`string`|[format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|keyVaultResourceGroupName|The name for the Resource Group for the Key Vault.|`string`|[resourceGroup().name]|no|
|shouldAssignAdminUserRole|Whether or not to create a role assignment for an admin user.|`bool`|`true`|no|
|adminUserObjectId|The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.|`string`|[deployer().objectId]|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|identity|`Microsoft.Resources/deployments`|2022-09-01|
|keyVault|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|identity|Creates user-assigned managed identities for Secret Store Extension and Azure IoT Operations components.|
|keyVault|Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.|

## Module Details

### identity

Creates user-assigned managed identities for Secret Store Extension and Azure IoT Operations components.

#### Parameters for identity

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|identityType|The identity type to use for onboarding the cluster to Azure Arc.|`[_1.OnboardIdentityType](#user-defined-types)`|n/a|yes|

#### Resources for identity

|Name|Type|API Version|
| :--- | :--- | :--- |
|arcOnboardingApp|`Microsoft.Graph/applications@v1.0`||
|arcOnboardingClientSp|`Microsoft.Graph/servicePrincipals@v1.0`||
|arcOnboardingIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|aioIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|

#### Outputs for identity

|Name|Type|Description|
| :--- | :--- | :--- |
|sseIdentityName|`string`|The Secret Store Extension User Assigned Managed Identity name.|
|sseIdentityId|`string`|The Secret Store Extension User Assigned Managed Identity ID.|
|sseIdentityPrincipalId|`string`|The Secret Store Extension User Assigned Managed Identity Principal ID.|
|aioIdentityName|`string`|The Azure IoT Operations User Assigned Managed Identity name.|
|aioIdentityId|`string`|The Azure IoT Operations User Assigned Managed Identity ID.|
|aioIdentityPrincipalId|`string`|The Azure IoT Operations User Assigned Managed Identity Principal ID.|
|arcOnboardingIdentityId|`string`|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingIdentityName|`string`|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|servicePrincipalClientId|`string`|The Service Principal App (Client) ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

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

### `_1.OnboardIdentitySettings`

Settings for onboarding identity creation.

|Property|Type|Description|
| :--- | :--- | :--- |
|shouldCreate|`bool`|Whether or not to create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc.|
|identityType|`[_1.OnboardIdentityType](#user-defined-types)`|Identity type to use for onboarding the cluster to Azure Arc.|

### `_1.OnboardIdentityType`

Identity type to use for onboarding the cluster to Azure Arc. Allowed values: "id" (User Assigned Managed Identity) or "sp" (Service Principal).

### `_1.StorageAccountSettings`

Settings for the Storage Account.

|Property|Type|Description|
| :--- | :--- | :--- |
|tier|`string`|Tier for the Storage Account.|
|replicationType|`string`|Replication Type for the Storage Account.|

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
|keyVaultName|`string`|The name of the Secret Store Extension Key Vault.|
|keyVaultId|`string`|The resource ID of the Secret Store Extension Key Vault.|
|sseIdentityName|`string`|The Secret Store Extension User Assigned Managed Identity name.|
|sseIdentityId|`string`|The Secret Store Extension User Assigned Managed Identity ID.|
|sseIdentityPrincipalId|`string`|The Secret Store Extension User Assigned Managed Identity Principal ID.|
|aioIdentityName|`string`|The Azure IoT Operations User Assigned Managed Identity name.|
|aioIdentityId|`string`|The Azure IoT Operations User Assigned Managed Identity ID.|
|aioIdentityPrincipalId|`string`|The Azure IoT Operations User Assigned Managed Identity Principal ID.|
|arcOnboardingIdentityId|`string`|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingIdentityName|`string`|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|servicePrincipalClientId|`string`|The Service Principal App (Client) ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->