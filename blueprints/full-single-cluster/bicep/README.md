<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Full Single Cluster Blueprint
  
Deploys a complete end-to-end environment for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.  

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|
|adminPassword|Password used for the host VM.|securestring|n/a|yes|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|string|n/a|no|
|shouldGetCustomLocationsOid|Flag to determine if the custom locations OID should be retrieved.|bool|true|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|bool|false|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|onboardReqs|Microsoft.Resources/deployments|2022-09-01|
|vmHost|Microsoft.Resources/deployments|2022-09-01|
|cncfCluster|Microsoft.Resources/deployments|2022-09-01|
|iotOpsCloudReqs|Microsoft.Resources/deployments|2022-09-01|
|iotOps|Microsoft.Resources/deployments|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|onboardReqs|Creates the required resources needed for an edge IaC deployment.|
|vmHost|Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.|
|cncfCluster|Sets up and deploys a script to a VM host that will setup the K3S cluster and optionally cluster nodes, Arc connect the cluster, Add cluster admins to the cluster, enable workload identity, install extensions for cluster connect and custom locations.|
|iotOpsCloudReqs|Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.|
|iotOps|Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.|

## Module Details

### onboardReqs
  
Creates the required resources needed for an edge IaC deployment.  

#### Parameters for onboardReqs

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|onboardIdentityConfig|Settings for the onboarding identity.|[_1.OnboardIdentitySettings](#user-defined-types)|[variables('_1.onboardIdentityDefaults')]|no|

#### Resources for onboardReqs

|Name|Type|API Version|
| :--- | :--- | :--- |
|onboardIdentity|Microsoft.Resources/deployments|2022-09-01|

#### Outputs for onboardReqs

|Name|Type|Description|
| :--- | :--- | :--- |
|arcOnboardingUserManagedIdentityId|string|The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingUserManagedIdentityName|string|The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|
|arcOnboardingSpClientId|string|The Service Principal Client ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.|

### vmHost
  
Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.  

#### Parameters for vmHost

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|adminPassword|The admin password for the VM.|securestring|n/a|yes|
|arcOnboardingUserAssignedIdentityId|The user-assigned identity for Arc onboarding.|string|n/a|yes|
|storageProfile|The storage profile for the VM.|[_1.StorageProfile](#user-defined-types)|[variables('_1.storageProfileDefaults')]|no|
|vmUsername|Username used for the host VM that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|string|n/a|yes|
|vmCount|The number of host VMs to create if a multi-node cluster is needed.|int|1|no|
|vmSkuSize|Size of the VM|string|Standard_D8s_v3|no|

#### Resources for vmHost

|Name|Type|API Version|
| :--- | :--- | :--- |
|network|Microsoft.Resources/deployments|2022-09-01|
|virtualMachine|Microsoft.Resources/deployments|2022-09-01|

#### Outputs for vmHost

|Name|Type|Description|
| :--- | :--- | :--- |
|adminUsername|string||
|privateIpAddresses|array||
|publicFqdns|array||
|publicIpAddresses|array||
|vmIds|array||
|vmNames|array||

### cncfCluster
  
Sets up and deploys a script to a VM host that will setup the K3S cluster and optionally cluster nodes, Arc connect the cluster, Add cluster admins to the cluster, enable workload identity, install extensions for cluster connect and custom locations.  

#### Parameters for cncfCluster

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_1.Common](#user-defined-types)|n/a|yes|
|clusterAdminOid|The Object ID that will be given cluster-admin permissions.|string|n/a|yes|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|string|n/a|yes|
|arcOnboardingSpClientId|Service Principal Client ID with Kubernetes Cluster - Azure Arc Onboarding permissions.|string|n/a|yes|
|arcOnboardingSpClientSecret|The Service Principal Client Secret for Arc onboarding.|securestring|n/a|yes|
|shouldAddCurrentUserClusterAdmin|Whether to add the current user as a cluster admin.|bool|true|no|
|shouldEnableArcAutoUpgrade|Whether to enable auto-upgrade for Azure Arc agents.|bool|[not(equals(parameters('common').environment, 'prod'))]|no|
|clusterNodeVirtualMachineNames|The node virtual machines names.|array|[]|no|
|clusterServerVirtualMachineName|The server virtual machines name.|string|n/a|yes|
|clusterServerHostMachineUsername|Username used for the host machines that will be given kube-config settings on setup. (Otherwise, resource_prefix if it exists as a user)|string|[parameters('common').resourcePrefix]|no|
|clusterServerIp|The IP address for the server for the cluster. (Needed for mult-node cluster)|string|n/a|yes|
|serverToken|The token that will be given to the server for the cluster or used by agent nodes.|string|n/a|yes|
|shouldDeployScriptToVm|Whether to deploy the scripts to the VM.|bool|true|no|
|shouldGetCustomLocationsOid|Whether to get Custom Locations Object ID using Azure APIs.|bool|true|no|
|shouldGenerateServerToken|Should generate token used by the server.|bool|false|no|
|shouldSkipAzCliLogin|Should skip login process with Azure CLI on the server.|bool|false|no|
|shouldSkipInstallingAzCli|Should skip downloading and installing Azure CLI on the server.|bool|false|no|

#### Resources for cncfCluster

|Name|Type|API Version|
| :--- | :--- | :--- |
|customLocationsServicePrincipal|Microsoft.Graph/servicePrincipals@v1.0||
|ubuntuK3s|Microsoft.Resources/deployments|2022-09-01|

#### Outputs for cncfCluster

|Name|Type|Description|
| :--- | :--- | :--- |
|connectedClusterName|string|The connected cluster name|
|connectedClusterResourceGroupName|string|The connected cluster resource group name|
|azureArcProxyCommand|string|Azure Arc proxy command for accessing the cluster|

### iotOpsCloudReqs
  
Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.  

#### Parameters for iotOpsCloudReqs

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

#### Resources for iotOpsCloudReqs

|Name|Type|API Version|
| :--- | :--- | :--- |
|schemaRegistryStorageAccount|Microsoft.Resources/deployments|2022-09-01|
|schemaRegistry|Microsoft.Resources/deployments|2022-09-01|
|schemaRegistryRoleAssignments|Microsoft.Resources/deployments|2022-09-01|
|uami|Microsoft.Resources/deployments|2022-09-01|
|sseKeyVault|Microsoft.Resources/deployments|2022-09-01|
|sseKeyVaultRoleAssignments|Microsoft.Resources/deployments|2022-09-01|

#### Outputs for iotOpsCloudReqs

|Name|Type|Description|
| :--- | :--- | :--- |
|adrSchemaRegistryId|string|The ADR Schema Registry ID.|
|sseKeyVaultName|string|The Key Vault ID.|
|sseUamiName|string|The Secret Sync Extension Managed Identity Name.|
|aioUamiName|string|The AIO Managed Identity Name.|
|aioUamiId|string|The User Assigned Managed Identity ID for Azure IoT Operations.|

### iotOps
  
Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.  

#### Parameters for iotOps

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|[_2.Common](#user-defined-types)|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|string|n/a|yes|
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|[_1.AioPlatformExtension](#user-defined-types)|[variables('_1.aioPlatformExtensionDefaults')]|no|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|[_1.ContainerStorageExtension](#user-defined-types)|[variables('_1.containerStorageExtensionDefaults')]|no|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|[_1.OpenServiceMeshExtension](#user-defined-types)|[variables('_1.openServiceMeshExtensionDefaults')]|no|
|secretStoreConfig|The settings for the Secret Store Extension.|[_1.SecretStoreExtension](#user-defined-types)|[variables('_1.secretStoreExtensionDefaults')]|no|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|[_1.AioExtension](#user-defined-types)|[variables('_1.aioExtensionDefaults')]|no|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|bool|true|no|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|[_1.AioMqBroker](#user-defined-types)|[variables('_1.aioMqBrokerDefaults')]|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|bool|false|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|[_1.AioMqBrokerAnonymous](#user-defined-types)|[variables('_1.aioMqBrokerAnonymousDefaults')]|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|[_1.AioDataFlowInstance](#user-defined-types)|[variables('_1.aioDataFlowInstanceDefaults')]|no|
|customLocationName|The name for the Custom Locations resource.|string|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|string|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|aioUserAssignedIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|string|n/a|yes|
|aioUserAssignedIdentityId|The resource ID for the User Assigned Identity for Azure IoT Operations.|string|n/a|yes|
|schemaRegistryId|The resource ID for the ADR Schema Registry for Azure IoT Operations.|string|n/a|yes|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|bool|false|no|
|trustSource|The source for trust for Azure IoT Operations.|[_1.TrustSource](#user-defined-types)|SelfSigned|no|
|sseUserAssignedIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|string|n/a|yes|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)|string|n/a|yes|

#### Resources for iotOps

|Name|Type|API Version|
| :--- | :--- | :--- |
|iotOpsInit|Microsoft.Resources/deployments|2022-09-01|
|iotOpsInstance|Microsoft.Resources/deployments|2022-09-01|
|iotOpsInstancePost|Microsoft.Resources/deployments|2022-09-01|

## User Defined Types

### `_1.Common`
  
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
|arcConnectedClusterName|string|The name of the Arc Connected Cluster.|
|vmUsername|string|The VM username for SSH access.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
