variable "environment" {
  type        = string
  description = "Environment for all resources in this module: dev, test, or prod"
}

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

variable "existing_resource_group_name" {
  type        = string
  default     = ""
  description = "Name of the pre-existing resource group in which to create resources. If left empty, a new resource group will be created"
}

variable "vm_sku_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D8s_v3"
}

variable "vm_username" {
  type        = string
  description = "Name for the user to create on the VM. If left empty, a random name will be generated"
  default     = ""
}

variable "use_service_principal_for_arc_onboarding_instead_of_managed_identity" {
  type        = bool
  description = "If set to true, a new service principal will be created for connecting to Azure Arc. If set to false, a managed identity will be created instead."
  default     = false
}

variable "add_current_entra_user_cluster_admin" {
  type        = bool
  default     = false
  description = "Only applies if 'environment!=prod'. Adds the current user as cluster-admin cluster role binding"
}

variable "custom_locations_oid" {
  type        = string
  default     = ""
  description = "The object id of the Custom Locations Entra ID application for your tenant. If none is provided, the script will attempt to retrieve this requiring 'Application.Read.All' or 'Directory.Read.All' permissions."
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
  validation {
    condition     = var.trust_config.source != "CustomerManaged" || (var.environment != "prod" && var.add_current_entra_user_cluster_admin)
    error_message = "TrustConfig 'CustomerManaged' is only supported in non 'prod' environments with 'add_current_entra_user_cluster_admin=true', as it utilizes connectedk8s proxy"
  }
  description = "TrustConfig must be one of 'SelfSigned' or 'CustomerManaged'. Defaults to SelfSigned."
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