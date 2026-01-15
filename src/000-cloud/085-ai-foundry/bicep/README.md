<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Microsoft Foundry

Deploys Microsoft Foundry account with optional projects, model deployments, RAI policies, and private endpoint support.

## Parameters

| Name                        | Description                                                                                                  | Type                                        | Default                                   | Required |
|:----------------------------|:-------------------------------------------------------------------------------------------------------------|:--------------------------------------------|:------------------------------------------|:---------|
| common                      | The common component configuration.                                                                          | `[_2.Common](#user-defined-types)`          | n/a                                       | yes      |
| aiFoundryName               | Name for the AI Foundry account. If not provided, defaults to aif-{resourcePrefix}-{environment}-{instance}. | `string`                                    | n/a                                       | no       |
| aiFoundryConfig             | Configuration settings for the Microsoft Foundry account.                                                    | `[_1.AiFoundryConfig](#user-defined-types)` | [variables('_1.aiFoundryConfigDefaults')] | no       |
| tags                        | Tags to apply to all resources.                                                                              | `object`                                    | {}                                        | no       |
| telemetry_opt_out           | Whether to opt out of telemetry data collection.                                                             | `bool`                                      | `false`                                   | no       |
| aiProjects                  | Array of AI Foundry projects to create.                                                                      | `array`                                     | []                                        | no       |
| raiPolicies                 | Array of RAI policies to create.                                                                             | `array`                                     | []                                        | no       |
| modelDeployments            | Array of model deployments to create.                                                                        | `array`                                     | []                                        | no       |
| shouldCreatePrivateEndpoint | Whether to create a private endpoint for the Microsoft Foundry account.                                      | `bool`                                      | `false`                                   | no       |
| privateEndpointSubnetId     | Subnet ID for the private endpoint.                                                                          | `string`                                    |                                           | no       |
| virtualNetworkId            | Virtual network ID for DNS zone links.                                                                       | `string`                                    |                                           | no       |

## Resources

| Name                            | Type                                                      | API Version |
|:--------------------------------|:----------------------------------------------------------|:------------|
| aiFoundryAccount                | `Microsoft.CognitiveServices/accounts`                    | 2025-06-01  |
| projects                        | `Microsoft.CognitiveServices/accounts/projects`           | 2025-06-01  |
| raiPolicyResources              | `Microsoft.CognitiveServices/accounts/raiPolicies`        | 2024-10-01  |
| deployments                     | `Microsoft.CognitiveServices/accounts/deployments`        | 2025-06-01  |
| privateDnsZoneCognitiveServices | `Microsoft.Network/privateDnsZones`                       | 2020-06-01  |
| privateDnsZoneOpenAI            | `Microsoft.Network/privateDnsZones`                       | 2020-06-01  |
| privateDnsZoneAIServices        | `Microsoft.Network/privateDnsZones`                       | 2020-06-01  |
| dnsLinkCognitiveServices        | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01  |
| dnsLinkOpenAI                   | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01  |
| dnsLinkAIServices               | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01  |
| privateEndpoint                 | `Microsoft.Network/privateEndpoints`                      | 2023-05-01  |
| privateEndpointDnsGroup         | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` | 2023-05-01  |

## User Defined Types

### `_1.AiFoundryConfig`

Configuration settings for Microsoft Foundry account.

| Property                        | Type     | Description                                        |
|:--------------------------------|:---------|:---------------------------------------------------|
| sku                             | `string` | SKU name for the Microsoft Foundry account.        |
| shouldEnablePublicNetworkAccess | `bool`   | Whether to enable public network access.           |
| shouldEnableLocalAuth           | `bool`   | Whether to enable local authentication (API keys). |

### `_1.AiProject`

Configuration for a Microsoft Foundry project.

| Property    | Type     | Description                   |
|:------------|:---------|:------------------------------|
| name        | `string` | Project resource name.        |
| displayName | `string` | Display name shown in portal. |
| description | `string` | Project description.          |

### `_1.ContentFilter`

Content filter configuration.

| Property          | Type     | Description                                    |
|:------------------|:---------|:-----------------------------------------------|
| name              | `string` | Filter name: Hate, Violence, Sexual, SelfHarm. |
| enabled           | `bool`   | Whether filter is enabled.                     |
| blocking          | `bool`   | Whether filter blocks content.                 |
| severityThreshold | `string` | Severity threshold.                            |
| source            | `string` | Filter source: Prompt or Completion.           |

### `_1.ModelDeployment`

Configuration for a model deployment.

| Property             | Type     | Description               |
|:---------------------|:---------|:--------------------------|
| name                 | `string` | Deployment resource name. |
| model                | `object` | Model configuration.      |
| scale                | `object` | Scale configuration.      |
| raiPolicyName        | `string` | Optional RAI policy name. |
| versionUpgradeOption | `string` | Version upgrade option.   |

### `_1.RaiPolicy`

Configuration for a RAI policy.

| Property       | Type     | Description                    |
|:---------------|:---------|:-------------------------------|
| name           | `string` | Policy resource name.          |
| basePolicyName | `string` | Base policy to inherit from.   |
| mode           | `string` | Policy mode.                   |
| contentFilters | `array`  | Content filter configurations. |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                       |
|:---------------|:---------|:------------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module.                          |
| location       | `string` | Location for all resources in this module.                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod. |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...        |

## Outputs

| Name                 | Type     | Description                                                                |
|:---------------------|:---------|:---------------------------------------------------------------------------|
| aiFoundry            | `object` | Microsoft Foundry account object with id, name, endpoint, and principalId. |
| aiFoundryId          | `string` | Microsoft Foundry account resource ID.                                     |
| aiFoundryName        | `string` | Microsoft Foundry account name.                                            |
| aiFoundryEndpoint    | `string` | Microsoft Foundry account endpoint.                                        |
| aiFoundryPrincipalId | `string` | Microsoft Foundry account system-assigned managed identity principal ID.   |
| projectsArray        | `array`  | Array of created Microsoft Foundry projects.                               |
| raiPoliciesArray     | `array`  | Array of created RAI policies.                                             |
| deploymentsArray     | `array`  | Array of created model deployments.                                        |
| privateEndpointId    | `string` | Private endpoint resource ID.                                              |

<!-- END_BICEP_DOCS -->