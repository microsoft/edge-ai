variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "Name of the resource group in which to create resources. If not provided, will default to '$(resource_prefix)-aio-edge-rg'. Will fail if resource group does not exist."
}

variable "connected_cluster_name" {
  type        = string
  default     = null
  description = "Name of the connected cluster to deploy AIO. If not provided, will default to '$(resource_prefix)-arc'. Will fail if connected cluster does not exist."
}

variable "trust_config" {
  type = object({
    source = string
  })
  default = {
    source = "SelfSigned"
  }
  validation {
    condition     = var.trust_config.source == "SelfSigned" || (var.trust_config.source == "CustomerManaged")
    error_message = "TrustConfig must be one of 'SelfSigned' or 'CustomerManaged'"
  }
  description = "TrustConfig must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned. When choosing CustomerManaged, ensure connectedk8s proxy is enabled on the cluster for current user"
}

variable "aio_root_ca" {
  type = object({
    cert_pem        = string
    private_key_pem = string
  })
  sensitive = true
  default   = null
  validation {
    condition     = var.aio_root_ca == null ? true : (var.aio_root_ca.cert_pem != "" && var.aio_root_ca.private_key_pem != "")
    error_message = "Both cert_pem and private_key_pem must be provided"
  }
  description = "Root CA for the MQTT broker"
}

variable "enable_aio_instance_secret_sync" {
  type        = bool
  default     = true
  description = "After AIO instance is created, enable secret sync on the instance"
}
