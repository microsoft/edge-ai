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

variable "aio_ca" {
  type = object({
    root_ca_cert_pem  = string
    ca_cert_chain_pem = string
    ca_key_pem        = string
  })
  sensitive = true
  default   = null
  validation {
    condition     = var.aio_ca == null ? true : (var.aio_ca.ca_cert_chain_pem != "" && var.aio_ca.ca_key_pem != "" && var.aio_ca.root_ca_cert_pem != "")
    error_message = "The values for ca_key_pem, ca_cert_chain_pem and root_ca_cert_pem must be provided"
  }

  validation {
    condition     = var.trust_config.source != "SelfSigned" || var.aio_ca == null
    error_message = "AIO CA cannot be provided when Trust Source is set to SelfSigned"
  }
  description = "CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged"
}

variable "enable_aio_instance_secret_sync" {
  type        = bool
  default     = true
  description = "After AIO instance is created, enable secret sync on the instance"
}
