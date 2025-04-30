metadata name = 'User Assigned Managed Identity Module'
metadata description = 'Creates user-assigned managed identities for Secret Store Extension, Azure IoT Operations components and optionally Arc onboarding.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Identity Parameters
*/

@description('Whether to create a User Assigned Managed Identity for onboarding a cluster to Azure Arc.')
param shouldCreateArcOnboardingUami bool

/*
  Resources
*/

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (shouldCreateArcOnboardingUami) {
  name: 'id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}'
  location: common.location
}

resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${common.resourcePrefix}-sse-${common.environment}-${common.instance}'
  location: common.location
}

resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
  location: common.location
}

resource deployIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${common.resourcePrefix}-deploy-${common.environment}-${common.instance}'
  location: common.location
}

/*
  Outputs
*/

@description('The Secret Store Extension User Assigned Managed Identity name.')
output sseIdentityName string = sseIdentity.name

@description('The Secret Store Extension User Assigned Managed Identity ID.')
output sseIdentityId string = sseIdentity.id

@description('The Secret Store Extension User Assigned Managed Identity Principal ID.')
output sseIdentityPrincipalId string = sseIdentity.properties.principalId

@description('The Azure IoT Operations User Assigned Managed Identity name.')
output aioIdentityName string = aioIdentity.name

@description('The Azure IoT Operations User Assigned Managed Identity ID.')
output aioIdentityId string = aioIdentity.id

@description('The Azure IoT Operations User Assigned Managed Identity Principal ID.')
output aioIdentityPrincipalId string = aioIdentity.properties.principalId

@description('The Deployment User Assigned Managed Identity name.')
output deployIdentityName string = deployIdentity.name

@description('The Deployment User Assigned Managed Identity ID.')
output deployIdentityId string = deployIdentity.id

@description('The Deployment User Assigned Managed Identity Principal ID.')
output deployIdentityPrincipalId string = deployIdentity.properties.principalId

@description('The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityId string? = shouldCreateArcOnboardingUami ? arcOnboardingIdentity.id : null

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityName string? = shouldCreateArcOnboardingUami ? arcOnboardingIdentity.name : null
