metadata name = 'Arc Extensions'
metadata description = 'Deploys foundational Arc-enabled Kubernetes cluster extensions including cert-manager and Azure Container Storage (ACSA).'

import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

/*
  Extension Parameters
*/

@description('The settings for the cert-manager Extension.')
param certManagerConfig types.CertManagerExtension = types.certManagerExtensionDefaults

@description('The settings for the Azure Container Storage for Azure Arc Extension.')
param containerStorageConfig types.ContainerStorageExtension = types.containerStorageExtensionDefaults

/*
  Existing Resources
*/

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2024-12-01-preview' existing = {
  name: arcConnectedClusterName
}

/*
  cert-manager Extension
*/

resource aioCertManager 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = if (certManagerConfig.enabled) {
  name: 'arc-cert-manager'
  scope: arcConnectedCluster
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.certmanagement'
    version: certManagerConfig.release.version
    releaseTrain: certManagerConfig.release.train
    autoUpgradeMinorVersion: certManagerConfig.release.?autoUpgradeMinorVersion ?? false
    scope: {
      cluster: {
        releaseNamespace: 'cert-manager'
      }
    }
    configurationSettings: {
      AgentOperationTimeoutInMinutes: certManagerConfig.settings.?agentOperationTimeoutInMinutes
      'global.telemetry.enabled': string(certManagerConfig.settings.?globalTelemetryEnabled ?? true)
    }
  }
}

/*
  Azure Container Storage Extension
*/

var defaultStorageClass = containerStorageConfig.settings.?faultToleranceEnabled
  ? 'acstor-arccontainerstorage-storage-pool'
  : 'default,local-path'
var kubernetesStorageClass = containerStorageConfig.settings.?diskStorageClass ?? defaultStorageClass
var diskMountPoint = containerStorageConfig.settings.?diskMountPoint ?? '/mnt'

var containerStorageSettings = containerStorageConfig.settings.?faultToleranceEnabled
  ? {
      'edgeStorageConfiguration.create': 'true'
      'feature.diskStorageClass': kubernetesStorageClass
      'acstorConfiguration.create': 'true'
      'acstorConfiguration.properties.diskMountPoint': diskMountPoint
    }
  : {
      'edgeStorageConfiguration.create': 'true'
      'feature.diskStorageClass': kubernetesStorageClass
    }

resource containerStorage 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = if (containerStorageConfig.enabled) {
  name: 'azure-arc-containerstorage'
  scope: arcConnectedCluster
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.arc.containerstorage'
    version: containerStorageConfig.release.version
    releaseTrain: containerStorageConfig.release.train
    autoUpgradeMinorVersion: false
    configurationSettings: containerStorageSettings
  }
  dependsOn: [
    aioCertManager
  ]
}

/*
  Outputs
*/

@description('The resource ID of the cert-manager extension.')
output certManagerExtensionId string = certManagerConfig.enabled ? aioCertManager.id : ''

@description('The name of the cert-manager extension.')
output certManagerExtensionName string = certManagerConfig.enabled ? aioCertManager.name : ''

@description('The resource ID of the Azure Container Storage extension.')
output containerStorageExtensionId string = containerStorageConfig.enabled ? containerStorage.id : ''

@description('The name of the Azure Container Storage extension.')
output containerStorageExtensionName string = containerStorageConfig.enabled ? containerStorage.name : ''
