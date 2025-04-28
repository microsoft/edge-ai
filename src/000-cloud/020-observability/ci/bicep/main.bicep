metadata name = 'Observability CI'
metadata description = 'CI deployment wrapper for Observability component that deploys Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules.'

import * as core from '../../bicep/types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Module Deployment
*/

module observabilityModule '../../bicep/main.bicep' = {
  name: '${deployment().name}-observability'
  params: {
    common: common
  }
}
