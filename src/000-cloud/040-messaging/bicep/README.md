<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Cloud Messaging

Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|tags|Additional tags to add to the resources.|`object`|{}|no|
|aioIdentityName|The User-Assigned Managed Identity for Azure IoT Operations.|`string`|n/a|yes|
|shouldCreateEventHub|Whether to create Event Hubs resources.|`bool`|`true`|no|
|eventHubConfig|The configuration for the Event Hubs Namespace.|`[_1.EventHubConfig](#user-defined-types)`|n/a|no|
|shouldCreateEventGrid|Whether to create Event Grid resources.|`bool`|`true`|no|
|eventGridConfig|The configuration for the Event Grid Domain.|`[_1.EventGridConfig](#user-defined-types)`|n/a|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|eventHub|`Microsoft.Resources/deployments`|2025-04-01|
|eventGrid|`Microsoft.Resources/deployments`|2025-04-01|

## Modules

|Name|Description|
| :--- | :--- |
|eventHub|Deploys Azure Event Hubs Namespace with Event Hubs, partitions, and consumer groups.|
|eventGrid|Deploys Azure Event Grid Domain with topics and event subscriptions.|

## Module Details

### eventHub

Deploys Azure Event Hubs Namespace with Event Hubs, partitions, and consumer groups.

#### Parameters for eventHub

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|eventHubConfig|The Event Hubs configuration.|`[_1.EventHubConfig](#user-defined-types)`|{'sku': 'Standard', 'capacity': 1, 'eventHubs': [{'name': "[format('evh-{0}-aio-{1}-{2}', parameters('common').resourcePrefix, parameters('common').environment, parameters('common').instance)]", 'messageRetentionInDays': 1, 'partitionCount': 1}]}|no|
|tags|Additional tags to add to the resources.|`object`|{}|no|
|aioIdentityName|The Azure IoT Operations User Assigned Managed Identity name.|`string`|n/a|yes|

#### Resources for eventHub

|Name|Type|API Version|
| :--- | :--- | :--- |
|eventHubNamespace|`Microsoft.EventHub/namespaces`|2024-05-01-preview|
|eventHubs|`Microsoft.EventHub/namespaces/eventhubs`|2024-05-01-preview|
|dataSenderRoleAssignment|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for eventHub

|Name|Type|Description|
| :--- | :--- | :--- |
|namespaceName|`string`|The name of the Event Hubs Namespace.|
|namespaceId|`string`|The ID of the Event Hubs Namespace.|
|eventHubNames|`array`|The list of Event Hub names created in the namespace.|

### eventGrid

Deploys Azure Event Grid Domain with topics and event subscriptions.

#### Parameters for eventGrid

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|eventGridConfig|The Event Grid configuration.|`[_1.EventGridConfig](#user-defined-types)`|{'capacity': 1, 'eventGridMaxClientSessionsPerAuthName': 8, 'topicTemplates': ['default']}|no|
|tags|Additional tags to add to the resources.|`object`|{}|no|
|aioIdentityName|The Azure IoT Operations User Assigned Managed Identity name.|`string`|n/a|yes|

#### Resources for eventGrid

|Name|Type|API Version|
| :--- | :--- | :--- |
|eventGridNamespace|`Microsoft.EventGrid/namespaces`|2025-02-15|
|topicSpace|`Microsoft.EventGrid/namespaces/topicSpaces`|2025-02-15|
|dataSenderRoleAssignment|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for eventGrid

|Name|Type|Description|
| :--- | :--- | :--- |
|namespaceName|`string`|The name of the Event Grid Namespace.|
|namespaceId|`string`|The ID of the Event Grid Namespace.|
|topicSpaceId|`string`|The ID of the Event Grid Topic Space.|
|topicSpaceName|`string`|The name of the Event Grid Topic Space.|
|mqttEndpoint|`string`|The MQTT endpoint for connecting to Event Grid.|

## User Defined Types

### `_1.EventGridConfig`

The configuration for Event Grid Domain.

|Property|Type|Description|
| :--- | :--- | :--- |
|capacity|`int`|Event Grid Namespace SKU capacity. Values between 1 and 40 are supported.|
|eventGridMaxClientSessionsPerAuthName|`int`|Specifies the maximum number of client sessions per authentication name. Valid values are from 3 to 100. This parameter should be greater than the number of dataflows|
|topicTemplates|`array`|The topic templates for Event Grid namespace topic spaces.|

### `_1.EventHubConfig`

The configuration for Event Hubs Namespace.

|Property|Type|Description|
| :--- | :--- | :--- |
|sku|`string`|The SKU of the Event Hubs Namespace.|
|capacity|`int`|The capacity of the Event Hubs Namespace.|
|eventHubs|`array`|The list of Event Hubs to create in the namespace.|

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
|eventHubNamespaceName|`string`|The Event Hubs Namespace name.|
|eventHubNamespaceId|`string`|The Event Hubs Namespace ID.|
|eventHubNames|`array`|The list of Event Hub names created in the namespace.|
|eventGridTopicNames|`string`|The Event Grid topic name created.|
|eventGridMqttEndpoint|`string`|The Event Grid endpoint URL for MQTT connections|
|eventHubConfig|`object`|The Event Hub configuration object for edge messaging.|
|eventGridConfig|`object`|The Event Grid configuration object for edge messaging.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->