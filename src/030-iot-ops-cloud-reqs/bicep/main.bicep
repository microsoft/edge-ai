import * as core from './types.core.bicep'
import * as types from './types.bicep'

@description('The common component configuration.')
param common core.Common

/*
  Storage Account for Schema Registry Parameters
*/

@description('Whether or not to create a new Storage Account for the ADR Schema Registry.')
param shouldCreateStorageAccount bool = true

@description('The name for the Resource Group for the Storage Account.')
param storageAccountResourceGroupName string = resourceGroup().name

@description('The name for the Storage Account.')
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

@description('The settings for the new Storage Account.')
param storageAccountSettings types.StorageAccountSettings = {
  replicationType: 'LRS'
  tier: 'Standard'
}

@description('The name for the Blob Container for schemas.')
param schemaContainerName string = 'schemas'

/*
  Schema Registry Parameters
*/

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string = 'sch-reg-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The ADLS Gen2 namespace for the ADR Schema Registry.')
param schemaRegistryNamespace string = 'sch-reg-ns-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Key Vault Parameters
*/

@description('Whether or not to create a new Key Vault for the Secret Sync Extension.')
param shouldCreateKeyVault bool = true

@description('The name of the Key Vault.')
param keyVaultName string = 'kv-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The name for the Resource Group for the Key Vault.')
param keyVaultResourceGroupName string = resourceGroup().name

@description('Whether or not to create a role assignment for an admin user.')
param shouldAssignAdminUserRole bool = true

@description('The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.')
param adminUserObjectId string = deployer().objectId

/*
  Modules
*/

module schemaRegistryStorageAccount 'modules/schema-registry-storage-account.bicep' = if (shouldCreateStorageAccount) {
  name: '${common.resourcePrefix}-schemaRegistryStorageAccount'
  scope: resourceGroup(storageAccountResourceGroupName)
  params: {
    common: common
    storageAccountSettings: storageAccountSettings
    storageAccountName: storageAccountName
    schemaContainerName: schemaContainerName
  }
}

module schemaRegistry 'modules/schema-registry.bicep' = {
  name: '${common.resourcePrefix}-schemaRegistry'
  dependsOn: [schemaRegistryStorageAccount]
  params: {
    common: common
    schemaRegistryName: schemaRegistryName
    schemaRegistryNamespace: schemaRegistryNamespace
    storageAccountContainerUrl: 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${schemaContainerName}'
  }
}

module schemaRegistryRoleAssignments 'modules/schema-registry-role-assignments.bicep' = {
  name: '${common.resourcePrefix}-schemaRegistryRoleAssignments'
  scope: resourceGroup(storageAccountResourceGroupName)
  params: {
    storageAccountName: storageAccountName
    schemaBlobContainerName: schemaContainerName
    schemaRegistryPrincipalId: schemaRegistry.outputs.schemaRegistryPrincipalId
  }
}

module uami 'modules/uami.bicep' = {
  name: '${common.resourcePrefix}-uami'
  params: {
    common: common
  }
}

module sseKeyVault 'modules/sse-key-vault.bicep' = if (shouldCreateKeyVault) {
  name: '${common.resourcePrefix}-sseKeyVault'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    common: common
    keyVaultName: keyVaultName
  }
}

module sseKeyVaultRoleAssignments 'modules/sse-key-vault-role-assignments.bicep' = {
  name: '${common.resourcePrefix}-sseKeyVaultRoleAssignments'
  scope: resourceGroup(keyVaultResourceGroupName)
  dependsOn: [sseKeyVault]
  params: {
    keyVaultName: keyVaultName
    sseUamiPrincipalId: uami.outputs.sseUamiPrincipalId
    shouldAssignAdminUserRole: shouldAssignAdminUserRole
    adminUserObjectId: adminUserObjectId
  }
}
