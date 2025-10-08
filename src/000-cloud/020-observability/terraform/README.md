<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Observability

Creates a new Azure Monitor Workspace, Log Analytics Workspace and Azure Managed Grafana and assigns the required roles.
[Kubernetes Monitor](https://learn.microsoft.com/azure/azure-monitor/containers/kubernetes-monitoring-enable?tabs=terraform)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |
| azurerm | >= 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.8.0 |
| terraform | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_dashboard_grafana.monitor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dashboard_grafana) | resource |
| [azurerm_log_analytics_solution.monitor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution) | resource |
| [azurerm_log_analytics_workspace.monitor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_data_collection_endpoint.data_collection_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_endpoint) | resource |
| [azurerm_monitor_data_collection_rule.logs_data_collection_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
| [azurerm_monitor_data_collection_rule.metrics_data_collection_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
| [azurerm_monitor_private_link_scope.monitor_private_link_scope](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope) | resource |
| [azurerm_monitor_private_link_scoped_service.application_insights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service) | resource |
| [azurerm_monitor_private_link_scoped_service.data_collection_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service) | resource |
| [azurerm_monitor_private_link_scoped_service.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service) | resource |
| [azurerm_monitor_workspace.monitor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_workspace) | resource |
| [azurerm_private_dns_zone.agentsvc_azure_automation_net](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.monitor_azure_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.ods_opinsights_azure_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.oms_opinsights_azure_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.agentsvc_azure_automation_net](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.monitor_azure_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.ods_opinsights_azure_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.oms_opinsights_azure_com](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.monitor_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.grafana_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.grafana_logs_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.grafana_metrics_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.grafana_monitoring_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [terraform_data.apply_scripts](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| application\_insights | ./modules/application-insights | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azmon\_resource\_group | The resource group object containing name and id for observability resources. | ```object({ name = string id = string location = string })``` | n/a | yes |
| environment | Environment for all resources in this module: dev, test, or prod | `string` | n/a | yes |
| location | Azure region where all resources will be deployed | `string` | n/a | yes |
| resource\_prefix | Prefix for all resources in this module | `string` | n/a | yes |
| app\_insights\_application\_type | The type of application being monitored by Application Insights. | `string` | `"web"` | no |
| app\_insights\_retention\_in\_days | The retention period in days for Application Insights data. | `number` | `30` | no |
| daily\_quota\_in\_gb | Daily quota to write logs in log analytics | `number` | `10` | no |
| grafana\_admin\_principal\_id | Object id of a user to grant grafana admin access to. Leave blank to not grant access to any users | `string` | `null` | no |
| grafana\_major\_version | Major version of grafana to use | `string` | `"11"` | no |
| instance | Instance identifier for naming resources: 001, 002, etc | `string` | `"001"` | no |
| log\_retention\_in\_days | Duration to retain logs in log analytics | `number` | `30` | no |
| logs\_data\_collection\_rule\_namespaces | List of cluster namespaces to be exposed in the log analytics workspace | `list(string)` | ```[ "kube-system", "gatekeeper-system", "azure-arc", "azure-iot-operations" ]``` | no |
| logs\_data\_collection\_rule\_streams | List of streams to be enabled in the log analytics workspace | `list(string)` | ```[ "Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory", "Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory", "Microsoft-ContainerNodeInventory", "Microsoft-Perf" ]``` | no |
| private\_endpoint\_subnet\_id | The ID of the subnet where private endpoints will be created. Required if should\_enable\_private\_endpoints is true. | `string` | `null` | no |
| should\_enable\_private\_endpoints | Whether to enable private endpoints for Azure Monitor and Application Insights. | `bool` | `false` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| virtual\_network\_id | The ID of the virtual network for private DNS zone linking. Required if should\_enable\_private\_endpoints is true. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| application\_insights | The Application Insights resource object with connection details for monitoring applications. |
| azure\_managed\_grafana | n/a |
| azure\_monitor\_workspace | n/a |
| data\_collection\_endpoint | n/a |
| log\_analytics\_workspace | n/a |
| logs\_data\_collection\_rule | n/a |
| metrics\_data\_collection\_rule | n/a |
| monitor\_private\_endpoint | The private endpoint for Azure Monitor services. |
| monitor\_private\_link\_scope | The Azure Monitor Private Link Scope for private endpoint connections. |
| private\_dns\_zones | The private DNS zones for Azure Monitor private link. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
