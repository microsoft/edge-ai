<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Full Cloud Single Cluster Blueprint

Deploys a complete end-to-end cloud environment as preparation for Azure IoT Operations on a single-node.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|useExistingResourceGroup|Whether to use an existing resource group instead of creating a new one.|`bool`|`false`|no|
|telemetry_opt_out|Whether to opt-out of telemetry. Set to true to disable telemetry.|`bool`|`false`|no|
|adminPassword|Password used for the host VM.|`securestring`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|`false`|no|
|shouldCreateAks|Whether to create an Azure Kubernetes Service cluster.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|cloudResourceGroup|`Microsoft.Resources/deployments`|2022-09-01|
|cloudSecurityIdentity|`Microsoft.Resources/deployments`|2022-09-01|
|cloudObservability|`Microsoft.Resources/deployments`|2022-09-01|
|cloudData|`Microsoft.Resources/deployments`|2022-09-01|
|cloudMessaging|`Microsoft.Resources/deployments`|2022-09-01|
|cloudNetworking|`Microsoft.Resources/deployments`|2022-09-01|
|cloudVmHost|`Microsoft.Resources/deployments`|2022-09-01|
|cloudAcr|`Microsoft.Resources/deployments`|2022-09-01|
|cloudKubernetes|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|cloudResourceGroup|Creates the required resources needed for an edge IaC deployment.|
|cloudSecurityIdentity|Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.|
|cloudObservability|Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.|
|cloudData|Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.|
|cloudMessaging|Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.|
|cloudNetworking|Creates virtual network, subnet, and network security group resources for Azure deployments.|
|cloudVmHost|Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.|
|cloudAcr|Deploys Azure Container Registry (ACR) resources.|
|cloudKubernetes|Deploys optionally Azure Kubernetes Service (AKS) resources.|

## Module Details

### cloudResourceGroup

Creates the required resources needed for an edge IaC deployment.

#### Parameters for cloudResourceGroup

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|useExistingResourceGroup|Whether to use an existing resource group instead of creating a new one.|`bool`|False|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|
|tags|Additional tags to add to the resources.|`object`|{}|no|

#### Resources for cloudResourceGroup

|Name|Type|API Version|
| :--- | :--- | :--- |
|newResourceGroup|`Microsoft.Resources/resourceGroups`|2022-09-01|
|existingResourceGroup|`Microsoft.Resources/resourceGroups`|2022-09-01|

#### Outputs for cloudResourceGroup

|Name|Type|Description|
| :--- | :--- | :--- |
|resourceGroupId|`string`|The ID of the resource group.|
|resourceGroupName|`string`|The name of the resource group.|
|location|`string`|The location of the resource group.|

### cloudSecurityIdentity

Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.

#### Parameters for cloudSecurityIdentity

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|shouldCreateArcOnboardingUami|Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.|`bool`|True|no|
|shouldCreateKeyVault|Whether or not to create a new Key Vault for the Secret Sync Extension.|`bool`|True|no|
|keyVaultName|The name of the Key Vault.|`string`|[format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|keyVaultResourceGroupName|The name for the Resource Group for the Key Vault.|`string`|[resourceGroup().name]|no|
|shouldAssignAdminUserRole|Whether or not to create a role assignment for an admin user.|`bool`|True|no|
|adminUserObjectId|The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.|`string`|[deployer().objectId]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudSecurityIdentity

|Name|Type|API Version|
| :--- | :--- | :--- |
|identity|`Microsoft.Resources/deployments`|2022-09-01|
|keyVault|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudSecurityIdentity

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

### cloudObservability

Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.

#### Parameters for cloudObservability

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|tags|Additional tags to add to the resources.|`object`|{}|no|
|logRetentionInDays|Log Analytics Workspace retention in days|`int`|30|no|
|dailyQuotaInGb|Log Analytics Workspace daily quota in GB|`int`|10|no|
|grafanaMajorVersion|Grafana major version|`string`|11|no|
|grafanaAdminPrincipalId|The principalId (objectId) of the user or service principal to assign the Grafana Admin role.|`string`|n/a|no|
|logsDataCollectionRuleNamespaces|List of cluster namespaces to be exposed in the log analytics workspace|`array`|['kube-system', 'gatekeeper-system', 'azure-arc', 'azure-iot-operations']|no|
|logsDataCollectionRuleStreams|List of streams to be enabled in the log analytics workspace|`array`|['Microsoft-ContainerLog', 'Microsoft-ContainerLogV2', 'Microsoft-KubeEvents', 'Microsoft-KubePodInventory', 'Microsoft-KubeNodeInventory', 'Microsoft-KubePVInventory', 'Microsoft-KubeServices', 'Microsoft-KubeMonAgentEvents', 'Microsoft-InsightsMetrics', 'Microsoft-ContainerInventory', 'Microsoft-ContainerNodeInventory', 'Microsoft-Perf']|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudObservability

|Name|Type|API Version|
| :--- | :--- | :--- |
|monitorWorkspace|`Microsoft.Monitor/accounts`|2023-04-03|
|logAnalytics|`Microsoft.OperationalInsights/workspaces`|2025-02-01|
|grafana|`Microsoft.Dashboard/grafana`|2024-10-01|
|containerInsightsSolution|`Microsoft.OperationsManagement/solutions`|2015-11-01-preview|
|grafanaLogsReaderRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|grafanaMetricsReaderRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|grafanaAdminRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|dataCollectionEndpoint|`Microsoft.Insights/dataCollectionEndpoints`|2023-03-11|
|logsDataCollectionRule|`Microsoft.Insights/dataCollectionRules`|2023-03-11|
|metricsDataCollectionRule|`Microsoft.Insights/dataCollectionRules`|2023-03-11|

#### Outputs for cloudObservability

|Name|Type|Description|
| :--- | :--- | :--- |
|monitorWorkspaceName|`string`|The Azure Monitor Workspace name.|
|logAnalyticsName|`string`|The Log Analytics Workspace name.|
|logAnalyticsId|`string`|The Log Analytics Workspace ID.|
|grafanaName|`string`|The Azure Managed Grafana name.|
|metricsDataCollectionRuleName|`string`|The metrics data collection rule name.|
|logsDataCollectionRuleName|`string`|The logs data collection rule name.|

### cloudData

Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.

#### Parameters for cloudData

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|shouldCreateStorageAccount|Whether to create the Storage Account.|`bool`|True|no|
|storageAccountResourceGroupName|The name for the Resource Group for the Storage Account.|`string`|[if(parameters('shouldCreateStorageAccount'), resourceGroup().name, fail('storageAccountResourceGroupName required when shouldCreateStorageAccount is false'))]|no|
|storageAccountName|The name for the Storage Account used by the Schema Registry.|`string`|[if(parameters('shouldCreateStorageAccount'), format('st{0}', uniqueString(resourceGroup().id)), fail('storageAccountName required when shouldCreateStorageAccount is false'))]|no|
|storageAccountSettings|The settings for the new Storage Account.|`[_1.StorageAccountSettings](#user-defined-types)`|[variables('_1.storageAccountSettingsDefaults')]|no|
|shouldCreateSchemaRegistry|Whether to create the ADR Schema Registry.|`bool`|True|no|
|shouldCreateSchemaContainer|Whether to create the Blob Container for schemas.|`bool`|True|no|
|schemaContainerName|The name for the Blob Container for schemas.|`string`|schemas|no|
|schemaRegistryName|The name for the ADR Schema Registry.|`string`|[format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|schemaRegistryNamespace|The ADLS Gen2 namespace for the ADR Schema Registry.|`string`|[format('srns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudData

|Name|Type|API Version|
| :--- | :--- | :--- |
|storageAccount|`Microsoft.Resources/deployments`|2022-09-01|
|schemaRegistry|`Microsoft.Resources/deployments`|2022-09-01|
|schemaRegistryRoleAssignment|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudData

|Name|Type|Description|
| :--- | :--- | :--- |
|schemaRegistryName|`string`|The ADR Schema Registry Name.|
|schemaRegistryId|`string`|The ADR Schema Registry ID.|
|storageAccountName|`string`|The Storage Account Name.|
|storageAccountId|`string`|The Storage Account ID.|
|schemaContainerName|`string`|The Schema Container Name.|

### cloudMessaging

Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.

#### Parameters for cloudMessaging

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|tags|Additional tags to add to the resources.|`object`|{}|no|
|aioIdentityName|The User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|shouldCreateEventHub|Whether to create Event Hubs resources.|`bool`|True|no|
|eventHubConfig|The configuration for the Event Hubs Namespace.|`[_1.EventHubConfig](#user-defined-types)`|n/a|no|
|shouldCreateEventGrid|Whether to create Event Grid resources.|`bool`|True|no|
|eventGridConfig|The configuration for the Event Grid Domain.|`[_1.EventGridConfig](#user-defined-types)`|n/a|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudMessaging

|Name|Type|API Version|
| :--- | :--- | :--- |
|eventHub|`Microsoft.Resources/deployments`|2022-09-01|
|eventGrid|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudMessaging

|Name|Type|Description|
| :--- | :--- | :--- |
|eventHubNamespaceName|`string`|The Event Hubs Namespace name.|
|eventHubNamespaceId|`string`|The Event Hubs Namespace ID.|
|eventHubNames|`array`|The list of Event Hub names created in the namespace.|
|eventGridTopicNames|`string`|The Event Grid topic name created.|
|eventGridMqttEndpoint|`string`|The Event Grid endpoint URL for MQTT connections|
|eventHubConfig|`object`|The Event Hub configuration object for edge messaging.|
|eventGridConfig|`object`|The Event Grid configuration object for edge messaging.|

### cloudNetworking

Creates virtual network, subnet, and network security group resources for Azure deployments.

#### Parameters for cloudNetworking

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|networkingConfig|Networking configuration settings.|`[_1.NetworkingConfig](#user-defined-types)`|[variables('_1.networkingConfigDefaults')]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudNetworking

|Name|Type|API Version|
| :--- | :--- | :--- |
|networkSecurityGroup|`Microsoft.Network/networkSecurityGroups`|2024-05-01|
|virtualNetwork|`Microsoft.Network/virtualNetworks`|2024-05-01|

#### Outputs for cloudNetworking

|Name|Type|Description|
| :--- | :--- | :--- |
|networkSecurityGroupId|`string`|The ID of the created network security group.|
|networkSecurityGroupName|`string`|The name of the created network security group.|
|subnetId|`string`|The ID of the created subnet.|
|virtualNetworkId|`string`|The ID of the created virtual network.|
|virtualNetworkName|`string`|The name of the created virtual network.|

### cloudVmHost

Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.

#### Parameters for cloudVmHost

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|adminPassword|The admin password for the VM.|`securestring`|n/a|yes|
|arcOnboardingIdentityName|The user-assigned identity for Arc onboarding.|`string`|n/a|no|
|storageProfile|The storage profile for the VM.|`[_1.StorageProfile](#user-defined-types)`|[variables('_1.storageProfileDefaults')]|no|
|vmUsername|Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|n/a|no|
|vmCount|The number of host VMs to create if a multi-node cluster is needed.|`int`|1|no|
|vmSkuSize|Size of the VM.|`string`|Standard_D8s_v3|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|
|subnetId|The subnet ID to connect the VMs to.|`string`|n/a|yes|

#### Resources for cloudVmHost

|Name|Type|API Version|
| :--- | :--- | :--- |
|virtualMachine|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudVmHost

|Name|Type|Description|
| :--- | :--- | :--- |
|adminUsername|`string`|The admin username for SSH access to the VMs.|
|privateIpAddresses|`array`|An array containing the private IP addresses of all deployed VMs.|
|publicFqdns|`array`|An array containing the public FQDNs of all deployed VMs.|
|publicIpAddresses|`array`|An array containing the public IP addresses of all deployed VMs.|
|vmIds|`array`|An array containing the IDs of all deployed VMs.|
|vmNames|`array`|An array containing the names of all deployed VMs.|

### cloudAcr

Deploys Azure Container Registry (ACR) resources.

#### Parameters for cloudAcr

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupName|Network security group name to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|False|no|
|containerRegistryConfig|The settings for the Azure Container Registry.|`[_1.ContainerRegistry](#user-defined-types)`|[variables('_1.containerRegistryDefaults')]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudAcr

|Name|Type|API Version|
| :--- | :--- | :--- |
|network|`Microsoft.Resources/deployments`|2022-09-01|
|containerRegistry|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudAcr

|Name|Type|Description|
| :--- | :--- | :--- |
|acrName|`string`|The Azure Container Registry name.|

### cloudKubernetes

Deploys optionally Azure Kubernetes Service (AKS) resources.

#### Parameters for cloudKubernetes

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupName|Network security group name to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAks|Whether to create an Azure Kubernetes Service cluster.|`bool`|False|no|
|kubernetesClusterConfig|The settings for the Azure Kubernetes Service cluster.|`[_1.KubernetesCluster](#user-defined-types)`|[variables('_1.kubernetesClusterDefaults')]|no|
|containerRegistryName|Name of the Azure Container Registry to create.|`string`|n/a|yes|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudKubernetes

|Name|Type|API Version|
| :--- | :--- | :--- |
|network|`Microsoft.Resources/deployments`|2022-09-01|
|aksCluster|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudKubernetes

|Name|Type|Description|
| :--- | :--- | :--- |
|aksName|`string`|The AKS cluster name.|

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
|vmUsername|`string`|The VM username for SSH access.|
|vmNames|`array`|The names of all virtual machines deployed.|
|aksName|`string`|The AKS cluster name.|
|acrName|`string`|The Azure Container Registry name.|
|keyVaultName|`string`|The name of the Secret Store Extension Key Vault.|
|sseIdentityName|`string`|The Secret Store Extension User Assigned Managed Identity name.|
|aioIdentityName|`string`|The Azure IoT Operations User Assigned Managed Identity name.|
|deployIdentityName|`string`|The Deployment User Assigned Managed Identity name.|
|arcOnboardingIdentityName|`string`|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->