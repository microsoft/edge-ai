<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Full Multi-node Cluster Blueprint

Deploys a complete end-to-end environment for Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|useExistingResourceGroup|Whether to use an existing resource group instead of creating a new one.|`bool`|`false`|no|
|telemetry_opt_out|Whether to opt-out of telemetry. Set to true to disable telemetry.|`bool`|`false`|no|
|adminPassword|Password used for the host VM.|`securestring`|n/a|yes|
|hostMachineCount|The number of host VMs to create for the cluster. (The first host VM will be the cluster server)|`int`|3|no|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|`false`|no|
|shouldCreateAks|Whether to create an Azure Kubernetes Service cluster.|`bool`|`false`|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|`false`|no|
|shouldInitAio|Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.|`bool`|`true`|no|
|shouldDeployAio|Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.|`bool`|`true`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|cloudResourceGroup|`Microsoft.Resources/deployments`|2022-09-01|
|cloudSecurityIdentity|`Microsoft.Resources/deployments`|2022-09-01|
|cloudObservability|`Microsoft.Resources/deployments`|2022-09-01|
|cloudData|`Microsoft.Resources/deployments`|2022-09-01|
|cloudMessaging|`Microsoft.Resources/deployments`|2022-09-01|
|cloudVmHost|`Microsoft.Resources/deployments`|2022-09-01|
|cloudAksAcr|`Microsoft.Resources/deployments`|2022-09-01|
|edgeCncfCluster|`Microsoft.Resources/deployments`|2022-09-01|
|edgeIotOps|`Microsoft.Resources/deployments`|2022-09-01|
|edgeObservability|`Microsoft.Resources/deployments`|2022-09-01|
|edgeMessaging|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||
|cloudResourceGroup|Creates the required resources needed for an edge IaC deployment.|
|cloudSecurityIdentity|Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.|
|cloudObservability|Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.|
|cloudData|Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.|
|cloudMessaging|Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.|
|cloudVmHost|Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.|
|cloudAksAcr|Deploys Azure Container Registry (ACR) and optionally Azure Kubernetes Service (AKS) resources.|
|edgeCncfCluster|This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.<br>The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.|
|edgeIotOps|Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.|
|edgeObservability|Deploys observability resources including cluster extensions for metrics and logs collection, and rule groups for monitoring.|
|edgeMessaging|Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.|

## Module Details

### attribution

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
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
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
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
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
|grafanaMajorVersion|Grafana major version|`string`|10|no|
|grafanaAdminPrincipalId|The principalId (objectId) of the user or service principal to assign the Grafana Admin role.|`string`|n/a|no|
|logsDataCollectionRuleNamespaces|List of cluster namespaces to be exposed in the log analytics workspace|`array`|['kube-system', 'gatekeeper-system', 'azure-arc', 'azure-iot-operations']|no|
|logsDataCollectionRuleStreams|List of streams to be enabled in the log analytics workspace|`array`|['Microsoft-ContainerLog', 'Microsoft-ContainerLogV2', 'Microsoft-KubeEvents', 'Microsoft-KubePodInventory', 'Microsoft-KubeNodeInventory', 'Microsoft-KubePVInventory', 'Microsoft-KubeServices', 'Microsoft-KubeMonAgentEvents', 'Microsoft-InsightsMetrics', 'Microsoft-ContainerInventory', 'Microsoft-ContainerNodeInventory', 'Microsoft-Perf']|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudObservability

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
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
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
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
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
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
|vmSkuSize|Size of the VM|`string`|Standard_D8s_v3|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudVmHost

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|network|`Microsoft.Resources/deployments`|2022-09-01|
|virtualMachine|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudVmHost

|Name|Type|Description|
| :--- | :--- | :--- |
|networkSecurityGroupId|`string`||
|virtualNetworkName|`string`||
|adminUsername|`string`||
|privateIpAddresses|`array`||
|publicFqdns|`array`||
|publicIpAddresses|`array`||
|vmIds|`array`||
|vmNames|`array`||

### cloudAksAcr

Deploys Azure Container Registry (ACR) and optionally Azure Kubernetes Service (AKS) resources.

#### Parameters for cloudAksAcr

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupId|Network security group ID to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|False|no|
|containerRegistryConfig|The settings for the Azure Container Registry.|`[_1.ContainerRegistry](#user-defined-types)`|[variables('_1.containerRegistryDefaults')]|no|
|shouldCreateAks|Whether to create an Azure Kubernetes Service cluster.|`bool`|False|no|
|kubernetesClusterConfig|The settings for the Azure Kubernetes Service cluster.|`[_1.KubernetesCluster](#user-defined-types)`|[variables('_1.kubernetesClusterDefaults')]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudAksAcr

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|network|`Microsoft.Resources/deployments`|2022-09-01|
|containerRegistry|`Microsoft.Resources/deployments`|2022-09-01|
|aksCluster|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudAksAcr

|Name|Type|Description|
| :--- | :--- | :--- |
|aksName|`string`|The AKS cluster name.|
|acrName|`string`|The Azure Container Registry name.|

### edgeCncfCluster

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.

#### Parameters for edgeCncfCluster

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|[format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|arcOnboardingSpClientId|Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.|`string`|n/a|no|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|`securestring`|n/a|no|
|arcOnboardingSpPrincipalId|Service Principal Object Id used when assigning roles for Arc onboarding.|`string`|n/a|no|
|arcOnboardingIdentityName|The resource name for the identity used for Arc onboarding.|`string`|n/a|no|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldAddCurrentUserClusterAdmin|Whether to add the current user as a cluster admin.|`bool`|True|no|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrade for Azure Arc agents.|`bool`|[not(equals(parameters('common').environment, 'prod'))]|no|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|`string`|n/a|no|
|clusterNodeVirtualMachineNames|The node virtual machines names.|`array`|n/a|no|
|clusterServerVirtualMachineName|The server virtual machines name.|`string`|n/a|no|
|clusterServerHostMachineUsername|Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|[parameters('common').resourcePrefix]|no|
|clusterServerIp|The IP address for the server for the cluster. (Needed for mult-node cluster)|`string`|n/a|no|
|serverToken|The token that will be given to the server for the cluster or used by agent nodes.|`securestring`|n/a|no|
|shouldAssignRoles|Whether to assign roles for Arc Onboarding.|`bool`|True|no|
|shouldDeployScriptToVm|Whether to deploy the scripts to the VM.|`bool`|True|no|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|`bool`|False|no|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|`bool`|False|no|
|deployUserTokenSecretName|The name for the deploy user token secret in Key Vault.|`string`|deploy-user-token|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|n/a|yes|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[resourceGroup().name]|no|
|k3sTokenSecretName|The name for the K3s token secret in Key Vault.|`string`|k3s-server-token|no|
|nodeScriptSecretName|The name for the node script secret in Key Vault.|`string`|cluster-node-ubuntu-k3s|no|
|serverScriptSecretName|The name for the server script secret in Key Vault.|`string`|cluster-server-ubuntu-k3s|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for edgeCncfCluster

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|arcOnboardingIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2024-11-30|
|ubuntuK3s|`Microsoft.Resources/deployments`|2022-09-01|
|roleAssignment|`Microsoft.Resources/deployments`|2022-09-01|
|keyVaultRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|deployScriptsToVm|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for edgeCncfCluster

|Name|Type|Description|
| :--- | :--- | :--- |
|connectedClusterName|`string`|The connected cluster name|
|connectedClusterResourceGroupName|`string`|The connected cluster resource group name|
|azureArcProxyCommand|`string`|Azure Arc proxy command for accessing the cluster|
|clusterServerScriptSecretName|`string`|The name of the Key Vault secret containing the server script|
|clusterNodeScriptSecretName|`string`|The name of the Key Vault secret containing the node script|
|clusterServerScriptSecretShowCommand|`string`|The AZ CLI command to get the cluster server script from Key Vault|
|clusterNodeScriptSecretShowCommand|`string`|The AZ CLI command to get the cluster node script from Key Vault|

### edgeIotOps

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

#### Parameters for edgeIotOps

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|[variables('_1.containerStorageExtensionDefaults')]|no|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|`[_1.OpenServiceMeshExtension](#user-defined-types)`|[variables('_1.openServiceMeshExtensionDefaults')]|no|
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioPlatformExtension](#user-defined-types)`|[variables('_1.aioPlatformExtensionDefaults')]|no|
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|[variables('_1.secretStoreExtensionDefaults')]|no|
|shouldInitAio|Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.|`bool`|True|no|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|[variables('_1.aioExtensionDefaults')]|no|
|aioFeatures|AIO Instance features.|`[_1.AioFeatures](#user-defined-types)`|n/a|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|[variables('_1.aioDataFlowInstanceDefaults')]|no|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|[variables('_1.aioMqBrokerDefaults')]|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|[variables('_1.aioMqBrokerAnonymousDefaults')]|no|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|shouldDeployAio|Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.|`bool`|True|no|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|True|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|False|no|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|True|no|
|shouldEnableOpcUaSimulator|Whether or not to enable the OPC UA Simulator for Azure IoT Operations.|`bool`|True|no|
|shouldEnableOpcUaSimulatorAsset|Whether or not to create the OPC UA Simulator ADR Asset for Azure IoT Operations.|`bool`|[parameters('shouldEnableOpcUaSimulator')]|no|
|customLocationName|The name for the Custom Locations resource.|`string`|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|trustIssuerSettings|The trust issuer settings for Customer Managed Azure IoT Operations Settings.|`[_1.TrustIssuerConfig](#user-defined-types)`|{'trustSource': 'SelfSigned'}|no|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)|`string`|n/a|yes|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|sseKeyVaultResourceGroupName|The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)|`string`|[resourceGroup().name]|no|
|shouldAssignSseKeyVaultRoles|Whether to assign roles for Key Vault to the provided Secret Sync Identity.|`bool`|True|no|
|shouldAssignDeployIdentityRoles|Whether to assign roles to the deploy identity.|`bool`|[not(empty(parameters('deployIdentityName')))]|no|
|deployIdentityName|The resource name for a managed identity that will be given deployment admin permissions.|`string`|n/a|no|
|shouldDeployAioDeploymentScripts|Whether to deploy DeploymentScripts for Azure IoT Operations.|`bool`|False|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|[parameters('sseKeyVaultName')]|no|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[parameters('sseKeyVaultResourceGroupName')]|no|
|deployUserTokenSecretName|The name for the deploy user token secret in Key Vault.|`string`|deploy-user-token|no|
|deploymentScriptsSecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script.|`string`|[format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|shouldAddDeployScriptsToKeyVault|Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)|`bool`|False|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for edgeIotOps

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|deployIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|deployArcK8sRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|deployKeyVaultRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|sseKeyVaultRoleAssignments|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInit|`Microsoft.Resources/deployments`|2022-09-01|
|postInitScriptsSecrets|`Microsoft.Resources/deployments`|2022-09-01|
|postInitScripts|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstance|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstancePost|`Microsoft.Resources/deployments`|2022-09-01|
|postInstanceScriptsSecrets|`Microsoft.Resources/deployments`|2022-09-01|
|postInstanceScripts|`Microsoft.Resources/deployments`|2022-09-01|
|opcUaSimulator|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for edgeIotOps

|Name|Type|Description|
| :--- | :--- | :--- |
|containerStorageExtensionId|`string`|The ID of the Container Storage Extension.|
|containerStorageExtensionName|`string`|The name of the Container Storage Extension.|
|openServiceMeshExtensionId|`string`|The ID of the Open Service Mesh Extension.|
|openServiceMeshExtensionName|`string`|The name of the Open Service Mesh Extension.|
|aioPlatformExtensionId|`string`|The ID of the Azure IoT Operations Platform Extension.|
|aioPlatformExtensionName|`string`|The name of the Azure IoT Operations Platform Extension.|
|secretStoreExtensionId|`string`|The ID of the Secret Store Extension.|
|secretStoreExtensionName|`string`|The name of the Secret Store Extension.|
|customLocationId|`string`|The ID of the deployed Custom Location.|
|customLocationName|`string`|The name of the deployed Custom Location.|
|aioInstanceId|`string`|The ID of the deployed Azure IoT Operations instance.|
|aioInstanceName|`string`|The name of the deployed Azure IoT Operations instance.|
|dataFlowProfileId|`string`|The ID of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowProfileName|`string`|The name of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowEndpointId|`string`|The ID of the deployed Azure IoT Operations Data Flow Endpoint.|
|dataFlowEndpointName|`string`|The name of the deployed Azure IoT Operations Data Flow Endpoint.|

### edgeObservability

Deploys observability resources including cluster extensions for metrics and logs collection, and rule groups for monitoring.

#### Parameters for edgeObservability

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|arcConnectedClusterName|The name of the Arc connected cluster.|`string`|n/a|yes|
|observabilitySettings|The observability settings.|`[_1.ObservabilitySettings](#user-defined-types)`|[variables('_1.observabilitySettingsDefaults')]|no|
|azureMonitorWorkspaceName|The name of the Azure Monitor Workspace.|`string`|n/a|yes|
|logAnalyticsWorkspaceName|The name of the Log Analytics Workspace.|`string`|n/a|yes|
|logAnalyticsWorkspaceResourceGroupName|The resource group name where the Log Analytics Workspace is located.|`string`|[resourceGroup().name]|no|
|azureManagedGrafanaName|The name of the Azure Managed Grafana instance.|`string`|n/a|yes|
|metricsDataCollectionRuleName|The name of the metrics data collection rule.|`string`|n/a|yes|
|logsDataCollectionRuleName|The name of the logs data collection rule.|`string`|n/a|yes|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for edgeObservability

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|clusterExtensionsObs|`Microsoft.Resources/deployments`|2022-09-01|
|ruleAssociationsObs|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for edgeObservability

|Name|Type|Description|
| :--- | :--- | :--- |
|clusterExtensions|`object`|The container extensions for observability.|
|ruleAssociations|`object`|The data collection rule associations for observability.|

### edgeMessaging

Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.

#### Parameters for edgeMessaging

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|aioIdentityName|The name of the User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioCustomLocationName|The name of the Azure IoT Operations Custom Location.|`string`|n/a|yes|
|aioInstanceName|The name of the Azure IoT Operations Instance.|`string`|n/a|yes|
|aioDataflowProfileName|The name of the Azure IoT Operations Dataflow Profile.|`string`|default|no|
|assetName|The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.|`string`|oven|no|
|eventHub|Values for the existing Event Hub namespace and Event Hub. If not provided, Event Hub dataflow will not be created.|`[_1.EventHub](#user-defined-types)`|n/a|no|
|eventGrid|Values for the existing Event Grid. If not provided, Event Grid dataflow will not be created.|`[_1.EventGrid](#user-defined-types)`|n/a|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for edgeMessaging

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|aioIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|aioCustomLocation|`Microsoft.ExtendedLocation/customLocations`|2021-08-31-preview|
|eventHubDataflow|`Microsoft.Resources/deployments`|2022-09-01|
|eventGridDataflow|`Microsoft.Resources/deployments`|2022-09-01|

## User Defined Types

### `_1.AioCaConfig`

Configuration for Azure IoT Operations Certificate Authority.

|Property|Type|Description|
| :--- | :--- | :--- |
|rootCaCertPem|`securestring`|The PEM-formatted root CA certificate.|
|caCertChainPem|`securestring`|The PEM-formatted CA certificate chain.|
|caKeyPem|`securestring`|The PEM-formatted CA private key.|

### `_1.AioDataFlowInstance`

The settings for Azure IoT Operations Data Flow Instances.

|Property|Type|Description|
| :--- | :--- | :--- |
|count|`int`|The number of data flow instances.|

### `_1.AioExtension`

The settings for the Azure IoT Operations Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.AioFeatures`

AIO Instance features.

### `_1.AioMqBroker`

The settings for the Azure IoT Operations MQ Broker.

|Property|Type|Description|
| :--- | :--- | :--- |
|brokerListenerServiceName|`string`|The service name for the broker listener.|
|brokerListenerPort|`int`|The port for the broker listener.|
|serviceAccountAudience|`string`|The audience for the service account.|
|frontendReplicas|`int`|The number of frontend replicas for the broker.|
|frontendWorkers|`int`|The number of frontend workers for the broker.|
|backendRedundancyFactor|`int`|The redundancy factor for the backend of the broker.|
|backendWorkers|`int`|The number of backend workers for the broker.|
|backendPartitions|`int`|The number of partitions for the backend of the broker.|
|memoryProfile|`string`|The memory profile for the broker (Low, Medium, High).|
|serviceType|`string`|The service type for the broker (ClusterIP, LoadBalancer, NodePort).|

### `_1.AioMqBrokerAnonymous`

Configuration for the insecure anonymous AIO MQ Broker Listener.

|Property|Type|Description|
| :--- | :--- | :--- |
|serviceName|`string`|The service name for the anonymous broker listener.|
|port|`int`|The port for the anonymous broker listener.|
|nodePort|`int`|The node port for the anonymous broker listener.|

### `_1.AioPlatformExtension`

The settings for the Azure IoT Operations Platform Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.ContainerStorageExtension`

The settings for the Azure Container Store for Azure Arc Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|
|settings|`object`||

### `_1.CustomerManagedByoIssuerConfig`

The configuration for Customer Managed Bring Your Own Issuer for Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustSource|`string`||
|trustSettings|`[_1.TrustSettingsConfig](#user-defined-types)`|The trust settings for Azure IoT Operations.|

### `_1.CustomerManagedGenerateIssuerConfig`

The configuration for the Customer Managed Generated trust source of Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustSource|`string`||
|aioCa|`[_1.AioCaConfig](#user-defined-types)`|The CA certificate, chain, and key for Azure IoT Operations.|

### `_1.IncludeFileConfig`

Additional file configuration for deployment scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|The name of the file to create.|
|content|`securestring`|The content of the file to create.|

### `_1.InstanceFeature`

Individual feature object within the AIO instance.

|Property|Type|Description|
| :--- | :--- | :--- |
|mode|`[_1.InstanceFeatureMode](#user-defined-types)`||
|settings|`object`||

### `_1.InstanceFeatureMode`

The mode of the AIO instance feature. Either "Stable", "Preview" or "Disabled".

### `_1.InstanceFeatureSettingValue`

The setting value of the AIO instance feature. Either "Enabled" or "Disabled".

### `_1.OpenServiceMeshExtension`

The settings for the Open Service Mesh Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|

### `_1.Release`

The common settings for Azure Arc Extensions.

|Property|Type|Description|
| :--- | :--- | :--- |
|version|`string`|The version of the extension.|
|train|`string`|The release train that has the version to deploy (ex., "preview", "stable").|

### `_1.ScriptConfig`

Script configuration for deployment scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|content|`securestring`|The script content to be executed.|
|env|`array`|Environment variables for the script.|

### `_1.ScriptEnvironmentVariable`

Environment variable configuration for scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|The name of the environment variable.|
|value|`string`|The value of the environment variable.|
|secureValue|`securestring`|The secure value of the environment variable.|

### `_1.ScriptFilesConfig`

The script and additional configuration files for deployment scripts.

|Property|Type|Description|
| :--- | :--- | :--- |
|scripts|`array`|The script configuration for deployment scripts.|
|includeFiles|`array`|The additional file configuration for deployment scripts.s|

### `_1.SecretStoreExtension`

The settings for the Secret Store Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|

### `_1.SelfSignedIssuerConfig`

The configuration for Self-Signed Issuer for Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustSource|`string`||

### `_1.TrustConfigSource`

The config source of trust for how to use or generate Azure IoT Operations certificates.

### `_1.TrustIssuerConfig`

The configuration for the trust source of Azure IoT Operations certificates.

### `_1.TrustSettingsConfig`

The configuration for the trust settings of Azure IoT Operations certificates.

|Property|Type|Description|
| :--- | :--- | :--- |
|issuerName|`string`||
|issuerKind|`string`||
|configMapName|`string`||
|configMapKey|`string`||

### `_1.TrustSource`

The source of trust for Azure IoT Operations certificates.

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
|arcConnectedClusterName|`string`|The name of the Arc-enabled Kubernetes cluster that was connected to Azure. This can be used to reference the cluster in other deployments.|
|vmUsername|`string`|The administrative username that can be used to SSH into the deployed virtual machines.|
|vmNames|`array`|An array containing the names of all virtual machines that were deployed as part of this blueprint.|
|aksName|`string`|The AKS cluster name.|
|acrName|`string`|The Azure Container Registry name.|
|aioPlatformExtensionId|`string`|The ID of the Azure IoT Operations Platform Extension.|
|aioPlatformExtensionName|`string`|The name of the Azure IoT Operations Platform Extension.|
|secretStoreExtensionId|`string`|The ID of the Secret Store Extension.|
|secretStoreExtensionName|`string`|The name of the Secret Store Extension.|
|customLocationId|`string`|The ID of the deployed Custom Location.|
|customLocationName|`string`|The name of the deployed Custom Location.|
|aioInstanceId|`string`|The ID of the deployed Azure IoT Operations instance.|
|aioInstanceName|`string`|The name of the deployed Azure IoT Operations instance.|
|dataFlowProfileId|`string`|The ID of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowProfileName|`string`|The name of the deployed Azure IoT Operations Data Flow Profile.|
|dataFlowEndpointId|`string`|The ID of the deployed Azure IoT Operations Data Flow Endpoint.|
|dataFlowEndpointName|`string`|The name of the deployed Azure IoT Operations Data Flow Endpoint.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->