metadata name = 'IoT Operations Cloud Requirements Component'
metadata description = 'Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.'

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Identity Parameters
*/

@description('Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.')
param shouldCreateArcOnboardingUami bool = true

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

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Resources
*/

@description('Disable telemetry data collection.')
resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

/*
  Modules
*/

module identity 'modules/identity.bicep' = {
  name: '${deployment().name}-identity'
  params: {
    common: common
    shouldCreateArcOnboardingUami: shouldCreateArcOnboardingUami
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
output keyVaultName string? = shouldCreateKeyVault ? keyVault.outputs.keyVaultName : null

@description('The resource ID of the Secret Store Extension Key Vault.')
output keyVaultId string? = shouldCreateKeyVault ? keyVault.outputs.keyVaultId : null

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

@description('The Deployment User Assigned Managed Identity name.')
output deployIdentityName string = identity.outputs.deployIdentityName

@description('The Deployment User Assigned Managed Identity ID.')
output deployIdentityId string = identity.outputs.deployIdentityId

@description('The Deployment User Assigned Managed Identity Principal ID.')
output deployIdentityPrincipalId string = identity.outputs.deployIdentityPrincipalId

@description('The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityId string? = identity.outputs.?arcOnboardingIdentityId

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityName string? = identity.outputs.?arcOnboardingIdentityName
