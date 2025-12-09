/*
 * Optional Variables
 *
 * IMPORTANT: The variable names in this file ('cert_manager', 'secret_sync_controller',
 * 'edge_storage_accelerator') are explicitly referenced by the
 * aio-version-checker.py script. If you rename these variables or change their structure,
 * you must also update the script and the aio-version-checker-template.yml pipeline.
 */

variable "cert_manager" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "0.6.2"
    train   = "stable"
  }
}

variable "edge_storage_accelerator" {
  type = object({
    version               = string
    train                 = string
    diskStorageClass      = string
    faultToleranceEnabled = bool
    diskMountPoint        = string
  })
  default = {
    version               = "2.6.0"
    train                 = "stable"
    diskStorageClass      = ""
    faultToleranceEnabled = false
    diskMountPoint        = "/mnt"
  }
}

variable "secret_sync_controller" {
  type = object({
    version = string
    train   = string
  })
  default = {
    version = "1.0.2"
    train   = "stable"
  }
}
