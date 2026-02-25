<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Azure IoT Operations Messaging

Deploys Dataflow endpoints and dataflows for Azure IoT Operations messaging integration, specifically for Event Hub and Event Grid.

## Parameters

| Name                   | Description                                                                                                         | Type                                           | Default | Required |
|:-----------------------|:--------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------|:--------|:---------|
| common                 | The common component configuration.                                                                                 | `[_2.Common](#user-defined-types)`             | n/a     | yes      |
| aioIdentityName        | The name of the User-Assigned Managed Identity for Azure IoT Operations.                                            | `string`                                       | n/a     | yes      |
| aioCustomLocationName  | The name of the Azure IoT Operations Custom Location.                                                               | `string`                                       | n/a     | yes      |
| aioInstanceName        | The name of the Azure IoT Operations Instance.                                                                      | `string`                                       | n/a     | yes      |
| aioDataflowProfileName | The name of the Azure IoT Operations Dataflow Profile.                                                              | `string`                                       | default | no       |
| assetName              | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud.            | `string`                                       | oven    | no       |
| adrNamespaceName       | The name of the Azure IoT Operations Device Registry namespace to use when referencing the asset.                   | `string`                                       | n/a     | no       |
| eventHub               | Values for the existing Event Hub namespace and Event Hub. If not provided, Event Hub dataflow will not be created. | `[_1.EventHub](#user-defined-types)`           | n/a     | no       |
| eventGrid              | Values for the existing Event Grid. If not provided, Event Grid dataflow will not be created.                       | `[_1.EventGrid](#user-defined-types)`          | n/a     | no       |
| dataflowGraphs         | The list of dataflow graphs to create.                                                                              | `[_1.DataflowGraph](#user-defined-types)[]`    | []      | no       |
| dataflows              | The list of dataflows to create.                                                                                    | `[_1.Dataflow](#user-defined-types)[]`         | []      | no       |
| dataflowEndpoints      | The list of dataflow endpoints to create.                                                                           | `[_1.DataflowEndpoint](#user-defined-types)[]` | []      | no       |
| telemetry_opt_out      | Whether to opt out of telemetry data collection.                                                                    | `bool`                                         | `false` | no       |

## Resources

| Name                    | Type                              | API Version |
|:------------------------|:----------------------------------|:------------|
| eventHubDataflow        | `Microsoft.Resources/deployments` | 2025-04-01  |
| eventGridDataflow       | `Microsoft.Resources/deployments` | 2025-04-01  |
| dataflowGraphsModule    | `Microsoft.Resources/deployments` | 2025-04-01  |
| dataflowsModule         | `Microsoft.Resources/deployments` | 2025-04-01  |
| dataflowEndpointsModule | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                    | Description                                                                                                     |
|:------------------------|:----------------------------------------------------------------------------------------------------------------|
| eventHubDataflow        | Provisions the ARM based data flow endpoint and data flow for Event Hub, requires Asset.                        |
| eventGridDataflow       | Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset.                       |
| dataflowGraphsModule    | Provisions dataflow graphs for Azure IoT Operations with WASM operator and standard dataflow node support.      |
| dataflowsModule         | Provisions dataflows for Azure IoT Operations with source, built-in transformation, and destination operations. |
| dataflowEndpointsModule | Provisions dataflow endpoints for Azure IoT Operations connecting dataflows to external services.               |

## Module Details

### eventHubDataflow

Provisions the ARM based data flow endpoint and data flow for Event Hub, requires Asset.

#### Parameters for eventHubDataflow

| Name                   | Description                                                                                              | Type                                 | Default | Required |
|:-----------------------|:---------------------------------------------------------------------------------------------------------|:-------------------------------------|:--------|:---------|
| common                 | The common component configuration.                                                                      | `[_2.Common](#user-defined-types)`   | n/a     | yes      |
| eventHub               | The values for the existing Event Hub namespace and Event Hub.                                           | `[_1.EventHub](#user-defined-types)` | n/a     | yes      |
| assetName              | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string`                             | n/a     | yes      |
| aioUamiTenantId        | The tenant ID of the User-Assigned Managed Identity for Azure IoT Operations.                            | `string`                             | n/a     | yes      |
| aioUamiClientId        | The client ID of the User-Assigned Managed Identity for Azure IoT Operations.                            | `string`                             | n/a     | yes      |
| aioInstanceName        | The name of the Azure IoT Operations Instance.                                                           | `string`                             | n/a     | yes      |
| aioDataflowProfileName | The name of the Azure IoT Operations Dataflow Profile.                                                   | `string`                             | default | no       |
| customLocationId       | The resource ID of the Custom Location.                                                                  | `string`                             | n/a     | yes      |
| adrNamespaceName       | The name of the Azure IoT Operations Device Registry namespace used when referencing assets.             | `string`                             | n/a     | no       |

#### Resources for eventHubDataflow

| Name                       | Type                                                           | API Version |
|:---------------------------|:---------------------------------------------------------------|:------------|
| dataflowEndpointToEventHub | `Microsoft.IoTOperations/instances/dataflowEndpoints`          | 2025-10-01  |
| dataflowToEventHub         | `Microsoft.IoTOperations/instances/dataflowProfiles/dataflows` | 2025-10-01  |

### eventGridDataflow

Provisions the ARM based data flow endpoint and data flow for Event Grid, requires Asset.

#### Parameters for eventGridDataflow

| Name                   | Description                                                                                              | Type                                  | Default | Required |
|:-----------------------|:---------------------------------------------------------------------------------------------------------|:--------------------------------------|:--------|:---------|
| common                 | The common component configuration.                                                                      | `[_2.Common](#user-defined-types)`    | n/a     | yes      |
| eventGrid              | The values for the existing Event Grid.                                                                  | `[_1.EventGrid](#user-defined-types)` | n/a     | yes      |
| assetName              | The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud. | `string`                              | n/a     | yes      |
| aioUamiTenantId        | The tenant ID of the User-Assigned Managed Identity for Azure IoT Operations.                            | `string`                              | n/a     | yes      |
| aioUamiClientId        | The client ID of the User-Assigned Managed Identity for Azure IoT Operations.                            | `string`                              | n/a     | yes      |
| aioInstanceName        | The name of the Azure IoT Operations Instance.                                                           | `string`                              | n/a     | yes      |
| aioDataflowProfileName | The name of the Azure IoT Operations Dataflow Profile.                                                   | `string`                              | default | no       |
| customLocationId       | The resource ID of the Custom Location.                                                                  | `string`                              | n/a     | yes      |
| adrNamespaceName       | The name of the Azure IoT Operations Device Registry namespace used when referencing assets.             | `string`                              | n/a     | no       |

#### Resources for eventGridDataflow

| Name                        | Type                                                           | API Version |
|:----------------------------|:---------------------------------------------------------------|:------------|
| dataflowEndpointToEventGrid | `Microsoft.IoTOperations/instances/dataflowEndpoints`          | 2025-10-01  |
| dataflowToEventGrid         | `Microsoft.IoTOperations/instances/dataflowProfiles/dataflows` | 2025-10-01  |

### dataflowGraphsModule

Provisions dataflow graphs for Azure IoT Operations with WASM operator and standard dataflow node support.

#### Parameters for dataflowGraphsModule

| Name                   | Description                                            | Type     | Default | Required |
|:-----------------------|:-------------------------------------------------------|:---------|:--------|:---------|
| aioInstanceName        | The name of the Azure IoT Operations Instance.         | `string` | n/a     | yes      |
| aioDataflowProfileName | The name of the Azure IoT Operations Dataflow Profile. | `string` | n/a     | yes      |
| customLocationId       | The resource ID of the Custom Location.                | `string` | n/a     | yes      |
| dataflowGraphs         | The list of dataflow graphs to create.                 | `array`  | n/a     | yes      |

#### Resources for dataflowGraphsModule

| Name          | Type                                                                | API Version |
|:--------------|:--------------------------------------------------------------------|:------------|
| dataflowGraph | `Microsoft.IoTOperations/instances/dataflowProfiles/dataflowGraphs` | 2025-10-01  |

#### Outputs for dataflowGraphsModule

| Name               | Type    | Description                               |
|:-------------------|:--------|:------------------------------------------|
| dataflowGraphNames | `array` | The names of the created dataflow graphs. |

### dataflowsModule

Provisions dataflows for Azure IoT Operations with source, built-in transformation, and destination operations.

#### Parameters for dataflowsModule

| Name                   | Description                                            | Type     | Default | Required |
|:-----------------------|:-------------------------------------------------------|:---------|:--------|:---------|
| aioInstanceName        | The name of the Azure IoT Operations Instance.         | `string` | n/a     | yes      |
| aioDataflowProfileName | The name of the Azure IoT Operations Dataflow Profile. | `string` | n/a     | yes      |
| customLocationId       | The resource ID of the Custom Location.                | `string` | n/a     | yes      |
| dataflows              | The list of dataflows to create.                       | `array`  | n/a     | yes      |

#### Resources for dataflowsModule

| Name     | Type                                                           | API Version |
|:---------|:---------------------------------------------------------------|:------------|
| dataflow | `Microsoft.IoTOperations/instances/dataflowProfiles/dataflows` | 2025-10-01  |

#### Outputs for dataflowsModule

| Name          | Type    | Description                         |
|:--------------|:--------|:------------------------------------|
| dataflowNames | `array` | The names of the created dataflows. |

### dataflowEndpointsModule

Provisions dataflow endpoints for Azure IoT Operations connecting dataflows to external services.

#### Parameters for dataflowEndpointsModule

| Name              | Description                                    | Type     | Default | Required |
|:------------------|:-----------------------------------------------|:---------|:--------|:---------|
| aioInstanceName   | The name of the Azure IoT Operations Instance. | `string` | n/a     | yes      |
| customLocationId  | The resource ID of the Custom Location.        | `string` | n/a     | yes      |
| dataflowEndpoints | The list of dataflow endpoints to create.      | `array`  | n/a     | yes      |

#### Resources for dataflowEndpointsModule

| Name             | Type                                                  | API Version |
|:-----------------|:------------------------------------------------------|:------------|
| dataflowEndpoint | `Microsoft.IoTOperations/instances/dataflowEndpoints` | 2025-10-01  |

#### Outputs for dataflowEndpointsModule

| Name                  | Type    | Description                                  |
|:----------------------|:--------|:---------------------------------------------|
| dataflowEndpointNames | `array` | The names of the created dataflow endpoints. |

## User Defined Types

### `_1.AccessTokenSettings`

Access token authentication settings.

| Property  | Type     | Description                                |
|:----------|:---------|:-------------------------------------------|
| secretRef | `string` | The secret reference for the access token. |

### `_1.BatchingSettingsSeconds`

Batching settings with latency in seconds.

| Property       | Type  | Description                               |
|:---------------|:------|:------------------------------------------|
| latencySeconds | `int` | The batching latency in seconds.          |
| maxMessages    | `int` | The maximum number of messages per batch. |

### `_1.DataExplorerAuthentication`

Data Explorer authentication settings.

| Property                              | Type                                                              | Description                                |
|:--------------------------------------|:------------------------------------------------------------------|:-------------------------------------------|
| method                                | `string`                                                          | The authentication method.                 |
| systemAssignedManagedIdentitySettings | `[_1.SystemAssignedManagedIdentitySettings](#user-defined-types)` | System-assigned managed identity settings. |
| userAssignedManagedIdentitySettings   | `[_1.UserAssignedManagedIdentitySettings](#user-defined-types)`   | User-assigned managed identity settings.   |

### `_1.DataExplorerSettings`

Data Explorer endpoint settings.

| Property       | Type                                                   | Description                  |
|:---------------|:-------------------------------------------------------|:-----------------------------|
| authentication | `[_1.DataExplorerAuthentication](#user-defined-types)` | The authentication settings. |
| batching       | `[_1.BatchingSettingsSeconds](#user-defined-types)`    | The batching settings.       |
| database       | `string`                                               | The database name.           |
| host           | `string`                                               | The Data Explorer host URI.  |

### `_1.Dataflow`

Dataflow configuration with operations.

| Property               | Type     | Description                                                                          |
|:-----------------------|:---------|:-------------------------------------------------------------------------------------|
| name                   | `string` | The name of the dataflow. Must be 3-63 lowercase alphanumeric characters or hyphens. |
| mode                   | `string` | The mode of the dataflow.                                                            |
| requestDiskPersistence | `string` | Whether to persist data to disk for recovery.                                        |
| operations             | `array`  | The list of operations in the dataflow.                                              |

### `_1.DataflowBuiltInTransformationSettings`

Built-in transformation settings for a dataflow operation.

| Property            | Type     | Description               |
|:--------------------|:---------|:--------------------------|
| serializationFormat | `string` | The serialization format. |
| schemaRef           | `string` | The schema reference.     |
| datasets            | `array`  | The dataset definitions.  |
| filter              | `array`  | The filter definitions.   |
| map                 | `array`  | The map definitions.      |

### `_1.DataflowDestinationSettings`

Destination settings for a dataflow operation.

| Property        | Type     | Description                         |
|:----------------|:---------|:------------------------------------|
| endpointRef     | `string` | The endpoint reference name.        |
| dataDestination | `string` | The data destination path or topic. |

### `_1.DataflowEndpoint`

Dataflow endpoint configuration.

| Property                | Type                                                | Description                                                                          |
|:------------------------|:----------------------------------------------------|:-------------------------------------------------------------------------------------|
| name                    | `string`                                            | The name of the endpoint. Must be 3-63 lowercase alphanumeric characters or hyphens. |
| endpointType            | `string`                                            | The type of the endpoint.                                                            |
| hostType                | `string`                                            | The host type for the endpoint.                                                      |
| dataExplorerSettings    | `[_1.DataExplorerSettings](#user-defined-types)`    | Data Explorer endpoint settings.                                                     |
| dataLakeStorageSettings | `[_1.DataLakeStorageSettings](#user-defined-types)` | Data Lake Storage endpoint settings.                                                 |
| fabricOneLakeSettings   | `[_1.FabricOneLakeSettings](#user-defined-types)`   | Fabric OneLake endpoint settings.                                                    |
| kafkaSettings           | `[_1.KafkaSettings](#user-defined-types)`           | Kafka endpoint settings.                                                             |
| localStorageSettings    | `[_1.LocalStorageSettings](#user-defined-types)`    | Local storage endpoint settings.                                                     |
| mqttSettings            | `[_1.MqttSettings](#user-defined-types)`            | MQTT endpoint settings.                                                              |
| openTelemetrySettings   | `[_1.OpenTelemetrySettings](#user-defined-types)`   | OpenTelemetry endpoint settings.                                                     |

### `_1.DataflowGraph`

Dataflow graph configuration with nodes and connections.

| Property               | Type     | Description                                                                                |
|:-----------------------|:---------|:-------------------------------------------------------------------------------------------|
| name                   | `string` | The name of the dataflow graph. Must be 3-63 lowercase alphanumeric characters or hyphens. |
| mode                   | `string` | The mode of the dataflow graph.                                                            |
| requestDiskPersistence | `string` | Whether to persist data to disk for recovery.                                              |
| nodes                  | `array`  | The list of nodes in the graph.                                                            |
| nodeConnections        | `array`  | The list of connections between nodes.                                                     |

### `_1.DataflowGraphConfiguration`

Configuration key-value pair for a dataflow graph node.

| Property | Type     | Description              |
|:---------|:---------|:-------------------------|
| key      | `string` | The configuration key.   |
| value    | `string` | The configuration value. |

### `_1.DataflowGraphConnectionFrom`

Connection from a source node in a dataflow graph.

| Property | Type                                            | Description                    |
|:---------|:------------------------------------------------|:-------------------------------|
| name     | `string`                                        | The name of the source node.   |
| schema   | `[_1.DataflowGraphSchema](#user-defined-types)` | The schema for the connection. |

### `_1.DataflowGraphConnectionTo`

Connection to a target node in a dataflow graph.

| Property | Type     | Description                  |
|:---------|:---------|:-----------------------------|
| name     | `string` | The name of the target node. |

### `_1.DataflowGraphDestinationHeaderAction`

Header action for a dataflow graph destination node.

| Property   | Type     | Description                                                                     |
|:-----------|:---------|:--------------------------------------------------------------------------------|
| actionType | `string` | The type of header operation to perform.                                        |
| key        | `string` | The name of the header.                                                         |
| value      | `string` | The value of the header. Required for AddIfNotPresent and AddOrReplace actions. |

### `_1.DataflowGraphDestinationSettings`

Destination settings for a dataflow graph node.

| Property        | Type     | Description                         |
|:----------------|:---------|:------------------------------------|
| endpointRef     | `string` | The endpoint reference name.        |
| dataDestination | `string` | The data destination path or topic. |
| headers         | `array`  | Headers for the output data.        |

### `_1.DataflowGraphNode`

Node in a dataflow graph.

| Property            | Type                                                         | Description                                        |
|:--------------------|:-------------------------------------------------------------|:---------------------------------------------------|
| nodeType            | `string`                                                     | The type of the node.                              |
| name                | `string`                                                     | The name of the node.                              |
| sourceSettings      | `[_1.DataflowGraphSourceSettings](#user-defined-types)`      | Source settings when nodeType is Source.           |
| graphSettings       | `[_1.DataflowGraphSettings](#user-defined-types)`            | Graph processing settings when nodeType is Graph.  |
| destinationSettings | `[_1.DataflowGraphDestinationSettings](#user-defined-types)` | Destination settings when nodeType is Destination. |

### `_1.DataflowGraphNodeConnection`

Connection between nodes in a dataflow graph.

| Property | Type                                                    | Description                 |
|:---------|:--------------------------------------------------------|:----------------------------|
| from     | `[_1.DataflowGraphConnectionFrom](#user-defined-types)` | The source node connection. |
| to       | `[_1.DataflowGraphConnectionTo](#user-defined-types)`   | The target node connection. |

### `_1.DataflowGraphSchema`

Schema reference for a dataflow graph node connection.

| Property            | Type     | Description                              |
|:--------------------|:---------|:-----------------------------------------|
| schemaRef           | `string` | The schema reference identifier.         |
| serializationFormat | `string` | The serialization format for the schema. |

### `_1.DataflowGraphSettings`

Graph processing settings for a dataflow graph node.

| Property            | Type     | Description                                            |
|:--------------------|:---------|:-------------------------------------------------------|
| registryEndpointRef | `string` | The registry endpoint reference for the WASM artifact. |
| artifact            | `string` | The artifact reference in the registry.                |
| configuration       | `array`  | The configuration key-value pairs for the graph node.  |

### `_1.DataflowGraphSourceSettings`

Source settings for a dataflow graph node.

| Property    | Type     | Description                                                                                        |
|:------------|:---------|:---------------------------------------------------------------------------------------------------|
| endpointRef | `string` | The endpoint reference name.                                                                       |
| assetRef    | `string` | Reference to the resource in Azure Device Registry where the data in the endpoint originates from. |
| dataSources | `array`  | The list of data sources to read from.                                                             |

### `_1.DataflowOperation`

Operation in a dataflow.

| Property                      | Type                                                              | Description                                                                   |
|:------------------------------|:------------------------------------------------------------------|:------------------------------------------------------------------------------|
| operationType                 | `string`                                                          | The type of the operation.                                                    |
| name                          | `string`                                                          | The name of the operation.                                                    |
| sourceSettings                | `[_1.DataflowSourceSettings](#user-defined-types)`                | Source settings when operationType is Source.                                 |
| builtInTransformationSettings | `[_1.DataflowBuiltInTransformationSettings](#user-defined-types)` | Built-in transformation settings when operationType is BuiltInTransformation. |
| destinationSettings           | `[_1.DataflowDestinationSettings](#user-defined-types)`           | Destination settings when operationType is Destination.                       |

### `_1.DataflowSourceSettings`

Source settings for a dataflow operation.

| Property            | Type     | Description                            |
|:--------------------|:---------|:---------------------------------------|
| endpointRef         | `string` | The endpoint reference name.           |
| assetRef            | `string` | The asset reference.                   |
| serializationFormat | `string` | The serialization format.              |
| schemaRef           | `string` | The schema reference.                  |
| dataSources         | `array`  | The list of data sources to read from. |

### `_1.DataflowTransformDataset`

Dataset for a built-in transformation.

| Property    | Type     | Description                 |
|:------------|:---------|:----------------------------|
| key         | `string` | The dataset key.            |
| description | `string` | The dataset description.    |
| schemaRef   | `string` | The schema reference.       |
| inputs      | `array`  | The input references.       |
| expression  | `string` | The expression to evaluate. |

### `_1.DataflowTransformFilter`

Filter for a built-in transformation.

| Property    | Type     | Description             |
|:------------|:---------|:------------------------|
| type        | `string` | The filter type.        |
| description | `string` | The filter description. |
| inputs      | `array`  | The input references.   |
| expression  | `string` | The filter expression.  |

### `_1.DataflowTransformMap`

Map for a built-in transformation.

| Property    | Type     | Description            |
|:------------|:---------|:-----------------------|
| type        | `string` | The map type.          |
| description | `string` | The map description.   |
| inputs      | `array`  | The input references.  |
| expression  | `string` | The map expression.    |
| output      | `string` | The output field name. |

### `_1.DataLakeStorageAuthentication`

Data Lake Storage authentication settings.

| Property                              | Type                                                              | Description                                |
|:--------------------------------------|:------------------------------------------------------------------|:-------------------------------------------|
| accessTokenSettings                   | `[_1.AccessTokenSettings](#user-defined-types)`                   | The access token settings.                 |
| method                                | `string`                                                          | The authentication method.                 |
| systemAssignedManagedIdentitySettings | `[_1.SystemAssignedManagedIdentitySettings](#user-defined-types)` | System-assigned managed identity settings. |
| userAssignedManagedIdentitySettings   | `[_1.UserAssignedManagedIdentitySettings](#user-defined-types)`   | User-assigned managed identity settings.   |

### `_1.DataLakeStorageSettings`

Data Lake Storage endpoint settings.

| Property       | Type                                                      | Description                     |
|:---------------|:----------------------------------------------------------|:--------------------------------|
| authentication | `[_1.DataLakeStorageAuthentication](#user-defined-types)` | The authentication settings.    |
| batching       | `[_1.BatchingSettingsSeconds](#user-defined-types)`       | The batching settings.          |
| host           | `string`                                                  | The Data Lake Storage host URI. |

### `_1.EndpointTlsSettings`

TLS settings for endpoint connections.

| Property                         | Type     | Description                                          |
|:---------------------------------|:---------|:-----------------------------------------------------|
| mode                             | `string` | The TLS mode.                                        |
| trustedCaCertificateConfigMapRef | `string` | The ConfigMap reference for trusted CA certificates. |

### `_1.EventGrid`

Event Grid configuration.

| Property  | Type     | Description                       |
|:----------|:---------|:----------------------------------|
| name      | `string` | The name of the Event Grid.       |
| topicName | `string` | The topic name of the Event Grid. |
| endpoint  | `string` | The endpoint of the Event Grid.   |

### `_1.EventHub`

Event Hub configuration.

| Property      | Type     | Description                          |
|:--------------|:---------|:-------------------------------------|
| namespaceName | `string` | The namespace name of the Event Hub. |
| eventHubName  | `string` | The name of the Event Hub.           |

### `_1.FabricOneLakeAuthentication`

Fabric OneLake authentication settings.

| Property                              | Type                                                              | Description                                |
|:--------------------------------------|:------------------------------------------------------------------|:-------------------------------------------|
| method                                | `string`                                                          | The authentication method.                 |
| systemAssignedManagedIdentitySettings | `[_1.SystemAssignedManagedIdentitySettings](#user-defined-types)` | System-assigned managed identity settings. |
| userAssignedManagedIdentitySettings   | `[_1.UserAssignedManagedIdentitySettings](#user-defined-types)`   | User-assigned managed identity settings.   |

### `_1.FabricOneLakeNames`

Fabric OneLake names configuration.

| Property      | Type     | Description         |
|:--------------|:---------|:--------------------|
| lakehouseName | `string` | The lakehouse name. |
| workspaceName | `string` | The workspace name. |

### `_1.FabricOneLakeSettings`

Fabric OneLake endpoint settings.

| Property        | Type                                                    | Description                        |
|:----------------|:--------------------------------------------------------|:-----------------------------------|
| authentication  | `[_1.FabricOneLakeAuthentication](#user-defined-types)` | The authentication settings.       |
| batching        | `[_1.BatchingSettingsSeconds](#user-defined-types)`     | The batching settings.             |
| host            | `string`                                                | The OneLake host URI.              |
| names           | `[_1.FabricOneLakeNames](#user-defined-types)`          | The lakehouse and workspace names. |
| oneLakePathType | `string`                                                | The OneLake path type.             |

### `_1.KafkaAuthentication`

Kafka authentication settings.

| Property                              | Type                                                              | Description                                |
|:--------------------------------------|:------------------------------------------------------------------|:-------------------------------------------|
| method                                | `string`                                                          | The authentication method.                 |
| saslSettings                          | `[_1.SaslSettings](#user-defined-types)`                          | SASL settings.                             |
| systemAssignedManagedIdentitySettings | `[_1.SystemAssignedManagedIdentitySettings](#user-defined-types)` | System-assigned managed identity settings. |
| userAssignedManagedIdentitySettings   | `[_1.UserAssignedManagedIdentitySettings](#user-defined-types)`   | User-assigned managed identity settings.   |
| x509CertificateSettings               | `[_1.X509CertificateSettings](#user-defined-types)`               | X.509 certificate settings.                |

### `_1.KafkaBatchingSettings`

Batching settings for Kafka endpoints.

| Property    | Type     | Description                               |
|:------------|:---------|:------------------------------------------|
| latencyMs   | `int`    | The batching latency in milliseconds.     |
| maxBytes    | `int`    | The maximum number of bytes per batch.    |
| maxMessages | `int`    | The maximum number of messages per batch. |
| mode        | `string` | The batching mode.                        |

### `_1.KafkaSettings`

Kafka endpoint settings.

| Property             | Type                                              | Description                           |
|:---------------------|:--------------------------------------------------|:--------------------------------------|
| authentication       | `[_1.KafkaAuthentication](#user-defined-types)`   | The authentication settings.          |
| batching             | `[_1.KafkaBatchingSettings](#user-defined-types)` | The batching settings.                |
| cloudEventAttributes | `string`                                          | How to handle cloud event attributes. |
| compression          | `string`                                          | The compression type.                 |
| consumerGroupId      | `string`                                          | The consumer group ID.                |
| copyMqttProperties   | `string`                                          | Whether to copy MQTT properties.      |
| host                 | `string`                                          | The Kafka host URI.                   |
| kafkaAcks            | `string`                                          | The Kafka acknowledgment level.       |
| partitionStrategy    | `string`                                          | The partition strategy.               |
| tls                  | `[_1.EndpointTlsSettings](#user-defined-types)`   | The TLS settings.                     |

### `_1.LocalStorageSettings`

Local storage endpoint settings.

| Property                 | Type     | Description                            |
|:-------------------------|:---------|:---------------------------------------|
| persistentVolumeClaimRef | `string` | The persistent volume claim reference. |

### `_1.MqttAuthentication`

MQTT authentication settings.

| Property                              | Type                                                              | Description                                |
|:--------------------------------------|:------------------------------------------------------------------|:-------------------------------------------|
| method                                | `string`                                                          | The authentication method.                 |
| serviceAccountTokenSettings           | `[_1.ServiceAccountTokenSettings](#user-defined-types)`           | Service account token settings.            |
| systemAssignedManagedIdentitySettings | `[_1.SystemAssignedManagedIdentitySettings](#user-defined-types)` | System-assigned managed identity settings. |
| userAssignedManagedIdentitySettings   | `[_1.UserAssignedManagedIdentitySettings](#user-defined-types)`   | User-assigned managed identity settings.   |
| x509CertificateSettings               | `[_1.X509CertificateSettings](#user-defined-types)`               | X.509 certificate settings.                |

### `_1.MqttSettings`

MQTT endpoint settings.

| Property             | Type                                            | Description                               |
|:---------------------|:------------------------------------------------|:------------------------------------------|
| authentication       | `[_1.MqttAuthentication](#user-defined-types)`  | The authentication settings.              |
| clientIdPrefix       | `string`                                        | The client ID prefix.                     |
| cloudEventAttributes | `string`                                        | How to handle cloud event attributes.     |
| host                 | `string`                                        | The MQTT host URI.                        |
| keepAliveSeconds     | `int`                                           | The keep-alive interval in seconds.       |
| maxInflightMessages  | `int`                                           | The maximum number of in-flight messages. |
| protocol             | `string`                                        | The MQTT protocol version.                |
| qos                  | `int`                                           | The quality of service level.             |
| retain               | `string`                                        | The retain policy.                        |
| sessionExpirySeconds | `int`                                           | The session expiry interval in seconds.   |
| tls                  | `[_1.EndpointTlsSettings](#user-defined-types)` | The TLS settings.                         |

### `_1.OpenTelemetryAuthentication`

OpenTelemetry authentication settings.

| Property                    | Type                                                    | Description                     |
|:----------------------------|:--------------------------------------------------------|:--------------------------------|
| method                      | `string`                                                | The authentication method.      |
| serviceAccountTokenSettings | `[_1.ServiceAccountTokenSettings](#user-defined-types)` | Service account token settings. |
| x509CertificateSettings     | `[_1.X509CertificateSettings](#user-defined-types)`     | X.509 certificate settings.     |

### `_1.OpenTelemetrySettings`

OpenTelemetry endpoint settings.

| Property       | Type                                                    | Description                           |
|:---------------|:--------------------------------------------------------|:--------------------------------------|
| authentication | `[_1.OpenTelemetryAuthentication](#user-defined-types)` | The authentication settings.          |
| batching       | `[_1.BatchingSettingsSeconds](#user-defined-types)`     | The batching settings.                |
| host           | `string`                                                | The OpenTelemetry collector host URI. |
| tls            | `[_1.EndpointTlsSettings](#user-defined-types)`         | The TLS settings.                     |

### `_1.SaslSettings`

SASL authentication settings.

| Property  | Type     | Description                                    |
|:----------|:---------|:-----------------------------------------------|
| saslType  | `string` | The SASL type.                                 |
| secretRef | `string` | The secret reference for the SASL credentials. |

### `_1.ServiceAccountTokenSettings`

Service account token authentication settings.

| Property | Type     | Description                                 |
|:---------|:---------|:--------------------------------------------|
| audience | `string` | The audience for the service account token. |

### `_1.SystemAssignedManagedIdentitySettings`

System-assigned managed identity authentication settings.

| Property | Type     | Description                                  |
|:---------|:---------|:---------------------------------------------|
| audience | `string` | The audience for the managed identity token. |

### `_1.UserAssignedManagedIdentitySettings`

User-assigned managed identity authentication settings.

| Property | Type     | Description                               |
|:---------|:---------|:------------------------------------------|
| clientId | `string` | The client ID of the managed identity.    |
| scope    | `string` | The scope for the managed identity token. |
| tenantId | `string` | The tenant ID of the managed identity.    |

### `_1.X509CertificateSettings`

X.509 certificate authentication settings.

| Property  | Type     | Description                               |
|:----------|:---------|:------------------------------------------|
| secretRef | `string` | The secret reference for the certificate. |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                  | Type    | Description                      |
|:----------------------|:--------|:---------------------------------|
| dataflowGraphNames    | `array` | List of dataflow graph names.    |
| dataflowNames         | `array` | List of dataflow names.          |
| dataflowEndpointNames | `array` | List of dataflow endpoint names. |

<!-- END_BICEP_DOCS -->