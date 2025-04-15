import * as core from '../../bicep/types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Modules
*/

module iotOpsCloudReqs '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
  }
}
