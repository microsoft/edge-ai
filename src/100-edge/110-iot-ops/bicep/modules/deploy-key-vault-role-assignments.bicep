metadata name = 'Deploy Key Vault Role Assignment Module'
metadata description = 'Assigns required Key Vault roles to the deployment identity for script execution.'

/*
  Parameters
*/

@description('The name of the Key Vault that will have scripts and secrets for deployment.')
param deployKeyVaultName string

@description('The Principal Id for the Deploy User Assigned Managed Identity.')
param deployIdentityPrincipalId string

/*
  Resources
*/

resource deployKeyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: deployKeyVaultName
}

@description('Assigns "Key Vault Secrets Officer" to Deploy User Assigned Managed Identity.')
resource keyVaultSecretsOfficerDeployUami 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deployIdentityPrincipalId!, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: deployKeyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-officer
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    )
    principalId: deployIdentityPrincipalId!
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The ID of the Key Vault Secrets Officer role assignment.')
output secretsOfficerRoleId string = keyVaultSecretsOfficerDeployUami.id
