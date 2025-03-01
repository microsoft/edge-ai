import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

@description('The common component configuration.')
param common core.Common

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

@description('The name for the ADR Schema Registry for Azure IoT Operations.')
param schemaRegistryName string

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioUserAssignedIdentityName string?

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseUserAssignedIdentityName string?

@description('The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)')
param sseKeyVaultName string?

resource schemaRegistry 'Microsoft.DeviceRegistry/schemaRegistries@2024-09-01-preview' existing = {
  name: schemaRegistryName
}

resource aioUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (!empty(aioUserAssignedIdentityName)) {
  name: aioUserAssignedIdentityName!
}

module iotOps '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-iotOps'
  params: {
    arcConnectedClusterName: arcConnectedClusterName
    common: common
    schemaRegistryId: schemaRegistry.id
    aioUserAssignedIdentityId: !empty(aioUserAssignedIdentityName) ? aioUserAssignedIdentity.id : null
    aioUserAssignedIdentityName: aioUserAssignedIdentityName
    sseUserAssignedIdentityName: sseUserAssignedIdentityName
    sseKeyVaultName: sseKeyVaultName
  }
}
