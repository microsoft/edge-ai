import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Virtual Network Parameters
*/

@description('Networking configuration settings.')
param networkingConfig types.NetworkingConfig = types.networkingConfigDefaults

/*
  Modules
*/

module virtualNetwork '../../bicep/main.bicep' = {
  name: '${deployment().name}-main'
  params: {
    common: common
    networkingConfig: networkingConfig
  }
}
