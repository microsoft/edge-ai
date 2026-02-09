/*
 * Optional Variables
 */

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

variable "enable_opc_ua_simulator" {
  type        = bool
  default     = true
  description = "Deploy OPC UA Simulator to the cluster"
}

variable "should_enable_otel_collector" {
  type        = bool
  description = "Whether to deploy the OpenTelemetry Collector and Azure Monitor ConfigMap"
  default     = true
}

variable "should_assign_key_vault_roles" {
  description = "Whether to assign Key Vault roles to provided Secret Sync identity."
  type        = bool
  default     = true
}

variable "registry_endpoints" {
  type = list(object({
    name                           = string
    host                           = string
    acr_resource_id                = optional(string)
    should_assign_acr_pull_for_aio = optional(bool, false)
    authentication = object({
      method = string
      system_assigned_managed_identity_settings = optional(object({
        audience = optional(string, "https://management.azure.com/")
      }))
      user_assigned_managed_identity_settings = optional(object({
        client_id = string
        tenant_id = string
        scope     = optional(string)
      }))
      artifact_pull_secret_settings = optional(object({
        secret_ref = string
      }))
    })
  }))

  default     = []
  description = <<-EOT
    List of additional container registry endpoints for pulling custom artifacts (WASM modules, graph definitions, connector templates).
    MCR (mcr.microsoft.com) is always added automatically with anonymous authentication.

    The `acr_resource_id` field enables automatic AcrPull role assignment for ACR endpoints
    using SystemAssignedManagedIdentity authentication. When `should_assign_acr_pull_for_aio` is true
    and `acr_resource_id` is provided, the AIO extension's identity will be granted AcrPull access to the specified ACR.
  EOT

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", ep.name)) && length(ep.name) >= 3 && length(ep.name) <= 63
    ])
    error_message = "Registry endpoint name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      contains(["SystemAssignedManagedIdentity", "UserAssignedManagedIdentity", "ArtifactPullSecret", "Anonymous"], ep.authentication.method)
    ])
    error_message = "Authentication method must be one of: SystemAssignedManagedIdentity, UserAssignedManagedIdentity, ArtifactPullSecret, Anonymous"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.authentication.method != "UserAssignedManagedIdentity" || (
        ep.authentication.user_assigned_managed_identity_settings != null &&
        ep.authentication.user_assigned_managed_identity_settings.client_id != null &&
        ep.authentication.user_assigned_managed_identity_settings.tenant_id != null
      )
    ])
    error_message = "UserAssignedManagedIdentity authentication requires client_id and tenant_id in user_assigned_managed_identity_settings"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.authentication.method != "ArtifactPullSecret" || (
        ep.authentication.artifact_pull_secret_settings != null &&
        ep.authentication.artifact_pull_secret_settings.secret_ref != null
      )
    ])
    error_message = "ArtifactPullSecret authentication requires secret_ref in artifact_pull_secret_settings"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.name != "mcr" && ep.name != "default"
    ])
    error_message = "Registry endpoint names 'mcr' and 'default' are reserved"
  }

  validation {
    condition = alltrue([
      for ep in var.registry_endpoints :
      ep.acr_resource_id == null || ep.authentication.method == "SystemAssignedManagedIdentity"
    ])
    error_message = "acr_resource_id can only be specified with SystemAssignedManagedIdentity authentication method"
  }
}
