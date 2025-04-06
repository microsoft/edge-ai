metadata name = 'IoT Operations Instance Post-Deployment Module'
metadata description = 'Configures federated identity credentials for Azure IoT Operations and Secret Sync Extension service accounts and sets up Key Vault Secret Provider Class.'

import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('Name of the existing arc-enabled cluster where AIO will be deployed.')
param arcConnectedClusterName string

@description('The resource Id for the Custom Locations for Azure IoT Operations.')
param customLocationId string

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseIdentityName string

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioIdentityName string

@description('The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)')
param sseKeyVaultName string

@description('The namespace for Azure IoT Operations in the cluster.')
param aioNamespace string

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2024-12-01-preview' existing = {
  name: arcConnectedClusterName
}

resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sseIdentityName

  resource sseFedCred 'federatedIdentityCredentials' = {
    name: 'aio-sse-ficred'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: arcConnectedCluster.properties.oidcIssuerProfile.issuerUrl
      subject: 'system:serviceaccount:${aioNamespace}:aio-ssc-sa'
    }
  }
}

resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: aioIdentityName

  resource aioFedCred 'federatedIdentityCredentials' = {
    name: 'aio-instance-ficred'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: arcConnectedCluster.properties.oidcIssuerProfile.issuerUrl
      subject: 'system:serviceaccount:${aioNamespace}:aio-dataflow'
    }
  }
}

resource defaultSecretSyncSecretProviderClass 'Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview' = {
  name: 'spc-ops-aio'
  location: common.location

  extendedLocation: {
    name: customLocationId
    type: 'CustomLocation'
  }

  properties: {
    clientId: sseIdentity.properties.clientId
    keyvaultName: sseKeyVaultName!
    tenantId: sseIdentity.properties.tenantId
  }
}
