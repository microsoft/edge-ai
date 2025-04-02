metadata name = 'Onboard Infrastructure Prerequisites'
metadata description = 'Creates the required resources needed for an edge IaC deployment.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Onboard Identity Parameters
*/

@description('Settings for the onboarding identity.')
param onboardIdentityConfig types.OnboardIdentitySettings = types.onboardIdentityDefaults

/*
  Modules
*/

// Onboard Identity module deployment at resource group scope
module onboardIdentity './modules/onboard-identity.bicep' = if (onboardIdentityConfig.shouldCreate) {
  name: '${deployment().name}-onboardIdentity'
  // scope: resourceGroup(resourceGroup.outputs.resourceGroupName)
  params: {
    common: common
    identityType: onboardIdentityConfig.identityType
  }
}

/*
  Outputs
*/

@description('The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingUserManagedIdentityId string = onboardIdentityConfig.shouldCreate ? onboardIdentity.outputs.userManagedIdentityId : ''

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingUserManagedIdentityName string = onboardIdentityConfig.shouldCreate ? onboardIdentity.outputs.userManagedIdentityName : ''

@description('The Service Principal Client ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingSpClientId string = onboardIdentityConfig.shouldCreate ? onboardIdentity.outputs.servicePrincipalClientId : ''
