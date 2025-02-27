@description('The name of the Key Vault to scope the role assignments.')
param keyVaultName string

@description('The Principal ID for the Secret Sync User Assigned Managed Identity.')
param sseUamiPrincipalId string

@description('Whether or not to create a role assignment for an admin user.')
param shouldAssignAdminUserRole bool

@description('The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.')
param adminUserObjectId string

resource sseKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

@description('Assigns "Key Vault Secrets Officer" to the admin user Object ID.')
resource keyVaultSecretsOfficerCurrentUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (shouldAssignAdminUserRole) {
  name: guid(resourceGroup().id, adminUserObjectId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: sseKeyVault
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

@description('Assigns "Key Vault Reader" role to the Secret Sync User Assigned Managed Identity.')
resource keyVaultReaderSseUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sseUamiPrincipalId, '21090545-7ca7-4776-b22c-e363652d74d2')
  scope: sseKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '21090545-7ca7-4776-b22c-e363652d74d2'
    )
    principalId: sseUamiPrincipalId
    principalType: 'ServicePrincipal'
  }
}

@description('Assigns "Key Vault Secrets User" role to the Secret Sync User Assigned Managed Identity.')
resource keyVaultSecretsUserSseUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sseUamiPrincipalId, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: sseKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: sseUamiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
