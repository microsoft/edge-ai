
variable "resource_group_id" {
  type        = string
  description = "The id of the Azure Resource Group."
}

variable "arc_connected_cluster_id" {
  type        = string
  description = "The id of the Azure Arc connected cluster resource for Azure IoT Operations."
  default     = null
}

variable "azure_monitor_workspace_name" {
  type        = string
  description = "The name of the Azure Monitor resource."
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Azure Log Analytics resource."
}

variable "grafana_name" {
  type        = string
  description = "The name of the Azure Managed Grafana resource."
}
