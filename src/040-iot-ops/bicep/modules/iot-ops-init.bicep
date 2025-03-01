import * as types from '../types.bicep'

@description('The settings for the Secret Store Extension.')
#disable-next-line secure-secrets-in-params
param secretStoreConfig types.SecretStoreExtension

@description('The settings for the Open Service Mesh Extension.')
param openServiceMeshConfig types.OpenServiceMeshExtension

@description('The settings for the Azure Container Store for Azure Arc Extension.')
param containerStorageConfig types.ContainerStorageExtension

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: arcConnectedClusterName
}

// Setup ACSA StorageClass based on either provided StorageClass, Fault Tolerance Enabled, or the
// default StorageClass provided by local-path.
var defaultStorageClass = containerStorageConfig.settings.faultToleranceEnabled
  ? 'acstor-arccontainerstorage-storage-pool'
  : 'default,local-path'

var kubernetesStorageClass = containerStorageConfig.settings.?diskStorageClass ?? defaultStorageClass

var faultToleranceConfig = containerStorageConfig.settings.faultToleranceEnabled
  ? {
      'acstorConfiguration.create': 'true'
      'acstorConfiguration.properties.diskMountPoint': '/mnt'
    }
  : {}

resource secretStore 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: arcConnectedCluster
  // 'azure-secret-store' is the required extension name for SSE.
  name: 'azure-secret-store'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.azure.secretstore'
    version: secretStoreConfig.release.version
    releaseTrain: secretStoreConfig.release.train
    autoUpgradeMinorVersion: false
    configurationSettings: {
      rotationPollIntervalInSeconds: '120'
      'validatingAdmissionPolicies.applyPolicies': 'false'
    }
  }
  dependsOn: [
    aioPlatform
  ]
}

resource openServiceMesh 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: arcConnectedCluster
  name: 'open-service-mesh'
  properties: {
    extensionType: 'microsoft.openservicemesh'
    autoUpgradeMinorVersion: false
    version: openServiceMeshConfig.release.version
    releaseTrain: openServiceMeshConfig.release.train
    configurationSettings: {
      'osm.osm.enablePermissiveTrafficPolicy': 'false'
      'osm.osm.featureFlags.enableWASMStats': 'false'
      'osm.osm.configResyncInterval': '10s'
      'osm.osm.osmController.resource.requests.cpu': '100m'
      'osm.osm.osmBootstrap.resource.requests.cpu': '100m'
      'osm.osm.injector.resource.requests.cpu': '100m'
    }
  }
}

resource containerStorage 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: arcConnectedCluster
  // 'azure-arc-containerstorage' is the required extension name for ACSA.
  name: 'azure-arc-containerstorage'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.arc.containerstorage'
    autoUpgradeMinorVersion: false
    version: containerStorageConfig.release.version
    releaseTrain: containerStorageConfig.release.train
    configurationSettings: {
      'edgeStorageConfiguration.create': 'true'
      'feature.diskStorageClass': kubernetesStorageClass
      ...faultToleranceConfig
    }
  }
  dependsOn: [
    openServiceMesh
    aioPlatform
  ]
}

resource aioPlatform 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: arcConnectedCluster
  name: 'azure-iot-operations-platform'
  properties: {
    extensionType: 'microsoft.iotoperations.platform'
    version: aioPlatformConfig.release.version
    releaseTrain: aioPlatformConfig.release.train
    autoUpgradeMinorVersion: false
    scope: {
      cluster: {
        releaseNamespace: 'cert-manager'
      }
    }
    configurationSettings: {
      installCertManager: '${aioPlatformConfig.?installCertManager ?? true}'
      installTrustManager: '${aioPlatformConfig.?installCertManager ?? true}'
    }
  }
}

output containerStorageExtensionId string = containerStorage.id
output secretStoreExtensionId string = secretStore.id
output openServiceMeshExtensionId string = openServiceMesh.id
output aioPlatformExtensionId string = aioPlatform.id
