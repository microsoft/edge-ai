// CI Wrapper for the Onboard Requirements Component
// This is a simple wrapper that passes parameters to the main component

import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

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
  Modules
*/

module onboardReqs '../../bicep/main.bicep' = {
  name: '${deployment().name}-onboardReqs'
  params: {
    common: common
    onboardIdentityConfig: onboardIdentityConfig
  }
}

/*
  Outputs
*/

@description('The Service Principal Client ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output servicePrincipalClientId string = onboardReqs.outputs.arcOnboardingSpClientId

