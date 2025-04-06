/*
 * Required Variables
 */

variable "resource_group" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}

variable "arc_connected_cluster" {
  type = object({
    name     = string
    id       = string
    location = string
  })
}

variable "aio_log_analytics_workspace" {
  type = object({
    id                 = string
    workspace_id       = string
    primary_shared_key = string
  })
}

variable "aio_azure_monitor_workspace" {
  type = object({
    id = string
  })
}

variable "aio_azure_managed_grafana" {
  type = object({
    id = string
  })
}

variable "aio_metrics_data_collection_rule" {
  type = object({
    name = string
    id   = string
  })
}

variable "aio_logs_data_collection_rule" {
  type = object({
    name = string
    id   = string
  })
}
