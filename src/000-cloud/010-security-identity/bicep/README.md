<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# IoT Operations Cloud Requirements Component

Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.

## Parameters

| Name                                             | Description                                                                                            | Type                               | Default                                                                                                                          | Required |
|:-------------------------------------------------|:-------------------------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                                           | The common component configuration.                                                                    | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| shouldCreateArcOnboardingUami                    | Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.              | `bool`                             | `true`                                                                                                                           | no       |
| shouldCreateKeyVault                             | Whether or not to create a new Key Vault for the Secret Sync Extension.                                | `bool`                             | `true`                                                                                                                           | no       |
| keyVaultName                                     | The name of the Key Vault.                                                                             | `string`                           | [format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| keyVaultResourceGroupName                        | The name for the Resource Group for the Key Vault.                                                     | `string`                           | [resourceGroup().name]                                                                                                           | no       |
| shouldAssignAdminUserRole                        | Whether or not to create a role assignment for an admin user.                                          | `bool`                             | `true`                                                                                                                           | no       |
| adminUserObjectId                                | The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.             | `string`                           | [deployer().objectId]                                                                                                            | no       |
| shouldCreateKeyVaultPrivateEndpoint              | Whether to create a private endpoint for the Key Vault.                                                | `bool`                             | `false`                                                                                                                          | no       |
| keyVaultPrivateEndpointSubnetId                  | Subnet resource ID for the Key Vault private endpoint.                                                 | `string`                           | n/a                                                                                                                              | no       |
| keyVaultVirtualNetworkId                         | Virtual network resource ID for the Key Vault private DNS link.                                        | `string`                           | n/a                                                                                                                              | no       |
| shouldEnableKeyVaultPublicNetworkAccess          | Whether to enable public network access on the Key Vault.                                              | `bool`                             | `true`                                                                                                                           | no       |
| shouldUseNetworkSecurityPerimeter                | Whether to create a Network Security Perimeter for Key Vault and Storage Account access.               | `bool`                             | `false`                                                                                                                          | no       |
| networkSecurityPerimeterAllowedIpAddressPrefixes | IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the Network Security Perimeter. | `string[]`                         | []                                                                                                                               | no       |
| telemetry_opt_out                                | Whether to opt out of telemetry data collection.                                                       | `bool`                             | `false`                                                                                                                          | no       |

## Resources

| Name                                        | Type                              | API Version |
|:--------------------------------------------|:----------------------------------|:------------|
| identity                                    | `Microsoft.Resources/deployments` | 2025-04-01  |
| networkSecurityPerimeter                    | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVault                                    | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVaultNetworkSecurityPerimeterAssociation | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                                        | Description                                                                                                                         |
|:--------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------|
| identity                                    | Creates user-assigned managed identities for Secret Store Extension, Azure IoT Operations components and optionally Arc onboarding. |
| networkSecurityPerimeter                    | Creates a Network Security Perimeter profile with inbound access for deployment clients and resources in the current subscription.  |
| keyVault                                    | Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.                        |
| keyVaultNetworkSecurityPerimeterAssociation | Associates a supported private-link resource with a Network Security Perimeter profile in Enforced mode.                            |

## Module Details

### identity

Creates user-assigned managed identities for Secret Store Extension, Azure IoT Operations components and optionally Arc onboarding.

#### Parameters for identity

| Name                          | Description                                                                               | Type                               | Default | Required |
|:------------------------------|:------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                        | The common component configuration.                                                       | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| shouldCreateArcOnboardingUami | Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc. | `bool`                             | n/a     | yes      |

#### Resources for identity

| Name                  | Type                                               | API Version |
|:----------------------|:---------------------------------------------------|:------------|
| arcOnboardingIdentity | `Microsoft.ManagedIdentity/userAssignedIdentities` | 2023-01-31  |
| sseIdentity           | `Microsoft.ManagedIdentity/userAssignedIdentities` | 2023-01-31  |
| aioIdentity           | `Microsoft.ManagedIdentity/userAssignedIdentities` | 2023-01-31  |
| deployIdentity        | `Microsoft.ManagedIdentity/userAssignedIdentities` | 2023-01-31  |

#### Outputs for identity

| Name                      | Type     | Description                                                                                           |
|:--------------------------|:---------|:------------------------------------------------------------------------------------------------------|
| sseIdentityName           | `string` | The Secret Store Extension User Assigned Managed Identity name.                                       |
| sseIdentityId             | `string` | The Secret Store Extension User Assigned Managed Identity ID.                                         |
| sseIdentityPrincipalId    | `string` | The Secret Store Extension User Assigned Managed Identity Principal ID.                               |
| aioIdentityName           | `string` | The Azure IoT Operations User Assigned Managed Identity name.                                         |
| aioIdentityId             | `string` | The Azure IoT Operations User Assigned Managed Identity ID.                                           |
| aioIdentityPrincipalId    | `string` | The Azure IoT Operations User Assigned Managed Identity Principal ID.                                 |
| deployIdentityName        | `string` | The Deployment User Assigned Managed Identity name.                                                   |
| deployIdentityId          | `string` | The Deployment User Assigned Managed Identity ID.                                                     |
| deployIdentityPrincipalId | `string` | The Deployment User Assigned Managed Identity Principal ID.                                           |
| arcOnboardingIdentityId   | `string` | The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.   |
| arcOnboardingIdentityName | `string` | The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions. |

### networkSecurityPerimeter

Creates a Network Security Perimeter profile with inbound access for deployment clients and resources in the current subscription.

#### Parameters for networkSecurityPerimeter

| Name                     | Description                                                                           | Type                               | Default | Required |
|:-------------------------|:--------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                   | The common component configuration.                                                   | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| allowedIpAddressPrefixes | IPv4 or IPv6 CIDR prefixes allowed to access resources associated with the perimeter. | `array`                            | n/a     | yes      |

#### Resources for networkSecurityPerimeter

| Name                       | Type                                                               | API Version |
|:---------------------------|:-------------------------------------------------------------------|:------------|
| networkSecurityPerimeter   | `Microsoft.Network/networkSecurityPerimeters`                      | 2025-01-01  |
| profile                    | `Microsoft.Network/networkSecurityPerimeters/profiles`             | 2025-01-01  |
| deploymentClientAccessRule | `Microsoft.Network/networkSecurityPerimeters/profiles/accessRules` | 2025-01-01  |
| subscriptionAccessRule     | `Microsoft.Network/networkSecurityPerimeters/profiles/accessRules` | 2025-01-01  |

#### Outputs for networkSecurityPerimeter

| Name                                      | Type     | Description                                                   |
|:------------------------------------------|:---------|:--------------------------------------------------------------|
| networkSecurityPerimeterId                | `string` | The resource ID of the Network Security Perimeter.            |
| networkSecurityPerimeterResourceGroupName | `string` | The resource group containing the Network Security Perimeter. |
| profileId                                 | `string` | The resource ID of the Network Security Perimeter profile.    |

### keyVault

Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.

#### Parameters for keyVault

| Name                            | Description                                                                                | Type                               | Default | Required |
|:--------------------------------|:-------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                          | The common component configuration.                                                        | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| keyVaultName                    | The name of the Key Vault.                                                                 | `string`                           | n/a     | yes      |
| shouldAssignAdminUserRole       | Whether or not to create a role assignment for an admin user.                              | `bool`                             | n/a     | yes      |
| adminUserObjectId               | The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role. | `string`                           | n/a     | yes      |
| shouldCreatePrivateEndpoint     | Whether to create a private endpoint for the Key Vault.                                    | `bool`                             | `false` | no       |
| privateEndpointSubnetId         | Subnet resource ID for the Key Vault private endpoint.                                     | `string`                           | n/a     | no       |
| virtualNetworkId                | Virtual network resource ID for the Key Vault private DNS link.                            | `string`                           | n/a     | no       |
| shouldEnablePublicNetworkAccess | Whether public network access remains enabled on the Key Vault.                            | `bool`                             | `true`  | no       |

#### Resources for keyVault

| Name                              | Type                                                    | API Version |
|:----------------------------------|:--------------------------------------------------------|:------------|
| keyVault                          | `Microsoft.KeyVault/vaults`                             | 2023-07-01  |
| keyVaultSecretsOfficerCurrentUser | `Microsoft.Authorization/roleAssignments`               | 2022-04-01  |
| keyVaultPrivateEndpoint           | `Microsoft.Network/privateEndpoints`                    | 2023-09-01  |
| keyVaultPrivateDnsZone            | `Microsoft.Network/privateDnsZones`                     | 2020-06-01  |
| keyVaultDnsZoneLink               | `Microsoft.Network/privateDnsZones/virtualNetworkLinks` | 2020-06-01  |
| keyVaultPrivateDnsRecord          | `Microsoft.Network/privateDnsZones/A`                   | 2020-06-01  |

#### Outputs for keyVault

| Name                        | Type     | Description                                              |
|:----------------------------|:---------|:---------------------------------------------------------|
| keyVaultName                | `string` | The name of the Secret Store Extension Key Vault.        |
| keyVaultId                  | `string` | The resource ID of the Secret Store Extension Key Vault. |
| keyVaultPrivateEndpointId   | `string` | The Key Vault private endpoint ID when created.          |
| keyVaultPrivateEndpointName | `string` | The Key Vault private endpoint name when created.        |
| keyVaultPrivateEndpointIp   | `string` | The Key Vault private endpoint IP address when created.  |
| keyVaultPrivateDnsZoneId    | `string` | The Key Vault private DNS zone ID when created.          |
| keyVaultPrivateDnsZoneName  | `string` | The Key Vault private DNS zone name when created.        |

### keyVaultNetworkSecurityPerimeterAssociation

Associates a supported private-link resource with a Network Security Perimeter profile in Enforced mode.

#### Parameters for keyVaultNetworkSecurityPerimeterAssociation

| Name                                | Description                                                             | Type     | Default | Required |
|:------------------------------------|:------------------------------------------------------------------------|:---------|:--------|:---------|
| networkSecurityPerimeterName        | Name of the Network Security Perimeter.                                 | `string` | n/a     | yes      |
| networkSecurityPerimeterProfileName | Name of the Network Security Perimeter profile.                         | `string` | n/a     | yes      |
| associationName                     | Name of the Network Security Perimeter resource association.            | `string` | n/a     | yes      |
| privateLinkResourceId               | Resource ID of the private-link resource associated with the perimeter. | `string` | n/a     | yes      |

#### Resources for keyVaultNetworkSecurityPerimeterAssociation

| Name                                                                                           | Type                                                               | API Version |
|:-----------------------------------------------------------------------------------------------|:-------------------------------------------------------------------|:------------|
| [format('{0}/{1}', parameters('networkSecurityPerimeterName'), parameters('associationName'))] | `Microsoft.Network/networkSecurityPerimeters/resourceAssociations` | 2025-01-01  |

#### Outputs for keyVaultNetworkSecurityPerimeterAssociation

| Name          | Type     | Description                                                    |
|:--------------|:---------|:---------------------------------------------------------------|
| associationId | `string` | The resource ID of the Network Security Perimeter association. |

## User Defined Types

### `_1.Common`

Common settings for the components.

| Property       | Type     | Description                                                       |
|:---------------|:---------|:------------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module.                          |
| location       | `string` | Location for all resources in this module.                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod. |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...        |

## Outputs

| Name                                      | Type     | Description                                                                                           |
|:------------------------------------------|:---------|:------------------------------------------------------------------------------------------------------|
| keyVaultName                              | `string` | The name of the Secret Store Extension Key Vault.                                                     |
| keyVaultId                                | `string` | The resource ID of the Secret Store Extension Key Vault.                                              |
| keyVaultPrivateEndpointId                 | `string` | The Key Vault private endpoint ID when created.                                                       |
| keyVaultPrivateEndpointName               | `string` | The Key Vault private endpoint name when created.                                                     |
| keyVaultPrivateEndpointIp                 | `string` | The Key Vault private endpoint IP address when created.                                               |
| keyVaultPrivateDnsZoneId                  | `string` | The Key Vault private DNS zone ID when created.                                                       |
| keyVaultPrivateDnsZoneName                | `string` | The Key Vault private DNS zone name when created.                                                     |
| networkSecurityPerimeterId                | `string` | The resource ID of the Network Security Perimeter when created.                                       |
| networkSecurityPerimeterResourceGroupName | `string` | The resource group containing the Network Security Perimeter when created.                            |
| networkSecurityPerimeterProfileId         | `string` | The resource ID of the Network Security Perimeter profile when created.                               |
| sseIdentityName                           | `string` | The Secret Store Extension User Assigned Managed Identity name.                                       |
| sseIdentityId                             | `string` | The Secret Store Extension User Assigned Managed Identity ID.                                         |
| sseIdentityPrincipalId                    | `string` | The Secret Store Extension User Assigned Managed Identity Principal ID.                               |
| aioIdentityName                           | `string` | The Azure IoT Operations User Assigned Managed Identity name.                                         |
| aioIdentityId                             | `string` | The Azure IoT Operations User Assigned Managed Identity ID.                                           |
| aioIdentityPrincipalId                    | `string` | The Azure IoT Operations User Assigned Managed Identity Principal ID.                                 |
| deployIdentityName                        | `string` | The Deployment User Assigned Managed Identity name.                                                   |
| deployIdentityId                          | `string` | The Deployment User Assigned Managed Identity ID.                                                     |
| deployIdentityPrincipalId                 | `string` | The Deployment User Assigned Managed Identity Principal ID.                                           |
| arcOnboardingIdentityId                   | `string` | The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.   |
| arcOnboardingIdentityName                 | `string` | The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions. |

<!-- END_BICEP_DOCS -->