variable "arc_connected_cluster" {
  type = object({
    id = string
  })
}

variable "aio_log_analytics_workspace" {
  type = object({
    id = string
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
