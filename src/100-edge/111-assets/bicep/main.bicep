metadata name = 'IoT Assets'
metadata description = 'Deploys and manages Kubernetes asset definitions for Edge AI applications. Facilitates the creation of asset types and asset instances.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The ID (resource ID) of the custom location to retrieve.')
param customLocationId string

/*
  Device Registry Parameters
*/

@description('Azure Device Registry namespace name to use with Azure IoT Operations.')
param adrNamespaceName string

/*
  Device Configuration Parameters
*/

@description('List of namespaced devices to create.')
param namespacedDevices types.NamespacedDevice[] = []

/*
  Legacy Asset Configuration Parameters
*/

@description('List of asset endpoint profiles to create.')
param assetEndpointProfiles types.AssetEndpointProfile[] = []

@description('List of legacy assets to create.')
param legacyAssets types.LegacyAsset[] = []

/*
  Namespaced Asset Configuration Parameters
*/

@description('List of namespaced assets to create.')
param namespacedAssets types.NamespacedAsset[] = []

/*
  Feature Flag Parameters
*/

@description('Whether to create a default legacy asset and endpoint profile.')
param shouldCreateDefaultAsset bool = false

@description('Whether to create a default namespaced asset and device.')
param shouldCreateDefaultNamespacedAsset bool = false

/*
  Identity Parameters
*/

@description('The principal ID of the K8 Bridge for Azure IoT Operations. Required for OPC asset discovery.')
param k8sBridgePrincipalId string?

/*
  Local Variables
*/

var processedNamespacedDevices = [
  for device in concat(shouldCreateDefaultNamespacedAsset ? [types.defaultNamespacedDevice] : [], namespacedDevices): {
    name: device.name
    isEnabled: device.?isEnabled ?? types.defaultNamespacedDevice.isEnabled
    endpoints: device.?endpoints ?? types.defaultNamespacedDevice.endpoints
  }
]

var processedNamespacedAssets = [
  for asset in concat(shouldCreateDefaultNamespacedAsset ? [types.defaultNamespacedAsset] : [], namespacedAssets): {
    name: asset.name
    displayName: asset.?displayName ?? asset.name
    deviceRef: asset.deviceRef
    description: asset.?description
    documentationUri: asset.?documentationUri
    isEnabled: asset.?isEnabled ?? types.defaultNamespacedAsset.isEnabled
    hardwareRevision: asset.?hardwareRevision
    manufacturer: asset.?manufacturer
    manufacturerUri: asset.?manufacturerUri
    model: asset.?model
    productCode: asset.?productCode
    serialNumber: asset.?serialNumber
    softwareRevision: asset.?softwareRevision
    attributes: asset.?attributes ?? types.defaultNamespacedAsset.attributes
    datasets: asset.?datasets ?? types.defaultNamespacedAsset.datasets
    defaultDatasetsConfiguration: asset.?defaultDatasetsConfiguration ?? types.defaultNamespacedAsset.defaultDatasetsConfiguration
    defaultEventsConfiguration: asset.?defaultEventsConfiguration ?? types.defaultNamespacedAsset.defaultEventsConfiguration
  }
]

var processedAssetEndpointProfiles = [
  for profile in concat(shouldCreateDefaultAsset ? [types.defaultAssetEndpointProfile] : [], assetEndpointProfiles): {
    name: profile.name
    endpointProfileType: profile.?endpointProfileType ?? types.defaultAssetEndpointProfile.endpointProfileType
    method: profile.?method ?? types.defaultAssetEndpointProfile.method
    targetAddress: profile.targetAddress
    opcAdditionalConfigString: profile.?opcAdditionalConfigString ?? (profile.?shouldEnableOpcAssetDiscovery == true
      ? '{"runAssetDiscovery": true}'
      : null)
  }
]

var processedLegacyAssets = [
  for asset in concat(shouldCreateDefaultAsset ? [types.defaultLegacyAsset] : [], legacyAssets): {
    name: asset.name
    assetEndpointProfileRef: asset.assetEndpointProfileRef
    displayName: asset.?displayName ?? asset.name
    description: asset.?description
    documentationUri: asset.?documentationUri
    isEnabled: asset.?isEnabled ?? types.defaultLegacyAsset.isEnabled
    hardwareRevision: asset.?hardwareRevision
    manufacturer: asset.?manufacturer
    manufacturerUri: asset.?manufacturerUri
    model: asset.?model
    productCode: asset.?productCode
    serialNumber: asset.?serialNumber
    softwareRevision: asset.?softwareRevision
    datasets: asset.?datasets ?? types.defaultLegacyAsset.datasets
    defaultDatasetsConfiguration: asset.?defaultDatasetsConfiguration ?? types.defaultLegacyAsset.defaultDatasetsConfiguration
  }
]

var shouldEnableOpcAssetDiscovery = length(filter(
  concat(
    shouldCreateDefaultAsset || shouldCreateDefaultNamespacedAsset ? [types.defaultAssetEndpointProfile] : [],
    assetEndpointProfiles
  ),
  profile => profile.?shouldEnableOpcAssetDiscovery == true
)) > 0

/*
  Resources
*/

resource adrNamespace 'Microsoft.DeviceRegistry/namespaces@2025-07-01-preview' existing = {
  name: adrNamespaceName!
}

/*
  Namespaced Devices (replaces Asset Endpoint Profiles)
*/

resource namespacedDevice 'Microsoft.DeviceRegistry/namespaces/devices@2025-07-01-preview' = [
  for device in processedNamespacedDevices: {
    name: device.name
    parent: adrNamespace
    properties: {
      enabled: device.isEnabled
      endpoints: device.endpoints
    }
    location: common.location
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
  }
]

/*
  Namespaced Asset Instances
*/

resource namespacedAsset 'Microsoft.DeviceRegistry/namespaces/assets@2025-07-01-preview' = [
  for (asset, i) in processedNamespacedAssets: {
    name: asset.name
    parent: adrNamespace
    dependsOn: namespacedDevice
    properties: {
      displayName: asset.displayName
      deviceRef: {
        deviceName: asset.deviceRef.deviceName
        endpointName: asset.deviceRef.endpointName
      }
      description: asset.description
      documentationUri: asset.documentationUri
      enabled: asset.isEnabled
      hardwareRevision: asset.hardwareRevision
      manufacturer: asset.manufacturer
      manufacturerUri: asset.manufacturerUri
      model: asset.model
      productCode: asset.productCode
      serialNumber: asset.serialNumber
      softwareRevision: asset.softwareRevision
      attributes: asset.attributes
      datasets: [
        for dataset in asset.datasets: {
          name: dataset.name
          dataPoints: dataset.dataPoints
          destinations: dataset.?destinations ?? []
        }
      ]
      defaultDatasetsConfiguration: asset.defaultDatasetsConfiguration
      defaultEventsConfiguration: asset.defaultEventsConfiguration
    }
    location: common.location
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
  }
]

/*
  Legacy Asset Endpoint Profiles
*/

resource assetEndpointProfile 'Microsoft.DeviceRegistry/assetEndpointProfiles@2024-11-01' = [
  for profile in processedAssetEndpointProfiles: {
    name: profile.name
    properties: {
      additionalConfiguration: profile.opcAdditionalConfigString
      authentication: {
        method: profile.method
      }
      endpointProfileType: profile.endpointProfileType
      targetAddress: profile.targetAddress
    }
    location: common.location
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
  }
]

/*
  Legacy Asset Instances
*/

resource legacyAsset 'Microsoft.DeviceRegistry/assets@2024-11-01' = [
  for (asset, i) in processedLegacyAssets: {
    name: asset.name
    dependsOn: assetEndpointProfile
    properties: {
      assetEndpointProfileRef: asset.assetEndpointProfileRef
      datasets: [
        for dataset in asset.datasets: {
          name: dataset.name
          dataPoints: dataset.dataPoints
        }
      ]
      defaultDatasetsConfiguration: asset.defaultDatasetsConfiguration
      description: asset.description
      displayName: asset.displayName
      documentationUri: asset.documentationUri
      enabled: asset.isEnabled
      hardwareRevision: asset.hardwareRevision
      manufacturer: asset.manufacturer
      manufacturerUri: asset.manufacturerUri
      model: asset.model
      productCode: asset.productCode
      serialNumber: asset.serialNumber
      softwareRevision: asset.softwareRevision
    }
    location: common.location
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
  }
]

/*
  Modules
*/

module k8BridgeRoleAssignment 'modules/k8-bridge-role-assignment.bicep' = if (shouldEnableOpcAssetDiscovery && k8sBridgePrincipalId != null) {
  name: '${deployment().name}-k8ra0'
  params: {
    customLocationId: customLocationId
    k8sBridgePrincipalId: k8sBridgePrincipalId!
  }
}

/*
  Outputs
*/

@description('Map of legacy asset endpoint profiles created by this component.')
output assetEndpointProfiles object = toObject(assetEndpointProfile, profile => profile.name, profile => {
  id: profile.id
  name: profile.name
})

@description('Map of legacy assets created by this component.')
output legacyAssets object = toObject(legacyAsset, asset => asset.name, asset => {
  id: asset.id
  name: asset.name
})

@description('Map of namespaced devices created by this component.')
output namespacedDevices object = toObject(namespacedDevice, device => device.name, device => {
  id: device.id
  name: device.name
})

@description('Map of namespaced assets created by this component.')
output namespacedAssets object = toObject(namespacedAsset, asset => asset.name, asset => {
  id: asset.id
  name: asset.name
})

@description('Whether OPC simulation asset discovery is enabled for any endpoint profile.')
output shouldEnableOpcAssetDiscovery bool = shouldEnableOpcAssetDiscovery
