import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

@description('The common component configuration.')
param common core.Common

@description('The resource name for the Arc connected cluster.')
param arcConnectedClusterName string

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string

@description('The name of the User Assigned Managed Identity for Azure IoT Operations.')
param aioUserAssignedIdentityName string

@description('The name of the User Assigned Managed Identity for Secret Sync.')
param sseUserAssignedIdentityName string

@description('The name of the Key Vault for Secret Sync. (Required when providing sseUserManagedIdentityName)')
param sseKeyVaultName string

module ci '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    arcConnectedClusterName: arcConnectedClusterName
    common: common
    schemaRegistryName: schemaRegistryName
    aioIdentityName: aioUserAssignedIdentityName
    sseIdentityName: sseUserAssignedIdentityName
    sseKeyVaultName: sseKeyVaultName
  }
}
