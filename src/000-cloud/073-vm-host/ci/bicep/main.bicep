import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'
import * as networkTypes from '../../../050-networking/bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Virtual Machine Parameters
*/

@description('Password used for the host VM.')
@secure()
param adminPassword string

@description('VM count for creating server and cluster node VMs. Defaults to 1 (server node only).')
param vmCount int = 1

/*
  Networking Parameters
*/

@description('Networking configuration settings.')
param networkingConfig networkTypes.NetworkingConfig = networkTypes.networkingConfigDefaults

/*
  Local Variables
*/

var arcOnboardingIdentityName = 'id-${common.resourcePrefix}-${common.environment}-arc-aio-${common.instance}'

/*
  Modules
*/

module networking '../../../050-networking/bicep/main.bicep' = {
  name: '${common.resourcePrefix}-networking'
  params: {
    common: common
    networkingConfig: networkingConfig
  }
}

module vmHost '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-vmHost'
  params: {
    common: common
    adminPassword: adminPassword
    arcOnboardingIdentityName: arcOnboardingIdentityName
    vmCount: vmCount
    subnetId: networking.outputs.subnetId
  }
}
