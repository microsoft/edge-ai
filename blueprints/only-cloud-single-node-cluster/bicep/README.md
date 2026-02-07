<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Full Cloud Single Cluster Blueprint

Deploys a complete end-to-end cloud environment as preparation for Azure IoT Operations on a single-node.

## Parameters

| Name                           | Description                                                                         | Type                               | Default                                                                                                                          | Required |
|:-------------------------------|:------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                         | The common component configuration.                                                 | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| resourceGroupName              | The name for the resource group. If not provided, a default name will be generated. | `string`                           | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| useExistingResourceGroup       | Whether to use an existing resource group instead of creating a new one.            | `bool`                             | `false`                                                                                                                          | no       |
| telemetry_opt_out              | Whether to opt-out of telemetry. Set to true to disable telemetry.                  | `bool`                             | `false`                                                                                                                          | no       |
| adminPassword                  | Password used for the host VM.                                                      | `securestring`                     | n/a                                                                                                                              | yes      |
| shouldCreateAcrPrivateEndpoint | Whether to create a private endpoint for the Azure Container Registry.              | `bool`                             | `false`                                                                                                                          | no       |
| shouldCreateAks                | Whether to create an Azure Kubernetes Service cluster.                              | `bool`                             | `false`                                                                                                                          | no       |

## Resources

| Name                  | Type                              | API Version |
|:----------------------|:----------------------------------|:------------|
| cloudResourceGroup    | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudSecurityIdentity | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudObservability    | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudData             | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudMessaging        | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudNetworking       | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudVmHost           | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudAcr              | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudKubernetes       | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                  | Description                                                                                                                                                                                         |
|:----------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cloudResourceGroup    | Creates the required resources needed for an edge IaC deployment.                                                                                                                                   |
| cloudSecurityIdentity | Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.                                           |
| cloudObservability    | Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection. |
| cloudData             | Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.                                                                                     |
| cloudMessaging        | Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.                                                                      |
| cloudNetworking       | Creates virtual network, subnet, and network security group resources for Azure deployments.                                                                                                        |
| cloudVmHost           | Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.                                                                                        |
| cloudAcr              | Deploys Azure Container Registry (ACR) resources.                                                                                                                                                   |
| cloudKubernetes       | Deploys optionally Azure Kubernetes Service (AKS) resources.                                                                                                                                        |

## Module Details

### cloudResourceGroup

Creates the required resources needed for an edge IaC deployment.

#### Parameters for cloudResourceGroup

| Name                     | Description                                                                         | Type                               | Default                                                                                                                          | Required |
|:-------------------------|:------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                   | The common component configuration.                                                 | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| resourceGroupName        | The name for the resource group. If not provided, a default name will be generated. | `string`                           | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| useExistingResourceGroup | Whether to use an existing resource group instead of creating a new one.            | `bool`                             | `false`                                                                                                                          | no       |
| telemetry_opt_out        | Whether to opt out of telemetry data collection.                                    | `bool`                             | `false`                                                                                                                          | no       |
| tags                     | Additional tags to add to the resources.                                            | `object`                           | {}                                                                                                                               | no       |

#### Outputs for cloudResourceGroup

| Name              | Type     | Description                         |
|:------------------|:---------|:------------------------------------|
| resourceGroupId   | `string` | The ID of the resource group.       |
| resourceGroupName | `string` | The name of the resource group.     |
| location          | `string` | The location of the resource group. |

### cloudSecurityIdentity

Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.

#### Parameters for cloudSecurityIdentity

| Name                                    | Description                                                                                | Type                               | Default                                                                                                                          | Required |
|:----------------------------------------|:-------------------------------------------------------------------------------------------|:-----------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                                  | The common component configuration.                                                        | `[_1.Common](#user-defined-types)` | n/a                                                                                                                              | yes      |
| shouldCreateArcOnboardingUami           | Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.  | `bool`                             | `true`                                                                                                                           | no       |
| shouldCreateKeyVault                    | Whether or not to create a new Key Vault for the Secret Sync Extension.                    | `bool`                             | `true`                                                                                                                           | no       |
| keyVaultName                            | The name of the Key Vault.                                                                 | `string`                           | [format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| keyVaultResourceGroupName               | The name for the Resource Group for the Key Vault.                                         | `string`                           | [resourceGroup().name]                                                                                                           | no       |
| shouldAssignAdminUserRole               | Whether or not to create a role assignment for an admin user.                              | `bool`                             | `true`                                                                                                                           | no       |
| adminUserObjectId                       | The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role. | `string`                           | [deployer().objectId]                                                                                                            | no       |
| shouldCreateKeyVaultPrivateEndpoint     | Whether to create a private endpoint for the Key Vault.                                    | `bool`                             | `false`                                                                                                                          | no       |
| keyVaultPrivateEndpointSubnetId         | Subnet resource ID for the Key Vault private endpoint.                                     | `string`                           | n/a                                                                                                                              | no       |
| keyVaultVirtualNetworkId                | Virtual network resource ID for the Key Vault private DNS link.                            | `string`                           | n/a                                                                                                                              | no       |
| shouldEnableKeyVaultPublicNetworkAccess | Whether to enable public network access on the Key Vault.                                  | `bool`                             | `true`                                                                                                                           | no       |
| telemetry_opt_out                       | Whether to opt out of telemetry data collection.                                           | `bool`                             | `false`                                                                                                                          | no       |

#### Resources for cloudSecurityIdentity

| Name     | Type                              | API Version |
|:---------|:----------------------------------|:------------|
| identity | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVault | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudSecurityIdentity

| Name                        | Type     | Description                                                                                           |
|:----------------------------|:---------|:------------------------------------------------------------------------------------------------------|
| keyVaultName                | `string` | The name of the Secret Store Extension Key Vault.                                                     |
| keyVaultId                  | `string` | The resource ID of the Secret Store Extension Key Vault.                                              |
| keyVaultPrivateEndpointId   | `string` | The Key Vault private endpoint ID when created.                                                       |
| keyVaultPrivateEndpointName | `string` | The Key Vault private endpoint name when created.                                                     |
| keyVaultPrivateEndpointIp   | `string` | The Key Vault private endpoint IP address when created.                                               |
| keyVaultPrivateDnsZoneId    | `string` | The Key Vault private DNS zone ID when created.                                                       |
| keyVaultPrivateDnsZoneName  | `string` | The Key Vault private DNS zone name when created.                                                     |
| sseIdentityName             | `string` | The Secret Store Extension User Assigned Managed Identity name.                                       |
| sseIdentityId               | `string` | The Secret Store Extension User Assigned Managed Identity ID.                                         |
| sseIdentityPrincipalId      | `string` | The Secret Store Extension User Assigned Managed Identity Principal ID.                               |
| aioIdentityName             | `string` | The Azure IoT Operations User Assigned Managed Identity name.                                         |
| aioIdentityId               | `string` | The Azure IoT Operations User Assigned Managed Identity ID.                                           |
| aioIdentityPrincipalId      | `string` | The Azure IoT Operations User Assigned Managed Identity Principal ID.                                 |
| deployIdentityName          | `string` | The Deployment User Assigned Managed Identity name.                                                   |
| deployIdentityId            | `string` | The Deployment User Assigned Managed Identity ID.                                                     |
| deployIdentityPrincipalId   | `string` | The Deployment User Assigned Managed Identity Principal ID.                                           |
| arcOnboardingIdentityId     | `string` | The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.   |
| arcOnboardingIdentityName   | `string` | The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions. |

### cloudObservability

Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.

#### Parameters for cloudObservability

| Name                             | Description                                                                                   | Type                               | Default                                                                                                                                                                                                                                                                                                                                               | Required |
|:---------------------------------|:----------------------------------------------------------------------------------------------|:-----------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                           | The common component configuration.                                                           | `[_1.Common](#user-defined-types)` | n/a                                                                                                                                                                                                                                                                                                                                                   | yes      |
| tags                             | Additional tags to add to the resources.                                                      | `object`                           | {}                                                                                                                                                                                                                                                                                                                                                    | no       |
| logRetentionInDays               | Log Analytics Workspace retention in days                                                     | `int`                              | 30                                                                                                                                                                                                                                                                                                                                                    | no       |
| dailyQuotaInGb                   | Log Analytics Workspace daily quota in GB                                                     | `int`                              | 10                                                                                                                                                                                                                                                                                                                                                    | no       |
| grafanaMajorVersion              | Grafana major version                                                                         | `string`                           | 11                                                                                                                                                                                                                                                                                                                                                    | no       |
| grafanaAdminPrincipalId          | The principalId (objectId) of the user or service principal to assign the Grafana Admin role. | `string`                           | n/a                                                                                                                                                                                                                                                                                                                                                   | no       |
| logsDataCollectionRuleNamespaces | List of cluster namespaces to be exposed in the log analytics workspace                       | `array`                            | ['kube-system', 'gatekeeper-system', 'azure-arc', 'azure-iot-operations']                                                                                                                                                                                                                                                                             | no       |
| logsDataCollectionRuleStreams    | List of streams to be enabled in the log analytics workspace                                  | `array`                            | ['Microsoft-ContainerLog', 'Microsoft-ContainerLogV2', 'Microsoft-KubeEvents', 'Microsoft-KubePodInventory', 'Microsoft-KubeNodeInventory', 'Microsoft-KubePVInventory', 'Microsoft-KubeServices', 'Microsoft-KubeMonAgentEvents', 'Microsoft-InsightsMetrics', 'Microsoft-ContainerInventory', 'Microsoft-ContainerNodeInventory', 'Microsoft-Perf'] | no       |
| shouldEnablePrivateEndpoints     | Whether to enable private endpoints for Azure Monitor resources.                              | `bool`                             | `false`                                                                                                                                                                                                                                                                                                                                               | no       |
| privateEndpointSubnetId          | Subnet resource ID used for the observability private endpoint.                               | `string`                           | n/a                                                                                                                                                                                                                                                                                                                                                   | no       |
| virtualNetworkId                 | Virtual network resource ID for private DNS links.                                            | `string`                           | n/a                                                                                                                                                                                                                                                                                                                                                   | no       |
| telemetry_opt_out                | Whether to opt out of telemetry data collection.                                              | `bool`                             | `false`                                                                                                                                                                                                                                                                                                                                               | no       |

#### Resources for cloudObservability

| Name                                          | Type                                                      | API Version        |
|:----------------------------------------------|:----------------------------------------------------------|:-------------------|
| monitorWorkspace                              | `Microsoft.Monitor/accounts`                              | 2023-04-03         |
| logAnalytics                                  | `Microsoft.OperationalInsights/workspaces`                | 2025-02-01         |
| grafana                                       | `Microsoft.Dashboard/grafana`                             | 2024-10-01         |
| containerInsightsSolution                     | `Microsoft.OperationsManagement/solutions`                | 2015-11-01-preview |
| grafanaLogsReaderRole                         | `Microsoft.Authorization/roleAssignments`                 | 2022-04-01         |
| grafanaMetricsReaderRole                      | `Microsoft.Authorization/roleAssignments`                 | 2022-04-01         |
| grafanaAdminRole                              | `Microsoft.Authorization/roleAssignments`                 | 2022-04-01         |
| dataCollectionEndpoint                        | `Microsoft.Insights/dataCollectionEndpoints`              | 2023-03-11         |
| logsDataCollectionRule                        | `Microsoft.Insights/dataCollectionRules`                  | 2023-03-11         |
| metricsDataCollectionRule                     | `Microsoft.Insights/dataCollectionRules`                  | 2023-03-11         |
| monitorPrivateLinkScope                       | `Microsoft.Insights/privateLinkScopes`                    | 2021-09-01         |
| monitorPrivateLinkScopeLogAnalytics           | `Microsoft.Insights/privateLinkScopes/scopedResources`    | 2021-09-01         |
| monitorPrivateLinkScopeDataCollectionEndpoint | `Microsoft.Insights/privateLinkScopes/scopedResources`    | 2021-09-01         |
| monitorPrivateDnsZoneMonitorAzure             | `Microsoft.Network/privateDnsZones`                       | 2020-06-01         |
| monitorPrivateDnsZoneOms                      | `Microsoft.Network/privateDnsZones`                       | 2020-06-01         |
| monitorPrivateDnsZoneOds                      | `Microsoft.Network/privateDnsZones`                       | 2020-06-01         |
| monitorPrivateDnsZoneAgentsvc                 | `Microsoft.Network/privateDnsZones`                       | 2020-06-01         |
| monitorPrivateDnsZoneBlob                     | `Microsoft.Network/privateDnsZones`                       | 2020-06-01         |
| monitorPrivateDnsLinkMonitorAzure             | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01         |
| monitorPrivateDnsLinkOms                      | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01         |
| monitorPrivateDnsLinkOds                      | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01         |
| monitorPrivateDnsLinkAgentsvc                 | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01         |
| monitorPrivateDnsLinkBlob                     | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2020-06-01         |
| monitorPrivateEndpoint                        | `Microsoft.Network/privateEndpoints`                      | 2023-05-01         |
| monitorPrivateDnsZoneGroup                    | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` | 2023-05-01         |

#### Outputs for cloudObservability

| Name                                  | Type     | Description                                                          |
|:--------------------------------------|:---------|:---------------------------------------------------------------------|
| monitorWorkspaceName                  | `string` | The Azure Monitor Workspace name.                                    |
| logAnalyticsName                      | `string` | The Log Analytics Workspace name.                                    |
| logAnalyticsId                        | `string` | The Log Analytics Workspace ID.                                      |
| grafanaName                           | `string` | The Azure Managed Grafana name.                                      |
| grafanaEndpoint                       | `string` | The Azure Managed Grafana endpoint.                                  |
| metricsDataCollectionRuleName         | `string` | The metrics data collection rule name.                               |
| logsDataCollectionRuleName            | `string` | The logs data collection rule name.                                  |
| monitorPrivateLinkScopeId             | `string` | Azure Monitor Private Link Scope resource ID.                        |
| monitorPrivateEndpointId              | `string` | Azure Monitor private endpoint resource ID.                          |
| monitorPrivateEndpointName            | `string` | Azure Monitor private endpoint name.                                 |
| monitorPrivateEndpointIp              | `string` | Azure Monitor private endpoint IP address.                           |
| monitorPrivateDnsZoneMonitorAzureName | `string` | Private DNS zone name for privatelink.monitor.azure.com.             |
| monitorPrivateDnsZoneOmsName          | `string` | Private DNS zone name for privatelink.oms.opinsights.azure.com.      |
| monitorPrivateDnsZoneOdsName          | `string` | Private DNS zone name for privatelink.ods.opinsights.azure.com.      |
| monitorPrivateDnsZoneAgentsvcName     | `string` | Private DNS zone name for privatelink.agentsvc.azure-automation.net. |
| monitorPrivateDnsZoneBlobName         | `string` | Private DNS zone name for the blob storage namespace.                |
| monitorPrivateDnsZoneBlobId           | `string` | Private DNS zone ID for the blob storage namespace.                  |

### cloudData

Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.

#### Parameters for cloudData

| Name                                   | Description                                                                                                        | Type                                                       | Default                                                                                                                                                                         | Required |
|:---------------------------------------|:-------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                                 | The common component configuration.                                                                                | `[_2.Common](#user-defined-types)`                         | n/a                                                                                                                                                                             | yes      |
| shouldCreateStorageAccount             | Whether to create the Storage Account.                                                                             | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| storageAccountResourceGroupName        | The name for the Resource Group for the Storage Account.                                                           | `string`                                                   | [if(parameters('shouldCreateStorageAccount'), resourceGroup().name, fail('storageAccountResourceGroupName required when shouldCreateStorageAccount is false'))]                 | no       |
| storageAccountName                     | The name for the Storage Account used by the Schema Registry.                                                      | `string`                                                   | [if(parameters('shouldCreateStorageAccount'), format('st{0}', uniqueString(resourceGroup().id)), fail('storageAccountName required when shouldCreateStorageAccount is false'))] | no       |
| storageAccountSettings                 | The settings for the new Storage Account.                                                                          | `[_1.StorageAccountSettings](#user-defined-types)`         | [variables('_1.storageAccountSettingsDefaults')]                                                                                                                                | no       |
| shouldEnableStoragePrivateEndpoint     | Whether to enable a private endpoint for the Storage Account.                                                      | `bool`                                                     | `false`                                                                                                                                                                         | no       |
| storagePrivateEndpointSubnetId         | Subnet resource ID used when deploying the Storage Account private endpoint.                                       | `string`                                                   | n/a                                                                                                                                                                             | no       |
| storageVirtualNetworkId                | Virtual network resource ID for Storage Account private DNS links.                                                 | `string`                                                   | n/a                                                                                                                                                                             | no       |
| shouldEnableStoragePublicNetworkAccess | Whether to enable public network access for the Storage Account.                                                   | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| shouldCreateBlobPrivateDnsZone         | Whether to create the blob private DNS zone. Set to false if using a shared DNS zone from observability component. | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| blobPrivateDnsZoneId                   | Existing blob Private DNS zone ID to reuse when private endpoints are enabled.                                     | `string`                                                   | n/a                                                                                                                                                                             | no       |
| shouldCreateSchemaRegistry             | Whether to create the ADR Schema Registry.                                                                         | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| shouldCreateSchemaContainer            | Whether to create the Blob Container for schemas.                                                                  | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| schemaContainerName                    | The name for the Blob Container for schemas.                                                                       | `string`                                                   | schemas                                                                                                                                                                         | no       |
| schemaRegistryName                     | The name for the ADR Schema Registry.                                                                              | `string`                                                   | [format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]                                                | no       |
| schemaRegistryNamespace                | The ADLS Gen2 namespace for the ADR Schema Registry.                                                               | `string`                                                   | [format('srns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]                                              | no       |
| shouldCreateAdrNamespace               | Whether to create the ADR Namespace.                                                                               | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| adrNamespaceName                       | The name for the ADR Namespace.                                                                                    | `string`                                                   | [format('adrns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]                                             | no       |
| adrNamespaceMessagingEndpoints         | Dictionary of messaging endpoints for the ADR namespace.                                                           | `[_1.AdrNamespaceMessagingEndpoints](#user-defined-types)` | n/a                                                                                                                                                                             | no       |
| adrNamespaceEnableIdentity             | Whether to enable system-assigned managed identity for the ADR namespace.                                          | `bool`                                                     | `true`                                                                                                                                                                          | no       |
| telemetry_opt_out                      | Whether to opt out of telemetry data collection.                                                                   | `bool`                                                     | `false`                                                                                                                                                                         | no       |

#### Resources for cloudData

| Name                         | Type                              | API Version |
|:-----------------------------|:----------------------------------|:------------|
| storageAccount               | `Microsoft.Resources/deployments` | 2025-04-01  |
| schemaRegistry               | `Microsoft.Resources/deployments` | 2025-04-01  |
| schemaRegistryRoleAssignment | `Microsoft.Resources/deployments` | 2025-04-01  |
| adrNamespace                 | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudData

| Name                         | Type     | Description                                                                |
|:-----------------------------|:---------|:---------------------------------------------------------------------------|
| schemaRegistryName           | `string` | The ADR Schema Registry Name.                                              |
| schemaRegistryId             | `string` | The ADR Schema Registry ID.                                                |
| storageAccountName           | `string` | The Storage Account Name.                                                  |
| storageAccountId             | `string` | The Storage Account ID.                                                    |
| schemaContainerName          | `string` | The Schema Container Name.                                                 |
| storageBlobPrivateEndpointId | `string` | The blob private endpoint ID for the Storage Account when created.         |
| storageBlobPrivateEndpointIp | `string` | The blob private endpoint IP address for the Storage Account when created. |
| blobPrivateDnsZoneId         | `string` | The blob private DNS zone ID when managed by this component.               |
| blobPrivateDnsZoneName       | `string` | The blob private DNS zone name when managed by this component.             |
| adrNamespaceName             | `string` | The ADR Namespace Name.                                                    |
| adrNamespaceId               | `string` | The ADR Namespace ID.                                                      |
| adrNamespace                 | `object` | The complete ADR namespace resource information.                           |

### cloudMessaging

Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.

#### Parameters for cloudMessaging

| Name                  | Description                                                  | Type                                        | Default | Required |
|:----------------------|:-------------------------------------------------------------|:--------------------------------------------|:--------|:---------|
| common                | The common component configuration.                          | `[_2.Common](#user-defined-types)`          | n/a     | yes      |
| tags                  | Additional tags to add to the resources.                     | `object`                                    | {}      | no       |
| aioIdentityName       | The User-Assigned Managed Identity for Azure IoT Operations. | `string`                                    | n/a     | yes      |
| shouldCreateEventHub  | Whether to create Event Hubs resources.                      | `bool`                                      | `true`  | no       |
| eventHubConfig        | The configuration for the Event Hubs Namespace.              | `[_1.EventHubConfig](#user-defined-types)`  | n/a     | no       |
| shouldCreateEventGrid | Whether to create Event Grid resources.                      | `bool`                                      | `true`  | no       |
| eventGridConfig       | The configuration for the Event Grid Domain.                 | `[_1.EventGridConfig](#user-defined-types)` | n/a     | no       |
| telemetry_opt_out     | Whether to opt out of telemetry data collection.             | `bool`                                      | `false` | no       |

#### Resources for cloudMessaging

| Name      | Type                              | API Version |
|:----------|:----------------------------------|:------------|
| eventHub  | `Microsoft.Resources/deployments` | 2025-04-01  |
| eventGrid | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudMessaging

| Name                  | Type     | Description                                             |
|:----------------------|:---------|:--------------------------------------------------------|
| eventHubNamespaceName | `string` | The Event Hubs Namespace name.                          |
| eventHubNamespaceId   | `string` | The Event Hubs Namespace ID.                            |
| eventHubNames         | `array`  | The list of Event Hub names created in the namespace.   |
| eventGridTopicNames   | `string` | The Event Grid topic name created.                      |
| eventGridMqttEndpoint | `string` | The Event Grid endpoint URL for MQTT connections        |
| eventHubConfig        | `object` | The Event Hub configuration object for edge messaging.  |
| eventGridConfig       | `object` | The Event Grid configuration object for edge messaging. |

### cloudNetworking

Creates virtual network, subnet, and network security group resources for Azure deployments.

#### Parameters for cloudNetworking

| Name                         | Description                                             | Type                                              | Default                                         | Required |
|:-----------------------------|:--------------------------------------------------------|:--------------------------------------------------|:------------------------------------------------|:---------|
| common                       | The common component configuration.                     | `[_2.Common](#user-defined-types)`                | n/a                                             | yes      |
| networkingConfig             | Networking configuration settings.                      | `[_1.NetworkingConfig](#user-defined-types)`      | [variables('_1.networkingConfigDefaults')]      | no       |
| natGatewayConfig             | NAT Gateway configuration settings.                     | `[_1.NatGatewayConfig](#user-defined-types)`      | [variables('_1.natGatewayConfigDefaults')]      | no       |
| privateResolverConfig        | Private DNS Resolver configuration settings.            | `[_1.PrivateResolverConfig](#user-defined-types)` | [variables('_1.privateResolverConfigDefaults')] | no       |
| defaultOutboundAccessEnabled | Whether default outbound access is enabled for subnets. | `bool`                                            | `false`                                         | no       |
| telemetry_opt_out            | Whether to opt out of telemetry data collection.        | `bool`                                            | `false`                                         | no       |

#### Resources for cloudNetworking

| Name            | Type                                        | API Version |
|:----------------|:--------------------------------------------|:------------|
| virtualNetwork  | `Microsoft.Network/virtualNetworks`         | 2025-01-01  |
| defaultSubnet   | `Microsoft.Network/virtualNetworks/subnets` | 2025-01-01  |
| natGateway      | `Microsoft.Resources/deployments`           | 2025-04-01  |
| privateResolver | `Microsoft.Resources/deployments`           | 2025-04-01  |

#### Outputs for cloudNetworking

| Name                         | Type     | Description                                                               |
|:-----------------------------|:---------|:--------------------------------------------------------------------------|
| networkSecurityGroupId       | `string` | The ID of the created network security group.                             |
| networkSecurityGroupName     | `string` | The name of the created network security group.                           |
| subnetId                     | `string` | The ID of the created subnet.                                             |
| subnetName                   | `string` | The name of the created subnet.                                           |
| virtualNetworkId             | `string` | The ID of the created virtual network.                                    |
| virtualNetworkName           | `string` | The name of the created virtual network.                                  |
| natGatewayId                 | `string` | The ID of the NAT Gateway (if enabled).                                   |
| natGatewayName               | `string` | The name of the NAT Gateway (if enabled).                                 |
| natGatewayPublicIps          | `array`  | The public IP addresses associated with NAT Gateway (if enabled).         |
| privateResolverId            | `string` | The Private DNS Resolver ID (if enabled).                                 |
| privateResolverName          | `string` | The Private DNS Resolver name (if enabled).                               |
| dnsServerIp                  | `string` | The DNS server IP address from Private Resolver (if enabled).             |
| defaultOutboundAccessEnabled | `bool`   | Whether default outbound access remains enabled for the shared subnet(s). |
| subnetAddressPrefix          | `string` | The address prefix allocated to the default subnet.                       |
| virtualNetworkAddressPrefix  | `string` | The address prefix allocated to the virtual network.                      |

### cloudVmHost

Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.

#### Parameters for cloudVmHost

| Name                      | Description                                                                                                                         | Type                                       | Default                                  | Required |
|:--------------------------|:------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------|:-----------------------------------------|:---------|
| common                    | The common component configuration.                                                                                                 | `[_2.Common](#user-defined-types)`         | n/a                                      | yes      |
| adminPassword             | The admin password for the VM.                                                                                                      | `securestring`                             | n/a                                      | yes      |
| arcOnboardingIdentityName | The user-assigned identity for Arc onboarding.                                                                                      | `string`                                   | n/a                                      | no       |
| storageProfile            | The storage profile for the VM.                                                                                                     | `[_1.StorageProfile](#user-defined-types)` | [variables('_1.storageProfileDefaults')] | no       |
| vmUsername                | Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user) | `string`                                   | n/a                                      | no       |
| vmCount                   | The number of host VMs to create if a multi-node cluster is needed.                                                                 | `int`                                      | 1                                        | no       |
| vmSkuSize                 | Size of the VM.                                                                                                                     | `string`                                   | Standard_D8s_v3                          | no       |
| telemetry_opt_out         | Whether to opt out of telemetry data collection.                                                                                    | `bool`                                     | `false`                                  | no       |
| subnetId                  | The subnet ID to connect the VMs to.                                                                                                | `string`                                   | n/a                                      | yes      |

#### Resources for cloudVmHost

| Name           | Type                              | API Version |
|:---------------|:----------------------------------|:------------|
| virtualMachine | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudVmHost

| Name               | Type     | Description                                                       |
|:-------------------|:---------|:------------------------------------------------------------------|
| adminUsername      | `string` | The admin username for SSH access to the VMs.                     |
| privateIpAddresses | `array`  | An array containing the private IP addresses of all deployed VMs. |
| publicFqdns        | `array`  | An array containing the public FQDNs of all deployed VMs.         |
| publicIpAddresses  | `array`  | An array containing the public IP addresses of all deployed VMs.  |
| vmIds              | `array`  | An array containing the IDs of all deployed VMs.                  |
| vmNames            | `array`  | An array containing the names of all deployed VMs.                |

### cloudAcr

Deploys Azure Container Registry (ACR) resources.

#### Parameters for cloudAcr

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

#### Resources for cloudAcr

| Name              | Type                              | API Version |
|:------------------|:----------------------------------|:------------|
| network           | `Microsoft.Resources/deployments` | 2025-04-01  |
| containerRegistry | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudAcr

| Name                  | Type     | Description                                            |
|:----------------------|:---------|:-------------------------------------------------------|
| acrId                 | `string` | The Azure Container Registry ID.                       |
| acrName               | `string` | The Azure Container Registry name.                     |
| acrSubnetId           | `string` | The ACR subnet ID (if private endpoint is enabled).    |
| acrPrivateEndpointId  | `string` | The ACR private endpoint ID (if enabled).              |
| acrPrivateDnsZoneName | `string` | The ACR private DNS zone name (if enabled).            |
| isNatGatewayEnabled   | `bool`   | Whether NAT Gateway is associated with the ACR subnet. |

### cloudKubernetes

Deploys optionally Azure Kubernetes Service (AKS) resources.

#### Parameters for cloudKubernetes

| Name                     | Description                                                     | Type                                                | Default                                           | Required |
|:-------------------------|:----------------------------------------------------------------|:----------------------------------------------------|:--------------------------------------------------|:---------|
| common                   | The common component configuration.                             | `[_2.Common](#user-defined-types)`                  | n/a                                               | yes      |
| virtualNetworkName       | Virtual network name for subnet creation.                       | `string`                                            | n/a                                               | yes      |
| networkSecurityGroupName | Network security group name to apply to the subnets.            | `string`                                            | n/a                                               | yes      |
| aksNetworkConfig         | AKS network configuration for subnets and NAT gateway.          | `[_1.AksNetworkConfig](#user-defined-types)`        | [variables('_1.aksNetworkConfigDefaults')]        | no       |
| natGatewayId             | NAT gateway ID for associating AKS subnets.                     | `string`                                            | n/a                                               | no       |
| shouldCreateAks          | Whether to create an Azure Kubernetes Service cluster.          | `bool`                                              | `false`                                           | no       |
| kubernetesClusterConfig  | The settings for the Azure Kubernetes Service cluster.          | `[_1.KubernetesCluster](#user-defined-types)`       | [variables('_1.kubernetesClusterDefaults')]       | no       |
| containerRegistryName    | Name of the Azure Container Registry to create.                 | `string`                                            | n/a                                               | yes      |
| aksPrivateClusterConfig  | AKS private cluster configuration.                              | `[_1.AksPrivateClusterConfig](#user-defined-types)` | [variables('_1.aksPrivateClusterConfigDefaults')] | no       |
| privateEndpointSubnetId  | Subnet ID for the private endpoint (from networking component). | `string`                                            | n/a                                               | no       |
| virtualNetworkId         | Virtual network ID for private DNS zone linking.                | `string`                                            | n/a                                               | no       |
| telemetry_opt_out        | Whether to opt out of telemetry data collection.                | `bool`                                              | `false`                                           | no       |

#### Resources for cloudKubernetes

| Name       | Type                              | API Version |
|:-----------|:----------------------------------|:------------|
| network    | `Microsoft.Resources/deployments` | 2025-04-01  |
| aksCluster | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudKubernetes

| Name                         | Type     | Description                                                 |
|:-----------------------------|:---------|:------------------------------------------------------------|
| aksName                      | `string` | The AKS cluster name.                                       |
| aksId                        | `string` | The AKS cluster ID.                                         |
| aksPrincipalId               | `string` | The AKS cluster principal ID.                               |
| snetAksId                    | `string` | The AKS system node subnet ID.                              |
| snetAksName                  | `string` | The AKS system node subnet name.                            |
| snetAksPodId                 | `string` | The AKS pod subnet ID.                                      |
| snetAksPodName               | `string` | The AKS pod subnet name.                                    |
| snetAksAddressPrefix         | `string` | The address prefix for the AKS system node subnet.          |
| snetAksPodAddressPrefix      | `string` | The address prefix for the AKS pod subnet.                  |
| defaultOutboundAccessEnabled | `bool`   | Whether default outbound access is enabled for AKS subnets. |
| natGatewayEnabled            | `bool`   | Whether NAT gateway is enabled for AKS subnets.             |
| privateEndpointId            | `string` | The private endpoint ID (if enabled).                       |
| privateDnsZoneId             | `string` | The private DNS zone ID (if enabled).                       |

## User Defined Types

### `_1.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                      | Type     | Description                                                                                           |
|:--------------------------|:---------|:------------------------------------------------------------------------------------------------------|
| vmUsername                | `string` | The VM username for SSH access.                                                                       |
| vmNames                   | `array`  | The names of all virtual machines deployed.                                                           |
| aksName                   | `string` | The AKS cluster name.                                                                                 |
| acrName                   | `string` | The Azure Container Registry name.                                                                    |
| keyVaultName              | `string` | The name of the Secret Store Extension Key Vault.                                                     |
| sseIdentityName           | `string` | The Secret Store Extension User Assigned Managed Identity name.                                       |
| aioIdentityName           | `string` | The Azure IoT Operations User Assigned Managed Identity name.                                         |
| deployIdentityName        | `string` | The Deployment User Assigned Managed Identity name.                                                   |
| arcOnboardingIdentityName | `string` | The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions. |

<!-- END_BICEP_DOCS -->