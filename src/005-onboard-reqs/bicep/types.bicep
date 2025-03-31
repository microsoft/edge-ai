import * as core from './types.core.bicep'

@export()
@description('Identity type to use for onboarding the cluster to Azure Arc. Allowed values: "id" (User Assigned Managed Identity) or "sp" (Service Principal)')
type OnboardIdentityType = 'id' | 'sp'

@export()
@description('Settings for onboarding identity creation.')
type OnboardIdentitySettings = {
  @description('Should create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc.')
  shouldCreate: bool

  @description('Identity type to use for onboarding the cluster to Azure Arc.')
  identityType: OnboardIdentityType
}

@export()
var onboardIdentityDefaults = {
  shouldCreate: true
  identityType: 'id'
}
