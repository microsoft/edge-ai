<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Full Multi-node Cluster Blueprint

Deploys a complete end-to-end environment for Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster.

## Parameters

| Name                                    | Description                                                                                                                                                                                                                                   | Type                                         | Default                                                                                                                          | Required |
|:----------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                                  | The common component configuration.                                                                                                                                                                                                           | `[_5.Common](#user-defined-types)`           | n/a                                                                                                                              | yes      |
| resourceGroupName                       | The name for the resource group. If not provided, a default name will be generated.                                                                                                                                                           | `string`                                     | [format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| useExistingResourceGroup                | Whether to use an existing resource group instead of creating a new one.                                                                                                                                                                      | `bool`                                       | `false`                                                                                                                          | no       |
| telemetry_opt_out                       | Whether to opt-out of telemetry. Set to true to disable telemetry.                                                                                                                                                                            | `bool`                                       | `false`                                                                                                                          | no       |
| adminPassword                           | Password used for the host VM.                                                                                                                                                                                                                | `securestring`                               | n/a                                                                                                                              | yes      |
| hostMachineCount                        | The number of host VMs to create for the cluster. (The first host VM will be the cluster server)                                                                                                                                              | `int`                                        | 3                                                                                                                                | no       |
| customLocationsOid                      | The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre> | `string`                                     | n/a                                                                                                                              | yes      |
| serverToken                             | The token that will be given to the server for the cluster or used by agent nodes. (Required for multi-node clusters where hostMachineCount > 1)                                                                                              | `securestring`                               | n/a                                                                                                                              | no       |
| shouldCreateAcrPrivateEndpoint          | Whether to create a private endpoint for the Azure Container Registry.                                                                                                                                                                        | `bool`                                       | `false`                                                                                                                          | no       |
| shouldDeployAiFoundry                   | Whether to deploy AI Foundry resources.                                                                                                                                                                                                       | `bool`                                       | `false`                                                                                                                          | no       |
| aiFoundryConfig                         | The AI Foundry configuration settings.                                                                                                                                                                                                        | `[_2.AiFoundryConfig](#user-defined-types)`  | [variables('_2.aiFoundryConfigDefaults')]                                                                                        | no       |
| aiFoundryProjects                       | Array of AI Foundry projects to create.                                                                                                                                                                                                       | `array`                                      | []                                                                                                                               | no       |
| aiFoundryRaiPolicies                    | Array of RAI policies to create.                                                                                                                                                                                                              | `array`                                      | []                                                                                                                               | no       |
| aiFoundryModelDeployments               | Array of model deployments to create.                                                                                                                                                                                                         | `array`                                      | []                                                                                                                               | no       |
| shouldCreateAiFoundryPrivateEndpoint    | Whether to create a private endpoint for AI Foundry.                                                                                                                                                                                          | `bool`                                       | `false`                                                                                                                          | no       |
| shouldEnableNatGateway                  | Whether to enable NAT Gateway for managed outbound access.                                                                                                                                                                                    | `bool`                                       | `false`                                                                                                                          | no       |
| shouldDisableDefaultOutboundAccess      | Whether to disable default outbound access for subnets when NAT gateway is enabled.                                                                                                                                                           | `bool`                                       | `true`                                                                                                                           | no       |
| natGatewayPublicIpCount                 | Number of public IP addresses for NAT Gateway (1-16).                                                                                                                                                                                         | `int`                                        | 1                                                                                                                                | no       |
| natGatewayIdleTimeoutMinutes            | Idle timeout in minutes for NAT gateway connections (4-120).                                                                                                                                                                                  | `int`                                        | 4                                                                                                                                | no       |
| natGatewayZones                         | Availability zones for NAT Gateway. Empty array for regional deployment.                                                                                                                                                                      | `array`                                      | []                                                                                                                               | no       |
| shouldEnableVpnGateway                  | Whether to deploy VPN Gateway for remote access.                                                                                                                                                                                              | `bool`                                       | `false`                                                                                                                          | no       |
| vpnGatewayConfig                        | VPN Gateway configuration settings.                                                                                                                                                                                                           | `[_1.VpnGatewayConfig](#user-defined-types)` | [variables('_1.vpnGatewayConfigDefaults')]                                                                                       | no       |
| vpnGatewayAzureAdConfig                 | Azure AD authentication configuration for VPN Gateway.                                                                                                                                                                                        | `[_1.AzureAdConfig](#user-defined-types)`    | [variables('_1.azureAdConfigDefaults')]                                                                                          | no       |
| shouldEnablePrivateEndpoints            | Whether to enable private endpoints across Key Vault, storage, and observability resources.                                                                                                                                                   | `bool`                                       | `false`                                                                                                                          | no       |
| shouldEnablePrivateResolver             | Whether to enable Azure Private Resolver for VPN client DNS resolution of private endpoints.                                                                                                                                                  | `bool`                                       | `false`                                                                                                                          | no       |
| resolverSubnetAddressPrefix             | Address prefix for the private resolver subnet; must be /28 or larger and not overlap with other subnets.                                                                                                                                     | `string`                                     | 10.0.9.0/28                                                                                                                      | no       |
| shouldEnableKeyVaultPublicNetworkAccess | Whether to enable public network access for the Key Vault.                                                                                                                                                                                    | `bool`                                       | `true`                                                                                                                           | no       |
| shouldEnableStoragePublicNetworkAccess  | Whether to enable public network access for the storage account.                                                                                                                                                                              | `bool`                                       | `true`                                                                                                                           | no       |
| subnetAddressPrefixAcr                  | Address prefix for the ACR subnet.                                                                                                                                                                                                            | `string`                                     | 10.0.4.0/24                                                                                                                      | no       |
| subnetAddressPrefixAks                  | Address prefix for the AKS subnet.                                                                                                                                                                                                            | `string`                                     | 10.0.5.0/24                                                                                                                      | no       |
| subnetAddressPrefixAksPod               | Address prefix for the AKS pod subnet.                                                                                                                                                                                                        | `string`                                     | 10.0.6.0/24                                                                                                                      | no       |
| shouldCreateAks                         | Whether to create an Azure Kubernetes Service cluster.                                                                                                                                                                                        | `bool`                                       | `false`                                                                                                                          | no       |
| shouldCreateAnonymousBrokerListener     | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)                                                                                                                            | `bool`                                       | `false`                                                                                                                          | no       |
| shouldInitAio                           | Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.                                                                                                                         | `bool`                                       | `true`                                                                                                                           | no       |
| shouldDeployAio                         | Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.                                                                                                                             | `bool`                                       | `true`                                                                                                                           | no       |
| namespacedDevices                       | List of namespaced devices to create.                                                                                                                                                                                                         | `array`                                      | []                                                                                                                               | no       |
| assetEndpointProfiles                   | List of asset endpoint profiles to create.                                                                                                                                                                                                    | `array`                                      | []                                                                                                                               | no       |
| legacyAssets                            | List of legacy assets to create.                                                                                                                                                                                                              | `array`                                      | []                                                                                                                               | no       |
| namespacedAssets                        | List of namespaced assets to create.                                                                                                                                                                                                          | `array`                                      | []                                                                                                                               | no       |
| shouldEnableAkriRestConnector           | Deploy Akri REST HTTP Connector template to the IoT Operations instance.                                                                                                                                                                      | `bool`                                       | `false`                                                                                                                          | no       |
| shouldEnableAkriMediaConnector          | Deploy Akri Media Connector template to the IoT Operations instance.                                                                                                                                                                          | `bool`                                       | `false`                                                                                                                          | no       |
| shouldEnableAkriOnvifConnector          | Deploy Akri ONVIF Connector template to the IoT Operations instance.                                                                                                                                                                          | `bool`                                       | `false`                                                                                                                          | no       |
| shouldEnableAkriSseConnector            | Deploy Akri SSE Connector template to the IoT Operations instance.                                                                                                                                                                            | `bool`                                       | `false`                                                                                                                          | no       |
| customAkriConnectors                    | List of custom Akri connector templates with user-defined endpoint types and container images.                                                                                                                                                | `array`                                      | []                                                                                                                               | no       |

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
| cloudVpnGateway       | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudAcr              | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudAiFoundry        | `Microsoft.Resources/deployments` | 2025-04-01  |
| cloudKubernetes       | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeCncfCluster       | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeIotOps            | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeAssets            | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeObservability     | `Microsoft.Resources/deployments` | 2025-04-01  |
| edgeMessaging         | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                  | Description                                                                                                                                                                                                                                                                                                      |
|:----------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cloudResourceGroup    | Creates the required resources needed for an edge IaC deployment.                                                                                                                                                                                                                                                |
| cloudSecurityIdentity | Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.                                                                                                                                                        |
| cloudObservability    | Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.                                                                                                              |
| cloudData             | Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.                                                                                                                                                                                                  |
| cloudMessaging        | Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.                                                                                                                                                                                   |
| cloudNetworking       | Creates virtual network, subnet, and network security group resources for Azure deployments.                                                                                                                                                                                                                     |
| cloudVmHost           | Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.                                                                                                                                                                                                     |
| cloudVpnGateway       | Creates a VPN Gateway with Point-to-Site and optional Site-to-Site connectivity.<br>Ths component currently only supports Azure AD (Entra ID) authentication for Point-to-Site VPN connections.                                                                                                                  |
| cloudAcr              | Deploys Azure Container Registry (ACR) resources.                                                                                                                                                                                                                                                                |
| cloudAiFoundry        | Deploys Microsoft Foundry account with optional projects, model deployments, RAI policies, and private endpoint support.                                                                                                                                                                                         |
| cloudKubernetes       | Deploys optionally Azure Kubernetes Service (AKS) resources.                                                                                                                                                                                                                                                     |
| edgeCncfCluster       | This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.<br>The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions. |
| edgeIotOps            | Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.                                                                                                                                                                                                 |
| edgeAssets            | Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.                                                                                                                   |
| edgeObservability     | Deploys observability resources including cluster extensions for metrics and logs collection, and rule groups for monitoring.                                                                                                                                                                                    |
| edgeMessaging         | Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.                                                                                                                                                                              |

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

### cloudVpnGateway

Creates a VPN Gateway with Point-to-Site and optional Site-to-Site connectivity.
Ths component currently only supports Azure AD (Entra ID) authentication for Point-to-Site VPN connections.

#### Parameters for cloudVpnGateway

| Name                         | Description                                                    | Type                                         | Default                                    | Required |
|:-----------------------------|:---------------------------------------------------------------|:---------------------------------------------|:-------------------------------------------|:---------|
| common                       | The common component configuration.                            | `[_2.Common](#user-defined-types)`           | n/a                                        | yes      |
| vpnGatewayConfig             | VPN Gateway configuration settings.                            | `[_1.VpnGatewayConfig](#user-defined-types)` | [variables('_1.vpnGatewayConfigDefaults')] | no       |
| gatewaySubnetAddressPrefix   | Gateway subnet address prefix.                                 | `string`                                     | 10.0.2.0/27                                | no       |
| virtualNetworkName           | Virtual network name for Gateway subnet creation.              | `string`                                     | n/a                                        | yes      |
| azureAdConfig                | Azure AD configuration for VPN Gateway authentication.         | `[_1.AzureAdConfig](#user-defined-types)`    | [variables('_1.azureAdConfigDefaults')]    | no       |
| defaultOutboundAccessEnabled | Whether default outbound access is enabled for Gateway subnet. | `bool`                                       | `false`                                    | no       |
| tags                         | Resource tags.                                                 | `object`                                     | {}                                         | no       |
| telemetry_opt_out            | Whether to opt out of telemetry data collection.               | `bool`                                       | `false`                                    | no       |
| vpnSiteConnections           | Site-to-site VPN connection definitions.                       | `array`                                      | []                                         | no       |
| vpnSiteDefaultIpsecPolicy    | Fallback IPsec policy applied when sites omit an override.     | `[_1.VpnIpsecPolicy](#user-defined-types)`   | n/a                                        | no       |
| vpnSiteSharedKeys            | Pre-shared keys keyed by sharedKeyReference values.            | `secureObject`                               | {}                                         | no       |

#### Resources for cloudVpnGateway

| Name       | Type                              | API Version |
|:-----------|:----------------------------------|:------------|
| vpnGateway | `Microsoft.Resources/deployments` | 2025-04-01  |
| siteToSite | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for cloudVpnGateway

| Name                        | Type     | Description                                            |
|:----------------------------|:---------|:-------------------------------------------------------|
| vpnGateway                  | `object` | VPN Gateway resource projection.                       |
| vpnGatewayId                | `string` | VPN Gateway resource ID.                               |
| vpnGatewayName              | `string` | VPN Gateway resource name.                             |
| vpnGatewaySku               | `string` | VPN Gateway SKU.                                       |
| vpnGatewayPublicIp          | `string` | VPN Gateway public IP address.                         |
| clientConnectionInfo        | `object` | VPN client connection information.                     |
| gatewaySubnetId             | `string` | Gateway subnet ID.                                     |
| vpnSiteConnections          | `object` | VPN site connection metadata keyed by VPN site name.   |
| vpnSiteLocalNetworkGateways | `object` | Local network gateway metadata keyed by VPN site name. |

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

### cloudAiFoundry

Deploys Microsoft Foundry account with optional projects, model deployments, RAI policies, and private endpoint support.

#### Parameters for cloudAiFoundry

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

#### Resources for cloudAiFoundry

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

#### Outputs for cloudAiFoundry

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

### edgeCncfCluster

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.

#### Parameters for edgeCncfCluster

| Name                             | Description                                                                                                                                                                                                                                   | Type                               | Default                                                                                                                            | Required |
|:---------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                           | The common component configuration.                                                                                                                                                                                                           | `[_1.Common](#user-defined-types)` | n/a                                                                                                                                | yes      |
| arcConnectedClusterName          | The resource name for the Arc connected cluster.                                                                                                                                                                                              | `string`                           | [format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| arcOnboardingSpClientId          | Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.                                                                                                                                                       | `string`                           | n/a                                                                                                                                | no       |
| arcOnboardingSpClientSecret      | The Service Principal Client Secret for Arc onboarding.                                                                                                                                                                                       | `securestring`                     | n/a                                                                                                                                | no       |
| arcOnboardingSpPrincipalId       | Service Principal Object Id used when assigning roles for Arc onboarding.                                                                                                                                                                     | `string`                           | n/a                                                                                                                                | no       |
| arcOnboardingIdentityName        | The resource name for the identity used for Arc onboarding.                                                                                                                                                                                   | `string`                           | n/a                                                                                                                                | no       |
| customLocationsOid               | The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre> | `string`                           | n/a                                                                                                                                | yes      |
| shouldAddCurrentUserClusterAdmin | Whether to add the current user as a cluster admin.                                                                                                                                                                                           | `bool`                             | `true`                                                                                                                             | no       |
| shouldEnableArcAutoUpgrade       | Whether to enable auto-upgrade for Azure Arc agents.                                                                                                                                                                                          | `bool`                             | [not(equals(parameters('common').environment, 'prod'))]                                                                            | no       |
| clusterAdminOid                  | The Object ID that will be given cluster-admin permissions.                                                                                                                                                                                   | `string`                           | n/a                                                                                                                                | no       |
| clusterAdminUpn                  | The User Principal Name that will be given cluster-admin permissions.                                                                                                                                                                         | `string`                           | n/a                                                                                                                                | no       |
| clusterNodeVirtualMachineNames   | The node virtual machines names.                                                                                                                                                                                                              | `array`                            | n/a                                                                                                                                | no       |
| clusterServerVirtualMachineName  | The server virtual machines name.                                                                                                                                                                                                             | `string`                           | n/a                                                                                                                                | no       |
| clusterServerHostMachineUsername | Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)                                                                                                     | `string`                           | [parameters('common').resourcePrefix]                                                                                              | no       |
| clusterServerIp                  | The IP address for the server for the cluster. (Needed for mult-node cluster)                                                                                                                                                                 | `string`                           | n/a                                                                                                                                | no       |
| serverToken                      | The token that will be given to the server for the cluster or used by agent nodes.                                                                                                                                                            | `securestring`                     | n/a                                                                                                                                | no       |
| shouldAssignRoles                | Whether to assign roles for Arc Onboarding.                                                                                                                                                                                                   | `bool`                             | `true`                                                                                                                             | no       |
| shouldDeployScriptToVm           | Whether to deploy the scripts to the VM.                                                                                                                                                                                                      | `bool`                             | `true`                                                                                                                             | no       |
| shouldSkipInstallingAzCli        | Should skip downloading and installing Azure CLI on the server.                                                                                                                                                                               | `bool`                             | `false`                                                                                                                            | no       |
| shouldSkipAzCliLogin             | Should skip login process with Azure CLI on the server.                                                                                                                                                                                       | `bool`                             | `false`                                                                                                                            | no       |
| deployUserTokenSecretName        | The name for the deploy user token secret in Key Vault.                                                                                                                                                                                       | `string`                           | deploy-user-token                                                                                                                  | no       |
| deployKeyVaultName               | The name of the Key Vault that will have scripts and secrets for deployment.                                                                                                                                                                  | `string`                           | n/a                                                                                                                                | yes      |
| deployKeyVaultResourceGroupName  | The resource group name where the Key Vault is located. Defaults to the current resource group.                                                                                                                                               | `string`                           | [resourceGroup().name]                                                                                                             | no       |
| k3sTokenSecretName               | The name for the K3s token secret in Key Vault.                                                                                                                                                                                               | `string`                           | k3s-server-token                                                                                                                   | no       |
| nodeScriptSecretName             | The name for the node script secret in Key Vault.                                                                                                                                                                                             | `string`                           | cluster-node-ubuntu-k3s                                                                                                            | no       |
| serverScriptSecretName           | The name for the server script secret in Key Vault.                                                                                                                                                                                           | `string`                           | cluster-server-ubuntu-k3s                                                                                                          | no       |
| telemetry_opt_out                | Whether to opt out of telemetry data collection.                                                                                                                                                                                              | `bool`                             | `false`                                                                                                                            | no       |

#### Resources for edgeCncfCluster

| Name                    | Type                              | API Version |
|:------------------------|:----------------------------------|:------------|
| ubuntuK3s               | `Microsoft.Resources/deployments` | 2025-04-01  |
| roleAssignment          | `Microsoft.Resources/deployments` | 2025-04-01  |
| keyVaultRoleAssignments | `Microsoft.Resources/deployments` | 2025-04-01  |
| deployScriptsToVm       | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for edgeCncfCluster

| Name                                 | Type     | Description                                                        |
|:-------------------------------------|:---------|:-------------------------------------------------------------------|
| connectedClusterName                 | `string` | The connected cluster name                                         |
| connectedClusterResourceGroupName    | `string` | The connected cluster resource group name                          |
| azureArcProxyCommand                 | `string` | Azure Arc proxy command for accessing the cluster                  |
| clusterServerScriptSecretName        | `string` | The name of the Key Vault secret containing the server script      |
| clusterNodeScriptSecretName          | `string` | The name of the Key Vault secret containing the node script        |
| clusterServerScriptSecretShowCommand | `string` | The AZ CLI command to get the cluster server script from Key Vault |
| clusterNodeScriptSecretShowCommand   | `string` | The AZ CLI command to get the cluster node script from Key Vault   |

### edgeIotOps

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

#### Parameters for edgeIotOps

| Name                                | Description                                                                                                                                                  | Type                                                  | Default                                                                                                                       | Required |
|:------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------|:---------|
| common                              | The common component configuration.                                                                                                                          | `[_2.Common](#user-defined-types)`                    | n/a                                                                                                                           | yes      |
| arcConnectedClusterName             | The resource name for the Arc connected cluster.                                                                                                             | `string`                                              | n/a                                                                                                                           | yes      |
| containerStorageConfig              | The settings for the Azure Container Store for Azure Arc Extension.                                                                                          | `[_1.ContainerStorageExtension](#user-defined-types)` | [variables('_1.containerStorageExtensionDefaults')]                                                                           | no       |
| aioCertManagerConfig                | The settings for the Azure IoT Operations Platform Extension.                                                                                                | `[_1.AioCertManagerExtension](#user-defined-types)`   | [variables('_1.aioCertManagerExtensionDefaults')]                                                                             | no       |
| secretStoreConfig                   | The settings for the Secret Store Extension.                                                                                                                 | `[_1.SecretStoreExtension](#user-defined-types)`      | [variables('_1.secretStoreExtensionDefaults')]                                                                                | no       |
| shouldInitAio                       | Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.                                        | `bool`                                                | `true`                                                                                                                        | no       |
| aioIdentityName                     | The name of the User Assigned Managed Identity for Azure IoT Operations.                                                                                     | `string`                                              | n/a                                                                                                                           | yes      |
| aioExtensionConfig                  | The settings for the Azure IoT Operations Extension.                                                                                                         | `[_1.AioExtension](#user-defined-types)`              | [variables('_1.aioExtensionDefaults')]                                                                                        | no       |
| aioFeatures                         | AIO Instance features.                                                                                                                                       | `[_1.AioFeatures](#user-defined-types)`               | n/a                                                                                                                           | no       |
| aioInstanceName                     | The name for the Azure IoT Operations Instance resource.                                                                                                     | `string`                                              | [format('{0}-ops-instance', parameters('arcConnectedClusterName'))]                                                           | no       |
| aioDataFlowInstanceConfig           | The settings for Azure IoT Operations Data Flow Instances.                                                                                                   | `[_1.AioDataFlowInstance](#user-defined-types)`       | [variables('_1.aioDataFlowInstanceDefaults')]                                                                                 | no       |
| aioMqBrokerConfig                   | The settings for the Azure IoT Operations MQ Broker.                                                                                                         | `[_1.AioMqBroker](#user-defined-types)`               | [variables('_1.aioMqBrokerDefaults')]                                                                                         | no       |
| brokerListenerAnonymousConfig       | Configuration for the insecure anonymous AIO MQ Broker Listener.                                                                                             | `[_1.AioMqBrokerAnonymous](#user-defined-types)`      | [variables('_1.aioMqBrokerAnonymousDefaults')]                                                                                | no       |
| configurationSettingsOverride       | Optional configuration settings to override default IoT Operations extension configuration. Use the same key names as the az iot ops --ops-config parameter. | `object`                                              | {}                                                                                                                            | no       |
| schemaRegistryName                  | The resource name for the ADR Schema Registry for Azure IoT Operations.                                                                                      | `string`                                              | n/a                                                                                                                           | yes      |
| adrNamespaceName                    | The resource name for the ADR Namespace for Azure IoT Operations.                                                                                            | `string`                                              | n/a                                                                                                                           | no       |
| shouldDeployAio                     | Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.                                            | `bool`                                                | `true`                                                                                                                        | no       |
| shouldDeployResourceSyncRules       | Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.                                                    | `bool`                                                | `true`                                                                                                                        | no       |
| shouldCreateAnonymousBrokerListener | Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)                                           | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableOtelCollector           | Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.                                                                              | `bool`                                                | `true`                                                                                                                        | no       |
| shouldEnableOpcUaSimulator          | Whether or not to enable the OPC UA Simulator for Azure IoT Operations.                                                                                      | `bool`                                                | `true`                                                                                                                        | no       |
| shouldEnableAkriRestConnector       | Deploy Akri REST HTTP Connector template to the IoT Operations instance.                                                                                     | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableAkriMediaConnector      | Deploy Akri Media Connector template to the IoT Operations instance.                                                                                         | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableAkriOnvifConnector      | Deploy Akri ONVIF Connector template to the IoT Operations instance.                                                                                         | `bool`                                                | `false`                                                                                                                       | no       |
| shouldEnableAkriSseConnector        | Deploy Akri SSE Connector template to the IoT Operations instance.                                                                                           | `bool`                                                | `false`                                                                                                                       | no       |
| customAkriConnectors                | List of custom Akri connector templates with user-defined endpoint types and container images.                                                               | `array`                                               | []                                                                                                                            | no       |
| akriMqttSharedConfig                | Shared MQTT connection configuration for all Akri connectors.                                                                                                | `[_1.AkriMqttConfig](#user-defined-types)`            | {'host': 'aio-broker:18883', 'audience': 'aio-internal', 'caConfigmap': 'azure-iot-operations-aio-ca-trust-bundle'}           | no       |
| customLocationName                  | The name for the Custom Locations resource.                                                                                                                  | `string`                                              | [format('{0}-cl', parameters('arcConnectedClusterName'))]                                                                     | no       |
| additionalClusterExtensionIds       | Additional cluster extension IDs to include in the custom location. (Appended to the default Secret Store and IoT Operations extension IDs)                  | `array`                                               | []                                                                                                                            | no       |
| trustIssuerSettings                 | The trust issuer settings for Customer Managed Azure IoT Operations Settings.                                                                                | `[_1.TrustIssuerConfig](#user-defined-types)`         | {'trustSource': 'SelfSigned'}                                                                                                 | no       |
| sseKeyVaultName                     | The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)                                                                         | `string`                                              | n/a                                                                                                                           | yes      |
| sseIdentityName                     | The name of the User Assigned Managed Identity for Secret Sync.                                                                                              | `string`                                              | n/a                                                                                                                           | yes      |
| sseKeyVaultResourceGroupName        | The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)                                                  | `string`                                              | [resourceGroup().name]                                                                                                        | no       |
| shouldAssignSseKeyVaultRoles        | Whether to assign roles for Key Vault to the provided Secret Sync Identity.                                                                                  | `bool`                                                | `true`                                                                                                                        | no       |
| shouldAssignDeployIdentityRoles     | Whether to assign roles to the deploy identity.                                                                                                              | `bool`                                                | [not(empty(parameters('deployIdentityName')))]                                                                                | no       |
| deployIdentityName                  | The resource name for a managed identity that will be given deployment admin permissions.                                                                    | `string`                                              | n/a                                                                                                                           | no       |
| shouldDeployAioDeploymentScripts    | Whether to deploy DeploymentScripts for Azure IoT Operations.                                                                                                | `bool`                                                | `false`                                                                                                                       | no       |
| deployKeyVaultName                  | The name of the Key Vault that will have scripts and secrets for deployment.                                                                                 | `string`                                              | [parameters('sseKeyVaultName')]                                                                                               | no       |
| deployKeyVaultResourceGroupName     | The resource group name where the Key Vault is located. Defaults to the current resource group.                                                              | `string`                                              | [parameters('sseKeyVaultResourceGroupName')]                                                                                  | no       |
| deployUserTokenSecretName           | The name for the deploy user token secret in Key Vault.                                                                                                      | `string`                                              | deploy-user-token                                                                                                             | no       |
| deploymentScriptsSecretNamePrefix   | The prefix used with constructing the secret name that will have the deployment script.                                                                      | `string`                                              | [format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)] | no       |
| shouldAddDeployScriptsToKeyVault    | Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)                                            | `bool`                                                | `false`                                                                                                                       | no       |
| telemetry_opt_out                   | Whether to opt out of telemetry data collection.                                                                                                             | `bool`                                                | `false`                                                                                                                       | no       |

#### Resources for edgeIotOps

| Name                          | Type                              | API Version |
|:------------------------------|:----------------------------------|:------------|
| deployArcK8sRoleAssignments   | `Microsoft.Resources/deployments` | 2025-04-01  |
| deployKeyVaultRoleAssignments | `Microsoft.Resources/deployments` | 2025-04-01  |
| sseKeyVaultRoleAssignments    | `Microsoft.Resources/deployments` | 2025-04-01  |
| iotOpsInit                    | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInitScriptsSecrets        | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInitScripts               | `Microsoft.Resources/deployments` | 2025-04-01  |
| iotOpsInstance                | `Microsoft.Resources/deployments` | 2025-04-01  |
| akriConnectors                | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInstanceScriptsSecrets    | `Microsoft.Resources/deployments` | 2025-04-01  |
| postInstanceScripts           | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for edgeIotOps

| Name                          | Type     | Description                                                        |
|:------------------------------|:---------|:-------------------------------------------------------------------|
| containerStorageExtensionId   | `string` | The ID of the Container Storage Extension.                         |
| containerStorageExtensionName | `string` | The name of the Container Storage Extension.                       |
| aioCertManagerExtensionId     | `string` | The ID of the Azure IoT Operations Cert-Manager Extension.         |
| aioCertManagerExtensionName   | `string` | The name of the Azure IoT Operations Cert-Manager Extension.       |
| secretStoreExtensionId        | `string` | The ID of the Secret Store Extension.                              |
| secretStoreExtensionName      | `string` | The name of the Secret Store Extension.                            |
| customLocationId              | `string` | The ID of the deployed Custom Location.                            |
| customLocationName            | `string` | The name of the deployed Custom Location.                          |
| aioInstanceId                 | `string` | The ID of the deployed Azure IoT Operations instance.              |
| aioInstanceName               | `string` | The name of the deployed Azure IoT Operations instance.            |
| dataFlowProfileId             | `string` | The ID of the deployed Azure IoT Operations Data Flow Profile.     |
| dataFlowProfileName           | `string` | The name of the deployed Azure IoT Operations Data Flow Profile.   |
| dataFlowEndpointId            | `string` | The ID of the deployed Azure IoT Operations Data Flow Endpoint.    |
| dataFlowEndpointName          | `string` | The name of the deployed Azure IoT Operations Data Flow Endpoint.  |
| akriConnectorTemplates        | `array`  | Map of deployed Akri connector templates by name with id and type. |
| akriConnectorTypesDeployed    | `array`  | List of Akri connector types that were deployed.                   |

### edgeAssets

Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.

#### Parameters for edgeAssets

| Name                               | Description                                                                                   | Type                               | Default | Required |
|:-----------------------------------|:----------------------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                             | The common component configuration.                                                           | `[_2.Common](#user-defined-types)` | n/a     | yes      |
| customLocationId                   | The ID (resource ID) of the custom location to retrieve.                                      | `string`                           | n/a     | yes      |
| adrNamespaceName                   | Azure Device Registry namespace name to use with Azure IoT Operations.                        | `string`                           | n/a     | yes      |
| namespacedDevices                  | List of namespaced devices to create.                                                         | `array`                            | []      | no       |
| assetEndpointProfiles              | List of asset endpoint profiles to create.                                                    | `array`                            | []      | no       |
| legacyAssets                       | List of legacy assets to create.                                                              | `array`                            | []      | no       |
| namespacedAssets                   | List of namespaced assets to create.                                                          | `array`                            | []      | no       |
| shouldCreateDefaultAsset           | Whether to create a default legacy asset and endpoint profile.                                | `bool`                             | `false` | no       |
| shouldCreateDefaultNamespacedAsset | Whether to create a default namespaced asset and device.                                      | `bool`                             | `false` | no       |
| k8sBridgePrincipalId               | The principal ID of the K8 Bridge for Azure IoT Operations. Required for OPC asset discovery. | `string`                           | n/a     | no       |

#### Resources for edgeAssets

| Name                   | Type                                             | API Version |
|:-----------------------|:-------------------------------------------------|:------------|
| namespacedDevice       | `Microsoft.DeviceRegistry/namespaces/devices`    | 2025-10-01  |
| namespacedAsset        | `Microsoft.DeviceRegistry/namespaces/assets`     | 2025-10-01  |
| assetEndpointProfile   | `Microsoft.DeviceRegistry/assetEndpointProfiles` | 2025-10-01  |
| legacyAsset            | `Microsoft.DeviceRegistry/assets`                | 2025-10-01  |
| k8BridgeRoleAssignment | `Microsoft.Resources/deployments`                | 2025-04-01  |

#### Outputs for edgeAssets

| Name                          | Type    | Description                                                                 |
|:------------------------------|:--------|:----------------------------------------------------------------------------|
| assetEndpointProfiles         | `array` | Array of legacy asset endpoint profiles created by this component.          |
| legacyAssets                  | `array` | Array of legacy assets created by this component.                           |
| namespacedDevices             | `array` | Array of namespaced devices created by this component.                      |
| namespacedAssets              | `array` | Array of namespaced assets created by this component.                       |
| shouldEnableOpcAssetDiscovery | `bool`  | Whether OPC simulation asset discovery is enabled for any endpoint profile. |

### edgeObservability

Deploys observability resources including cluster extensions for metrics and logs collection, and rule groups for monitoring.

#### Parameters for edgeObservability

| Name                                   | Description                                                           | Type                                              | Default                                         | Required |
|:---------------------------------------|:----------------------------------------------------------------------|:--------------------------------------------------|:------------------------------------------------|:---------|
| arcConnectedClusterName                | The name of the Arc connected cluster.                                | `string`                                          | n/a                                             | yes      |
| observabilitySettings                  | The observability settings.                                           | `[_1.ObservabilitySettings](#user-defined-types)` | [variables('_1.observabilitySettingsDefaults')] | no       |
| azureMonitorWorkspaceName              | The name of the Azure Monitor Workspace.                              | `string`                                          | n/a                                             | yes      |
| logAnalyticsWorkspaceName              | The name of the Log Analytics Workspace.                              | `string`                                          | n/a                                             | yes      |
| logAnalyticsWorkspaceResourceGroupName | The resource group name where the Log Analytics Workspace is located. | `string`                                          | [resourceGroup().name]                          | no       |
| azureManagedGrafanaName                | The name of the Azure Managed Grafana instance.                       | `string`                                          | n/a                                             | yes      |
| metricsDataCollectionRuleName          | The name of the metrics data collection rule.                         | `string`                                          | n/a                                             | yes      |
| logsDataCollectionRuleName             | The name of the logs data collection rule.                            | `string`                                          | n/a                                             | yes      |
| telemetry_opt_out                      | Whether to opt out of telemetry data collection.                      | `bool`                                            | `false`                                         | no       |

#### Resources for edgeObservability

| Name                 | Type                              | API Version |
|:---------------------|:----------------------------------|:------------|
| clusterExtensionsObs | `Microsoft.Resources/deployments` | 2025-04-01  |
| ruleAssociationsObs  | `Microsoft.Resources/deployments` | 2025-04-01  |

#### Outputs for edgeObservability

| Name              | Type     | Description                                              |
|:------------------|:---------|:---------------------------------------------------------|
| clusterExtensions | `object` | The container extensions for observability.              |
| ruleAssociations  | `object` | The data collection rule associations for observability. |

### edgeMessaging

Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.

#### Parameters for edgeMessaging

| Name                   | Description                                                                                                         | Type                                  | Default | Required |
|:-----------------------|:--------------------------------------------------------------------------------------------------------------------|:--------------------------------------|:--------|:---------|
| common                 | The common component configuration.                                                                                 | `[_2.Common](#user-defined-types)`    | n/a     | yes      |
| aioIdentityName        | The name of the User-Assigned Managed Identity for Azure IoT Operations.                                            | `string`                              | n/a     | yes      |
| aioCustomLocationName  | The name of the Azure IoT Operations Custom Location.                                                               | `string`                              | n/a     | yes      |
| aioInstanceName        | The name of the Azure IoT Operations Instance.                                                                      | `string`                              | n/a     | yes      |
| aioDataflowProfileName | The name of the Azure IoT Operations Dataflow Profile.                                                              | `string`                              | default | no       |
| assetName              | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.            | `string`                              | oven    | no       |
| adrNamespaceName       | The name of the Azure IoT Operations Device Registry namespace to use when referencing the asset.                   | `string`                              | n/a     | no       |
| eventHub               | Values for the existing Event Hub namespace and Event Hub. If not provided, Event Hub dataflow will not be created. | `[_1.EventHub](#user-defined-types)`  | n/a     | no       |
| eventGrid              | Values for the existing Event Grid. If not provided, Event Grid dataflow will not be created.                       | `[_1.EventGrid](#user-defined-types)` | n/a     | no       |
| telemetry_opt_out      | Whether to opt out of telemetry data collection.                                                                    | `bool`                                | `false` | no       |

#### Resources for edgeMessaging

| Name              | Type                              | API Version |
|:------------------|:----------------------------------|:------------|
| eventHubDataflow  | `Microsoft.Resources/deployments` | 2025-04-01  |
| eventGridDataflow | `Microsoft.Resources/deployments` | 2025-04-01  |

## User Defined Types

### `_1.AzureAdConfig`

Azure AD authentication configuration.

| Property | Type     | Description                         |
|:---------|:---------|:------------------------------------|
| tenantId | `string` | Azure AD tenant ID.                 |
| audience | `string` | Azure AD audience (application ID). |
| issuer   | `string` | Azure AD issuer URL.                |

### `_1.VpnGatewayConfig`

VPN Gateway configuration.

| Property          | Type     | Description                                                    |
|:------------------|:---------|:---------------------------------------------------------------|
| sku               | `string` | SKU name for VPN Gateway. AZ variants provide zone redundancy. |
| generation        | `string` | Generation of VPN Gateway.                                     |
| clientAddressPool | `array`  | Client address pool for P2S VPN.                               |
| vpnProtocols      | `array`  | VPN protocols to enable.                                       |

### `_1.VpnIpsecPolicy`

IPsec/IKE settings applied to VPN tunnels.

| Property          | Type     | Description                                             |
|:------------------|:---------|:--------------------------------------------------------|
| dhGroup           | `string` | Diffie-Hellman group for the IKE phase.                 |
| ikeEncryption     | `string` | IKE phase encryption algorithm.                         |
| ikeIntegrity      | `string` | IKE phase integrity algorithm.                          |
| ipsecEncryption   | `string` | IPsec phase encryption algorithm.                       |
| ipsecIntegrity    | `string` | IPsec phase integrity algorithm.                        |
| pfsGroup          | `string` | Perfect forward secrecy group.                          |
| saDataSizeKb      | `int`    | Optional data size threshold in kilobytes for rekeying. |
| saLifetimeSeconds | `int`    | Optional lifetime in seconds before rekeying the SA.    |

### `_1.VpnSiteBgpSettings`

BGP settings for a VPN site connection.

| Property    | Type     | Description                                                    |
|:------------|:---------|:---------------------------------------------------------------|
| asn         | `int`    | Autonomous system number advertised by the on-premises device. |
| peerAddress | `string` | Peer address Azure uses for BGP sessions.                      |
| peerWeight  | `int`    | Optional weight applied to the BGP peer.                       |

### `_1.VpnSiteConnection`

Site-to-site VPN connection definition.

| Property                | Type                                           | Description                                                        |
|:------------------------|:-----------------------------------------------|:-------------------------------------------------------------------|
| name                    | `string`                                       | Friendly name for the on-premises site.                            |
| addressSpaces           | `array`                                        | Address spaces reachable through the site.                         |
| sharedKeyReference      | `string`                                       | Reference key used to look up the shared key input.                |
| connectionMode          | `string`                                       | Optional connection mode (defaults to Default).                    |
| dpdTimeoutSeconds       | `int`                                          | Optional DPD timeout in seconds.                                   |
| gatewayFqdn             | `string`                                       | Optional fully qualified domain name for the on-premises gateway.  |
| gatewayIpAddress        | `string`                                       | Optional public IP address for the on-premises gateway.            |
| ikeProtocol             | `string`                                       | IKE protocol version (defaults to IKEv2).                          |
| usePolicyBasedSelectors | `bool`                                         | Whether to use policy-based traffic selectors (defaults to false). |
| bgpSettings             | `[_1.VpnSiteBgpSettings](#user-defined-types)` | Optional BGP configuration for the site.                           |
| ipsecPolicy             | `[_1.VpnIpsecPolicy](#user-defined-types)`     | Optional IPsec policy override for the site.                       |

### `_2.AiFoundryConfig`

Configuration settings for Microsoft Foundry account.

| Property                        | Type     | Description                                        |
|:--------------------------------|:---------|:---------------------------------------------------|
| sku                             | `string` | SKU name for the Microsoft Foundry account.        |
| shouldEnablePublicNetworkAccess | `bool`   | Whether to enable public network access.           |
| shouldEnableLocalAuth           | `bool`   | Whether to enable local authentication (API keys). |

### `_2.AiProject`

Configuration for a Microsoft Foundry project.

| Property    | Type     | Description                   |
|:------------|:---------|:------------------------------|
| name        | `string` | Project resource name.        |
| displayName | `string` | Display name shown in portal. |
| description | `string` | Project description.          |

### `_2.ContentFilter`

Content filter configuration.

| Property          | Type     | Description                                    |
|:------------------|:---------|:-----------------------------------------------|
| name              | `string` | Filter name: Hate, Violence, Sexual, SelfHarm. |
| enabled           | `bool`   | Whether filter is enabled.                     |
| blocking          | `bool`   | Whether filter blocks content.                 |
| severityThreshold | `string` | Severity threshold.                            |
| source            | `string` | Filter source: Prompt or Completion.           |

### `_2.ModelDeployment`

Configuration for a model deployment.

| Property             | Type     | Description               |
|:---------------------|:---------|:--------------------------|
| name                 | `string` | Deployment resource name. |
| model                | `object` | Model configuration.      |
| scale                | `object` | Scale configuration.      |
| raiPolicyName        | `string` | Optional RAI policy name. |
| versionUpgradeOption | `string` | Version upgrade option.   |

### `_2.RaiPolicy`

Configuration for a RAI policy.

| Property       | Type     | Description                    |
|:---------------|:---------|:-------------------------------|
| name           | `string` | Policy resource name.          |
| basePolicyName | `string` | Base policy to inherit from.   |
| mode           | `string` | Policy mode.                   |
| contentFilters | `array`  | Content filter configurations. |

### `_3.AioCaConfig`

Configuration for Azure IoT Operations Certificate Authority.

| Property       | Type           | Description                             |
|:---------------|:---------------|:----------------------------------------|
| rootCaCertPem  | `securestring` | The PEM-formatted root CA certificate.  |
| caCertChainPem | `securestring` | The PEM-formatted CA certificate chain. |
| caKeyPem       | `securestring` | The PEM-formatted CA private key.       |

### `_3.AioCertManagerExtension`

The settings for the Azure IoT Operations Platform Extension.

| Property | Type                                | Description                            |
|:---------|:------------------------------------|:---------------------------------------|
| release  | `[_3.Release](#user-defined-types)` | The common settings for the extension. |
| settings | `object`                            |                                        |

### `_3.AioDataFlowInstance`

The settings for Azure IoT Operations Data Flow Instances.

| Property | Type  | Description                        |
|:---------|:------|:-----------------------------------|
| count    | `int` | The number of data flow instances. |

### `_3.AioExtension`

The settings for the Azure IoT Operations Extension.

| Property | Type                                | Description                            |
|:---------|:------------------------------------|:---------------------------------------|
| release  | `[_3.Release](#user-defined-types)` | The common settings for the extension. |
| settings | `object`                            |                                        |

### `_3.AioFeatures`

AIO Instance features.

### `_3.AioMqBroker`

The settings for the Azure IoT Operations MQ Broker.

| Property                  | Type                                          | Description                                                          |
|:--------------------------|:----------------------------------------------|:---------------------------------------------------------------------|
| brokerListenerServiceName | `string`                                      | The service name for the broker listener.                            |
| brokerListenerPort        | `int`                                         | The port for the broker listener.                                    |
| serviceAccountAudience    | `string`                                      | The audience for the service account.                                |
| frontendReplicas          | `int`                                         | The number of frontend replicas for the broker.                      |
| frontendWorkers           | `int`                                         | The number of frontend workers for the broker.                       |
| backendRedundancyFactor   | `int`                                         | The redundancy factor for the backend of the broker.                 |
| backendWorkers            | `int`                                         | The number of backend workers for the broker.                        |
| backendPartitions         | `int`                                         | The number of partitions for the backend of the broker.              |
| memoryProfile             | `string`                                      | The memory profile for the broker (Low, Medium, High).               |
| serviceType               | `string`                                      | The service type for the broker (ClusterIP, LoadBalancer, NodePort). |
| logsLevel                 | `string`                                      | The log level for broker diagnostics (info, debug, trace).           |
| persistence               | `[_3.BrokerPersistence](#user-defined-types)` | Broker persistence configuration for disk-backed message storage.    |

### `_3.AioMqBrokerAnonymous`

Configuration for the insecure anonymous AIO MQ Broker Listener.

| Property    | Type     | Description                                         |
|:------------|:---------|:----------------------------------------------------|
| serviceName | `string` | The service name for the anonymous broker listener. |
| port        | `int`    | The port for the anonymous broker listener.         |
| nodePort    | `int`    | The node port for the anonymous broker listener.    |

### `_3.AkriAllocationPolicy`

Resource allocation policy for Akri connector pods.

| Property   | Type     | Description                         |
|:-----------|:---------|:------------------------------------|
| policy     | `string` | Allocation policy type.             |
| bucketSize | `int`    | Bucket size for allocation (1-100). |

### `_3.AkriConnectorTemplate`

Akri connector template configuration.

| Property                   | Type                                             | Description                                                                   |
|:---------------------------|:-------------------------------------------------|:------------------------------------------------------------------------------|
| name                       | `string`                                         | Unique name for the connector (lowercase letters, numbers, and hyphens only). |
| type                       | `string`                                         | Connector type.                                                               |
| customEndpointType         | `string`                                         | Custom endpoint type (required for custom connectors).                        |
| customImageName            | `string`                                         | Custom image name (required for custom connectors).                           |
| customEndpointVersion      | `string`                                         | Custom endpoint version.                                                      |
| customConnectorMetadataRef | `string`                                         | Custom connector metadata reference.                                          |
| registry                   | `string`                                         | Container registry for pulling connector images.                              |
| imageTag                   | `string`                                         | Image tag for the connector.                                                  |
| replicas                   | `int`                                            | Number of connector replicas.                                                 |
| imagePullPolicy            | `string`                                         | Image pull policy.                                                            |
| logLevel                   | `string`                                         | Log level for connector diagnostics.                                          |
| mqttConfig                 | `[_3.AkriMqttConfig](#user-defined-types)`       | MQTT configuration override for this connector.                               |
| aioMinVersion              | `string`                                         | Minimum AIO version requirement.                                              |
| aioMaxVersion              | `string`                                         | Maximum AIO version requirement.                                              |
| allocation                 | `[_3.AkriAllocationPolicy](#user-defined-types)` | Resource allocation policy.                                                   |
| additionalConfiguration    | `object`                                         | Additional configuration key-value pairs.                                     |
| secrets                    | `array`                                          | Secret configurations.                                                        |
| trustSettings              | `[_3.AkriTrustSettings](#user-defined-types)`    | Trust settings configuration.                                                 |

### `_3.AkriMqttConfig`

MQTT connection configuration for Akri connectors.

| Property             | Type     | Description                                        |
|:---------------------|:---------|:---------------------------------------------------|
| host                 | `string` | MQTT broker host address.                          |
| audience             | `string` | Service account token audience for authentication. |
| caConfigmap          | `string` | ConfigMap reference for trusted CA certificates.   |
| keepAliveSeconds     | `int`    | Keep alive interval in seconds.                    |
| maxInflightMessages  | `int`    | Maximum number of in-flight messages.              |
| sessionExpirySeconds | `int`    | Session expiry interval in seconds.                |

### `_3.AkriSecretConfig`

Secret configuration for Akri connector.

| Property    | Type     | Description                       |
|:------------|:---------|:----------------------------------|
| secretAlias | `string` | Alias for the secret.             |
| secretKey   | `string` | Key within the secret.            |
| secretRef   | `string` | Reference to the secret resource. |

### `_3.AkriTrustSettings`

Trust settings for Akri connector.

| Property           | Type     | Description                         |
|:-------------------|:---------|:------------------------------------|
| trustListSecretRef | `string` | Reference to the trust list secret. |

### `_3.BrokerPersistence`

Broker persistence configuration for disk-backed message storage.

| Property                  | Type     | Description                                                          |
|:--------------------------|:---------|:---------------------------------------------------------------------|
| enabled                   | `bool`   | Whether persistence is enabled.                                      |
| maxSize                   | `string` | Maximum size of the message buffer on disk (e.g., "500M", "1G").     |
| encryption                | `object` | Encryption configuration for the persistence database.               |
| dynamicSettings           | `object` | Dynamic settings for MQTTv5 user property-based persistence control. |
| retain                    | `object` | Controls which retained messages should be persisted to disk.        |
| stateStore                | `object` | Controls which state store keys should be persisted to disk.         |
| subscriberQueue           | `object` | Controls which subscriber queues should be persisted to disk.        |
| persistentVolumeClaimSpec | `object` | Persistent volume claim specification for storage.                   |

### `_3.ContainerStorageExtension`

The settings for the Azure Container Store for Azure Arc Extension.

| Property | Type                                | Description                            |
|:---------|:------------------------------------|:---------------------------------------|
| release  | `[_3.Release](#user-defined-types)` | The common settings for the extension. |
| settings | `object`                            |                                        |

### `_3.CustomerManagedByoIssuerConfig`

The configuration for Customer Managed Bring Your Own Issuer for Azure IoT Operations certificates.

| Property      | Type                                            | Description                                  |
|:--------------|:------------------------------------------------|:---------------------------------------------|
| trustSource   | `string`                                        |                                              |
| trustSettings | `[_3.TrustSettingsConfig](#user-defined-types)` | The trust settings for Azure IoT Operations. |

### `_3.CustomerManagedGenerateIssuerConfig`

The configuration for the Customer Managed Generated trust source of Azure IoT Operations certificates.

| Property    | Type                                    | Description                                                  |
|:------------|:----------------------------------------|:-------------------------------------------------------------|
| trustSource | `string`                                |                                                              |
| aioCa       | `[_3.AioCaConfig](#user-defined-types)` | The CA certificate, chain, and key for Azure IoT Operations. |

### `_3.IncludeFileConfig`

Additional file configuration for deployment scripts.

| Property | Type           | Description                        |
|:---------|:---------------|:-----------------------------------|
| name     | `string`       | The name of the file to create.    |
| content  | `securestring` | The content of the file to create. |

### `_3.InstanceFeature`

Individual feature object within the AIO instance.

| Property | Type                                            | Description |
|:---------|:------------------------------------------------|:------------|
| mode     | `[_3.InstanceFeatureMode](#user-defined-types)` |             |
| settings | `object`                                        |             |

### `_3.InstanceFeatureMode`

The mode of the AIO instance feature. Either "Stable", "Preview" or "Disabled".

### `_3.InstanceFeatureSettingValue`

The setting value of the AIO instance feature. Either "Enabled" or "Disabled".

### `_3.Release`

The common settings for Azure Arc Extensions.

| Property | Type     | Description                                                                  |
|:---------|:---------|:-----------------------------------------------------------------------------|
| version  | `string` | The version of the extension.                                                |
| train    | `string` | The release train that has the version to deploy (ex., "preview", "stable"). |

### `_3.ScriptConfig`

Script configuration for deployment scripts.

| Property | Type           | Description                           |
|:---------|:---------------|:--------------------------------------|
| content  | `securestring` | The script content to be executed.    |
| env      | `array`        | Environment variables for the script. |

### `_3.ScriptEnvironmentVariable`

Environment variable configuration for scripts.

| Property    | Type           | Description                                   |
|:------------|:---------------|:----------------------------------------------|
| name        | `string`       | The name of the environment variable.         |
| value       | `string`       | The value of the environment variable.        |
| secureValue | `securestring` | The secure value of the environment variable. |

### `_3.ScriptFilesConfig`

The script and additional configuration files for deployment scripts.

| Property     | Type    | Description                                                |
|:-------------|:--------|:-----------------------------------------------------------|
| scripts      | `array` | The script configuration for deployment scripts.           |
| includeFiles | `array` | The additional file configuration for deployment scripts.s |

### `_3.SecretStoreExtension`

The settings for the Secret Store Extension.

| Property | Type                                | Description                            |
|:---------|:------------------------------------|:---------------------------------------|
| release  | `[_3.Release](#user-defined-types)` | The common settings for the extension. |

### `_3.SelfSignedIssuerConfig`

The configuration for Self-Signed Issuer for Azure IoT Operations certificates.

| Property    | Type     | Description |
|:------------|:---------|:------------|
| trustSource | `string` |             |

### `_3.TrustConfigSource`

The config source of trust for how to use or generate Azure IoT Operations certificates.

### `_3.TrustIssuerConfig`

The configuration for the trust source of Azure IoT Operations certificates.

### `_3.TrustSettingsConfig`

The configuration for the trust settings of Azure IoT Operations certificates.

| Property      | Type     | Description |
|:--------------|:---------|:------------|
| issuerName    | `string` |             |
| issuerKind    | `string` |             |
| configMapName | `string` |             |
| configMapKey  | `string` |             |

### `_3.TrustSource`

The source of trust for Azure IoT Operations certificates.

### `_4.AssetAction`

Management action configuration for assets.

| Property            | Type     | Description                                               |
|:--------------------|:---------|:----------------------------------------------------------|
| name                | `string` | Name of the action.                                       |
| actionType          | `string` | Type of the action. Must be one of: Call, Read, or Write. |
| targetUri           | `string` | Target URI for the action.                                |
| topic               | `string` | MQTT topic for the action.                                |
| timeoutInSeconds    | `int`    | Timeout in seconds for the action.                        |
| actionConfiguration | `string` | Action configuration as JSON string.                      |
| typeRef             | `string` | Type reference for the action.                            |

### `_4.AssetDataPoint`

Data point configuration for asset datasets.

| Property               | Type     | Description                                           |
|:-----------------------|:---------|:------------------------------------------------------|
| name                   | `string` | Name of the data point.                               |
| dataSource             | `string` | Data source address.                                  |
| dataPointConfiguration | `string` | Data point configuration as JSON string.              |
| samplingIntervalMs     | `int`    | Sampling interval in milliseconds for REST endpoints. |
| mqttTopic              | `string` | MQTT topic for REST state store.                      |
| includeStateStore      | `bool`   | Whether to include state store for REST endpoints.    |
| stateStoreKey          | `string` | State store key for REST endpoints.                   |

### `_4.AssetDataset`

Dataset configuration for assets.

| Property             | Type     | Description                           |
|:---------------------|:---------|:--------------------------------------|
| name                 | `string` | Name of the dataset.                  |
| datasetConfiguration | `string` | Dataset configuration as JSON string. |
| dataSource           | `string` | Data source address for the dataset.  |
| typeRef              | `string` | Type reference for the dataset.       |
| dataPoints           | `array`  | Data points in the dataset.           |
| destinations         | `array`  | Destinations for the dataset.         |

### `_4.AssetEndpointProfile`

Legacy asset endpoint profile configuration.

| Property                      | Type     | Description                                         |
|:------------------------------|:---------|:----------------------------------------------------|
| name                          | `string` | Name of the asset endpoint profile.                 |
| endpointProfileType           | `string` | Type of the endpoint profile: Microsoft.OpcUa, etc. |
| method                        | `string` | Authentication method: Anonymous, etc.              |
| targetAddress                 | `string` | Target address of the endpoint.                     |
| opcAdditionalConfigString     | `string` | Additional OPC configuration as JSON string.        |
| shouldEnableOpcAssetDiscovery | `bool`   | Whether to enable OPC asset discovery.              |

### `_4.AssetEvent`

Event configuration for assets.

| Property           | Type     | Description                         |
|:-------------------|:---------|:------------------------------------|
| name               | `string` | Name of the event.                  |
| dataSource         | `string` | Data source address for the event.  |
| eventConfiguration | `string` | Event configuration as JSON string. |
| typeRef            | `string` | Type reference for the event.       |
| destinations       | `array`  | Destinations for the event.         |

### `_4.AssetEventDestination`

Event destination configuration.

| Property      | Type     | Description                            |
|:--------------|:---------|:---------------------------------------|
| target        | `string` | Target for the destination: Mqtt, etc. |
| configuration | `object` | Configuration for the destination.     |

### `_4.AssetEventGroup`

Event group configuration for assets.

| Property                | Type     | Description                                   |
|:------------------------|:---------|:----------------------------------------------|
| name                    | `string` | Name of the event group.                      |
| dataSource              | `string` | Data source address for the event group.      |
| eventGroupConfiguration | `string` | Event group configuration as JSON string.     |
| typeRef                 | `string` | Type reference for the event group.           |
| defaultDestinations     | `array`  | Default destinations for events in the group. |
| events                  | `array`  | Events in the event group.                    |

### `_4.AssetManagementGroup`

Management group configuration for assets.

| Property                     | Type     | Description                                          |
|:-----------------------------|:---------|:-----------------------------------------------------|
| name                         | `string` | Name of the management group.                        |
| dataSource                   | `string` | Data source address for the management group.        |
| managementGroupConfiguration | `string` | Management group configuration as JSON string.       |
| typeRef                      | `string` | Type reference for the management group.             |
| defaultTopic                 | `string` | Default MQTT topic for actions in the group.         |
| defaultTimeoutInSeconds      | `int`    | Default timeout in seconds for actions in the group. |
| actions                      | `array`  | Actions in the management group.                     |

### `_4.AssetStream`

Stream configuration for assets.

| Property            | Type     | Description                          |
|:--------------------|:---------|:-------------------------------------|
| name                | `string` | Name of the stream.                  |
| streamConfiguration | `string` | Stream configuration as JSON string. |
| typeRef             | `string` | Type reference for the stream.       |
| destinations        | `array`  | Destinations for the stream set.     |

### `_4.DatasetDestination`

Dataset destination configuration.

| Property      | Type     | Description                            |
|:--------------|:---------|:---------------------------------------|
| target        | `string` | Target for the destination: Mqtt, etc. |
| configuration | `object` | Configuration for the destination.     |

### `_4.DeviceEndpoint`

Endpoint configuration for devices.

| Property                | Type                                               | Description                                    |
|:------------------------|:---------------------------------------------------|:-----------------------------------------------|
| endpointType            | `string`                                           | Type of the endpoint: Microsoft.OpcUa, etc.    |
| address                 | `string`                                           | Address of the endpoint.                       |
| version                 | `string`                                           | Version of the endpoint protocol.              |
| additionalConfiguration | `string`                                           | Additional configuration as JSON string.       |
| authentication          | `[_4.EndpointAuthentication](#user-defined-types)` | Authentication configuration for the endpoint. |
| trustSettings           | `[_4.TrustSettings](#user-defined-types)`          | Trust settings for the endpoint.               |

### `_4.DeviceEndpoints`

Device endpoints configuration.

| Property | Type     | Description                      |
|:---------|:---------|:---------------------------------|
| outbound | `object` | Outbound endpoint configuration. |
| inbound  | `object` | Inbound endpoint configurations. |

### `_4.DeviceReference`

Device reference for namespaced assets.

| Property     | Type     | Description                         |
|:-------------|:---------|:------------------------------------|
| deviceName   | `string` | Name of the device.                 |
| endpointName | `string` | Name of the endpoint on the device. |

### `_4.EndpointAuthentication`

Endpoint authentication configuration for assets.

| Property                    | Type     | Description                                                 |
|:----------------------------|:---------|:------------------------------------------------------------|
| method                      | `string` | Authentication method: Anonymous, UsernamePassword, or X509 |
| usernamePasswordCredentials | `object` | Username and password credentials for authentication.       |
| x509Credentials             | `object` | X509 certificate credentials for authentication.            |

### `_4.LegacyAsset`

Legacy asset configuration.

| Property                     | Type     | Description                                    |
|:-----------------------------|:---------|:-----------------------------------------------|
| name                         | `string` | Name of the asset.                             |
| assetEndpointProfileRef      | `string` | Reference to the asset endpoint profile.       |
| displayName                  | `string` | Display name of the asset.                     |
| description                  | `string` | Description of the asset.                      |
| documentationUri             | `string` | Documentation URI for the asset.               |
| isEnabled                    | `bool`   | Whether the asset is enabled.                  |
| hardwareRevision             | `string` | Hardware revision of the asset.                |
| manufacturer                 | `string` | Manufacturer of the asset.                     |
| manufacturerUri              | `string` | Manufacturer URI of the asset.                 |
| model                        | `string` | Model of the asset.                            |
| productCode                  | `string` | Product code of the asset.                     |
| serialNumber                 | `string` | Serial number of the asset.                    |
| softwareRevision             | `string` | Software revision of the asset.                |
| datasets                     | `array`  | Datasets for the asset.                        |
| defaultDatasetsConfiguration | `string` | Default datasets configuration as JSON string. |

### `_4.LegacyAssetDataPoint`

Legacy asset data point configuration.

| Property               | Type     | Description                              |
|:-----------------------|:---------|:-----------------------------------------|
| name                   | `string` | Name of the data point.                  |
| dataSource             | `string` | Data source address.                     |
| dataPointConfiguration | `string` | Data point configuration as JSON string. |
| observabilityMode      | `string` | Observability mode: None, etc.           |

### `_4.LegacyAssetDataset`

Legacy asset dataset configuration.

| Property   | Type     | Description                 |
|:-----------|:---------|:----------------------------|
| name       | `string` | Name of the dataset.        |
| dataPoints | `array`  | Data points in the dataset. |

### `_4.NamespacedAsset`

Namespaced asset configuration.

| Property                     | Type                                        | Description                                         |
|:-----------------------------|:--------------------------------------------|:----------------------------------------------------|
| name                         | `string`                                    | Name of the asset.                                  |
| displayName                  | `string`                                    | Display name of the asset.                          |
| deviceRef                    | `[_4.DeviceReference](#user-defined-types)` | Reference to the device and endpoint.               |
| description                  | `string`                                    | Description of the asset.                           |
| documentationUri             | `string`                                    | Documentation URI for the asset.                    |
| externalAssetId              | `string`                                    | Asset Id provided by external system for the asset. |
| isEnabled                    | `bool`                                      | Whether the asset is enabled.                       |
| hardwareRevision             | `string`                                    | Hardware revision of the asset.                     |
| manufacturer                 | `string`                                    | Manufacturer of the asset.                          |
| manufacturerUri              | `string`                                    | Manufacturer URI of the asset.                      |
| model                        | `string`                                    | Model of the asset.                                 |
| productCode                  | `string`                                    | Product code of the asset.                          |
| serialNumber                 | `string`                                    | Serial number of the asset.                         |
| softwareRevision             | `string`                                    | Software revision of the asset.                     |
| attributes                   | `object`                                    | Custom attributes for the asset.                    |
| datasets                     | `array`                                     | Datasets for the asset.                             |
| streams                      | `array`                                     | Streams for the asset.                              |
| eventGroups                  | `array`                                     | Event groups for the asset.                         |
| managementGroups             | `array`                                     | Management groups for the asset.                    |
| defaultDatasetsConfiguration | `string`                                    | Default datasets configuration as JSON string.      |
| defaultStreamsConfiguration  | `string`                                    | Default streams configuration as JSON string.       |
| defaultEventsConfiguration   | `string`                                    | Default events configuration as JSON string.        |

### `_4.NamespacedDevice`

Namespaced device configuration.

| Property  | Type                                        | Description                             |
|:----------|:--------------------------------------------|:----------------------------------------|
| name      | `string`                                    | Name of the device.                     |
| isEnabled | `bool`                                      | Whether the device is enabled.          |
| endpoints | `[_4.DeviceEndpoints](#user-defined-types)` | Endpoint configurations for the device. |

### `_4.TrustSettings`

Trust settings for endpoint connections.

| Property  | Type     | Description               |
|:----------|:---------|:--------------------------|
| trustList | `string` | Trust list configuration. |

### `_5.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                         | Type     | Description                                                                                                                                 |
|:-----------------------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| arcConnectedClusterName      | `string` | The name of the Arc-enabled Kubernetes cluster that was connected to Azure. This can be used to reference the cluster in other deployments. |
| vmUsername                   | `string` | The administrative username that can be used to SSH into the deployed virtual machines.                                                     |
| vmNames                      | `array`  | An array containing the names of all virtual machines that were deployed as part of this blueprint.                                         |
| aksName                      | `string` | The AKS cluster name.                                                                                                                       |
| acrName                      | `string` | The Azure Container Registry name.                                                                                                          |
| aiFoundryName                | `string` | The AI Foundry account name.                                                                                                                |
| aiFoundryEndpoint            | `string` | The AI Foundry account endpoint.                                                                                                            |
| aiFoundryPrincipalId         | `string` | The AI Foundry account principal ID.                                                                                                        |
| aioCertManagerExtensionId    | `string` | The ID of the Azure IoT Operations Cert-Manager Extension.                                                                                  |
| aioCertManagerExtensionName  | `string` | The name of the Azure IoT Operations Cert-Manager Extension.                                                                                |
| secretStoreExtensionId       | `string` | The ID of the Secret Store Extension.                                                                                                       |
| secretStoreExtensionName     | `string` | The name of the Secret Store Extension.                                                                                                     |
| customLocationId             | `string` | The ID of the deployed Custom Location.                                                                                                     |
| customLocationName           | `string` | The name of the deployed Custom Location.                                                                                                   |
| aioInstanceId                | `string` | The ID of the deployed Azure IoT Operations instance.                                                                                       |
| aioInstanceName              | `string` | The name of the deployed Azure IoT Operations instance.                                                                                     |
| dataFlowProfileId            | `string` | The ID of the deployed Azure IoT Operations Data Flow Profile.                                                                              |
| dataFlowProfileName          | `string` | The name of the deployed Azure IoT Operations Data Flow Profile.                                                                            |
| dataFlowEndpointId           | `string` | The ID of the deployed Azure IoT Operations Data Flow Endpoint.                                                                             |
| dataFlowEndpointName         | `string` | The name of the deployed Azure IoT Operations Data Flow Endpoint.                                                                           |
| natGatewayId                 | `string` | The NAT Gateway ID (if enabled).                                                                                                            |
| natGatewayName               | `string` | The NAT Gateway name (if enabled).                                                                                                          |
| defaultOutboundAccessEnabled | `bool`   | Whether default outbound access is enabled.                                                                                                 |
| privateResolverId            | `string` | The Private DNS Resolver ID (if enabled).                                                                                                   |
| privateResolverName          | `string` | The Private DNS Resolver name (if enabled).                                                                                                 |
| dnsServerIp                  | `string` | The DNS server IP from Private Resolver (if enabled).                                                                                       |
| privateEndpointsEnabled      | `bool`   | Whether private endpoints are enabled.                                                                                                      |
| keyVaultPrivateEndpointId    | `string` | The Key Vault private endpoint ID (if enabled).                                                                                             |
| storageBlobPrivateEndpointId | `string` | The storage account blob private endpoint ID (if enabled).                                                                                  |
| vpnGatewayId                 | `string` | The VPN Gateway ID (if enabled).                                                                                                            |
| vpnGatewayName               | `string` | The VPN Gateway name (if enabled).                                                                                                          |
| vpnGatewayPublicIp           | `string` | The VPN Gateway public IP address (if enabled).                                                                                             |
| vpnClientConnectionInfo      | `object` | VPN client connection information (if enabled).                                                                                             |

<!-- END_BICEP_DOCS -->