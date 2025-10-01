metadata name = 'IoT Operations Initialization Module'
metadata description = 'Initializes and configures the required Arc extensions for Azure IoT Operations including Secret Store, Open Service Mesh, Container Storage, and IoT Operations Platform.'

import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

@description('The settings for the Azure Container Store for Azure Arc Extension.')
param containerStorageConfig types.ContainerStorageExtension

@description('The settings for the Azure IoT Operations Platform Extension.')
param aioPlatformConfig types.AioPlatformExtension

@description('The settings for the Secret Store Extension.')
#disable-next-line secure-secrets-in-params
param secretStoreConfig types.SecretStoreExtension

/*
  Variables
*/

// Setup ACSA StorageClass based on either provided StorageClass, Fault Tolerance Enabled, or the
// default StorageClass provided by local-path.
var defaultStorageClass = containerStorageConfig.settings.faultToleranceEnabled
  ? 'acstor-arccontainerstorage-storage-pool'
  : 'default,local-path'

var kubernetesStorageClass = containerStorageConfig.settings.?diskStorageClass ?? defaultStorageClass
var diskMountPoint = containerStorageConfig.settings.?diskMountPoint ?? '/mnt'

var faultToleranceConfig = containerStorageConfig.settings.faultToleranceEnabled
  ? {
      'acstorConfiguration.create': 'true'
      'acstorConfiguration.properties.diskMountPoint': diskMountPoint
    }
  : {}

/*
  Resources
*/

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: arcConnectedClusterName
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
      installCertManager: '${aioPlatformConfig.settings.?installCertManager ?? true}'
      installTrustManager: '${aioPlatformConfig.settings.?installCertManager ?? true}'
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
    aioPlatform
  ]
}

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

/*
  Outputs
*/

@description('The ID of the Container Storage Extension.')
output containerStorageExtensionId string = containerStorage.id

@description('The name of the Container Storage Extension.')
output containerStorageExtensionName string = containerStorage.name

@description('The ID of the Secret Store Extension.')
output secretStoreExtensionId string = secretStore.id

@description('The name of the Secret Store Extension.')
output secretStoreExtensionName string = secretStore.name

@description('The ID of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionId string = aioPlatform.id

@description('The name of the Azure IoT Operations Platform Extension.')
output aioPlatformExtensionName string = aioPlatform.name
