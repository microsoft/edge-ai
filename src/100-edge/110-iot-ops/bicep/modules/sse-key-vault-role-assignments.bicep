metadata name = 'Key Vault Role Assignment Module'
metadata description = 'Assigns roles for Secret Sync to access Key Vault.'

/*
  Parameters
*/

@description('The name of the Key Vault to scope the role assignments.')
param keyVaultName string

@description('The Principal ID for the Secret Sync User Assigned Managed Identity.')
param sseIdentityPrincipalId string

/*
  Resources
*/

resource sseKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

@description('Assigns "Key Vault Reader" role to the Secret Sync User Assigned Managed Identity.')
resource keyVaultReaderSseUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sseIdentityPrincipalId, '21090545-7ca7-4776-b22c-e363652d74d2')
  scope: sseKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '21090545-7ca7-4776-b22c-e363652d74d2'
    )
    principalId: sseIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

@description('Assigns "Key Vault Secrets User" role to the Secret Sync User Assigned Managed Identity.')
resource keyVaultSecretsUserSseUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sseIdentityPrincipalId, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: sseKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: sseIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The ID of the Key Vault Reader role assignment.')
output readerRoleId string = keyVaultReaderSseUami.id

@description('The ID of the Key Vault Secrets User role assignment.')
output secretsUserRoleId string = keyVaultSecretsUserSseUami.id
