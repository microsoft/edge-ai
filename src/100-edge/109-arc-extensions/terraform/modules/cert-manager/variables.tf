variable "arc_connected_cluster_id" {
  type        = string
  description = "The resource ID of the Arc-connected Kubernetes cluster"
}
variable "cert_manager_extension" {
  type = object({
    enabled                            = optional(bool)
    version                            = optional(string)
    train                              = optional(string)
    auto_upgrade_minor_version         = optional(bool)
    agent_operation_timeout_in_minutes = optional(number)
    global_telemetry_enabled           = optional(bool)
  })
  description = "cert-manager extension configuration object"
}
