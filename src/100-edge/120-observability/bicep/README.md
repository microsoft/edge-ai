<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Observability Component

Deploys observability resources including cluster extensions for metrics and logs collection, and rule groups for monitoring.

## Parameters

| Name                                   | Description                                                           | Type                                              | Default                                         | Required |
|:---------------------------------------|:----------------------------------------------------------------------|:--------------------------------------------------|:------------------------------------------------|:---------|
| arcConnectedClusterName                | The name of the Arc connected cluster.                                | `string`                                          | n/a                                             | yes      |
| observabilitySettings                  | The observability settings.                                           | `[_1.ObservabilitySettings](#user-defined-types)` | [variables('_1.observabilitySettingsDefaults')] | no       |
| azureMonitorWorkspaceName              | The name of the Azure Monitor Workspace.                              | `string`                                          | n/a                                             | yes      |
| logAnalyticsWorkspaceName              | The name of the Log Analytics Workspace.                              | `string`                                          | n/a                                             | yes      |
| logAnalyticsWorkspaceResourceGroupName | The resource group name where the Log Analytics Workspace is located. | `string`                                          | [resourceGroup().name]                          | no       |
| azureManagedGrafanaName                | The name of the Azure Managed Grafana instance.                       | `string`                                          | n/a                                             | yes      |
| metricsDataCollectionRuleName          | The name of the metrics data collection rule.                         | `string`                                          | n/a                                             | yes      |
| logsDataCollectionRuleName             | The name of the logs data collection rule.                            | `string`                                          | n/a                                             | yes      |
| telemetry_opt_out                      | Whether to opt out of telemetry data collection.                      | `bool`                                            | `false`                                         | no       |

## Resources

| Name                 | Type                              | API Version |
|:---------------------|:----------------------------------|:------------|
| clusterExtensionsObs | `Microsoft.Resources/deployments` | 2025-04-01  |
| ruleAssociationsObs  | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name                 | Description                                                                                                         |
|:---------------------|:--------------------------------------------------------------------------------------------------------------------|
| clusterExtensionsObs | Creates the cluster extensions required to expose cluster and container metrics.                                    |
| ruleAssociationsObs  | Creates the data collection rule associations required for observability and Prometheus rule groups for monitoring. |

## Module Details

### clusterExtensionsObs

Creates the cluster extensions required to expose cluster and container metrics.

#### Parameters for clusterExtensionsObs

| Name                                   | Description                                                           | Type     | Default                | Required |
|:---------------------------------------|:----------------------------------------------------------------------|:---------|:-----------------------|:---------|
| arcConnectedClusterName                | The name of the Arc connected cluster.                                | `string` | n/a                    | yes      |
| azureMonitorWorkspaceName              | The name of the Azure Monitor Workspace.                              | `string` | n/a                    | yes      |
| logAnalyticsWorkspaceName              | The name of the Log Analytics Workspace.                              | `string` | n/a                    | yes      |
| logAnalyticsWorkspaceResourceGroupName | The resource group name where the Log Analytics Workspace is located. | `string` | [resourceGroup().name] | no       |
| azureManagedGrafanaName                | The name of the Azure Managed Grafana instance.                       | `string` | n/a                    | yes      |

#### Resources for clusterExtensionsObs

| Name                    | Type                                           | API Version |
|:------------------------|:-----------------------------------------------|:------------|
| azuremonitor-metrics    | `Microsoft.KubernetesConfiguration/extensions` | 2024-11-01  |
| azuremonitor-containers | `Microsoft.KubernetesConfiguration/extensions` | 2024-11-01  |

#### Outputs for clusterExtensionsObs

| Name                      | Type     | Description                      |
|:--------------------------|:---------|:---------------------------------|
| containerMetricsExtension | `object` | The container metrics extension. |
| containerLogsExtension    | `object` | The container logs extension.    |

### ruleAssociationsObs

Creates the data collection rule associations required for observability and Prometheus rule groups for monitoring.

#### Parameters for ruleAssociationsObs

| Name                          | Description                                                                                        | Type     | Default | Required |
|:------------------------------|:---------------------------------------------------------------------------------------------------|:---------|:--------|:---------|
| arcConnectedClusterName       | The name of the Arc connected cluster.                                                             | `string` | n/a     | yes      |
| azureMonitorWorkspaceName     | The name of the Azure Monitor Workspace.                                                           | `string` | n/a     | yes      |
| metricsDataCollectionRuleName | The name of the metrics data collection rule.                                                      | `string` | n/a     | yes      |
| logsDataCollectionRuleName    | The name of the logs data collection rule.                                                         | `string` | n/a     | yes      |
| scrapeInterval                | Interval to scrape metrics from the cluster, valid values are between 1m and 30m (PT1M and PT30M). | `string` | PT1M    | no       |

#### Resources for ruleAssociationsObs

| Name                                                              | Type                                                | API Version |
|:------------------------------------------------------------------|:----------------------------------------------------|:------------|
| [parameters('metricsDataCollectionRuleName')]                     | `Microsoft.Insights/dataCollectionRuleAssociations` | 2022-06-01  |
| [parameters('logsDataCollectionRuleName')]                        | `Microsoft.Insights/dataCollectionRuleAssociations` | 2022-06-01  |
| [format('node-group-{0}', parameters('arcConnectedClusterName'))] | `Microsoft.AlertsManagement/prometheusRuleGroups`   | 2023-03-01  |
| [format('k8s-group-{0}', parameters('arcConnectedClusterName'))]  | `Microsoft.AlertsManagement/prometheusRuleGroups`   | 2023-03-01  |

#### Outputs for ruleAssociationsObs

| Name                                 | Type     | Description                                   |
|:-------------------------------------|:---------|:----------------------------------------------|
| metricsDataCollectionRuleAssociation | `object` | The metrics data collection rule association. |
| logsDataCollectionRuleAssociation    | `object` | The logs data collection rule association.    |
| nodeRecordingRuleGroup               | `object` | The node recording rule group.                |
| kubernetesRecordingRuleGroup         | `object` | The Kubernetes recording rule group.          |

## User Defined Types

### `_1.ObservabilitySettings`

Settings for the observability configuration.

| Property       | Type     | Description                                                                                        |
|:---------------|:---------|:---------------------------------------------------------------------------------------------------|
| scrapeInterval | `string` | Interval to scrape metrics from the cluster, valid values are between 1m and 30m (PT1M and PT30M). |

## Outputs

| Name              | Type     | Description                                              |
|:------------------|:---------|:---------------------------------------------------------|
| clusterExtensions | `object` | The container extensions for observability.              |
| ruleAssociations  | `object` | The data collection rule associations for observability. |

<!-- END_BICEP_DOCS -->