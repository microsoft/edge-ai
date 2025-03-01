import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('Name of the existing arc-enabled cluster where AIO will be deployed.')
param arcConnectedClusterName string

@description('The resource Id for the Custom Locations for Azure IoT Operations.')
param customLocationId string

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseUserManagedIdentityName string?

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioUserManagedIdentityName string?

@description('The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)')
param sseKeyVaultName string?

@description('The namespace for Azure IoT Operations in the cluster.')
param aioNamespace string

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2024-12-01-preview' existing = {
  name: arcConnectedClusterName
}

resource sseUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (!empty(sseUserManagedIdentityName)) {
  name: sseUserManagedIdentityName!

  resource sseFedCred 'federatedIdentityCredentials' = {
    name: 'aio-sse-ficred'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: arcConnectedCluster.properties.oidcIssuerProfile.issuerUrl
      subject: 'system:serviceaccount:${aioNamespace}:aio-ssc-sa'
    }
  }
}

resource aioUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (!empty(aioUserManagedIdentityName)) {
  name: aioUserManagedIdentityName!

  resource sseFedCred 'federatedIdentityCredentials' = {
    name: 'aio-instance-ficred'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: arcConnectedCluster.properties.oidcIssuerProfile.issuerUrl
      subject: 'system:serviceaccount:${aioNamespace}:aio-dataflow'
    }
  }
}

resource defaultSecretSyncSecretProviderClass 'Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview' = if (!empty(sseUserManagedIdentityName)) {
  name: 'spc-ops-aio'
  location: common.location

  extendedLocation: {
    name: customLocationId
    type: 'CustomLocation'
  }

  properties: {
    clientId: sseUserManagedIdentity.properties.clientId
    keyvaultName: sseKeyVaultName!
    tenantId: sseUserManagedIdentity.properties.tenantId
  }
}
