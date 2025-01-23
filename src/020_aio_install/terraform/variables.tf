variable "resource_prefix" {
  type        = string
  description = "Prefix for all resources in this module"
  validation {
    condition     = length(var.resource_prefix) > 0 && can(regex("^[a-zA-Z](?:-?[a-zA-Z0-9])*$", var.resource_prefix))
    error_message = "Resource prefix must not be empty, and must only contain alphanumeric characters and dashes. Must start with an alphabetic character."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources in this module"
  validation {
    condition     = length(var.location) > 0
    error_message = "Location name cannot be empty."
  }
}

variable "existing_resource_group_name" {
  type        = string
  default     = null
  description = "Name of the resource group in which to create resources. If not provided, will look for '$(resource_prefix)-aio-edge-rg'. Will fail if resource group does not exist."
}

variable "existing_key_vault_name" {
  type        = string
  default     = null
  description = "Name of the Azure Key Vault to use by Secret Sync Extension. If not provided, will create new key vault. Will fail if key vault does not exist in provided resource group."
}

variable "existing_connected_cluster_name" {
  type        = string
  default     = null
  description = "Name of the connected cluster to deploy AIO. If not provided, will look for '$(resource_prefix)-arc'. Will fail if connected cluster does not exist."
}

variable "trust_config_source" {
  type    = string
  default = "SelfSigned"
  validation {
    condition     = contains(["SelfSigned", "CustomerManagedByoIssuer", "CustomerManagedGenerateIssuer"], var.trust_config_source)
    error_message = "TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'"
  }
  description = "TrustConfig source must be one of 'SelfSigned', 'CustomerManagedByoIssuer' or 'CustomerManagedGenerateIssuer'. Defaults to SelfSigned. When choosing CustomerManagedGenerateIssuer, ensure connectedk8s proxy is enabled on the cluster for current user. When choosing CustomerManagedByoIssuer, ensure an Issuer and ConfigMap resources exist in the cluster."
}

variable "byo_issuer_trust_settings" {
  type = object({
    issuer_name    = string
    issuer_kind    = string
    configmap_name = string
    configmap_key  = string
  })
  default = null
  validation {
    condition     = var.trust_config_source == "CustomerManagedByoIssuer" ? var.byo_issuer_trust_settings != null : var.byo_issuer_trust_settings == null
    error_message = "If 'trust_config_source' is 'CustomerManagedByoIssuer' then 'byo_issuer_trust_settings' must be non-null. If 'trust_config_source' is any other value, then 'byo_issuer_trust_settings' must be null."
  }
  validation {
    condition = var.byo_issuer_trust_settings == null ? true : alltrue([
      for _, value in var.byo_issuer_trust_settings : (value != null && value != "")
    ])
    error_message = "All fields are required for 'byo_issuer_trust_settings'."
  }
  description = "Settings for CustomerManagedByoIssuer (Bring Your Own Issuer) trust configuration"
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
    condition     = var.trust_config_source != "SelfSigned" || var.aio_ca == null
    error_message = "AIO CA cannot be provided when Trust Source is set to SelfSigned"
  }
  description = "CA certificate for the MQTT broker, can be either Root CA or Root CA with any number of Intermediate CAs. If not provided, a self-signed Root CA with a intermediate will be generated. Only valid when Trust Source is set to CustomerManaged"
}

variable "enable_aio_instance_secret_sync" {
  type        = bool
  default     = true
  description = "After AIO instance is created, enable secret sync on the instance"
}

variable "aio_platform_config" {
  type = object({
    install_cert_manager  = bool
    install_trust_manager = bool
  })
  default = {
    install_cert_manager  = true
    install_trust_manager = true
  }
  validation {
    condition     = var.trust_config_source == "CustomerManagedByoIssuer" ? (var.aio_platform_config.install_cert_manager == false && var.aio_platform_config.install_trust_manager == false) : true
    error_message = "When trust_config_source is CustomerManagedByoIssuer, install_cert_manager and install_trust_manager must be false because these should always be installed as a pre-requisite"
  }
  description = "Install cert-manager and trust-manager extensions"
}

variable "provision_event_hubs" {
  type        = bool
  description = "Whether to provision Azure Event Hubs resources and role assignment"
  default     = true
}

variable "enable_opc_ua_simulator" {
  type        = bool
  default     = false
  description = "Deploy OPC UA Simulator to the cluster"
}

variable "enable_otel_collector" {
  type        = bool
  default     = false
  description = "Deploy the OpenTelemetry Collector and Azure Monitor ConfigMap (optionally used)"
}
