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
|namespacedDevices|List of namespaced devices to create.|`array`|[]|no|
|assetEndpointProfiles|List of asset endpoint profiles to create.|`array`|[]|no|
|legacyAssets|List of legacy assets to create.|`array`|[]|no|
|namespacedAssets|List of namespaced assets to create.|`array`|[]|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|edgeIotOps|`Microsoft.Resources/deployments`|2025-04-01|
|edgeAssets|`Microsoft.Resources/deployments`|2025-04-01|

## Modules

|Name|Description|
| :--- | :--- |
|edgeIotOps|Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.|
|edgeAssets|Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.|

## Module Details

### edgeIotOps

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.

#### Parameters for edgeIotOps

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|arcConnectedClusterName|The resource name for the Arc connected cluster.|`string`|n/a|yes|
|containerStorageConfig|The settings for the Azure Container Store for Azure Arc Extension.|`[_1.ContainerStorageExtension](#user-defined-types)`|[variables('_1.containerStorageExtensionDefaults')]|no|
|aioCertManagerConfig|The settings for the Azure IoT Operations Platform Extension.|`[_1.AioCertManagerExtension](#user-defined-types)`|[variables('_1.aioCertManagerExtensionDefaults')]|no|
|secretStoreConfig|The settings for the Secret Store Extension.|`[_1.SecretStoreExtension](#user-defined-types)`|[variables('_1.secretStoreExtensionDefaults')]|no|
|shouldInitAio|Whether to deploy the Azure IoT Operations initial connected cluster resources, Secret Sync, ACSA, OSM, AIO Platform.|`bool`|`true`|no|
|aioIdentityName|The name of the User Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioExtensionConfig|The settings for the Azure IoT Operations Extension.|`[_1.AioExtension](#user-defined-types)`|[variables('_1.aioExtensionDefaults')]|no|
|aioFeatures|AIO Instance features.|`[_1.AioFeatures](#user-defined-types)`|n/a|no|
|aioInstanceName|The name for the Azure IoT Operations Instance resource.|`string`|[format('{0}-ops-instance', parameters('arcConnectedClusterName'))]|no|
|aioDataFlowInstanceConfig|The settings for Azure IoT Operations Data Flow Instances.|`[_1.AioDataFlowInstance](#user-defined-types)`|[variables('_1.aioDataFlowInstanceDefaults')]|no|
|aioMqBrokerConfig|The settings for the Azure IoT Operations MQ Broker.|`[_1.AioMqBroker](#user-defined-types)`|[variables('_1.aioMqBrokerDefaults')]|no|
|brokerListenerAnonymousConfig|Configuration for the insecure anonymous AIO MQ Broker Listener.|`[_1.AioMqBrokerAnonymous](#user-defined-types)`|[variables('_1.aioMqBrokerAnonymousDefaults')]|no|
|schemaRegistryName|The resource name for the ADR Schema Registry for Azure IoT Operations.|`string`|n/a|yes|
|adrNamespaceName|The resource name for the ADR Namespace for Azure IoT Operations.|`string`|n/a|no|
|shouldDeployAio|Whether to deploy an Azure IoT Operations Instance and all of its required components into the connected cluster.|`bool`|`true`|no|
|shouldDeployResourceSyncRules|Whether or not to deploy the Custom Locations Resource Sync Rules for the Azure IoT Operations resources.|`bool`|`true`|no|
|shouldCreateAnonymousBrokerListener|Whether to enable an insecure anonymous AIO MQ Broker Listener. (Should only be used for dev or test environments)|`bool`|`false`|no|
|shouldEnableOtelCollector|Whether or not to enable the Open Telemetry Collector for Azure IoT Operations.|`bool`|`true`|no|
|shouldEnableOpcUaSimulator|Whether or not to enable the OPC UA Simulator for Azure IoT Operations.|`bool`|`true`|no|
|shouldEnableAkriRestConnector|Deploy Akri REST HTTP Connector template to the IoT Operations instance.|`bool`|`false`|no|
|shouldEnableAkriMediaConnector|Deploy Akri Media Connector template to the IoT Operations instance.|`bool`|`false`|no|
|shouldEnableAkriOnvifConnector|Deploy Akri ONVIF Connector template to the IoT Operations instance.|`bool`|`false`|no|
|shouldEnableAkriSseConnector|Deploy Akri SSE Connector template to the IoT Operations instance.|`bool`|`false`|no|
|customAkriConnectors|List of custom Akri connector templates with user-defined endpoint types and container images.|`array`|[]|no|
|akriMqttSharedConfig|Shared MQTT connection configuration for all Akri connectors.|`[_1.AkriMqttConfig](#user-defined-types)`|{'host': 'aio-broker:18883', 'audience': 'aio-internal', 'caConfigmap': 'azure-iot-operations-aio-ca-trust-bundle'}|no|
|customLocationName|The name for the Custom Locations resource.|`string`|[format('{0}-cl', parameters('arcConnectedClusterName'))]|no|
|trustIssuerSettings|The trust issuer settings for Customer Managed Azure IoT Operations Settings.|`[_1.TrustIssuerConfig](#user-defined-types)`|{'trustSource': 'SelfSigned'}|no|
|sseKeyVaultName|The name of the Key Vault for Secret Sync. (Required when providing sseIdentityName)|`string`|n/a|yes|
|sseIdentityName|The name of the User Assigned Managed Identity for Secret Sync.|`string`|n/a|yes|
|sseKeyVaultResourceGroupName|The name of the Resource Group for the Key Vault for Secret Sync. (Required when providing sseIdentityName)|`string`|[resourceGroup().name]|no|
|shouldAssignSseKeyVaultRoles|Whether to assign roles for Key Vault to the provided Secret Sync Identity.|`bool`|`true`|no|
|shouldAssignDeployIdentityRoles|Whether to assign roles to the deploy identity.|`bool`|[not(empty(parameters('deployIdentityName')))]|no|
|deployIdentityName|The resource name for a managed identity that will be given deployment admin permissions.|`string`|n/a|no|
|shouldDeployAioDeploymentScripts|Whether to deploy DeploymentScripts for Azure IoT Operations.|`bool`|`false`|no|
|deployKeyVaultName|The name of the Key Vault that will have scripts and secrets for deployment.|`string`|[parameters('sseKeyVaultName')]|no|
|deployKeyVaultResourceGroupName|The resource group name where the Key Vault is located. Defaults to the current resource group.|`string`|[parameters('sseKeyVaultResourceGroupName')]|no|
|deployUserTokenSecretName|The name for the deploy user token secret in Key Vault.|`string`|deploy-user-token|no|
|deploymentScriptsSecretNamePrefix|The prefix used with constructing the secret name that will have the deployment script.|`string`|[format('{0}-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]|no|
|shouldAddDeployScriptsToKeyVault|Whether to add the deploy scripts for DeploymentScripts to Key Vault as secrets. (Required for DeploymentScripts)|`bool`|`false`|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

#### Resources for edgeIotOps

|Name|Type|API Version|
| :--- | :--- | :--- |
|deployArcK8sRoleAssignments|`Microsoft.Resources/deployments`|2025-04-01|
|deployKeyVaultRoleAssignments|`Microsoft.Resources/deployments`|2025-04-01|
|sseKeyVaultRoleAssignments|`Microsoft.Resources/deployments`|2025-04-01|
|iotOpsInit|`Microsoft.Resources/deployments`|2025-04-01|
|postInitScriptsSecrets|`Microsoft.Resources/deployments`|2025-04-01|
|postInitScripts|`Microsoft.Resources/deployments`|2025-04-01|
|iotOpsInstance|`Microsoft.Resources/deployments`|2025-04-01|
|akriConnectors|`Microsoft.Resources/deployments`|2025-04-01|
|postInstanceScriptsSecrets|`Microsoft.Resources/deployments`|2025-04-01|
|postInstanceScripts|`Microsoft.Resources/deployments`|2025-04-01|

#### Outputs for edgeIotOps

|Name|Type|Description|
| :--- | :--- | :--- |
|containerStorageExtensionId|`string`|The ID of the Container Storage Extension.|
|containerStorageExtensionName|`string`|The name of the Container Storage Extension.|
|aioCertManagerExtensionId|`string`|The ID of the Azure IoT Operations Cert-Manager Extension.|
|aioCertManagerExtensionName|`string`|The name of the Azure IoT Operations Cert-Manager Extension.|
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
|akriConnectorTemplates|`array`|Map of deployed Akri connector templates by name with id and type.|
|akriConnectorTypesDeployed|`array`|List of Akri connector types that were deployed.|

### edgeAssets

Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.

#### Parameters for edgeAssets

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|customLocationId|The ID (resource ID) of the custom location to retrieve.|`string`|n/a|yes|
|adrNamespaceName|Azure Device Registry namespace name to use with Azure IoT Operations.|`string`|n/a|yes|
|namespacedDevices|List of namespaced devices to create.|`array`|[]|no|
|assetEndpointProfiles|List of asset endpoint profiles to create.|`array`|[]|no|
|legacyAssets|List of legacy assets to create.|`array`|[]|no|
|namespacedAssets|List of namespaced assets to create.|`array`|[]|no|
|shouldCreateDefaultAsset|Whether to create a default legacy asset and endpoint profile.|`bool`|`false`|no|
|shouldCreateDefaultNamespacedAsset|Whether to create a default namespaced asset and device.|`bool`|`false`|no|
|k8sBridgePrincipalId|The principal ID of the K8 Bridge for Azure IoT Operations. Required for OPC asset discovery.|`string`|n/a|no|

#### Resources for edgeAssets

|Name|Type|API Version|
| :--- | :--- | :--- |
|namespacedDevice|`Microsoft.DeviceRegistry/namespaces/devices`|2025-10-01|
|namespacedAsset|`Microsoft.DeviceRegistry/namespaces/assets`|2025-10-01|
|assetEndpointProfile|`Microsoft.DeviceRegistry/assetEndpointProfiles`|2025-10-01|
|legacyAsset|`Microsoft.DeviceRegistry/assets`|2025-10-01|
|k8BridgeRoleAssignment|`Microsoft.Resources/deployments`|2025-04-01|

#### Outputs for edgeAssets

|Name|Type|Description|
| :--- | :--- | :--- |
|assetEndpointProfiles|`array`|Array of legacy asset endpoint profiles created by this component.|
|legacyAssets|`array`|Array of legacy assets created by this component.|
|namespacedDevices|`array`|Array of namespaced devices created by this component.|
|namespacedAssets|`array`|Array of namespaced assets created by this component.|
|shouldEnableOpcAssetDiscovery|`bool`|Whether OPC simulation asset discovery is enabled for any endpoint profile.|

## User Defined Types

### `_1.AssetDataPoint`

Data point configuration for asset datasets.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the data point.|
|dataSource|`string`|Data source address.|
|dataPointConfiguration|`string`|Data point configuration as JSON string.|
|samplingIntervalMs|`int`|Sampling interval in milliseconds for REST endpoints.|
|mqttTopic|`string`|MQTT topic for REST state store.|
|includeStateStore|`bool`|Whether to include state store for REST endpoints.|
|stateStoreKey|`string`|State store key for REST endpoints.|

### `_1.AssetDataset`

Dataset configuration for assets.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the dataset.|
|datasetConfiguration|`string`|Dataset configuration as JSON string.|
|dataSource|`string`|Data source address for the dataset.|
|typeRef|`string`|Type reference for the dataset.|
|dataPoints|`array`|Data points in the dataset.|
|destinations|`array`|Destinations for the dataset.|

### `_1.AssetEndpointProfile`

Legacy asset endpoint profile configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the asset endpoint profile.|
|endpointProfileType|`string`|Type of the endpoint profile: Microsoft.OpcUa, etc.|
|method|`string`|Authentication method: Anonymous, etc.|
|targetAddress|`string`|Target address of the endpoint.|
|opcAdditionalConfigString|`string`|Additional OPC configuration as JSON string.|
|shouldEnableOpcAssetDiscovery|`bool`|Whether to enable OPC asset discovery.|

### `_1.DatasetDestination`

Dataset destination configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|target|`string`|Target for the destination: Mqtt, etc.|
|configuration|`object`|Configuration for the destination.|

### `_1.DeviceEndpoint`

Endpoint configuration for devices.

|Property|Type|Description|
| :--- | :--- | :--- |
|endpointType|`string`|Type of the endpoint: Microsoft.OpcUa, etc.|
|address|`string`|Address of the endpoint.|
|version|`string`|Version of the endpoint protocol.|
|additionalConfiguration|`string`|Additional configuration as JSON string.|
|authentication|`[_1.EndpointAuthentication](#user-defined-types)`|Authentication configuration for the endpoint.|
|trustSettings|`[_1.TrustSettings](#user-defined-types)`|Trust settings for the endpoint.|

### `_1.DeviceEndpoints`

Device endpoints configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|outbound|`object`|Outbound endpoint configuration.|
|inbound|`object`|Inbound endpoint configurations.|

### `_1.DeviceReference`

Device reference for namespaced assets.

|Property|Type|Description|
| :--- | :--- | :--- |
|deviceName|`string`|Name of the device.|
|endpointName|`string`|Name of the endpoint on the device.|

### `_1.EndpointAuthentication`

Endpoint authentication configuration for assets.

|Property|Type|Description|
| :--- | :--- | :--- |
|method|`string`|Authentication method: Anonymous, UsernamePassword, or X509|
|usernamePasswordCredentials|`object`|Username and password credentials for authentication.|
|x509Credentials|`object`|X509 certificate credentials for authentication.|

### `_1.LegacyAsset`

Legacy asset configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the asset.|
|assetEndpointProfileRef|`string`|Reference to the asset endpoint profile.|
|displayName|`string`|Display name of the asset.|
|description|`string`|Description of the asset.|
|documentationUri|`string`|Documentation URI for the asset.|
|isEnabled|`bool`|Whether the asset is enabled.|
|hardwareRevision|`string`|Hardware revision of the asset.|
|manufacturer|`string`|Manufacturer of the asset.|
|manufacturerUri|`string`|Manufacturer URI of the asset.|
|model|`string`|Model of the asset.|
|productCode|`string`|Product code of the asset.|
|serialNumber|`string`|Serial number of the asset.|
|softwareRevision|`string`|Software revision of the asset.|
|datasets|`array`|Datasets for the asset.|
|defaultDatasetsConfiguration|`string`|Default datasets configuration as JSON string.|

### `_1.LegacyAssetDataPoint`

Legacy asset data point configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the data point.|
|dataSource|`string`|Data source address.|
|dataPointConfiguration|`string`|Data point configuration as JSON string.|
|observabilityMode|`string`|Observability mode: None, etc.|

### `_1.LegacyAssetDataset`

Legacy asset dataset configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the dataset.|
|dataPoints|`array`|Data points in the dataset.|

### `_1.NamespacedAsset`

Namespaced asset configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the asset.|
|displayName|`string`|Display name of the asset.|
|deviceRef|`[_1.DeviceReference](#user-defined-types)`|Reference to the device and endpoint.|
|description|`string`|Description of the asset.|
|documentationUri|`string`|Documentation URI for the asset.|
|externalAssetId|`string`|Asset Id provided by external system for the asset.|
|isEnabled|`bool`|Whether the asset is enabled.|
|hardwareRevision|`string`|Hardware revision of the asset.|
|manufacturer|`string`|Manufacturer of the asset.|
|manufacturerUri|`string`|Manufacturer URI of the asset.|
|model|`string`|Model of the asset.|
|productCode|`string`|Product code of the asset.|
|serialNumber|`string`|Serial number of the asset.|
|softwareRevision|`string`|Software revision of the asset.|
|attributes|`object`|Custom attributes for the asset.|
|datasets|`array`|Datasets for the asset.|
|defaultDatasetsConfiguration|`string`|Default datasets configuration as JSON string.|
|defaultEventsConfiguration|`string`|Default events configuration as JSON string.|

### `_1.NamespacedDevice`

Namespaced device configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the device.|
|isEnabled|`bool`|Whether the device is enabled.|
|endpoints|`[_1.DeviceEndpoints](#user-defined-types)`|Endpoint configurations for the device.|

### `_1.TrustSettings`

Trust settings for endpoint connections.

|Property|Type|Description|
| :--- | :--- | :--- |
|trustList|`string`|Trust list configuration.|

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
|aioCertManagerExtensionId|`string`|The ID of the Azure IoT Operations Cert-Manager Extension.|
|aioCertManagerExtensionName|`string`|The name of the Azure IoT Operations Cert-Manager Extension.|
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