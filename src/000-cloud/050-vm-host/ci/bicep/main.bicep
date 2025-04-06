import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

@description('The common component configuration.')
param common core.Common

// Note this wil be replaced with SSH public key usage in future, simplifying until we have automation scripts for Bicep deployment
@secure()
@description('Password used for the host VM.')
param adminPassword string

@description('VM count for creating server and cluster node VMs. Defaults to 1 (server node only).')
param vmCount int = 1

/*
  Variables
*/

var arcOnboardingIdentityName = 'id-${common.resourcePrefix}-${common.environment}-arc-aio-${common.instance}'

module vmHost '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-vmHost'
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingIdentityName: arcOnboardingIdentityName
    vmCount: vmCount
  }
}
