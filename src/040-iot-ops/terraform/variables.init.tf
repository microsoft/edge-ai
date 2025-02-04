/*
 * Optional Variables
 */

variable "platform" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "0.7.6"
    train   = "preview"
  }
}

variable "open_service_mesh" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "1.2.10"
    train   = "stable"
  }
}

variable "edge_storage_accelerator" {
  type = object({
    version               = string
    train                 = string
    diskStorageClass      = string
    faultToleranceEnabled = bool
  })
  default = {
    version               = "2.2.2"
    train                 = "stable"
    diskStorageClass      = ""
    faultToleranceEnabled = false
  }
}

variable "secret_sync_controller" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "0.6.7"
    train   = "preview"
  }
}
