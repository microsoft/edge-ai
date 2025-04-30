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

/*
  Resources
*/

resource assetEndpoint 'Microsoft.DeviceRegistry/assetEndpointProfiles@2024-11-01' = {
  name: 'opc-ua-connector-0'
  location: common.location
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    targetAddress: 'opc.tcp://opcplc-000000:50000'
    endpointProfileType: 'Microsoft.OpcUa'
    authentication: {
      method: 'Anonymous'
    }
  }
}

resource asset 'Microsoft.DeviceRegistry/assets@2024-11-01' = {
  name: 'oven'
  location: common.location
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    displayName: 'oven'
    assetEndpointProfileRef: assetEndpoint.name
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
    defaultDatasetsConfiguration: '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
  }
}

/*
  Outputs
*/

@description('The ID of the asset endpoint.')
output assetEndpointId string = assetEndpoint.id

@description('The ID of the asset.')
output assetId string = asset.id
