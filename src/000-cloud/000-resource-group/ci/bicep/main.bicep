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

@description('Whether to use an existing resource group instead of creating a new one.')
param useExistingResourceGroup bool = false

@description('The name for the resource group. If not provided, a default name will be generated.')
param resourceGroupName string = ''

module ci '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
    useExistingResourceGroup: useExistingResourceGroup
    resourceGroupName: !empty(resourceGroupName) ? resourceGroupName : null
  }
}
