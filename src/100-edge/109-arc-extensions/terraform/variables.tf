variable "arc_extensions" {
  type = object({
    cert_manager_extension = optional(object({
      enabled                            = optional(bool)
      version                            = optional(string)
      train                              = optional(string)
      auto_upgrade_minor_version         = optional(bool)
      agent_operation_timeout_in_minutes = optional(number)
      global_telemetry_enabled           = optional(bool)
    }))
    container_storage_extension = optional(object({
      enabled                    = optional(bool)
      version                    = optional(string)
      train                      = optional(string)
      auto_upgrade_minor_version = optional(bool)
      disk_storage_class         = optional(string)
      fault_tolerance_enabled    = optional(bool)
      disk_mount_point           = optional(string)
    }))
  })
  description = "Combined configuration object for Arc extensions (cert-manager and container storage)"
  default = {
    cert_manager_extension = {
      enabled                            = true
      version                            = "0.7.0"
      train                              = "stable"
      auto_upgrade_minor_version         = false
      agent_operation_timeout_in_minutes = 20
      global_telemetry_enabled           = true
    }
    container_storage_extension = {
      enabled                    = true
      version                    = "2.6.0"
      train                      = "stable"
      auto_upgrade_minor_version = false
      disk_storage_class         = ""
      fault_tolerance_enabled    = false
      disk_mount_point           = "/mnt"
    }
  }
}
