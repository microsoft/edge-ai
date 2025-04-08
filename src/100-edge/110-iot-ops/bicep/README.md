<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Azure IoT Operations

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioPlatformExtension](#user-defined-types)`|[variables('_1.aioPlatformExtensionDefaults')]|no|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|[variables('_1.containerStorageExtensionDefaults')]|no|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|`[_1.OpenServiceMeshExtension](#user-defined-types)`|[variables('_1.openServiceMeshExtensionDefaults')]|no|
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|[variables('_1.secretStoreExtensionDefaults')]|no|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|[variables('_1.aioExtensionDefaults')]|no|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|`true`|no|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|[variables('_1.aioMqBrokerDefaults')]|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|`false`|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|[variables('_1.aioMqBrokerAnonymousDefaults')]|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|[variables('_1.aioDataFlowInstanceDefaults')]|no|
|customLocationName|The name for the Custom Locations resource.|`string`|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|`false`|no|
|trustSource|The source for trust for Azure IoT Operations.|`[_1.TrustSource](#user-defined-types)`|SelfSigned|no|
|shouldAssignKeyVaultRoles|Whether to assign roles for Key Vault to the provided Secret Sync Identity.|`bool`|`true`|no|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)|`string`|n/a|yes|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|roleAssignment|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInit|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstance|`Microsoft.Resources/deployments`|2022-09-01|
|iotOpsInstancePost|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|roleAssignment|Assigns roles for Secret Sync to access Key Vault.|
|iotOpsInit|Initializes and configures the required Arc extensions for Azure IoT Operations including Secret Store, Open Service Mesh, Container Storage, and IoT Operations Platform.|
|iotOpsInstance|Deploys Azure IoT Operations instance, broker, authentication, listeners, and data flow components on an Azure Arc-enabled Kubernetes cluster.|
|iotOpsInstancePost|Configures federated identity credentials for Azure IoT Operations and Secret Sync Extension service accounts and sets up Key Vault Secret Provider Class.|

## Module Details

### roleAssignment

Assigns roles for Secret Sync to access Key Vault.

#### Parameters for roleAssignment

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|keyVaultName|The name of the Key Vault to scope the role assignments.|`string`|n/a|yes|
|sseUserAssignedIdentityName|The Principal ID for the Secret Sync User Assigned Managed Identity.|`string`|n/a|yes|

#### Resources for roleAssignment

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseKeyVault|`Microsoft.KeyVault/vaults`|2023-07-01|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|keyVaultReaderSseUami|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|keyVaultSecretsUserSseUami|`Microsoft.Authorization/roleAssignments`|2022-04-01|

### iotOpsInit

Initializes and configures the required Arc extensions for Azure IoT Operations including Secret Store, Open Service Mesh, Container Storage, and IoT Operations Platform.

#### Parameters for iotOpsInit

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|n/a|yes|
|openServiceMeshConfig|The settings for the Open Service Mesh Extension.|`[_1.OpenServiceMeshExtension](#user-defined-types)`|n/a|yes|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|n/a|yes|
|aioPlatformConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioPlatformExtension](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|

#### Resources for iotOpsInit

|Name|Type|API Version|
| :--- | :--- | :--- |
|arcConnectedCluster|`Microsoft.Kubernetes/connectedClusters`|2021-03-01|
|secretStore|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|openServiceMesh|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|containerStorage|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|aioPlatform|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|

#### Outputs for iotOpsInit

|Name|Type|Description|
| :--- | :--- | :--- |
|containerStorageExtensionId|`string`||
|secretStoreExtensionId|`string`||
|openServiceMeshExtensionId|`string`||
|aioPlatformExtensionId|`string`||

### iotOpsInstance

Deploys Azure IoT Operations instance, broker, authentication, listeners, and data flow components on an Azure Arc-enabled Kubernetes cluster.

#### Parameters for iotOpsInstance

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|Name of the existing arc-enabled cluster where AIO will be deployed.|`string`|n/a|yes|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|n/a|yes|
|secretStoreExtensionId|The resource ID for the Secret Store Extension.|`string`|n/a|yes|
|aioPlatformExtensionId|The resource ID for the Azure IoT Operations Platform Extension.|`string`|n/a|yes|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|n/a|yes|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|n/a|yes|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|False|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|n/a|yes|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|n/a|yes|
|customLocationName|The name for the Custom Locations resource.|`string`|n/a|yes|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|n/a|yes|
|aioIdentityName|The resource name for the User Assigned Identity for Azure IoT Operations.|`string`|n/a|yes|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|n/a|yes|
|trustSource|The source for trust for Azure IoT Operations.|`[_1.TrustSource](#user-defined-types)`|n/a|yes|

#### Resources for iotOpsInstance

|Name|Type|API Version|
| :--- | :--- | :--- |
|aioIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|schemaRegistry|`Microsoft.DeviceRegistry/schemaRegistries`|2024-09-01-preview|
|arcConnectedCluster|`Microsoft.Kubernetes/connectedClusters`|2021-03-01|
|aioExtension|`Microsoft.KubernetesConfiguration/extensions`|2023-05-01|
|customLocation|`Microsoft.ExtendedLocation/customLocations`|2021-08-31-preview|
|aioSyncRule|`Microsoft.ExtendedLocation/customLocations/resourceSyncRules`|2021-08-31-preview|
|adrSyncRule|`Microsoft.ExtendedLocation/customLocations/resourceSyncRules`|2021-08-31-preview|
|aioInstance|`Microsoft.IoTOperations/instances`|2024-11-01|
|broker|`Microsoft.IoTOperations/instances/brokers`|2024-11-01|
|brokerAuthn|`Microsoft.IoTOperations/instances/brokers/authentications`|2024-11-01|
|brokerListener|`Microsoft.IoTOperations/instances/brokers/listeners`|2024-11-01|
|brokerListenerAnonymous|`Microsoft.IoTOperations/instances/brokers/listeners`|2024-11-01|
|dataFlowProfile|`Microsoft.IoTOperations/instances/dataflowProfiles`|2024-11-01|
|dataFlowEndpoint|`Microsoft.IoTOperations/instances/dataflowEndpoints`|2024-11-01|

#### Outputs for iotOpsInstance

|Name|Type|Description|
| :--- | :--- | :--- |
|aioInstanceName|`string`||
|aioInstanceId|`string`||
|customLocationName|`string`||
|customLocationId|`string`||
|dataFlowProfileName|`string`||
|dataFlowProfileId|`string`||
|dataFlowEndpointName|`string`||
|dataFlowEndPointId|`string`||

### iotOpsInstancePost

Configures federated identity credentials for Azure IoT Operations and Secret Sync Extension service accounts and sets up Key Vault Secret Provider Class.

#### Parameters for iotOpsInstancePost

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|Name of the existing arc-enabled cluster where AIO will be deployed.|`string`|n/a|yes|
|customLocationId|The resource Id for the Custom Locations for Azure IoT Operations.|`string`|n/a|yes|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)|`string`|n/a|yes|
|aioNamespace|The namespace for Azure IoT Operations in the cluster.|`string`|n/a|yes|

#### Resources for iotOpsInstancePost

|Name|Type|API Version|
| :--- | :--- | :--- |
|sseIdentity::sseFedCred|`Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials`|2023-01-31|
|aioIdentity::aioFedCred|`Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials`|2023-01-31|
|arcConnectedCluster|`Microsoft.Kubernetes/connectedClusters`|2024-12-01-preview|
|sseIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|aioIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|defaultSecretSyncSecretProviderClass|`Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses`|2024-08-21-preview|

## User Defined Types

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

### `_1.AioMqBroker`

The settings for the Azure IoT Operations MQ Broker.

|Property|Type|Description|
| :--- | :--- | :--- |
|brokerListenerServiceName|`string`||
|brokerListenerPort|`int`||
|serviceAccountAudience|`string`||
|frontendReplicas|`int`||
|frontendWorkers|`int`||
|backendRedundancyFactor|`int`||
|backendWorkers|`int`||
|backendPartitions|`int`||
|memoryProfile|`string`||
|serviceType|`string`||

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

### `_1.SecretStoreExtension`

The settings for the Secret Store Extension.

|Property|Type|Description|
| :--- | :--- | :--- |
|release|`[_1.Release](#user-defined-types)`|The common settings for the extension.|

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

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->