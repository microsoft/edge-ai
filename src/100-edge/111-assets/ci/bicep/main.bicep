metadata name = 'IoT Assets CI Deployment'
metadata description = 'CI deployment configuration for IoT Assets component with minimal required parameters.'

import * as core from '../../bicep/types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The ID (resource ID) of the custom location to retrieve.')
param customLocationId string

@description('Azure Device Registry namespace name to use with Azure IoT Operations.')
param adrNamespaceName string

/*
  Optional CI Parameters
*/

@description('Whether to create a default legacy asset and endpoint profile for testing.')
param shouldCreateDefaultAsset bool = false

@description('Whether to create a default namespaced asset and device for testing.')
param shouldCreateDefaultNamespacedAsset bool = false

@description('The principal ID of the K8 Bridge for Azure IoT Operations.')
param k8sBridgePrincipalId string?

/*
  Modules
*/

module assets '../../bicep/main.bicep' = {
  name: '${deployment().name}-assets'
  params: {
    common: common
    customLocationId: customLocationId
    adrNamespaceName: adrNamespaceName
    shouldCreateDefaultAsset: shouldCreateDefaultAsset
    shouldCreateDefaultNamespacedAsset: shouldCreateDefaultNamespacedAsset
    k8sBridgePrincipalId: k8sBridgePrincipalId
  }
}

/*
  Outputs
*/

@description('Map of legacy asset endpoint profiles created by this component.')
output assetEndpointProfiles object = assets.outputs.assetEndpointProfiles

@description('Map of legacy assets created by this component.')
output legacyAssets object = assets.outputs.legacyAssets

@description('Map of namespaced devices created by this component.')
output namespacedDevices object = assets.outputs.namespacedDevices

@description('Map of namespaced assets created by this component.')
output namespacedAssets object = assets.outputs.namespacedAssets

@description('Whether OPC simulation asset discovery is enabled for any endpoint profile.')
output shouldEnableOpcAssetDiscovery bool = assets.outputs.shouldEnableOpcAssetDiscovery
