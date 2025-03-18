/*
 * Optional Variables
 *
 * IMPORTANT: The variable names in this file ('platform', 'secret_sync_controller',
 * 'edge_storage_accelerator', 'open_service_mesh') are explicitly referenced by the
 * aio-version-checker.py script. If you rename these variables or change their structure,
 * you must also update the script and the aio-version-checker-template.yml pipeline.
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
