/*
  Arc Connected Cluster Parameters
*/

@description('The name of the Arc connected cluster.')
param arcConnectedClusterName string

/*
  Azure Monitor Workspace Parameters
*/

@description('The name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string

@description('The name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string

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
  Module
*/

module ci '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    arcConnectedClusterName: arcConnectedClusterName
    azureMonitorWorkspaceName: azureMonitorWorkspaceName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    azureManagedGrafanaName: azureManagedGrafanaName
    metricsDataCollectionRuleName: metricsDataCollectionRuleName
    logsDataCollectionRuleName: logsDataCollectionRuleName
  }
}
