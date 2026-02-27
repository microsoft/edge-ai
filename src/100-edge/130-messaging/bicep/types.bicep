metadata name = 'Component Types for Azure IoT Operations Messaging'
metadata description = 'Provides component-specific type definitions and defaults for messaging components.'

/*
  Type Definitions
*/

@export()
@description('Event Hub configuration.')
type EventHub = {
  @description('The namespace name of the Event Hub.')
  namespaceName: string

  @description('The name of the Event Hub.')
  eventHubName: string
}

@export()
@description('Event Grid configuration.')
type EventGrid = {
  @description('The name of the Event Grid.')
  name: string

  @description('The topic name of the Event Grid.')
  topicName: string

  @description('The endpoint of the Event Grid.')
  endpoint: string
}

/*
  Dataflow Graph Types
*/

@export()
@description('Schema reference for a dataflow graph node connection.')
type DataflowGraphSchema = {
  @description('The schema reference identifier.')
  schemaRef: string

  @description('The serialization format for the schema.')
  serializationFormat: 'Json' | 'Parquet' | 'Delta' | 'Raw'?
}

@export()
@description('Source settings for a dataflow graph node.')
type DataflowGraphSourceSettings = {
  @description('The endpoint reference name.')
  endpointRef: string

  @description('Reference to the resource in Azure Device Registry where the data in the endpoint originates from.')
  assetRef: string?

  @description('The list of data sources to read from.')
  dataSources: string[]
}

@export()
@description('Graph processing settings for a dataflow graph node.')
type DataflowGraphSettings = {
  @description('The registry endpoint reference for the WASM artifact.')
  registryEndpointRef: string

  @description('The artifact reference in the registry.')
  artifact: string

  @description('The configuration key-value pairs for the graph node.')
  configuration: DataflowGraphConfiguration[]?
}

@export()
@description('Configuration key-value pair for a dataflow graph node.')
type DataflowGraphConfiguration = {
  @description('The configuration key.')
  key: string

  @description('The configuration value.')
  value: string
}

@export()
@description('Header action for a dataflow graph destination node.')
type DataflowGraphDestinationHeaderAction = {
  @description('The type of header operation to perform.')
  actionType: 'AddIfNotPresent' | 'AddOrReplace' | 'Remove'

  @description('The name of the header.')
  key: string

  @description('The value of the header. Required for AddIfNotPresent and AddOrReplace actions.')
  value: string?
}

@export()
@description('Destination settings for a dataflow graph node.')
type DataflowGraphDestinationSettings = {
  @description('The endpoint reference name.')
  endpointRef: string

  @description('The data destination path or topic.')
  dataDestination: string

  @description('Headers for the output data.')
  headers: DataflowGraphDestinationHeaderAction[]?
}

@export()
@description('Connection from a source node in a dataflow graph.')
type DataflowGraphConnectionFrom = {
  @description('The name of the source node.')
  name: string

  @description('The schema for the connection.')
  schema: DataflowGraphSchema?
}

@export()
@description('Connection to a target node in a dataflow graph.')
type DataflowGraphConnectionTo = {
  @description('The name of the target node.')
  name: string
}

@export()
@description('Connection between nodes in a dataflow graph.')
type DataflowGraphNodeConnection = {
  @description('The source node connection.')
  from: DataflowGraphConnectionFrom

  @description('The target node connection.')
  to: DataflowGraphConnectionTo
}

@export()
@description('Node in a dataflow graph.')
type DataflowGraphNode = {
  @description('The type of the node.')
  nodeType: 'Source' | 'Graph' | 'Destination'

  @description('The name of the node.')
  name: string

  @description('Source settings when nodeType is Source.')
  sourceSettings: DataflowGraphSourceSettings?

  @description('Graph processing settings when nodeType is Graph.')
  graphSettings: DataflowGraphSettings?

  @description('Destination settings when nodeType is Destination.')
  destinationSettings: DataflowGraphDestinationSettings?
}

@export()
@description('Dataflow graph configuration with nodes and connections.')
type DataflowGraph = {
  @description('The name of the dataflow graph. Must be 3-63 lowercase alphanumeric characters or hyphens.')
  name: string

  @description('The mode of the dataflow graph.')
  mode: 'Enabled' | 'Disabled'?

  @description('Whether to persist data to disk for recovery.')
  requestDiskPersistence: 'Enabled' | 'Disabled'?

  @description('The list of nodes in the graph.')
  nodes: DataflowGraphNode[]

  @description('The list of connections between nodes.')
  nodeConnections: DataflowGraphNodeConnection[]
}

@export()
@description('Default values for dataflow graph configuration.')
var dataflowGraphDefaults = {
  mode: 'Enabled'
  requestDiskPersistence: 'Disabled'
}

/*
  Dataflow Types
*/

@export()
@description('Source settings for a dataflow operation.')
type DataflowSourceSettings = {
  @description('The endpoint reference name.')
  endpointRef: string

  @description('The asset reference.')
  assetRef: string?

  @description('The serialization format.')
  serializationFormat: 'Json' | 'Parquet' | 'Delta' | 'Raw'?

  @description('The schema reference.')
  schemaRef: string?

  @description('The list of data sources to read from.')
  dataSources: string[]
}

@export()
@description('Dataset for a built-in transformation.')
type DataflowTransformDataset = {
  @description('The dataset key.')
  key: string

  @description('The dataset description.')
  description: string?

  @description('The schema reference.')
  schemaRef: string?

  @description('The input references.')
  inputs: string[]

  @description('The expression to evaluate.')
  expression: string
}

@export()
@description('Filter for a built-in transformation.')
type DataflowTransformFilter = {
  @description('The filter type.')
  type: 'Filter'?

  @description('The filter description.')
  description: string?

  @description('The input references.')
  inputs: string[]

  @description('The filter expression.')
  expression: string
}

@export()
@description('Map for a built-in transformation.')
type DataflowTransformMap = {
  @description('The map type.')
  type: 'PassThrough' | 'Compute' | 'NewProperties' | 'Rename'?

  @description('The map description.')
  description: string?

  @description('The input references.')
  inputs: string[]

  @description('The map expression.')
  expression: string?

  @description('The output field name.')
  output: string
}

@export()
@description('Built-in transformation settings for a dataflow operation.')
type DataflowBuiltInTransformationSettings = {
  @description('The serialization format.')
  serializationFormat: 'Json' | 'Parquet' | 'Delta' | 'Raw'?

  @description('The schema reference.')
  schemaRef: string?

  @description('The dataset definitions.')
  datasets: DataflowTransformDataset[]?

  @description('The filter definitions.')
  filter: DataflowTransformFilter[]?

  @description('The map definitions.')
  map: DataflowTransformMap[]?
}

@export()
@description('Destination settings for a dataflow operation.')
type DataflowDestinationSettings = {
  @description('The endpoint reference name.')
  endpointRef: string

  @description('The data destination path or topic.')
  dataDestination: string
}

@export()
@description('Operation in a dataflow.')
type DataflowOperation = {
  @description('The type of the operation.')
  operationType: 'Source' | 'BuiltInTransformation' | 'Destination'

  @description('The name of the operation.')
  name: string?

  @description('Source settings when operationType is Source.')
  sourceSettings: DataflowSourceSettings?

  @description('Built-in transformation settings when operationType is BuiltInTransformation.')
  builtInTransformationSettings: DataflowBuiltInTransformationSettings?

  @description('Destination settings when operationType is Destination.')
  destinationSettings: DataflowDestinationSettings?
}

@export()
@description('Dataflow configuration with operations.')
type Dataflow = {
  @description('The name of the dataflow. Must be 3-63 lowercase alphanumeric characters or hyphens.')
  name: string

  @description('The mode of the dataflow.')
  mode: 'Enabled' | 'Disabled'?

  @description('Whether to persist data to disk for recovery.')
  requestDiskPersistence: 'Enabled' | 'Disabled'?

  @description('The list of operations in the dataflow.')
  operations: DataflowOperation[]
}

@export()
@description('Default values for dataflow configuration.')
var dataflowDefaults = {
  mode: 'Enabled'
  requestDiskPersistence: 'Disabled'
}

/*
  Dataflow Endpoint Types
*/

@export()
@description('System-assigned managed identity authentication settings.')
type SystemAssignedManagedIdentitySettings = {
  @description('The audience for the managed identity token.')
  audience: string?
}

@export()
@description('User-assigned managed identity authentication settings.')
type UserAssignedManagedIdentitySettings = {
  @description('The client ID of the managed identity.')
  clientId: string

  @description('The scope for the managed identity token.')
  scope: string?

  @description('The tenant ID of the managed identity.')
  tenantId: string
}

@export()
@description('X.509 certificate authentication settings.')
type X509CertificateSettings = {
  @description('The secret reference for the certificate.')
  secretRef: string
}

@export()
@description('Service account token authentication settings.')
type ServiceAccountTokenSettings = {
  @description('The audience for the service account token.')
  audience: string
}

@export()
@description('Access token authentication settings.')
type AccessTokenSettings = {
  @description('The secret reference for the access token.')
  secretRef: string
}

@export()
@description('SASL authentication settings.')
type SaslSettings = {
  @description('The SASL type.')
  saslType: 'Plain' | 'ScramSha256' | 'ScramSha512'

  @description('The secret reference for the SASL credentials.')
  secretRef: string
}

@export()
@description('TLS settings for endpoint connections.')
type EndpointTlsSettings = {
  @description('The TLS mode.')
  mode: 'Enabled' | 'Disabled'?

  @description('The ConfigMap reference for trusted CA certificates.')
  trustedCaCertificateConfigMapRef: string?
}

@export()
@description('Batching settings with latency in seconds.')
type BatchingSettingsSeconds = {
  @description('The batching latency in seconds.')
  latencySeconds: int?

  @description('The maximum number of messages per batch.')
  maxMessages: int?
}

@export()
@description('Batching settings for Kafka endpoints.')
type KafkaBatchingSettings = {
  @description('The batching latency in milliseconds.')
  latencyMs: int?

  @description('The maximum number of bytes per batch.')
  maxBytes: int?

  @description('The maximum number of messages per batch.')
  maxMessages: int?

  @description('The batching mode.')
  mode: 'Enabled' | 'Disabled'?
}

@export()
@description('Data Explorer authentication settings.')
type DataExplorerAuthentication = {
  @description('The authentication method.')
  method: 'SystemAssignedManagedIdentity' | 'UserAssignedManagedIdentity'

  @description('System-assigned managed identity settings.')
  systemAssignedManagedIdentitySettings: SystemAssignedManagedIdentitySettings?

  @description('User-assigned managed identity settings.')
  userAssignedManagedIdentitySettings: UserAssignedManagedIdentitySettings?
}

@export()
@description('Data Explorer endpoint settings.')
type DataExplorerSettings = {
  @description('The authentication settings.')
  authentication: DataExplorerAuthentication

  @description('The batching settings.')
  batching: BatchingSettingsSeconds?

  @description('The database name.')
  database: string

  @description('The Data Explorer host URI.')
  host: string
}

@export()
@description('Data Lake Storage authentication settings.')
type DataLakeStorageAuthentication = {
  @description('The access token settings.')
  accessTokenSettings: AccessTokenSettings?

  @description('The authentication method.')
  method: 'SystemAssignedManagedIdentity' | 'UserAssignedManagedIdentity' | 'AccessToken'

  @description('System-assigned managed identity settings.')
  systemAssignedManagedIdentitySettings: SystemAssignedManagedIdentitySettings?

  @description('User-assigned managed identity settings.')
  userAssignedManagedIdentitySettings: UserAssignedManagedIdentitySettings?
}

@export()
@description('Data Lake Storage endpoint settings.')
type DataLakeStorageSettings = {
  @description('The authentication settings.')
  authentication: DataLakeStorageAuthentication

  @description('The batching settings.')
  batching: BatchingSettingsSeconds?

  @description('The Data Lake Storage host URI.')
  host: string
}

@export()
@description('Fabric OneLake names configuration.')
type FabricOneLakeNames = {
  @description('The lakehouse name.')
  lakehouseName: string

  @description('The workspace name.')
  workspaceName: string
}

@export()
@description('Fabric OneLake authentication settings.')
type FabricOneLakeAuthentication = {
  @description('The authentication method.')
  method: 'SystemAssignedManagedIdentity' | 'UserAssignedManagedIdentity'

  @description('System-assigned managed identity settings.')
  systemAssignedManagedIdentitySettings: SystemAssignedManagedIdentitySettings?

  @description('User-assigned managed identity settings.')
  userAssignedManagedIdentitySettings: UserAssignedManagedIdentitySettings?
}

@export()
@description('Fabric OneLake endpoint settings.')
type FabricOneLakeSettings = {
  @description('The authentication settings.')
  authentication: FabricOneLakeAuthentication

  @description('The batching settings.')
  batching: BatchingSettingsSeconds?

  @description('The OneLake host URI.')
  host: string

  @description('The lakehouse and workspace names.')
  names: FabricOneLakeNames

  @description('The OneLake path type.')
  oneLakePathType: 'Files' | 'Tables'
}

@export()
@description('Kafka authentication settings.')
type KafkaAuthentication = {
  @description('The authentication method.')
  method: 'SystemAssignedManagedIdentity' | 'UserAssignedManagedIdentity' | 'Sasl' | 'X509Certificate' | 'Anonymous'

  @description('SASL settings.')
  saslSettings: SaslSettings?

  @description('System-assigned managed identity settings.')
  systemAssignedManagedIdentitySettings: SystemAssignedManagedIdentitySettings?

  @description('User-assigned managed identity settings.')
  userAssignedManagedIdentitySettings: UserAssignedManagedIdentitySettings?

  @description('X.509 certificate settings.')
  x509CertificateSettings: X509CertificateSettings?
}

@export()
@description('Kafka endpoint settings.')
type KafkaSettings = {
  @description('The authentication settings.')
  authentication: KafkaAuthentication

  @description('The batching settings.')
  batching: KafkaBatchingSettings?

  @description('How to handle cloud event attributes.')
  cloudEventAttributes: ('Propagate' | 'CreateOrRemap')?

  @description('The compression type.')
  compression: ('None' | 'Gzip' | 'Snappy' | 'Lz4')?

  @description('The consumer group ID.')
  consumerGroupId: string?

  @description('Whether to copy MQTT properties.')
  copyMqttProperties: ('Enabled' | 'Disabled')?

  @description('The Kafka host URI.')
  host: string

  @description('The Kafka acknowledgment level.')
  kafkaAcks: ('Zero' | 'One' | 'All')?

  @description('The partition strategy.')
  partitionStrategy: ('Default' | 'Static' | 'Topic' | 'Property')?

  @description('The TLS settings.')
  tls: EndpointTlsSettings?
}

@export()
@description('Local storage endpoint settings.')
type LocalStorageSettings = {
  @description('The persistent volume claim reference.')
  persistentVolumeClaimRef: string
}

@export()
@description('MQTT authentication settings.')
type MqttAuthentication = {
  @description('The authentication method.')
  method:
    | 'SystemAssignedManagedIdentity'
    | 'UserAssignedManagedIdentity'
    | 'ServiceAccountToken'
    | 'X509Certificate'
    | 'Anonymous'

  @description('Service account token settings.')
  serviceAccountTokenSettings: ServiceAccountTokenSettings?

  @description('System-assigned managed identity settings.')
  systemAssignedManagedIdentitySettings: SystemAssignedManagedIdentitySettings?

  @description('User-assigned managed identity settings.')
  userAssignedManagedIdentitySettings: UserAssignedManagedIdentitySettings?

  @description('X.509 certificate settings.')
  x509CertificateSettings: X509CertificateSettings?
}

@export()
@description('MQTT endpoint settings.')
type MqttSettings = {
  @description('The authentication settings.')
  authentication: MqttAuthentication

  @description('The client ID prefix.')
  clientIdPrefix: string?

  @description('How to handle cloud event attributes.')
  cloudEventAttributes: ('Propagate' | 'CreateOrRemap')?

  @description('The MQTT host URI.')
  host: string?

  @description('The keep-alive interval in seconds.')
  keepAliveSeconds: int?

  @description('The maximum number of in-flight messages.')
  maxInflightMessages: int?

  @description('The MQTT protocol version.')
  protocol: ('Mqtt' | 'WebSockets')?

  @description('The quality of service level.')
  qos: (0 | 1)?

  @description('The retain policy.')
  retain: ('Keep' | 'Never')?

  @description('The session expiry interval in seconds.')
  sessionExpirySeconds: int?

  @description('The TLS settings.')
  tls: EndpointTlsSettings?
}

@export()
@description('OpenTelemetry authentication settings.')
type OpenTelemetryAuthentication = {
  @description('The authentication method.')
  method: 'Anonymous' | 'ServiceAccountToken' | 'X509Certificate'

  @description('Service account token settings.')
  serviceAccountTokenSettings: ServiceAccountTokenSettings?

  @description('X.509 certificate settings.')
  x509CertificateSettings: X509CertificateSettings?
}

@export()
@description('OpenTelemetry endpoint settings.')
type OpenTelemetrySettings = {
  @description('The authentication settings.')
  authentication: OpenTelemetryAuthentication

  @description('The batching settings.')
  batching: BatchingSettingsSeconds?

  @description('The OpenTelemetry collector host URI.')
  host: string

  @description('The TLS settings.')
  tls: EndpointTlsSettings?
}

@export()
@description('Dataflow endpoint configuration.')
type DataflowEndpoint = {
  @description('The name of the endpoint. Must be 3-63 lowercase alphanumeric characters or hyphens.')
  name: string

  @description('The type of the endpoint.')
  endpointType:
    | 'DataExplorer'
    | 'DataLakeStorage'
    | 'FabricOneLake'
    | 'Kafka'
    | 'LocalStorage'
    | 'Mqtt'
    | 'OpenTelemetry'

  @description('The host type for the endpoint.')
  hostType: ('CustomKafka' | 'CustomMqtt' | 'EventGrid' | 'Eventhub' | 'FabricRT' | 'LocalBroker')?

  @description('Data Explorer endpoint settings.')
  dataExplorerSettings: DataExplorerSettings?

  @description('Data Lake Storage endpoint settings.')
  dataLakeStorageSettings: DataLakeStorageSettings?

  @description('Fabric OneLake endpoint settings.')
  fabricOneLakeSettings: FabricOneLakeSettings?

  @description('Kafka endpoint settings.')
  kafkaSettings: KafkaSettings?

  @description('Local storage endpoint settings.')
  localStorageSettings: LocalStorageSettings?

  @description('MQTT endpoint settings.')
  mqttSettings: MqttSettings?

  @description('OpenTelemetry endpoint settings.')
  openTelemetrySettings: OpenTelemetrySettings?
}
