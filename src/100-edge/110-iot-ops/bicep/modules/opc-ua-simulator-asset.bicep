metadata name = 'OPC UA Simulator'
metadata description = 'Deploy and configure the OPC UA Simulator'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The ID of the custom location.')
param customLocationId string

@description('The ID of the ADR namespace.')
param adrNamespaceId string

/*
  Resources
*/

resource device 'Microsoft.DeviceRegistry/namespaces/devices@2025-10-01' = {
  name: 'opc-ua-connector-0'
  location: common.location
  parent: adrNamespace
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    endpoints: {
      outbound: {
        assigned: {}
      }
      inbound: {
        'opc-ua-connector-0-endpoint': {
          endpointType: 'Microsoft.OpcUa'
          address: 'opc.tcp://opcplc-000000:50000'
          authentication: {
            method: 'Anonymous'
          }
        }
      }
    }
  }
}

resource adrNamespace 'Microsoft.DeviceRegistry/namespaces@2025-10-01' existing = {
  name: last(split(adrNamespaceId, '/'))
}

resource asset 'Microsoft.DeviceRegistry/namespaces/assets@2025-10-01' = {
  name: 'oven'
  location: common.location
  parent: adrNamespace
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    displayName: 'oven'
    deviceRef: {
      deviceName: device.name
      endpointName: 'opc-ua-connector-0-endpoint'
    }
    description: 'an oven is essential for baking a wide variety of products'
    enabled: true
    externalAssetId: '32faab3f-88e8-4f38-b901-e175dde50c28'
    manufacturer: 'http://asset.oven.contoso'
    manufacturerUri: 'http://oven.asset.contoso'
    model: 'Mymodel'
    productCode: '12345C'
    hardwareRevision: 'http://docs.oven.asset.contoso'
    softwareRevision: '1.1'
    serialNumber: '12345'
    documentationUri: 'http://docs.oven.asset.contoso'
    datasets: [
      {
        name: 'some random datasets name'
        dataPoints: [
          {
            name: 'Temperature'
            dataSource: 'ns=3;s=FastUInt10'
            dataPointConfiguration: '{"samplingInterval":500,"queueSize":1}'
          }
          {
            name: 'FillWeight'
            dataSource: 'ns=3;s=FastUInt4'
            dataPointConfiguration: '{"samplingInterval":500,"queueSize":1}'
          }
          {
            name: 'EnergyUse'
            dataSource: 'ns=3;s=FastUInt5'
            dataPointConfiguration: '{"samplingInterval":500,"queueSize":1}'
          }
        ]
      }
    ]
    defaultDatasetsConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
  }
}

/*
  Outputs
*/

@description('The ID of the device.')
output deviceId string = device.id

@description('The ID of the asset.')
output assetId string = asset.id
