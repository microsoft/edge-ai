variable "arc_connected_cluster_id" {
  type        = string
  description = "The resource ID of the connected cluster to deploy Azure IoT Operations Platform to"
}

variable "aio_platform_config" {
  type = object({
    install_cert_manager  = bool
    install_trust_manager = bool
  })
  description = "Install cert-manager and trust-manager extensions"
}

variable "platform" {
  type = object({
    version = string
    train   = string
  })
}

variable "secret_sync_controller" {
  type = object({
    version = string
    train   = string
  })
}

variable "edge_storage_accelerator" {
  type = object({
    version               = string
    train                 = string
    diskStorageClass      = string
    faultToleranceEnabled = bool
  })
}

variable "open_service_mesh" {
  type = object({
    version = string
    train   = string
  })
}
