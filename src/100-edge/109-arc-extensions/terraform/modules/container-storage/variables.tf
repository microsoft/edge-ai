variable "arc_connected_cluster_id" {
  type        = string
  description = "The resource ID of the Arc-connected Kubernetes cluster"
}
variable "container_storage_extension" {
  type = object({
    enabled                    = optional(bool)
    version                    = optional(string)
    train                      = optional(string)
    auto_upgrade_minor_version = optional(bool)
    disk_storage_class         = optional(string)
    fault_tolerance_enabled    = optional(bool)
    disk_mount_point           = optional(string)
  })
  description = "container-storage extension configuration object"
}
