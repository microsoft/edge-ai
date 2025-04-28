<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Full Single Cluster Blueprint

Deploys a complete end-to-end environment for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|adminPassword|Password used for the host VM.|`securestring`|n/a|yes|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|cloudResourceGroup|`Microsoft.Resources/deployments`|2022-09-01|
|cloudSecurityIdentity|`Microsoft.Resources/deployments`|2022-09-01|
|cloudObservability|`Microsoft.Resources/deployments`|2022-09-01|
|cloudData|`Microsoft.Resources/deployments`|2022-09-01|
|cloudVmHost|`Microsoft.Resources/deployments`|2022-09-01|
|edgeCncfCluster|`Microsoft.Resources/deployments`|2022-09-01|
|edgeIotOps|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|cloudResourceGroup|Creates the required resources needed for an edge IaC deployment.|
|cloudSecurityIdentity|Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.|
|cloudObservability|Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.|
|cloudData|Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.|
|cloudVmHost|Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.|
|edgeCncfCluster|This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.<br>The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.|
|edgeIotOps|Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.|

## Module Details

### cloudResourceGroup

Creates the required resources needed for an edge IaC deployment.

#### Parameters for cloudResourceGroup

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|tags|Additional tags to add to the resources.|`object`|{}|no|

#### Resources for cloudResourceGroup

|Name|Type|API Version|
| :--- | :--- | :--- |
|resourceGroup|`Microsoft.Resources/resourceGroups`|2022-09-01|

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
|logsDataCollectionRuleNamespaces|List of cluster namespaces to be exposed in the log analytics workspace|`array`|['kube-system', 'gatekeeper-system', 'azure-arc', 'azure-iot-operations']|no|
|logsDataCollectionRuleStreams|List of streams to be enabled in the log analytics workspace|`array`|['Microsoft-ContainerLog', 'Microsoft-ContainerLogV2', 'Microsoft-KubeEvents', 'Microsoft-KubePodInventory', 'Microsoft-KubeNodeInventory', 'Microsoft-KubePVInventory', 'Microsoft-KubeServices', 'Microsoft-KubeMonAgentEvents', 'Microsoft-InsightsMetrics', 'Microsoft-ContainerInventory', 'Microsoft-ContainerNodeInventory', 'Microsoft-Perf']|no|

#### Resources for cloudObservability

|Name|Type|API Version|
| :--- | :--- | :--- |
|monitorWorkspace|`Microsoft.Monitor/accounts`|2023-04-03|
|logAnalytics|`Microsoft.OperationalInsights/workspaces`|2025-02-01|
|grafana|`Microsoft.Dashboard/grafana`|2024-10-01|
|containerInsightsSolution|`Microsoft.OperationsManagement/solutions`|2015-11-01-preview|
|grafanaLogsReaderRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|grafanaMetricsReaderRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
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

#### Resources for cloudVmHost

|Name|Type|API Version|
| :--- | :--- | :--- |
|network|`Microsoft.Resources/deployments`|2022-09-01|
|virtualMachine|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudVmHost

|Name|Type|Description|
| :--- | :--- | :--- |
|adminUsername|`string`||
|privateIpAddresses|`array`||
|publicFqdns|`array`||
|publicIpAddresses|`array`||
|vmIds|`array`||
|vmNames|`array`||

### edgeCncfCluster

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.
The scripts handle primary and secondary node(s) setup, cluster administration, workload identity enablement, and installation of required Azure Arc extensions.

#### Parameters for edgeCncfCluster

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|keyVaultName|The name of the Key Vault to save the scripts to.|`string`|n/a|yes|
|keyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[resourceGroup().name]|no|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|[format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|clusterServerVirtualMachineName|The server virtual machines name.|`string`|n/a|no|
|clusterNodeVirtualMachineNames|The node virtual machines names.|`array`|n/a|no|
|clusterServerHostMachineUsername|Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|`string`|[parameters('common').resourcePrefix]|no|
|clusterServerIp|The IP address for the server for the cluster. (Needed for mult-node cluster)|`string`|n/a|no|
|serverToken|The token that will be given to the server for the cluster or used by agent nodes.|`string`|n/a|no|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|`string`|n/a|no|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldAssignRoles|Whether to assign roles for Arc Onboarding.|`bool`|True|no|
|arcOnboardingSpPrincipalId|Service Principal Object Id used when assigning roles for Arc onboarding.|`string`|n/a|no|
|arcOnboardingSpClientId|Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.|`string`|n/a|no|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|`securestring`|n/a|no|
|arcOnboardingIdentityName|The resource name for the identity used for Arc onboarding.|`string`|n/a|no|
|shouldAddCurrentUserClusterAdmin|Whether to add the current user as a cluster admin.|`bool`|True|no|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrade for Azure Arc agents.|`bool`|[not(equals(parameters('common').environment, 'prod'))]|no|
|shouldDeployScriptToVm|Whether to deploy the scripts to the VM.|`bool`|True|no|
|shouldGenerateServerToken|Should generate token used by the server.|`bool`|False|no|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|`bool`|False|no|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|`bool`|False|no|

#### Resources for edgeCncfCluster

|Name|Type|API Version|
| :--- | :--- | :--- |
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
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioPlatformExtension](#user-defined-types)`|[variables('_1.aioPlatformExtensionDefaults')]|no|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|[variables('_1.containerStorageExtensionDefaults')]|no|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|`[_1.OpenServiceMeshExtension](#user-defined-types)`|[variables('_1.openServiceMeshExtensionDefaults')]|no|
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|[variables('_1.secretStoreExtensionDefaults')]|no|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|[variables('_1.aioExtensionDefaults')]|no|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|True|no|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|[variables('_1.aioMqBrokerDefaults')]|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|False|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|[variables('_1.aioMqBrokerAnonymousDefaults')]|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|[variables('_1.aioDataFlowInstanceDefaults')]|no|
|customLocationName|The name for the Custom Locations resource.|`string`|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|False|no|
|trustSource|The source for trust for Azure IoT Operations.|`[_1.TrustSource](#user-defined-types)`|SelfSigned|no|
|shouldAssignKeyVaultRoles|Whether to assign roles for Key Vault to the provided Secret Sync Identity.|`bool`|True|no|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)|`string`|n/a|yes|

#### Resources for edgeIotOps

|Name|Type|API Version|
| :--- | :--- | :--- |
|roleAssignment|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInit|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstance|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstancePost|`Microsoft.Resources/deployments`|2022-09-01|

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
|arcConnectedClusterName|`string`|The name of the Arc Connected Cluster.|
|vmUsername|`string`|The VM username for SSH access.|
|vmNames|`array`|The names of all virtual machines deployed.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
