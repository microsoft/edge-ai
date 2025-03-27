import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

@description('The common component configuration.')
param common core.Common

@secure()
@description('Password used for the host VM')
param adminPassword string

@description('VM count for creating server and cluster node VMs. Defaults to 1 (server node only).')
param vmCount int = 1

/*
  Variables
*/

var arcOnboardingUserManagedIdentityName = 'id-${common.resourcePrefix}-${common.environment}-arc-aio-${common.instance}'

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: arcOnboardingUserManagedIdentityName
}

module vmHost '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-vmHost'
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingUserAssignedIdentityId: arcOnboardingIdentity.id
    vmCount: vmCount
  }
}
