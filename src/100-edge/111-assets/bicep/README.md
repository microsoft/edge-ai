<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Kubernetes Assets

Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.

## Parameters

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

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|namespacedDevice|`Microsoft.DeviceRegistry/namespaces/devices`|2025-10-01|
|namespacedAsset|`Microsoft.DeviceRegistry/namespaces/assets`|2025-10-01|
|assetEndpointProfile|`Microsoft.DeviceRegistry/assetEndpointProfiles`|2025-10-01|
|legacyAsset|`Microsoft.DeviceRegistry/assets`|2025-10-01|
|k8BridgeRoleAssignment|`Microsoft.Resources/deployments`|2025-04-01|

## Modules

|Name|Description|
| :--- | :--- |
|k8BridgeRoleAssignment|Assigns Azure Kubernetes Service Arc Contributor Role to K8 Bridge principal for OPC asset discovery.|

## Module Details

### k8BridgeRoleAssignment

Assigns Azure Kubernetes Service Arc Contributor Role to K8 Bridge principal for OPC asset discovery.

#### Parameters for k8BridgeRoleAssignment

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|customLocationId|The ID (resource ID) of the custom location.|`string`|n/a|yes|
|k8sBridgePrincipalId|The principal ID of the K8 Bridge for Azure IoT Operations. Required when this module is used.|`string`|n/a|yes|

#### Resources for k8BridgeRoleAssignment

|Name|Type|API Version|
| :--- | :--- | :--- |
|[guid(parameters('customLocationId'), 'Azure Kubernetes Service Arc Contributor Role', parameters('k8sBridgePrincipalId'))]|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for k8BridgeRoleAssignment

|Name|Type|Description|
| :--- | :--- | :--- |
|roleAssignmentId|`string`|The ID of the role assignment.|
|principalId|`string`|The principal ID used for the role assignment.|

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

### `_1.AssetEvent`

Event configuration for assets.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the event.|
|eventConfiguration|`string`|Event configuration as JSON string.|
|eventPoints|`array`|Event points in the event.|
|destinations|`array`|Destinations for the event.|

### `_1.AssetEventPoint`

Event point configuration for asset events.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the event point.|
|eventNotifier|`string`|Event notifier address.|
|eventPointConfiguration|`string`|Event point configuration as JSON string.|

### `_1.AssetStreamSet`

Stream set configuration for assets.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|Name of the stream set.|
|streamSetConfiguration|`string`|Stream set configuration as JSON string.|
|dataSource|`string`|Data source address for the stream.|
|destinations|`array`|Destinations for the stream set.|

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
|streamSets|`array`|Stream sets for the asset.|
|defaultStreamSetsConfiguration|`string`|Default stream sets configuration as JSON string.|
|events|`array`|Events for the asset.|
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
|assetEndpointProfiles|`array`|Array of legacy asset endpoint profiles created by this component.|
|legacyAssets|`array`|Array of legacy assets created by this component.|
|namespacedDevices|`array`|Array of namespaced devices created by this component.|
|namespacedAssets|`array`|Array of namespaced assets created by this component.|
|shouldEnableOpcAssetDiscovery|`bool`|Whether OPC simulation asset discovery is enabled for any endpoint profile.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
