metadata name = 'CI Configuration for Kubernetes Assets'
metadata description = 'CI configuration for deploying Kubernetes assets.'

/*
  Parameters
*/

@description('Prefix for all resources in this module')
param resourcePrefix string

@description('Azure region where all resources will be deployed')
param location string

@description('Environment for all resources in this module: dev, test, or prod.')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Instance identifier for naming resources: 001, 002, etc')
param instance string = '001'

@description('Whether to create a default legacy asset. Otherwise, false.')
param shouldCreateDefaultAsset bool = false

@description('Whether to create a default namespaced asset and device. Otherwise, false.')
param shouldCreateDefaultNamespacedAsset bool = false

/*
  Existing Resources
*/

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  scope: subscription()
  name: 'rg-${resourcePrefix}-${environment}-${instance}'
}

resource customLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' existing = {
  scope: resourceGroup
  name: 'cl-arck-${resourcePrefix}-${environment}-${instance}'
}

resource adrNamespace 'Microsoft.DeviceRegistry/namespaces@2025-10-01' existing = {
  scope: resourceGroup
  name: 'adrns-${resourcePrefix}-${environment}-${instance}'
}

/*
  Module
*/

module ci '../../bicep/main.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-ci'
  params: {
    common: {
      resourcePrefix: resourcePrefix
      location: location
      environment: environment
      instance: instance
    }
    customLocationId: customLocation.id
    adrNamespaceName: adrNamespace.name
    shouldCreateDefaultAsset: shouldCreateDefaultAsset
    shouldCreateDefaultNamespacedAsset: shouldCreateDefaultNamespacedAsset
  }
}

/*
  Outputs
*/

@description('Array of legacy asset endpoint profiles created by this CI deployment.')
output assetEndpointProfiles array = ci.outputs.assetEndpointProfiles

@description('Array of legacy assets created by this CI deployment.')
output legacyAssets array = ci.outputs.legacyAssets

@description('Array of namespaced devices created by this CI deployment.')
output namespacedDevices array = ci.outputs.namespacedDevices

@description('Array of namespaced assets created by this CI deployment.')
output namespacedAssets array = ci.outputs.namespacedAssets

@description('Whether OPC simulation asset discovery is enabled for any endpoint profile.')
output shouldEnableOpcAssetDiscovery bool = ci.outputs.shouldEnableOpcAssetDiscovery
