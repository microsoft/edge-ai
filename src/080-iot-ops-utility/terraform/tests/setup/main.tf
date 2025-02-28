terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
  required_version = ">= 1.9.8, < 2.0"
}

locals {
  subscription_id_part                       = "/subscriptions/00000000-0000-0000-0000-000000000000"
  resource_prefix                            = "a${random_string.prefix.id}"
  resource_group_name                        = "rg-${local.resource_prefix}"
  resource_group_id                          = "${local.subscription_id_part}/resourceGroups/${local.resource_group_name}"
  arc_connected_cluster_name                 = "arc-${local.resource_prefix}"
  arc_connected_cluster_id                   = "${local.resource_group_id}/providers/Microsoft.Kubernetes/connectedClusters/${local.arc_connected_cluster_name}"
  log_analytics_workspace_name               = "log-${local.resource_prefix}"
  log_analytics_workspace_id                 = "${local.resource_group_id}/providers/Microsoft.OperationalInsights/workspaces/${local.log_analytics_workspace_name}"
  log_analytics_workspace_primary_shared_key = "00000000-0000-0000-0000-000000000000"
  azure_monitor_workspace_name               = "azmon-${local.resource_prefix}"
  azure_monitor_workspace_id                 = "${local.resource_group_id}/providers/Microsoft.Monitor/accounts/${local.azure_monitor_workspace_name}"
  azure_managed_grafana_name                 = "amg-${local.resource_prefix}"
  azure_managed_grafana_id                   = "${local.resource_group_id}/providers/Microsoft.Dashboard/grafana/${local.azure_managed_grafana_name}"
  metrics_data_collection_rule_name          = "dcr-metrics-${local.resource_prefix}"
  metrics_data_collection_rule_id            = "${local.resource_group_id}/providers/Microsoft.Insights/dataCollectionRules/${local.metrics_data_collection_rule_name}"
  logs_data_collection_rule_name             = "dcr-logs-${local.resource_prefix}"
  logs_data_collection_rule_id               = "${local.resource_group_id}/providers/Microsoft.Insights/dataCollectionRules/${local.logs_data_collection_rule_name}"
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

output "resource_prefix" {
  value = "a${random_string.prefix.id}"
}

output "aio_resource_group" {
  value = {
    name     = local.resource_group_name
    id       = local.resource_group_id
    location = "eastus2"
  }
}

output "arc_connected_cluster" {
  value = {
    name     = local.arc_connected_cluster_name
    id       = local.arc_connected_cluster_id
    location = "eastus2"
  }
}

output "aio_log_analytics_workspace" {
  value = {
    id                 = local.log_analytics_workspace_id
    workspace_id       = local.log_analytics_workspace_id
    primary_shared_key = local.log_analytics_workspace_primary_shared_key
  }
}

output "aio_azure_monitor_workspace" {
  value = {
    id = local.azure_monitor_workspace_id
  }
}

output "aio_azure_managed_grafana" {
  value = {
    id = local.azure_managed_grafana_id
  }
}

output "aio_metrics_data_collection_rule" {
  value = {
    name = local.metrics_data_collection_rule_name
    id   = local.metrics_data_collection_rule_id
  }
}

output "aio_logs_data_collection_rule" {
  value = {
    name = local.logs_data_collection_rule_name
    id   = local.logs_data_collection_rule_id
  }
}

