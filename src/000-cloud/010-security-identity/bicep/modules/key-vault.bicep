metadata name = 'Secret Store Extension Key Vault Module'
metadata description = 'Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Key Vault Parameters
*/

@description('The name of the Key Vault.')
param keyVaultName string

/*
  Role Assignment Parameters
*/

@description('Whether or not to create a role assignment for an admin user.')
param shouldAssignAdminUserRole bool

@description('The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.')
param adminUserObjectId string

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: common.location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
  }
}

@description('Assigns "Key Vault Secrets Officer" to the admin user Object ID.')
resource keyVaultSecretsOfficerCurrentUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (shouldAssignAdminUserRole) {
  name: guid(resourceGroup().id, adminUserObjectId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: keyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-officer
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    )
    principalId: adminUserObjectId
    principalType: 'User'
  }
}

/*
  Outputs
*/

@description('The name of the Secret Store Extension Key Vault.')
output keyVaultName string = keyVault.name

@description('The resource ID of the Secret Store Extension Key Vault.')
output keyVaultId string = keyVault.id
