metadata name = 'Security and Identity Component Types'
metadata description = 'Defines specialized types and defaults for the Security and Identity component.'

@export()
@description('Settings for the Storage Account.')
type StorageAccountSettings = {
  @description('Tier for the Storage Account.')
  tier: 'Standard' | 'Premium'

  @description('Replication Type for the Storage Account.')
  replicationType: 'LRS' | 'ZRS' | 'GRS' | 'GZRS' | 'RAGRS' | 'RAGZRS'
}

@export()
@description('Identity type to use for onboarding the cluster to Azure Arc. Allowed values: "id" (User Assigned Managed Identity) or "sp" (Service Principal).')
type OnboardIdentityType = 'id' | 'sp'

@export()
@description('Settings for onboarding identity creation.')
type OnboardIdentitySettings = {
  @description('Whether or not to create either a User Assigned Managed Identity or Service Principal to be used with onboarding a cluster to Azure Arc.')
  shouldCreate: bool

  @description('Identity type to use for onboarding the cluster to Azure Arc.')
  identityType: OnboardIdentityType
}

@export()
var onboardIdentityDefaults = {
  shouldCreate: true
  identityType: 'id'
}
