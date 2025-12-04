metadata name = 'Kubernetes Assets'
metadata description = 'Deploys Kubernetes asset definitions to a connected cluster using the namespaced Device Registry model. This component facilitates the management of devices and assets within ADR namespaces.'

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
    isEnabled: device.?isEnabled ?? true
    endpoints: {
      inbound: device.endpoints.inbound
      outbound: device.?endpoints.?outbound
    }
  }
]

var processedNamespacedAssets = [
  for asset in concat(shouldCreateDefaultNamespacedAsset ? [types.defaultNamespacedAsset] : [], namespacedAssets): {
    name: asset.name
    displayName: asset.?displayName ?? asset.name
    deviceRef: asset.deviceRef
    description: asset.?description
    documentationUri: asset.?documentationUri
    isEnabled: asset.?isEnabled ?? true
    hardwareRevision: asset.?hardwareRevision
    manufacturer: asset.?manufacturer
    manufacturerUri: asset.?manufacturerUri
    model: asset.?model
    productCode: asset.?productCode
    serialNumber: asset.?serialNumber
    softwareRevision: asset.?softwareRevision
    attributes: asset.?attributes ?? {}
    datasets: asset.?datasets ?? []
    defaultDatasetsConfiguration: asset.?defaultDatasetsConfiguration ?? '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
    defaultEventsConfiguration: asset.?defaultEventsConfiguration ?? '{"publishingInterval":1000,"samplingInterval":500,"queueSize":1}'
  }
]

var processedAssetEndpointProfiles = [
  for profile in concat(shouldCreateDefaultAsset ? [types.defaultAssetEndpointProfile] : [], assetEndpointProfiles): {
    name: profile.name
    endpointProfileType: profile.?endpointProfileType ?? 'Microsoft.OpcUa'
    method: profile.?method ?? 'Anonymous'
    targetAddress: profile.targetAddress
    opcAdditionalConfigString: profile.?opcAdditionalConfigString ?? (profile.?shouldEnableOpcAssetDiscovery == true
      ? '{"runAssetDiscovery":true}'
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
    isEnabled: asset.?isEnabled ?? true
    hardwareRevision: asset.?hardwareRevision
    manufacturer: asset.?manufacturer
    manufacturerUri: asset.?manufacturerUri
    model: asset.?model
    productCode: asset.?productCode
    serialNumber: asset.?serialNumber
    softwareRevision: asset.?softwareRevision
    datasets: asset.?datasets ?? []
    defaultDatasetsConfiguration: asset.?defaultDatasetsConfiguration ?? '{"samplingInterval":500,"queueSize":1,"publishingInterval":1000}'
  }
]

var shouldEnableOpcAssetDiscovery = length(filter(
  concat(shouldCreateDefaultAsset ? [types.defaultAssetEndpointProfile] : [], assetEndpointProfiles),
  profile => profile.?shouldEnableOpcAssetDiscovery == true
)) > 0

/*
  Resources
*/

resource adrNamespace 'Microsoft.DeviceRegistry/namespaces@2025-10-01' existing = {
  name: adrNamespaceName!
}

/*
  Namespaced Devices (replaces Asset Endpoint Profiles)
*/

resource namespacedDevice 'Microsoft.DeviceRegistry/namespaces/devices@2025-10-01' = [
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

resource namespacedAsset 'Microsoft.DeviceRegistry/namespaces/assets@2025-10-01' = [
  for asset in processedNamespacedAssets: {
    name: asset.name
    parent: adrNamespace
    dependsOn: namespacedDevice
    properties: union(
      {
        attributes: asset.attributes
        defaultDatasetsConfiguration: asset.defaultDatasetsConfiguration
        defaultEventsConfiguration: asset.defaultEventsConfiguration
        deviceRef: {
          deviceName: asset.deviceRef.deviceName
          endpointName: asset.deviceRef.endpointName
        }
        displayName: asset.displayName
        enabled: asset.isEnabled
        datasets: asset.datasets
      },
      asset.description != null ? { description: asset.description } : {},
      asset.documentationUri != null ? { documentationUri: asset.documentationUri } : {},
      asset.hardwareRevision != null ? { hardwareRevision: asset.hardwareRevision } : {},
      asset.manufacturer != null ? { manufacturer: asset.manufacturer } : {},
      asset.manufacturerUri != null ? { manufacturerUri: asset.manufacturerUri } : {},
      asset.model != null ? { model: asset.model } : {},
      asset.productCode != null ? { productCode: asset.productCode } : {},
      asset.serialNumber != null ? { serialNumber: asset.serialNumber } : {},
      asset.softwareRevision != null ? { softwareRevision: asset.softwareRevision } : {}
    )
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

resource assetEndpointProfile 'Microsoft.DeviceRegistry/assetEndpointProfiles@2025-10-01' = [
  for profile in processedAssetEndpointProfiles: {
    name: profile.name
    properties: union(
      {
        authentication: {
          method: profile.method
        }
        endpointProfileType: profile.endpointProfileType
        targetAddress: profile.targetAddress
      },
      profile.opcAdditionalConfigString != null ? { additionalConfiguration: profile.opcAdditionalConfigString } : {}
    )
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

resource legacyAsset 'Microsoft.DeviceRegistry/assets@2025-10-01' = [
  for asset in processedLegacyAssets: {
    name: asset.name
    dependsOn: assetEndpointProfile
    properties: {
      assetEndpointProfileRef: asset.assetEndpointProfileRef
      datasets: asset.datasets
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

@description('Array of legacy asset endpoint profiles created by this component.')
output assetEndpointProfiles array = [
  for (profile, i) in processedAssetEndpointProfiles: {
    id: assetEndpointProfile[i].id
    name: assetEndpointProfile[i].name
  }
]

@description('Array of legacy assets created by this component.')
output legacyAssets array = [
  for (asset, i) in processedLegacyAssets: {
    id: legacyAsset[i].id
    name: legacyAsset[i].name
  }
]

@description('Array of namespaced devices created by this component.')
output namespacedDevices array = [
  for (device, i) in processedNamespacedDevices: {
    id: namespacedDevice[i].id
    name: namespacedDevice[i].name
  }
]

@description('Array of namespaced assets created by this component.')
output namespacedAssets array = [
  for (asset, i) in processedNamespacedAssets: {
    id: namespacedAsset[i].id
    name: namespacedAsset[i].name
  }
]

@description('Whether OPC simulation asset discovery is enabled for any endpoint profile.')
output shouldEnableOpcAssetDiscovery bool = shouldEnableOpcAssetDiscovery
