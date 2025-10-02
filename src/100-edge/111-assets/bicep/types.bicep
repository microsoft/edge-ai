@export()
@description('Endpoint authentication configuration for assets.')
type EndpointAuthentication = {
  @description('Authentication method: Anonymous, UsernamePassword, or X509')
  method: 'Anonymous' | 'UsernamePassword' | 'X509'

  @description('Username and password credentials for authentication.')
  usernamePasswordCredentials: {
    @description('Secret name containing the username.')
    usernameSecretName: string

    @description('Secret name containing the password.')
    passwordSecretName: string
  }?

  @description('X509 certificate credentials for authentication.')
  x509Credentials: {
    @description('Secret name containing the certificate.')
    certificateSecretName: string
  }?
}

@export()
@description('Trust settings for endpoint connections.')
type TrustSettings = {
  @description('Trust list configuration.')
  trustList: string
}

@export()
@description('Endpoint configuration for devices.')
type DeviceEndpoint = {
  @description('Type of the endpoint: Microsoft.OpcUa, etc.')
  endpointType: string

  @description('Address of the endpoint.')
  address: string

  @description('Version of the endpoint protocol.')
  version: string?

  @description('Additional configuration as JSON string.')
  additionalConfiguration: string?

  @description('Authentication configuration for the endpoint.')
  authentication: EndpointAuthentication

  @description('Trust settings for the endpoint.')
  trustSettings: TrustSettings?
}

@export()
@description('Device endpoints configuration.')
type DeviceEndpoints = {
  @description('Outbound endpoint configuration.')
  outbound: {
    @description('Assigned outbound configuration.')
    assigned: object
  }

  @description('Inbound endpoint configurations.')
  inbound: object
}

@export()
@description('Namespaced device configuration.')
type NamespacedDevice = {
  @description('Name of the device.')
  name: string

  @description('Whether the device is enabled.')
  isEnabled: bool

  @description('Endpoint configurations for the device.')
  endpoints: DeviceEndpoints
}

@export()
@description('Data point configuration for asset datasets.')
type AssetDataPoint = {
  @description('Name of the data point.')
  name: string

  @description('Data source address.')
  dataSource: string

  @description('Data point configuration as JSON string.')
  dataPointConfiguration: string?
}

@export()
@description('Dataset destination configuration.')
type DatasetDestination = {
  @description('Target for the destination: Mqtt, etc.')
  target: string

  @description('Configuration for the destination.')
  configuration: {
    @description('MQTT topic for the destination.')
    topic: string?

    @description('Retain setting: Never, etc.')
    retain: string?

    @description('Quality of Service: Qos1, etc.')
    qos: string?
  }
}

@export()
@description('Dataset configuration for assets.')
type AssetDataset = {
  @description('Name of the dataset.')
  name: string

  @description('Data points in the dataset.')
  dataPoints: AssetDataPoint[]

  @description('Destinations for the dataset.')
  destinations: DatasetDestination[]
}

@export()
@description('Device reference for namespaced assets.')
type DeviceReference = {
  @description('Name of the device.')
  deviceName: string

  @description('Name of the endpoint on the device.')
  endpointName: string
}

@export()
@description('Namespaced asset configuration.')
type NamespacedAsset = {
  @description('Name of the asset.')
  name: string

  @description('Display name of the asset.')
  displayName: string?

  @description('Reference to the device and endpoint.')
  deviceRef: DeviceReference

  @description('Description of the asset.')
  description: string?

  @description('Documentation URI for the asset.')
  documentationUri: string?

  @description('Whether the asset is enabled.')
  isEnabled: bool

  @description('Hardware revision of the asset.')
  hardwareRevision: string?

  @description('Manufacturer of the asset.')
  manufacturer: string?

  @description('Manufacturer URI of the asset.')
  manufacturerUri: string?

  @description('Model of the asset.')
  model: string?

  @description('Product code of the asset.')
  productCode: string?

  @description('Serial number of the asset.')
  serialNumber: string?

  @description('Software revision of the asset.')
  softwareRevision: string?

  @description('Custom attributes for the asset.')
  attributes: object

  @description('Datasets for the asset.')
  datasets: AssetDataset[]

  @description('Default datasets configuration as JSON string.')
  defaultDatasetsConfiguration: string?

  @description('Default events configuration as JSON string.')
  defaultEventsConfiguration: string?
}

@export()
@description('Legacy asset endpoint profile configuration.')
type AssetEndpointProfile = {
  @description('Name of the asset endpoint profile.')
  name: string

  @description('Type of the endpoint profile: Microsoft.OpcUa, etc.')
  endpointProfileType: string?

  @description('Authentication method: Anonymous, etc.')
  method: string?

  @description('Target address of the endpoint.')
  targetAddress: string

  @description('Additional OPC configuration as JSON string.')
  opcAdditionalConfigString: string?

  @description('Whether to enable OPC asset discovery.')
  shouldEnableOpcAssetDiscovery: bool?
}

@export()
@description('Legacy asset data point configuration.')
type LegacyAssetDataPoint = {
  @description('Name of the data point.')
  name: string

  @description('Data source address.')
  dataSource: string

  @description('Data point configuration as JSON string.')
  dataPointConfiguration: string?

  @description('Observability mode: None, etc.')
  observabilityMode: string?
}

@export()
@description('Legacy asset dataset configuration.')
type LegacyAssetDataset = {
  @description('Name of the dataset.')
  name: string

  @description('Data points in the dataset.')
  dataPoints: LegacyAssetDataPoint[]
}

@export()
@description('Legacy asset configuration.')
type LegacyAsset = {
  @description('Name of the asset.')
  name: string

  @description('Reference to the asset endpoint profile.')
  assetEndpointProfileRef: string

  @description('Display name of the asset.')
  displayName: string?

  @description('Description of the asset.')
  description: string?

  @description('Documentation URI for the asset.')
  documentationUri: string?

  @description('Whether the asset is enabled.')
  isEnabled: bool

  @description('Hardware revision of the asset.')
  hardwareRevision: string?

  @description('Manufacturer of the asset.')
  manufacturer: string?

  @description('Manufacturer URI of the asset.')
  manufacturerUri: string?

  @description('Model of the asset.')
  model: string?

  @description('Product code of the asset.')
  productCode: string?

  @description('Serial number of the asset.')
  serialNumber: string?

  @description('Software revision of the asset.')
  softwareRevision: string?

  @description('Datasets for the asset.')
  datasets: LegacyAssetDataset[]

  @description('Default datasets configuration as JSON string.')
  defaultDatasetsConfiguration: string?
}

@export()
@description('Default namespaced device configuration.')
var defaultNamespacedDevice = {
  name: 'namespaced-opc-ua-connector'
  isEnabled: true
  endpoints: {
    outbound: {
      assigned: {}
    }
    inbound: {
      'namespaced-opc-ua-connector-0': {
        endpointType: 'Microsoft.OpcUa'
        address: 'opc.tcp://opcplc-000000:50000'
        version: null
        additionalConfiguration: null
        authentication: {
          method: 'Anonymous'
        }
        trustSettings: null
      }
    }
  }
}

@export()
@description('Default namespaced asset configuration.')
var defaultNamespacedAsset = {
  name: 'namespaced-oven'
  displayName: 'oven namespaced'
  deviceRef: {
    deviceName: defaultNamespacedDevice.name
    endpointName: 'namespaced-opc-ua-connector-0'
  }
  description: 'Multi-function large oven for baked goods.'
  documentationUri: 'http://docs.contoso.com/ovens'
  isEnabled: true
  hardwareRevision: '2.3'
  manufacturer: 'Contoso'
  manufacturerUri: 'http://www.contoso.com/ovens'
  model: 'Oven-003'
  productCode: '12345C'
  serialNumber: '12345'
  softwareRevision: '14.1'
  attributes: {}
  datasets: [
    {
      name: 'Oven namespaced telemetry'
      dataPoints: [
        {
          name: 'Temp'
          dataSource: 'ns=3;s=FastUInt10'
          dataPointConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
        }
        {
          name: 'FillWeight'
          dataSource: 'ns=3;s=FastUInt4'
          dataPointConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
        }
        {
          name: 'EnergyUse'
          dataSource: 'ns=3;s=FastUInt5'
          dataPointConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
        }
      ]
      destinations: [
        {
          target: 'Mqtt'
          configuration: {
            topic: 'azure-iot-operations/data/oven-ns'
            retain: 'Never'
            qos: 'Qos1'
          }
        }
      ]
    }
  ]
  defaultDatasetsConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
  defaultEventsConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
}

@export()
@description('Default legacy asset endpoint profile configuration.')
var defaultAssetEndpointProfile = {
  name: 'opc-ua-connector-0'
  endpointProfileType: 'Microsoft.OpcUa'
  method: 'Anonymous'
  targetAddress: 'opc.tcp://opcplc-000000:50000'
}

@export()
@description('Default legacy asset configuration.')
var defaultLegacyAsset = {
  name: 'oven'
  assetEndpointProfileRef: defaultAssetEndpointProfile.name
  displayName: 'oven'
  description: 'An oven is essential for baking a wide variety of products.'
  documentationUri: 'http://docs.oven.asset.contoso'
  isEnabled: true
  hardwareRevision: 'http://docs.oven.asset.contoso'
  manufacturer: 'http://asset.oven.contoso'
  manufacturerUri: 'http://oven.asset.contoso'
  model: 'Mymodel'
  productCode: '12345C'
  serialNumber: '12345'
  softwareRevision: '1.1'
  datasets: [
    {
      name: 'default-dataset'
      dataPoints: [
        {
          name: 'Temperature'
          dataSource: 'ns=3;s=FastUInt10'
          dataPointConfiguration: '{"samplingInterval":500,"queueSize":1}'
          observabilityMode: 'None'
        }
        {
          name: 'FillWeight'
          dataSource: 'ns=3;s=FastUInt4'
          dataPointConfiguration: '{"samplingInterval":500,"queueSize":1}'
          observabilityMode: 'None'
        }
        {
          name: 'EnergyUse'
          dataSource: 'ns=3;s=FastUInt5'
          dataPointConfiguration: '{"samplingInterval":500,"queueSize":1}'
          observabilityMode: 'None'
        }
      ]
    }
  ]
  defaultDatasetsConfiguration: '{"samplingInterval":500,"queueSize":1,"publishingInterval":1000}'
}
