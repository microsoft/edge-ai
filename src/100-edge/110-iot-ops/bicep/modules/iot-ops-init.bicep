metadata name = 'IoT Operations Initialization Module'
metadata description = 'Initializes and configures the Secret Store extension for Azure IoT Operations. Depends on cert-manager deployed via 109-arc-extensions component.'

import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

@description('The settings for the Secret Store Extension.')
#disable-next-line secure-secrets-in-params
param secretStoreConfig types.SecretStoreExtension

/*
  Resources
*/

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: arcConnectedClusterName
}

resource secretStore 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = {
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
}

/*
  Outputs
*/

@description('The ID of the Secret Store Extension.')
output secretStoreExtensionId string = secretStore.id

@description('The name of the Secret Store Extension.')
output secretStoreExtensionName string = secretStore.name
