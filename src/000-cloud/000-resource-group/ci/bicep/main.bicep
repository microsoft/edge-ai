import * as core from '../../bicep/types.core.bicep'

targetScope = 'subscription'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Modules
*/

module ci '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
  }
}
