metadata name = 'Observability Component'
metadata description = 'Deploys observability resources including cluster extensions for metrics and logs collection, and rule groups for monitoring.'

import * as types from './types.bicep'

/*
  Arc Connected Cluster Parameters
*/

@description('The name of the Arc connected cluster.')
param arcConnectedClusterName string

/*
  Observability Configuration Parameters
*/

@description('The observability settings.')
param observabilitySettings types.ObservabilitySettings = types.observabilitySettingsDefaults

/*
  Azure Monitor Workspace Parameters
*/

@description('The name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string

@description('The name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string

@description('The resource group name where the Log Analytics Workspace is located.')
param logAnalyticsWorkspaceResourceGroupName string = resourceGroup().name

@description('The name of the Azure Managed Grafana instance.')
param azureManagedGrafanaName string

/*
  Data Collection Rule Parameters
*/

@description('The name of the metrics data collection rule.')
param metricsDataCollectionRuleName string

@description('The name of the logs data collection rule.')
param logsDataCollectionRuleName string

/*
  Modules
*/

module clusterExtensionsObs 'modules/cluster-extensions-obs.bicep' = {
  name: '${deployment().name}-ce'
  params: {
    arcConnectedClusterName: arcConnectedClusterName
    azureMonitorWorkspaceName: azureMonitorWorkspaceName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspaceResourceGroupName
    azureManagedGrafanaName: azureManagedGrafanaName
  }
}

module ruleAssociationsObs 'modules/rule-associations-obs.bicep' = {
  name: '${deployment().name}-ra'
  params: {
    arcConnectedClusterName: arcConnectedClusterName
    azureMonitorWorkspaceName: azureMonitorWorkspaceName
    metricsDataCollectionRuleName: metricsDataCollectionRuleName
    logsDataCollectionRuleName: logsDataCollectionRuleName
    scrapeInterval: observabilitySettings.scrapeInterval
  }
}

/*
  Outputs
*/

@description('The container extensions for observability.')
output clusterExtensions object = {
  containerMetrics: clusterExtensionsObs.outputs.containerMetricsExtension
  containerLogs: clusterExtensionsObs.outputs.containerLogsExtension
}

@description('The data collection rule associations for observability.')
output ruleAssociations object = {
  metricsAssociation: ruleAssociationsObs.outputs.metricsDataCollectionRuleAssociation
  logsAssociation: ruleAssociationsObs.outputs.logsDataCollectionRuleAssociation
}
