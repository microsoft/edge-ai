<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Minimum Single Node Cluster Blueprint

Deploys the minimal set of resources required for Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|resourceGroupName|The name for the resource group. If not provided, a default name will be generated.|`string`|[format('rg-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|telemetry_opt_out|Whether to opt-out of telemetry. Set to true to disable telemetry.|`bool`|`false`|no|
|adminPassword|Password used for the host VM.|`securestring`|n/a|yes|
|customLocationsOid|The object id of the Custom Locations Entra ID application for your tenant.<br>Can be retrieved using:<br><br>  <pre><code class="language-sh">  az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv<br>  </code></pre><br>|`string`|n/a|yes|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|`false`|no|
|shouldInitAio|Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.|`bool`|`true`|no|
|shouldDeployAio|Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.|`bool`|`true`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|cloudResourceGroup|`Microsoft.Resources/deployments`|2022-09-01|
|cloudSecurityIdentity|`Microsoft.Resources/deployments`|2022-09-01|
|cloudData|`Microsoft.Resources/deployments`|2022-09-01|
|cloudNetworking|`Microsoft.Resources/deployments`|2022-09-01|
|cloudVmHost|`Microsoft.Resources/deployments`|2022-09-01|
|edgeCncfCluster|`Microsoft.Resources/deployments`|2022-09-01|
|edgeIotOps|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|cloudResourceGroup|Creates the required resources needed for an edge IaC deployment.|
|cloudSecurityIdentity|Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.|
|cloudData|Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.|
|cloudNetworking|Creates virtual network, subnet, and network security group resources for Azure deployments.|
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
|shouldCreateAdrNamespace|Whether to create the ADR Namespace.|`bool`|True|no|
|adrNamespaceName|The name for the ADR Namespace.|`string`|[format('adrns-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|adrNamespaceMessagingEndpoints|Dictionary of messaging endpoints for the ADR namespace.|`[_1.AdrNamespaceMessagingEndpoints](#user-defined-types)`|n/a|no|
|adrNamespaceEnableIdentity|Whether to enable system-assigned managed identity for the ADR namespace.|`bool`|True|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|False|no|

#### Resources for cloudData

|Name|Type|API Version|
| :--- | :--- | :--- |
|storageAccount|`Microsoft.Resources/deployments`|2022-09-01|
|schemaRegistry|`Microsoft.Resources/deployments`|2022-09-01|
|schemaRegistryRoleAssignment|`Microsoft.Resources/deployments`|2022-09-01|
|adrNamespace|`Microsoft.Resources/deployments`|2022-09-01|

#### Outputs for cloudData

|Name|Type|Description|
| :--- | :--- | :--- |
|schemaRegistryName|`string`|The ADR Schema Registry Name.|
|schemaRegistryId|`string`|The ADR Schema Registry ID.|
|storageAccountName|`string`|The Storage Account Name.|
|storageAccountId|`string`|The Storage Account ID.|
|schemaContainerName|`string`|The Schema Container Name.|
|adrNamespaceName|`string`|The ADR Namespace Name.|
|adrNamespaceId|`string`|The ADR Namespace ID.|
|adrNamespace|`object`|The complete ADR namespace resource information.|

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
|clusterAdminUpn|The User Principal Name that will be given cluster-admin permissions.|`string`|n/a|no|
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
|adrNamespaceName|The resource name for the ADR Namespace for Azure IoT Operations.|`string`|n/a|no|
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
|deployIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|adrNamespace|`Microsoft.DeviceRegistry/namespaces`|2025-07-01-preview|
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
|arcConnectedClusterName|`string`|The name of the Arc-enabled Kubernetes cluster that was connected to Azure. This can be used to reference the cluster in other deployments.|
|vmUsername|`string`|The administrative username that can be used to SSH into the deployed virtual machines.|
|vmNames|`array`|An array containing the names of all virtual machines that were deployed as part of this blueprint.|
|aioPlatformExtensionId|`string`|The ID of the Azure IoT Operations Platform Extension.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->