<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Only Edge IoT Ops Blueprint

Deploys Azure IoT Operations on an existing Arc-enabled Kubernetes cluster without setting up cloud resources.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|telemetry_opt_out|Whether to opt-out of telemetry. Set to true to disable telemetry.|`bool`|`false`|no|
|customLocationName|The name for the Custom Locations resource.|`string`|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync Extension.|`string`|[format('id-{0}-sse-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|sseKeyVaultName|The name of the Key Vault for Secret Sync Extension. Required when providing sseIdentityName.|`string`|[format('kv-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|sseKeyVaultResourceGroupName|The name of the Resource Group for the Key Vault for Secret Sync Extension. Required when providing sseIdentityName.|`string`|[resourceGroup().name]|no|
|shouldAssignSseKeyVaultRoles|Whether to assign roles for Key Vault to the provided Secret Sync Identity.|`bool`|`true`|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|[parameters('sseKeyVaultName')]|no|
|deployIdentityName|The resource name for a managed identity that will be given deployment admin permissions.|`string`|[format('id-{0}-deploy-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[parameters('sseKeyVaultResourceGroupName')]|no|
|deployUserTokenSecretName|The name of the secret in Key Vault that has the token for the deploy user with cluster-admin role.|`string`|n/a|no|
|deploymentScriptsSecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script.|`string`|[format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|shouldAssignDeployIdentityRoles|Whether to assign roles to the deploy identity.|`bool`|`true`|no|
|shouldInitAio|Whether to init Azure IoT Operations. (For debugging)|`bool`|`true`|no|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|[format('id-{0}-aio-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|arcConnectedClusterName|The resource name for the Arc-enabled Kubernetes cluster.|`string`|[format('arck-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|schemaRegistryName|The resource name for the Azure Data Registry Schema Registry for Azure IoT Operations.|`string`|[format('sr-{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|adrNamespaceName|The resource name for the ADR Namespace for Azure IoT Operations. Optional parameter for referencing an existing ADR namespace.|`string`|n/a|no|
|shouldDeployAio|Whether to deploy Azure IoT Operations. (For debugging)|`bool`|`true`|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous Azure IoT Operations MQ Broker Listener. Should only be used for dev or test environments.|`bool`|`false`|no|
|shouldDeployResourceSyncRules|Whether to deploy Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|`true`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|edgeIotOps|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|edgeIotOps|Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.|

## Module Details

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
|persistence|`[_1.BrokerPersistence](#user-defined-types)`|Broker persistence configuration for disk-backed message storage.|

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

### `_1.BrokerPersistence`

Broker persistence configuration for disk-backed message storage.

|Property|Type|Description|
| :--- | :--- | :--- |
|enabled|`bool`|Whether persistence is enabled.|
|maxSize|`string`|Maximum size of the message buffer on disk (e.g., "500M", "1G").|
|encryption|`object`|Encryption configuration for the persistence database.|
|dynamicSettings|`object`|Dynamic settings for MQTTv5 user property-based persistence control.|
|retain|`object`|Controls which retained messages should be persisted to disk.|
|stateStore|`object`|Controls which state store keys should be persisted to disk.|
|subscriberQueue|`object`|Controls which subscriber queues should be persisted to disk.|
|persistentVolumeClaimSpec|`object`|Persistent volume claim specification for storage.|

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