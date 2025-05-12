<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Azure IoT Operations Messaging

Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.

## Parameters

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

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|aioIdentity|`Microsoft.ManagedIdentity/userAssignedIdentities`|2023-01-31|
|aioCustomLocation|`Microsoft.ExtendedLocation/customLocations`|2021-08-31-preview|
|eventHubDataflow|`Microsoft.Resources/deployments`|2022-09-01|
|eventGridDataflow|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|eventHubDataflow|Provisions the ARM based data flow endpoint and data flow for Event Hub, requires Asset.|
|eventGridDataflow|Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset.|

## Module Details

### eventHubDataflow

Provisions the ARM based data flow endpoint and data flow for Event Hub, requires Asset.

#### Parameters for eventHubDataflow

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|eventHub|The values for the existing Event Hub namespace and Event Hub.|`[_1.EventHub](#user-defined-types)`|n/a|yes|
|assetName|The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.|`string`|n/a|yes|
|aioUamiTenantId|The tenant ID of the User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioUamiClientId|The client ID of the User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioInstanceName|The name of the Azure IoT Operations Instance.|`string`|n/a|yes|
|aioDataflowProfileName|The name of the Azure IoT Operations Dataflow Profile.|`string`|default|no|
|customLocationId|The resource ID of the Custom Location.|`string`|n/a|yes|

#### Resources for eventHubDataflow

|Name|Type|API Version|
| :--- | :--- | :--- |
|aioInstanceResource|`Microsoft.IoTOperations/instances`|2025-04-01|
|aioDataflowProfileResource|`Microsoft.IoTOperations/instances/dataflowProfiles`|2025-04-01|
|dataflowEndpointToEventHub|`Microsoft.IoTOperations/instances/dataflowEndpoints`|2025-04-01|
|dataflowToEventHub|`Microsoft.IoTOperations/instances/dataflowProfiles/dataflows`|2025-04-01|

### eventGridDataflow

Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset.

#### Parameters for eventGridDataflow

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|eventGrid|The values for the existing Event Grid.|`[_1.EventGrid](#user-defined-types)`|n/a|yes|
|assetName|The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.|`string`|n/a|yes|
|aioUamiTenantId|The tenant ID of the User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioUamiClientId|The client ID of the User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|aioInstanceName|The name of the Azure IoT Operations Instance.|`string`|n/a|yes|
|aioDataflowProfileName|The name of the Azure IoT Operations Dataflow Profile.|`string`|default|no|
|customLocationId|The resource ID of the Custom Location.|`string`|n/a|yes|

#### Resources for eventGridDataflow

|Name|Type|API Version|
| :--- | :--- | :--- |
|aioInstanceResource|`Microsoft.IoTOperations/instances`|2025-04-01|
|aioDataflowProfileResource|`Microsoft.IoTOperations/instances/dataflowProfiles`|2025-04-01|
|dataflowEndpointToEventGrid|`Microsoft.IoTOperations/instances/dataflowEndpoints`|2025-04-01|
|dataflowToEventGrid|`Microsoft.IoTOperations/instances/dataflowProfiles/dataflows`|2025-04-01|

## User Defined Types

### `_1.EventGrid`

Event Grid configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|name|`string`|The name of the Event Grid.|
|topicName|`string`|The topic name of the Event Grid.|
|endpoint|`string`|The endpoint of the Event Grid.|

### `_1.EventHub`

Event Hub configuration.

|Property|Type|Description|
| :--- | :--- | :--- |
|namespaceName|`string`|The namespace name of the Event Hub.|
|eventHubName|`string`|The name of the Event Hub.|

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