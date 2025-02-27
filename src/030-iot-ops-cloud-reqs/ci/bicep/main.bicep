import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

@description('The common component configuration.')
param common core.Common

/*
  Modules
*/

module iotOpsCloudReqs '../../bicep/main.bicep' = {
  name: '${common.resourcePrefix}-iotOpsCloudReqs'
  params: {
    common: common
  }
}
