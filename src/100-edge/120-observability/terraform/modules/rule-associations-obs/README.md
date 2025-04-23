<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Data Collection Rule Associations for Observability

Creates the data collection rule associations required to link the right data for observability.
[Data Collection Rule](https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-rule-associations?tabs=cli)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_alert_prometheus_rule_group.kubernetes_recording_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_prometheus_rule_group) | resource |
| [azurerm_monitor_alert_prometheus_rule_group.node_recording_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_prometheus_rule_group) | resource |
| [azurerm_monitor_data_collection_rule_association.logs_data_collection_rule_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_monitor_data_collection_rule_association.metrics_data_collection_rule_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_azure\_monitor\_workspace | n/a | ```object({ id = string })``` | n/a | yes |
| aio\_logs\_data\_collection\_rule | n/a | ```object({ name = string id = string })``` | n/a | yes |
| aio\_metrics\_data\_collection\_rule | n/a | ```object({ name = string id = string })``` | n/a | yes |
| aio\_resource\_group | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| arc\_connected\_cluster | n/a | ```object({ name = string id = string location = string })``` | n/a | yes |
| scrape\_interval | Interval to scrape metrics from the cluster | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| logs\_data\_collection\_rule\_association | The logs data collection rule association resource. |
| metrics\_data\_collection\_rule\_association | The metrics data collection rule association resource. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
