metadata name = 'IoT Operations Cloud Requirements Component'
metadata description = 'Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Identity Parameters
*/

@description('Settings for the onboarding identity.')
param onboardIdentityConfig types.OnboardIdentitySettings = types.onboardIdentityDefaults

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

module identity 'modules/identity.bicep' = {
  name: '${deployment().name}-identity'
  params: {
    common: common
    identityType: onboardIdentityConfig.identityType
  }
}

module keyVault 'modules/key-vault.bicep' = if (shouldCreateKeyVault) {
  name: '${deployment().name}-keyVault'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    common: common
    keyVaultName: keyVaultName
    shouldAssignAdminUserRole: shouldAssignAdminUserRole
    adminUserObjectId: adminUserObjectId
  }
}

/*
  Outputs
*/

@description('The name of the Secret Store Extension Key Vault.')
output keyVaultName string? = keyVault.?outputs.keyVaultName

@description('The resource ID of the Secret Store Extension Key Vault.')
output keyVaultId string? = keyVault.?outputs.keyVaultId

@description('The Secret Store Extension User Assigned Managed Identity name.')
output sseIdentityName string = identity.outputs.sseIdentityName

@description('The Secret Store Extension User Assigned Managed Identity ID.')
output sseIdentityId string = identity.outputs.sseIdentityId

@description('The Secret Store Extension User Assigned Managed Identity Principal ID.')
output sseIdentityPrincipalId string = identity.outputs.sseIdentityPrincipalId

@description('The Azure IoT Operations User Assigned Managed Identity name.')
output aioIdentityName string = identity.outputs.aioIdentityName

@description('The Azure IoT Operations User Assigned Managed Identity ID.')
output aioIdentityId string = identity.outputs.aioIdentityId

@description('The Azure IoT Operations User Assigned Managed Identity Principal ID.')
output aioIdentityPrincipalId string = identity.outputs.aioIdentityPrincipalId

@description('The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityId string? = identity.outputs.?arcOnboardingIdentityId

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityName string? = identity.outputs.?arcOnboardingIdentityName

@description('The Service Principal App (Client) ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output servicePrincipalClientId string? = identity.outputs.?servicePrincipalClientId
