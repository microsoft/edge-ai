metadata name = 'Key Vault Role Assignment Module'
metadata description = 'Assigns appropriate roles to access Key Vault secrets.'

@description('The name of the Key Vault containing the scripts.')
param keyVaultName string

@description('The principal ID of the Arc identity that needs access to the secrets.')
param arcOnboardingPrincipalId string

@description('The name for the server script secret in Key Vault.')
param serverScriptSecretName string

@description('The name for the node script secret in Key Vault.')
param nodeScriptSecretName string

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName

  resource serverScriptSecret 'secrets' existing = {
    name: serverScriptSecretName
  }

  resource nodeScriptSecret 'secrets' existing = {
    name: nodeScriptSecretName
  }
}

// Role assignments for server script secret
resource keyVaultReaderServerSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    resourceGroup().id,
    arcOnboardingPrincipalId,
    serverScriptSecretName,
    '21090545-7ca7-4776-b22c-e363652d74d2'
  )
  scope: keyVault::serverScriptSecret
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '21090545-7ca7-4776-b22c-e363652d74d2'
    )
    principalId: arcOnboardingPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultSecretsUserServerSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    resourceGroup().id,
    arcOnboardingPrincipalId,
    serverScriptSecretName,
    '4633458b-17de-408a-b874-0445c86b69e6'
  )
  scope: keyVault::serverScriptSecret
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: arcOnboardingPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Role assignments for node script secret
resource keyVaultReaderNodeSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, arcOnboardingPrincipalId, nodeScriptSecretName, '21090545-7ca7-4776-b22c-e363652d74d2')
  scope: keyVault::nodeScriptSecret
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '21090545-7ca7-4776-b22c-e363652d74d2'
    )
    principalId: arcOnboardingPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultSecretsUserNodeSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, arcOnboardingPrincipalId, nodeScriptSecretName, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault::nodeScriptSecret
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: arcOnboardingPrincipalId
    principalType: 'ServicePrincipal'
  }
}
