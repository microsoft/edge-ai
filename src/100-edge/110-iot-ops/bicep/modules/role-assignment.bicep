metadata name = 'Role Assignment Module'
metadata description = 'Assigns roles for Secret Sync to access Key Vault.'

@description('The name of the Key Vault to scope the role assignments.')
param keyVaultName string

@description('The Principal ID for the Secret Sync User Assigned Managed Identity.')
param sseUserAssignedIdentityName string

resource sseKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sseUserAssignedIdentityName
}

@description('Assigns "Key Vault Reader" role to the Secret Sync User Assigned Managed Identity.')
resource keyVaultReaderSseUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sseUserAssignedIdentityName, '21090545-7ca7-4776-b22c-e363652d74d2')
  scope: sseKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '21090545-7ca7-4776-b22c-e363652d74d2'
    )
    principalId: sseIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Assigns "Key Vault Secrets User" role to the Secret Sync User Assigned Managed Identity.')
resource keyVaultSecretsUserSseUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sseUserAssignedIdentityName, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: sseKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: sseIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
